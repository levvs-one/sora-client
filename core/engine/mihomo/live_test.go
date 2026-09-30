package mihomo

import (
	"context"
	"os"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
)

// TestLiveEngineLifecycle runs the real mihomo binary end to end: render,
// offline validation with -t, start, controller handshake, group readout,
// counters, hot apply and shutdown. It is the test that proves the integration
// is not a wish, so it runs whenever an engine binary is available and is
// skipped otherwise, for example in a container without the engine.
func TestLiveEngineLifecycle(t *testing.T) {
	path := os.Getenv(EnvBinary)
	if path == "" {
		t.Skipf("set %s to the path of an engine binary to run this test", EnvBinary)
	}
	ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
	defer cancel()

	binary, err := Probe(ctx, path, 10*time.Second)
	if err != nil {
		t.Fatalf("probe %s: %v", path, err)
	}
	if binary.Goos != "" && binary.Goos != currentOS() {
		t.Skipf("engine binary is built for %s", binary.Goos)
	}

	instance, err := New(Config{
		Binary:        binary,
		HomeDir:       t.TempDir(),
		ProbeURL:      engine.TestURLProduction,
		StartTimeout:  20 * time.Second,
		StopGrace:     3 * time.Second,
		RestartBudget: 1,
	})
	if err != nil {
		t.Fatalf("New: %v", err)
	}
	events, unsubscribe := instance.Events().Subscribe()
	defer unsubscribe()
	defer func() { _ = instance.Close() }()

	go func() {
		for event := range events {
			if event.Message != "" {
				t.Logf("engine event %s/%s: %s", event.Kind, event.State, event.Message)
			}
			if event.Err != nil {
				t.Logf("engine error event %s: %v", event.Kind, event.Err)
			}
		}
	}()

	if err := instance.Apply(ctx, livePlan("первая")); err != nil {
		t.Fatalf("first Apply: %v", err)
	}
	if got := instance.State(); got != engine.StateRunning {
		t.Fatalf("state after Apply = %s, want running", got)
	}
	if instance.Version().Major == 0 {
		t.Error("the version must come from the engine, not from the config")
	}

	groups, err := instance.Groups(ctx)
	if err != nil {
		t.Fatalf("Groups: %v", err)
	}
	var found bool
	for _, g := range groups {
		if g.Name == "Sora" {
			found = true
			if len(g.All) == 0 {
				t.Errorf("group Sora has no members: %+v", g)
			}
		}
	}
	if !found {
		t.Errorf("the group from the plan is missing from %v", groups)
	}

	counters, err := instance.Counters(ctx)
	if err != nil {
		t.Fatalf("Counters: %v", err)
	}
	if counters.At.IsZero() {
		t.Error("counters must carry a timestamp")
	}

	// A second Apply must reuse the running process instead of restarting it.
	if err := instance.Apply(ctx, livePlan("вторая")); err != nil {
		t.Fatalf("hot Apply: %v", err)
	}
	if got := instance.State(); got != engine.StateRunning {
		t.Fatalf("state after hot apply = %s", got)
	}

	if err := instance.Stop(ctx); err != nil {
		t.Fatalf("Stop: %v", err)
	}
	if got := instance.State(); got != engine.StateStopped {
		t.Fatalf("state after Stop = %s", got)
	}
}

// livePlan builds the smallest plan the engine accepts: one direct outbound and
// one selectable group. No tun and no system listener beyond the mixed port.
func livePlan(session string) *engine.Plan {
	return &engine.Plan{
		SessionID: session,
		Outbounds: []engine.Outbound{
			{ID: "edge", Name: "Edge", Protocol: engine.ProtocolShadowsocks, Server: "127.0.0.1", Port: 8388, Password: "live-test-password", Cipher: "aes-256-gcm"},
			{ID: "fallback", Protocol: engine.ProtocolDirect},
		},
		Groups:  []engine.Group{{Name: "Sora", Type: engine.GroupSelect, Outbounds: []string{"edge", "fallback"}}},
		Rules:   []engine.Rule{{Type: engine.RuleMatchAll, Target: "fallback"}},
		Options: engine.Options{LogLevel: "warning", Mode: "rule", TestURL: engine.TestURLProduction},
	}
}

func currentOS() string {
	if os.PathSeparator == '\\' {
		return "windows"
	}
	return "linux"
}
