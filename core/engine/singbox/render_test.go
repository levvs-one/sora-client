package singbox

import (
	"context"
	"encoding/json"
	"net/netip"
	"os"
	"runtime"
	"strings"
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/enginetest"
	"github.com/levvs-one/sora-client/core/engine/supervise"
)

var allProtocols = []engine.Protocol{
	engine.ProtocolVLESS, engine.ProtocolVMess, engine.ProtocolTrojan, engine.ProtocolShadowsocks,
	engine.ProtocolHysteria2, engine.ProtocolTUIC, engine.ProtocolAnyTLS, engine.ProtocolWireGuard,
	engine.ProtocolSOCKS5, engine.ProtocolHTTP, engine.ProtocolDirect,
}

var testRuntime = supervise.Runtime{LocalPort: 7890, ControlAddr: "127.0.0.1:9090", Secret: "secret", ProbeURL: engine.TestURLProduction}

func render(t *testing.T, p *engine.Plan) map[string]any {
	t.Helper()
	raw, err := Render(p, testRuntime)
	if err != nil {
		t.Fatalf("Render: %v", err)
	}
	var out map[string]any
	if err := json.Unmarshal(raw, &out); err != nil {
		t.Fatalf("rendered config is not JSON: %v", err)
	}
	return out
}

func TestRenderPlacesWireGuardInEndpoints(t *testing.T) {
	cfg := render(t, enginetest.Plan(engine.ProtocolWireGuard, engine.ProtocolVLESS))
	endpoints, _ := cfg["endpoints"].([]any)
	if len(endpoints) != 1 || endpoints[0].(map[string]any)["type"] != "wireguard" {
		t.Fatalf("wireguard must be an endpoint since sing-box 1.13, got %v", cfg["endpoints"])
	}
	for _, o := range cfg["outbounds"].([]any) {
		if o.(map[string]any)["type"] == "wireguard" {
			t.Fatal("wireguard must not be rendered as an outbound")
		}
	}
}

func TestRenderTurnsGeoRulesIntoRuleSets(t *testing.T) {
	cfg := render(t, enginetest.Plan(engine.ProtocolVLESS))
	route := cfg["route"].(map[string]any)
	sets, _ := route["rule_set"].([]any)
	if len(sets) != 1 || !strings.Contains(sets[0].(map[string]any)["url"].(string), "geosite-category-ads-all.srs") {
		t.Fatalf("geosite must become a remote rule set, got %v", route["rule_set"])
	}
	if route["final"] != "Proxy" {
		t.Errorf("final = %v, want the group of the match-all rule", route["final"])
	}
	raw, _ := json.Marshal(route["rules"])
	if !strings.Contains(string(raw), `"ip_is_private":true`) {
		t.Errorf("geoip:private must use ip_is_private, rules: %s", raw)
	}
}

func TestRenderFragmentSkipsQUIC(t *testing.T) {
	p := enginetest.Plan(engine.ProtocolTrojan, engine.ProtocolHysteria2)
	p.Options.Fragment.Enabled = true
	raw, err := Render(p, testRuntime)
	if err != nil {
		t.Fatal(err)
	}
	if strings.Count(string(raw), `"fragment":true`) != 1 {
		t.Fatalf("fragment must be set on the TCP outbound only: %s", raw)
	}
}

func TestRenderRefusesWhatSingBoxCannotCarry(t *testing.T) {
	p := enginetest.Plan(engine.ProtocolVLESS)
	p.Outbounds[0].Transport = engine.Transport{Type: "xhttp"}
	if _, err := Render(p, testRuntime); err == nil {
		t.Fatal("xhttp must be refused")
	}
	p = enginetest.Plan(engine.ProtocolVLESS)
	p.Groups[0].Type = engine.GroupFallback
	if _, err := Render(p, testRuntime); err == nil {
		t.Fatal("fallback groups must be refused")
	}
}

func TestTunUsesSessionAddressesAndLinuxPolicyRouting(t *testing.T) {
	p := enginetest.Plan(engine.ProtocolVLESS)
	p.Tun = engine.Tun{Enabled: true, IPv4: netip.MustParsePrefix("172.20.0.1/30"), IPv6: netip.MustParsePrefix("fdfe:dcba:9877::1/126")}
	cfg := render(t, p)
	var inbound map[string]any
	for _, in := range cfg["inbounds"].([]any) {
		if in.(map[string]any)["type"] == "tun" {
			inbound = in.(map[string]any)
		}
	}
	addresses := inbound["address"].([]any)
	if addresses[0] != p.Tun.IPv4.String() || addresses[1] != p.Tun.IPv6.String() {
		t.Fatalf("TUN addresses = %v", addresses)
	}
	if runtime.GOOS == "linux" {
		if inbound["auto_route"] != false || cfg["route"].(map[string]any)["auto_detect_interface"] != false {
			t.Fatal("Linux routing must belong to the core")
		}
	}
}

// TestEngineAcceptsRenderedPlans checks rendered grammar with "sing-box check"
// whenever a binary is available.
func TestEngineAcceptsRenderedPlans(t *testing.T) {
	path := os.Getenv(Prober.EnvVar)
	if path == "" {
		t.Skipf("set %s to run sing-box against the rendered plans", Prober.EnvVar)
	}
	ctx := context.Background()
	binary, err := Prober.Probe(ctx, path)
	if err != nil {
		t.Fatal(err)
	}
	fake := enginetest.Plan(engine.ProtocolVLESS)
	fake.DNS.Mode = string(engine.DNSFakeIP)
	fragment := enginetest.Plan(allProtocols...)
	fragment.Options.Fragment.Enabled = true
	for name, p := range map[string]*engine.Plan{"all protocols": enginetest.Plan(allProtocols...), "fake-ip": fake, "fragment": fragment} {
		t.Run(name, func(t *testing.T) {
			raw, err := Render(p, testRuntime)
			if err != nil {
				t.Fatal(err)
			}
			home := t.TempDir()
			rt := testRuntime
			rt.HomeDir = home
			if err := supervise.Check(ctx, supervise.Spec{Name: "sing-box", Path: binary.Path, Args: driver{}.CheckArgs(rt), Dir: home, Config: raw}); err != nil {
				t.Fatal(err)
			}
		})
	}
}
