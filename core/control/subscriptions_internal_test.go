package control

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"sync"
	"sync/atomic"
	"testing"
	"time"

	"google.golang.org/protobuf/types/known/durationpb"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/errs"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
	"github.com/levvs-one/sora-client/core/secret"
	"github.com/levvs-one/sora-client/core/session"
	"github.com/levvs-one/sora-client/core/subscription"
)

// panel is a fake provider whose answer a test changes between fetches.
type panel struct {
	mu      sync.Mutex
	body    string
	info    subscription.Info
	err     error
	calls   atomic.Int32
	release chan struct{}
}

func (p *panel) Fetch(context.Context, string, subscription.FetchOptions) (subscription.Result, error) {
	p.calls.Add(1)
	if p.release != nil {
		<-p.release
	}
	p.mu.Lock()
	defer p.mu.Unlock()
	if p.err != nil {
		return subscription.Result{}, p.err
	}
	return subscription.Result{Body: []byte(p.body), Info: p.info}, nil
}

func (p *panel) set(body string, err error) {
	p.mu.Lock()
	defer p.mu.Unlock()
	p.body, p.err = body, err
}

func servers(names ...string) string {
	var lines []string
	for _, n := range names {
		lines = append(lines, fmt.Sprintf("trojan://password-%s@%s.example.com:443?security=tls#%s", n, n, n))
	}
	return strings.Join(lines, "\n")
}

func bookServer(t *testing.T, dir string, fetcher Fetcher) (*Server, *secret.Store) {
	t.Helper()
	store, err := secret.Open(dir, secret.Options{Protector: secret.FileProtector{}})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = store.Close() })
	auth, err := NewAuthenticator(make([]byte, TokenLen))
	if err != nil {
		t.Fatal(err)
	}
	sessions := session.NewManager(session.ManagerConfig{
		TunUp: func(context.Context, string) error { return nil },
		Factory: func(context.Context, *engine.Plan) (engine.Engine, error) {
			return nil, errors.New("subscription tests start no session")
		},
	})
	srv, err := New(Config{Authenticator: auth, Secrets: store, Fetcher: fetcher, Sessions: sessions})
	if err != nil {
		t.Fatal(err)
	}
	return srv, store
}

// saveAndWait saves a new subscription and waits for its first fetch.
func saveAndWait(t *testing.T, b *subscriptionBook, settings *corev1.SubscriptionSettings) *corev1.SubscriptionState {
	t.Helper()
	changes, stop := b.watch()
	defer stop()
	state, err := b.save(settings)
	if err != nil {
		t.Fatal(err)
	}
	for {
		select {
		case s := <-changes:
			if s.GetSettings().GetId() == state.GetSettings().GetId() && !s.GetUpdating() && (s.GetLastUpdate() != nil || s.GetLastError() != nil) {
				return s
			}
		case <-time.After(5 * time.Second):
			t.Fatal("the first fetch never finished")
		}
	}
}

func TestSubscriptionKeepsItsServersWhenTheProviderFails(t *testing.T) {
	p := &panel{body: servers("tokyo", "berlin"), info: subscription.Info{Title: "Provider"}}
	srv, store := bookServer(t, t.TempDir(), p)
	state := saveAndWait(t, srv.subs, &corev1.SubscriptionSettings{Url: "https://panel.example/sub/abc", AutoUpdate: true})
	id := state.GetSettings().GetId()
	if len(state.GetOutbounds()) != 2 || state.GetDisplayName() != "Provider" || state.GetSettings().GetUrl() != "" {
		t.Fatalf("state = %v: two servers, the provider title, and never the link", state)
	}

	for name, fail := range map[string]func(){
		"provider down": func() {
			p.set("", errs.Newf(errs.CodeUnavailable, errs.KeySubscriptionStatus, "the provider answered 502"))
		},
		"html instead":      func() { p.set("<html><body>Checking your browser</body></html>", nil) },
		"no servers at all": func() { p.set("# nothing here\n", nil) },
	} {
		fail()
		got, err := srv.subs.refresh(context.Background(), id)
		if err == nil || len(got.GetOutbounds()) != 2 || got.GetLastError() == nil {
			t.Fatalf("%s: err %v, state %v: the last good servers must stay, with the error", name, err, got)
		}
		at := srv.subs.nextUpdate(srv.subs.records[id])
		if !at.Before(time.Now().Add(defaultUpdateInterval)) {
			t.Fatalf("%s: a failure must retry sooner than the interval, next %s", name, at)
		}
	}
	for _, ref := range srv.subs.records[id].Servers {
		if !store.Has(ref) {
			t.Fatalf("a failed update removed credential %s", ref)
		}
	}
}

func TestDroppedServersLoseTheirCredentialsAndOthersStay(t *testing.T) {
	p := &panel{body: servers("tokyo", "berlin", "paris")}
	srv, store := bookServer(t, t.TempDir(), p)
	if err := store.Put("s1_imported_by_hand", []byte("manual")); err != nil {
		t.Fatal(err)
	}
	state := saveAndWait(t, srv.subs, &corev1.SubscriptionSettings{Url: "https://panel.example/sub/abc"})
	id := state.GetSettings().GetId()
	before := append([]string(nil), srv.subs.records[id].Servers...)

	p.set(servers("tokyo", "paris"), nil)
	if _, err := srv.subs.refresh(context.Background(), id); err != nil {
		t.Fatal(err)
	}
	after := srv.subs.records[id].Servers
	if len(after) != 2 {
		t.Fatalf("servers after = %v", after)
	}
	removed := 0
	for _, ref := range before {
		if !store.Has(ref) {
			removed++
		}
	}
	if removed != 1 || !store.Has("s1_imported_by_hand") {
		t.Fatalf("removed %d credentials, manual kept %v", removed, store.Has("s1_imported_by_hand"))
	}

	if err := srv.subs.delete(id); err != nil {
		t.Fatal(err)
	}
	for _, ref := range store.Refs() {
		if strings.HasPrefix(ref, "u1_"+id) {
			t.Fatalf("deleting the subscription left %s in the vault", ref)
		}
	}
}

func TestSaveRefusesDuplicatesBadIntervalsAndHeaderInjection(t *testing.T) {
	srv, _ := bookServer(t, t.TempDir(), &panel{body: servers("a")})
	saveAndWait(t, srv.subs, &corev1.SubscriptionSettings{Url: "https://Panel.Example/sub/abc#mine"})
	cases := map[string]*corev1.SubscriptionSettings{
		"same link":           {Url: "https://panel.example/sub/abc"},
		"plain http":          {Url: "http://panel.example/sub/other"},
		"ten minutes":         {Url: "https://panel.example/sub/b", UpdateInterval: durationpb.New(10 * time.Minute)},
		"a year":              {Url: "https://panel.example/sub/c", UpdateInterval: durationpb.New(365 * 24 * time.Hour)},
		"user agent injected": {Url: "https://panel.example/sub/d", UserAgent: "Sora\r\nCookie: x"},
		"no link":             {},
		"unknown id":          {Id: "0011223344556677", Name: "x"},
	}
	for name, settings := range cases {
		if _, err := srv.subs.save(settings); err == nil {
			t.Errorf("%s must be refused", name)
		}
	}
}

func TestRefreshRunsOnceAndADeletedSubscriptionStaysDeleted(t *testing.T) {
	p := &panel{body: servers("a")}
	srv, store := bookServer(t, t.TempDir(), p)
	state := saveAndWait(t, srv.subs, &corev1.SubscriptionSettings{Url: "https://panel.example/sub/abc"})
	id := state.GetSettings().GetId()
	p.calls.Store(0)
	p.release = make(chan struct{})

	done := make(chan error, 1)
	go func() {
		_, err := srv.subs.refresh(context.Background(), id)
		done <- err
	}()
	for p.calls.Load() == 0 {
		time.Sleep(time.Millisecond)
	}
	second, err := srv.subs.refresh(context.Background(), id)
	if err != nil || !second.GetUpdating() {
		t.Fatalf("a second refresh while one runs answers the state, got %v, %v", second, err)
	}
	if err := srv.subs.delete(id); err != nil {
		t.Fatal(err)
	}
	close(p.release)
	if err := <-done; err == nil {
		t.Fatal("the update of a deleted subscription must not succeed")
	}
	if p.calls.Load() != 1 {
		t.Fatalf("the provider was asked %d times", p.calls.Load())
	}
	if len(srv.subs.list()) != 0 {
		t.Fatal("the update brought a deleted subscription back")
	}
	for _, ref := range store.Refs() {
		if strings.HasPrefix(ref, "u1_") {
			t.Fatalf("the update wrote %s for a deleted subscription", ref)
		}
	}
}

func TestSubscriptionsSurviveARestartIncludingLargeLists(t *testing.T) {
	dir := t.TempDir()
	names := make([]string, 700)
	for i := range names {
		names[i] = fmt.Sprintf("node%03d", i)
	}
	srv, store := bookServer(t, dir, &panel{body: servers(names...), info: subscription.Info{Title: "Big"}})
	state := saveAndWait(t, srv.subs, &corev1.SubscriptionSettings{Url: "https://panel.example/sub/big", AutoUpdate: true, Name: "Mine"})
	id := state.GetSettings().GetId()
	if srv.subs.records[id].ListParts < 2 {
		t.Fatalf("a list of %d servers should take several vault entries, took %d", len(names), srv.subs.records[id].ListParts)
	}
	_ = store.Close()

	restarted, _ := bookServer(t, dir, &panel{err: errors.New("offline")})
	got := restarted.subs.list()
	if len(got) != 1 || len(got[0].GetOutbounds()) != len(names) || got[0].GetDisplayName() != "Mine" || got[0].GetLastUpdate() == nil {
		t.Fatalf("after a restart: %d subscriptions, %d servers, name %q", len(got), len(got[0].GetOutbounds()), got[0].GetDisplayName())
	}
}

func TestSchedulerCatchesUpAfterTheMachineSlept(t *testing.T) {
	p := &panel{body: servers("a")}
	srv, _ := bookServer(t, t.TempDir(), p)
	state := saveAndWait(t, srv.subs, &corev1.SubscriptionSettings{Url: "https://panel.example/sub/abc", AutoUpdate: true})
	id := state.GetSettings().GetId()
	p.calls.Store(0)

	// Wall time jumps two days ahead, as after a sleep; the scheduler reads the
	// wall clock, so the update that fell due during the sleep runs at once.
	srv.subs.mu.Lock()
	srv.subs.now = func() time.Time { return time.Now().Add(48 * time.Hour) }
	srv.subs.mu.Unlock()
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	go srv.subs.run(ctx)
	deadline := time.Now().Add(5 * time.Second)
	for p.calls.Load() == 0 {
		if time.Now().After(deadline) {
			t.Fatalf("the overdue update of %s never ran", id)
		}
		time.Sleep(10 * time.Millisecond)
	}
}

func TestDisplayNameIsNeverEmpty(t *testing.T) {
	for want, rec := range map[string]*subscriptionRecord{
		"Mine":              {Name: "Mine", Info: subscription.Info{Title: "Provider"}},
		"Provider":          {Info: subscription.Info{Title: "Provider"}},
		"panel.example.com": {URL: "https://panel.example.com/sub/x"},
		"0011223344556677":  {ID: "0011223344556677"},
	} {
		if got := displayName(rec); got != want {
			t.Errorf("display name = %q, want %q", got, want)
		}
	}
}
