package mihomo

import (
	"context"
	"fmt"
	"net"
	"net/http"
	"net/http/httptest"
	"net/netip"
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

func TestLiveLegacyFakeIPCacheMigration(t *testing.T) {
	path := os.Getenv(Prober.EnvVar)
	if path == "" {
		t.Skipf("set %s to exercise persistent fake-IP cache migration", Prober.EnvVar)
	}
	ctx, cancel := context.WithTimeout(t.Context(), 45*time.Second)
	defer cancel()
	binary, err := Prober.Probe(ctx, path)
	if err != nil {
		t.Fatal(err)
	}
	control, err := supervise.FreePort()
	if err != nil {
		t.Fatal(err)
	}
	dnsPort, err := supervise.FreePort()
	if err != nil {
		t.Fatal(err)
	}
	home := t.TempDir()
	rt := supervise.Runtime{HomeDir: home, ControlAddr: fmt.Sprintf("127.0.0.1:%d", control), Secret: "cache-test"}
	p := livePlan("cache-upgrade")
	p.DNS = engine.DNS{Enabled: true, Mode: string(engine.DNSFakeIP), FakeIPRange: "172.19.0.0/16",
		HijackTun: []string{fmt.Sprintf("127.0.0.1:%d", dnsPort)},
		Servers:   []engine.DNSServer{{Tag: "local", Transport: engine.DNSPlain, Address: "127.0.0.1", Port: 9}}}
	if err := (driver{}).Prepare(rt, binary); err != nil {
		t.Fatal(err)
	}
	resolver := &net.Resolver{PreferGo: true, Dial: func(ctx context.Context, network, _ string) (net.Conn, error) {
		return (&net.Dialer{}).DialContext(ctx, network, p.DNS.HijackTun[0])
	}}
	lookup := func() netip.Addr {
		t.Helper()
		lookupCtx, stop := context.WithTimeout(ctx, 5*time.Second)
		defer stop()
		ticker := time.NewTicker(50 * time.Millisecond)
		defer ticker.Stop()
		for {
			ips, err := resolver.LookupNetIP(lookupCtx, "ip4", "persistent-cache.example")
			if err == nil {
				if len(ips) != 1 {
					t.Fatalf("fake-IP DNS response = %v, want one address", ips)
				}
				return ips[0].Unmap()
			}
			// The controller can answer before the DNS listener has opened.
			// Retry readiness errors, never a successful but stale address.
			select {
			case <-lookupCtx.Done():
				t.Fatalf("fake-IP DNS listener not ready: %v", err)
			case <-ticker.C:
			}
		}
	}
	// Run the actual engine without Sora's migration, then kill it before
	// its shutdown handler writes the offset used for upstream pool detection.
	rawStart := func() *supervise.Process {
		t.Helper()
		cfg, err := (driver{}).Render(p, rt)
		if err != nil {
			t.Fatal(err)
		}
		proc, err := supervise.Start(ctx, supervise.Spec{Name: "mihomo-cache", Path: path,
			Args: (driver{}).RunArgs(rt), Dir: home, Config: cfg})
		if err != nil {
			t.Fatal(err)
		}
		t.Cleanup(func() { _ = proc.Stop(context.Background(), 0) })
		for {
			if _, err := (driver{}).Handshake(ctx, rt); err == nil {
				return proc
			}
			if proc.Exited() || ctx.Err() != nil {
				t.Fatalf("engine not ready: %v %s", proc.Err(), proc.Output().Last(8))
			}
			time.Sleep(50 * time.Millisecond)
		}
	}
	old := rawStart()
	cached := lookup()
	if !netip.MustParsePrefix("172.19.0.0/16").Contains(cached) {
		t.Fatalf("old pool returned %s", cached)
	}
	if err := old.Stop(ctx, 0); err != nil {
		t.Fatal(err)
	}
	p.DNS.FakeIPRange = "198.18.0.0/16"
	unfixed := rawStart()
	if got := lookup(); got != cached {
		t.Fatalf("old-cache reproduction returned %s, want %s", got, cached)
	}
	t.Logf("unmigrated engine returned legacy cached address %s after pool change", cached)
	if err := unfixed.Stop(ctx, 0); err != nil {
		t.Fatal(err)
	}
	fixed, err := New(supervise.Config{Binary: binary, HomeDir: home, StartTimeout: 10 * time.Second})
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = fixed.Close() }()
	for _, pool := range []string{"198.18.0.0/16", "198.19.0.0/16"} {
		p.DNS.FakeIPRange = pool
		if err := fixed.Apply(ctx, p); err != nil {
			t.Fatal(err)
		}
		if got := lookup(); !netip.MustParsePrefix(pool).Contains(got) {
			t.Fatalf("migrated %s returned %s", pool, got)
		}
		t.Logf("migrated pool %s returned a current fake address", pool)
	}
}
