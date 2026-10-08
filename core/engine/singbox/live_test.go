package singbox

import (
	"context"
	"os"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/supervise"
)

// TestLiveEngineLifecycle checks startup, handshake, groups, selection,
// counters, configuration restart, and shutdown with a real sing-box binary.
func TestLiveEngineLifecycle(t *testing.T) {
	path := os.Getenv(Prober.EnvVar)
	if path == "" {
		t.Skipf("set %s to the path of an engine binary to run this test", Prober.EnvVar)
	}
	ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
	defer cancel()
	binary, err := Prober.Probe(ctx, path)
	if err != nil {
		t.Fatal(err)
	}
	instance, err := New(supervise.Config{Binary: binary, HomeDir: t.TempDir(), RestartBudget: 1})
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = instance.Close() }()

	if err := instance.Apply(ctx, livePlan()); err != nil {
		t.Fatalf("Apply: %v", err)
	}
	if v := instance.Version(); v.Major != 1 {
		t.Errorf("version %q must come from the running engine", v)
	}
	groups, err := instance.Groups(ctx)
	if err != nil || len(groups) != 1 || groups[0].Name != "Sora" {
		t.Fatalf("Groups = %+v, %v", groups, err)
	}
	if err := instance.Select(ctx, "Sora", "direct-out"); err != nil {
		t.Fatalf("Select: %v", err)
	}
	if groups, _ = instance.Groups(ctx); groups[0].Selected != "direct-out" {
		t.Errorf("selection did not stick: %+v", groups[0])
	}
	if _, err := instance.Counters(ctx); err != nil {
		t.Fatalf("Counters: %v", err)
	}
	if err := instance.Apply(ctx, livePlan()); err != nil {
		t.Fatalf("second Apply: %v", err)
	}
	if got := instance.State(); got != engine.StateRunning {
		t.Fatalf("state after restart = %s", got)
	}
	if err := instance.Stop(ctx); err != nil {
		t.Fatalf("Stop: %v", err)
	}
}

func livePlan() *engine.Plan {
	return &engine.Plan{
		SessionID: "live",
		Outbounds: []engine.Outbound{
			{ID: "edge", Name: "Edge", Protocol: engine.ProtocolShadowsocks, Server: "127.0.0.1", Port: 8388, Password: "live-test-password", Cipher: "aes-256-gcm"},
			{ID: "direct-out", Name: "Direct", Protocol: engine.ProtocolDirect},
		},
		Groups:  []engine.Group{{Name: "Sora", Type: engine.GroupSelect, Outbounds: []string{"edge", "direct-out"}}},
		Rules:   []engine.Rule{{Type: engine.RuleMatchAll, Target: "Sora"}},
		Options: engine.Options{LogLevel: "warning", TestURL: engine.TestURLProduction},
	}
}
