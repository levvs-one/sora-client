package xray

import (
	"context"
	"encoding/json"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/enginetest"
	"github.com/levvs-one/sora-client/core/engine/supervise"
)

var allProtocols = []engine.Protocol{
	engine.ProtocolVLESS, engine.ProtocolVMess, engine.ProtocolTrojan, engine.ProtocolShadowsocks,
	engine.ProtocolHysteria2, engine.ProtocolWireGuard, engine.ProtocolSOCKS5, engine.ProtocolHTTP,
	engine.ProtocolDirect,
}

var testRuntime = supervise.Runtime{LocalPort: 7890, ControlAddr: "127.0.0.1:9090", ProbeURL: engine.TestURLProduction}

func hysteriaWithoutObfs(p *engine.Plan) *engine.Plan {
	for i := range p.Outbounds {
		if p.Outbounds[i].Protocol == engine.ProtocolHysteria2 {
			p.Outbounds[i].Obfs, p.Outbounds[i].ObfsParam = "", ""
		}
	}
	return p
}

func TestRenderPinsSelectGroupAndBalancesAutoGroup(t *testing.T) {
	p := enginetest.Plan(engine.ProtocolVLESS, engine.ProtocolTrojan)
	raw, err := Render(p, testRuntime, nil)
	if err != nil {
		t.Fatal(err)
	}
	var cfg struct {
		Routing struct {
			Rules     []map[string]any `json:"rules"`
			Balancers []map[string]any `json:"balancers"`
		} `json:"routing"`
		Observatory map[string]any `json:"observatory"`
	}
	if err := json.Unmarshal(raw, &cfg); err != nil {
		t.Fatal(err)
	}
	last := cfg.Routing.Rules[len(cfg.Routing.Rules)-1]
	// The selector resolves to its nested automatic group, requiring a
	// balancer tag.
	if last["balancerTag"] != "b-1" {
		t.Fatalf("default route = %v, want the balancer of Auto", last)
	}
	if len(cfg.Routing.Balancers) != 1 || cfg.Observatory == nil {
		t.Fatalf("an automatic group needs a balancer and the observatory: %s", raw)
	}

	raw, err = Render(p, testRuntime, Selection{"Proxy": "trojan"})
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(string(raw), `{"network":"tcp,udp","outboundTag":"o0002"}`) {
		t.Fatalf("pinned member must become the default route: %s", raw)
	}
}

func TestRenderRoutesProxiesThroughFragment(t *testing.T) {
	p := enginetest.Plan(engine.ProtocolTrojan)
	p.Options.Fragment = engine.Fragment{Enabled: true}
	raw, err := Render(p, testRuntime, nil)
	if err != nil {
		t.Fatal(err)
	}
	for _, want := range []string{`"dialerProxy":"fragment"`, `"packets":"tlshello"`} {
		if !strings.Contains(string(raw), want) {
			t.Errorf("rendered config lacks %s", want)
		}
	}
}

func TestRenderRefusesUnreadableHysteriaObfs(t *testing.T) {
	if _, err := Render(enginetest.Plan(engine.ProtocolHysteria2), testRuntime, nil); err == nil {
		t.Fatal("hysteria2 obfs must be refused rather than silently dropped")
	}
}

func TestRenderRefusesUnsupportedTLSVerificationSetting(t *testing.T) {
	for _, protocol := range []engine.Protocol{engine.ProtocolVLESS, engine.ProtocolTrojan, engine.ProtocolHysteria2} {
		p := hysteriaWithoutObfs(enginetest.Plan(protocol))
		p.Outbounds[0].TLS = engine.TLS{Enabled: true, Insecure: true}
		if _, err := Render(p, testRuntime, nil); err == nil {
			t.Errorf("%s silently dropped disabled certificate verification", protocol)
		}
	}
	for _, tls := range []engine.TLS{{Insecure: true}, {Enabled: true, Reality: true, Insecure: true, RealityPublicKey: "public-key"}} {
		p := enginetest.Plan(engine.ProtocolVLESS)
		p.Outbounds[0].TLS = tls
		raw, err := Render(p, testRuntime, nil)
		if err != nil || strings.Contains(string(raw), "allowInsecure") {
			t.Errorf("an inactive TLS flag should not reject plaintext or REALITY: %s, %v", raw, err)
		}
	}
}

func TestTagsAreNeverPrefixesOfEachOther(t *testing.T) {
	seen := map[string]bool{}
	for i := 0; i < engine.MaxOutbounds; i++ {
		seen[outboundTag(i)] = true
	}
	for tag := range seen {
		for n := 1; n < len(tag); n++ {
			if seen[tag[:n]] {
				t.Fatalf("%s is a prefix of %s: a balancer would select both", tag[:n], tag)
			}
		}
	}
}

func binary(t *testing.T) supervise.Binary {
	t.Helper()
	path := os.Getenv(Prober.EnvVar)
	if path == "" {
		t.Skipf("set %s to run Xray against the rendered plans", Prober.EnvVar)
	}
	b, err := Prober.Probe(context.Background(), path)
	if err != nil {
		t.Fatal(err)
	}
	return b
}

// TestEngineAcceptsRenderedPlans runs "xray run -test". geoip.dat and
// geosite.dat must be next to the binary, as shipped by Sora.
func TestEngineAcceptsRenderedPlans(t *testing.T) {
	b := binary(t)
	xhttp := enginetest.Plan(engine.ProtocolVLESS)
	xhttp.Outbounds[0].Flow = ""
	xhttp.Outbounds[0].Transport = engine.Transport{Type: "xhttp", Path: "/x", Mode: "stream-one"}
	fragment := hysteriaWithoutObfs(enginetest.Plan(allProtocols...))
	fragment.Options.Fragment.Enabled = true
	for name, p := range map[string]*engine.Plan{
		"all protocols": hysteriaWithoutObfs(enginetest.Plan(allProtocols...)),
		"xhttp reality": xhttp,
		"fragment":      fragment,
	} {
		t.Run(name, func(t *testing.T) {
			raw, err := Render(p, testRuntime, nil)
			if err != nil {
				t.Fatal(err)
			}
			home := t.TempDir()
			if err := supervise.Check(context.Background(), supervise.Spec{Name: "xray", Path: b.Path, Args: (&driver{}).CheckArgs(testRuntime), Dir: home, Config: raw}); err != nil {
				t.Fatal(err)
			}
		})
	}
}

// TestLiveEngineLifecycle checks startup, metrics, counters, groups, selection
// restart, real tester-process latency, and shutdown.
func TestLiveEngineLifecycle(t *testing.T) {
	b := binary(t)
	ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
	defer cancel()
	instance, err := New(supervise.Config{Binary: b, HomeDir: t.TempDir(), RestartBudget: 1})
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = instance.Close() }()
	p := &engine.Plan{
		SessionID: "live",
		Outbounds: []engine.Outbound{
			{ID: "edge", Name: "Edge", Protocol: engine.ProtocolShadowsocks, Server: "127.0.0.1", Port: 8388, Password: "live-test-password", Cipher: "aes-256-gcm"},
			{ID: "out", Name: "Direct", Protocol: engine.ProtocolDirect},
		},
		Groups:  []engine.Group{{Name: "Sora", Type: engine.GroupSelect, Outbounds: []string{"edge", "out"}}},
		Rules:   []engine.Rule{{Type: engine.RuleMatchAll, Target: "Sora"}},
		Options: engine.Options{LogLevel: "warning"},
	}
	if err := instance.Apply(ctx, p); err != nil {
		t.Fatalf("Apply: %v", err)
	}
	if _, err := instance.Counters(ctx); err != nil {
		t.Fatalf("Counters: %v", err)
	}
	if err := instance.Select(ctx, "Sora", "Direct"); err != nil {
		t.Fatalf("Select: %v", err)
	}
	groups, err := instance.Groups(ctx)
	if err != nil || len(groups) != 1 || groups[0].Selected != "Direct" {
		t.Fatalf("Groups after Select = %+v, %v", groups, err)
	}
	if d, err := instance.Delay(ctx, "Direct", "", 5*time.Second); err != nil || d <= 0 {
		t.Fatalf("Delay through the direct outbound = %v, %v", d, err)
	}
	if _, err := instance.Delay(ctx, "Edge", "", 2*time.Second); err == nil {
		t.Error("a dead server must not report a latency")
	}
	if err := instance.Stop(ctx); err != nil {
		t.Fatalf("Stop: %v", err)
	}
}
