package engine

import (
	"context"
	"errors"
	"slices"
	"strings"
	"testing"
	"time"
)

func TestBackoffGrowsAndCaps(t *testing.T) {
	b := Backoff{Initial: 100 * time.Millisecond, Max: 2 * time.Second, Factor: 2, Rand: func() float64 { return 1 }}
	want := []time.Duration{100, 200, 400, 800, 1600, 2000, 2000}
	for i, expected := range want {
		if got := b.Delay(i); got != expected*time.Millisecond {
			t.Errorf("attempt %d: got %s, want %s", i, got, expected*time.Millisecond)
		}
	}
	lowJitter := Backoff{Initial: time.Second, Max: time.Second, Factor: 2, Rand: func() float64 { return 0 }}
	if got := lowJitter.Delay(3); got != 500*time.Millisecond {
		t.Errorf("jitter must stay within half of the delay, got %s", got)
	}
}

func TestBackoffWaitHonoursCancellation(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	cancel()
	if err := DefaultBackoff().Wait(ctx, 0); !errors.Is(err, context.Canceled) {
		t.Fatalf("Wait must report cancellation, got %v", err)
	}
}

func TestRestartBudgetSlidesAndBlocks(t *testing.T) {
	now := time.Unix(0, 0)
	budget := NewRestartBudget(3, time.Minute, func() time.Time { return now })
	for i := 0; i < 3; i++ {
		if !budget.Allow() {
			t.Fatalf("attempt %d should be allowed", i)
		}
	}
	if budget.Allow() {
		t.Fatal("the fourth attempt inside the window must be refused")
	}
	now = now.Add(2 * time.Minute)
	if !budget.Allow() {
		t.Fatal("attempts must expire with the window")
	}
	budget.Reset()
	if budget.Used() != 0 {
		t.Fatalf("Reset must clear the window, used=%d", budget.Used())
	}
}

func TestRedactorMasksPlanSecretsAndPatterns(t *testing.T) {
	plan := validPlan()
	redactor := NewRedactor(plan.Secrets()...)
	line := "dial https://user:pass@b.example.com:8443 failed " +
		"uuid=aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee password=secret-pass token: abcdef123456"
	masked := redactor.String(line)
	for _, leak := range []string{"secret-pass", "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee", "user:pass", "abcdef123456"} {
		if strings.Contains(masked, leak) {
			t.Errorf("%s leaked into %q", leak, masked)
		}
	}
	if !strings.Contains(masked, "b.example.com") {
		t.Errorf("hostnames stay readable for diagnosis, got %q", masked)
	}
	cause := errors.New("handshake with password=secret-pass failed")
	wrapped := redactor.Err(cause)
	if strings.Contains(wrapped.Error(), "secret-pass") {
		t.Errorf("masked error must not leak: %v", wrapped)
	}
	if !errors.Is(errors.Unwrap(wrapped), cause) {
		t.Error("the wrap chain must survive masking")
	}
}

func TestEventBusDropsInsteadOfBlocking(t *testing.T) {
	bus := NewEventBus(2)
	ch, cancel := bus.Subscribe()
	defer cancel()
	for i := 0; i < 5; i++ {
		bus.Publish(Event{Kind: EventLog, Message: "line"})
	}
	if got := <-ch; got.Message != "line" {
		t.Fatalf("first event lost: %+v", got)
	}
	if bus.Dropped() != 3 {
		t.Errorf("expected 3 dropped events, got %d", bus.Dropped())
	}
}

func TestParseVersion(t *testing.T) {
	for _, in := range []string{"1.19.32", "v1.19.32", "v1.19.32-beta.3"} {
		v, err := ParseVersion(in)
		if err != nil {
			t.Fatalf("%s: %v", in, err)
		}
		if v.Major != 1 || v.Minor != 19 || v.Patch != 32 {
			t.Errorf("%s parsed as %+v", in, v)
		}
	}
	for _, in := range []string{"", "v1.19", "1.19.x"} {
		if _, err := ParseVersion(in); err == nil {
			t.Errorf("%q must not parse", in)
		}
	}
	old, _ := ParseVersion("1.18.9")
	fresh, _ := ParseVersion("v1.19.0")
	if !old.Less(fresh) {
		t.Error("version ordering is wrong")
	}
}

func mustVersion(t *testing.T, s string) Version {
	t.Helper()
	v, err := ParseVersion(s)
	if err != nil {
		t.Fatal(err)
	}
	return v
}

func TestAProfileHidesItsCredentials(t *testing.T) {
	o := Outbound{ID: "p", Protocol: ProtocolXrayProfile, Profile: []byte(`{"outbounds":[{"settings":{"vnext":[{"users":[{"id":"9f1c2d3e-aaaa-bbbb-cccc-0123456789ab"}]}]},
		"streamSettings":{"realitySettings":{"publicKey":"pubkey-value-123","shortId":"shortid42"}}}]}`)}
	secrets := o.Secrets()
	for _, want := range []string{"9f1c2d3e-aaaa-bbbb-cccc-0123456789ab", "pubkey-value-123", "shortid42"} {
		if !slices.Contains(secrets, want) {
			t.Errorf("%q is not masked: %v", want, secrets)
		}
	}
}
