package mihomo

import (
	"context"
	"net/http"
	"net/http/httptest"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/supervise"
)

// TestLiveEngineLifecycle checks render, -t validation, startup, handshake,
// groups, counters, hot apply, and shutdown. It runs when a mihomo binary is
// available and skips otherwise.
func TestLiveEngineLifecycle(t *testing.T) {
	path := os.Getenv(Prober.EnvVar)
	if path == "" {
		t.Skipf("set %s to the path of an engine binary to run this test", Prober.EnvVar)
	}
	ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
	defer cancel()

	binary, err := Prober.Probe(ctx, path)
	if err != nil {
		t.Fatalf("probe %s: %v", path, err)
	}
	if binary.Goos != "" && binary.Goos != currentOS() {
		t.Skipf("engine binary is built for %s", binary.Goos)
	}

	instance, err := New(supervise.Config{
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
			// The engine knows the server as "Edge"; the session and the
			// client know it by its plan id.
			if strings.Join(g.All, ",") != "edge,fallback" {
				t.Errorf("group Sora members = %v, want the plan ids", g.All)
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

	// A second Apply must reuse the running process instead of restarting
	// it.
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

// livePlan returns a direct outbound and selectable group, with no TUN and only
// a mixed listener.
// TestLiveFallbackReportsTheBackupByPlanID starts a fallback group whose
// first server is dead and checks that the group moves to the second one and
// names it by its plan id, which the session reports to the client.
func TestLiveFallbackReportsTheBackupByPlanID(t *testing.T) {
	path := os.Getenv(Prober.EnvVar)
	if path == "" {
		t.Skipf("set %s to the path of an engine binary to run this test", Prober.EnvVar)
	}
	ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
	defer cancel()
	binary, err := Prober.Probe(ctx, path)
	if err != nil {
		t.Fatalf("probe %s: %v", path, err)
	}
	if binary.Goos != "" && binary.Goos != currentOS() {
		t.Skipf("engine binary is built for %s", binary.Goos)
	}
	answers := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusNoContent)
	}))
	defer answers.Close()

	instance, err := New(supervise.Config{
		Binary: binary, HomeDir: t.TempDir(), ProbeURL: answers.URL,
		StartTimeout: 20 * time.Second, StopGrace: 3 * time.Second, RestartBudget: 1,
	})
	if err != nil {
		t.Fatalf("New: %v", err)
	}
	defer func() { _ = instance.Close() }()
	plan := &engine.Plan{
		SessionID: "fallback",
		Outbounds: []engine.Outbound{
			// Nothing listens on port 9 of the loopback.
			{ID: "dead", Name: "Main server", Protocol: engine.ProtocolShadowsocks, Server: "127.0.0.1", Port: 9, Password: "live-test-password", Cipher: "aes-256-gcm"},
			{ID: "spare", Name: "Spare server", Protocol: engine.ProtocolDirect},
		},
		Groups:  []engine.Group{{Name: "sora:failover", Type: engine.GroupFallback, Outbounds: []string{"dead", "spare"}, URL: answers.URL}},
		Rules:   []engine.Rule{{Type: engine.RuleMatchAll, Target: "sora:failover"}},
		Options: engine.Options{LogLevel: "warning", Mode: "rule", TestURL: answers.URL},
	}
	if err := instance.Apply(ctx, plan); err != nil {
		t.Fatalf("Apply: %v", err)
	}
	var last []engine.GroupStatus
	for ctx.Err() == nil {
		if last, err = instance.Groups(ctx); err != nil {
			t.Fatalf("Groups: %v", err)
		}
		for _, g := range last {
			if g.Name == "sora:failover" && g.Selected == "spare" {
				// The session passes over a member whose check failed.
				if g.LatencyMS["dead"] != 0 || g.LatencyMS["spare"] <= 0 {
					t.Errorf("latency = %v, want the dead server at 0 and the spare above", g.LatencyMS)
				}
				return
			}
		}
		time.Sleep(200 * time.Millisecond)
	}
	t.Fatalf("the group never moved to the spare server: %+v", last)
}

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
