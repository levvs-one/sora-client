package mihomo

import (
	"context"
	"net/netip"
	"os"
	"runtime"
	"strings"
	"testing"

	"gopkg.in/yaml.v3"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/enginetest"
	"github.com/levvs-one/sora-client/core/engine/supervise"
)

func testPlan() *engine.Plan {
	return &engine.Plan{
		SessionID:  "session-1",
		LocalProxy: engine.LocalProxy{Enabled: true},
		Outbounds: []engine.Outbound{
			{
				ID: "srv-1", Name: "Tokyo 01", Protocol: engine.ProtocolVLESS,
				Server: "jp.example.com", Port: 443, UUID: "11111111-2222-3333-4444-555555555555",
				Flow:      "xtls-rprx-vision",
				TLS:       engine.TLS{Enabled: true, ServerName: "jp.example.com", ALPN: []string{"h2", "http/1.1"}, Fingerprint: "chrome"},
				Transport: engine.Transport{Type: "tcp"},
			},
			{
				ID: "srv-2", Name: "Berlin H2", Protocol: engine.ProtocolHysteria2,
				Server: "de.example.com", Port: 8443, Password: "hunter2hunter2",
				TLS: engine.TLS{Enabled: true, ServerName: "de.example.com"},
			},
			{ID: "direct", Protocol: engine.ProtocolDirect},
		},
		Groups: []engine.Group{
			{Name: "Выбор сервера", Type: engine.GroupSelect, Outbounds: []string{"srv-1", "srv-2", "direct"}},
			{Name: "Авто", Type: engine.GroupURLTest, Outbounds: []string{"srv-1", "srv-2"}, Interval: 120},
		},
		Rules: []engine.Rule{
			{Type: engine.RuleGeoSite, Value: "ads", Target: "reject"},
			{Type: engine.RuleDomainSuffix, Value: "internal.local", Target: "direct"},
			{Type: engine.RuleIPCIDR, Value: "10.0.0.0/8", Target: "direct", NoResolve: true},
			{Type: engine.RuleIPCIDR, Value: "2001:db8::/32", Target: "srv-1"},
			{Type: engine.RuleMatchAll, Target: "srv-2"},
		},
		DNS: engine.DNS{
			Enabled: true, Mode: string(engine.DNSFakeIP),
			Servers: []engine.DNSServer{{Tag: "ali", Transport: engine.DNSTLS, Address: "223.5.5.5"}},
		},
		Tun:     engine.Tun{Enabled: true, Stack: "mixed", MTU: 1420, AutoRoute: true},
		Options: engine.Options{LogLevel: "warning", Mode: "rule", GeoData: true, TestURL: engine.TestURLProduction},
	}
}

func testRuntime(t *testing.T) Runtime {
	t.Helper()
	return Runtime{
		HomeDir:        t.TempDir(),
		ControllerAddr: "127.0.0.1:23456",
		Secret:         "c0ffee",
		MixedPort:      21000,
		TestURL:        engine.TestURLProduction,
	}
}

func TestRenderProducesEveryBlockTheEngineNeeds(t *testing.T) {
	out, err := Render(testPlan(), testRuntime(t))
	if err != nil {
		t.Fatalf("Render: %v", err)
	}
	wants := []string{
		"mixed-port: 21000",
		"external-controller: 127.0.0.1:23456",
		"secret: c0ffee",
		"type: vless",
		"flow: xtls-rprx-vision",
		"client-fingerprint: chrome",
		"type: hysteria2",
		"- direct",
		"type: direct",
		"type: select",
		"type: url-test",
		"url: " + engine.TestURLProduction,
		"interval: 120",
		"GEOSITE,ads,REJECT",
		"DOMAIN-SUFFIX,internal.local,DIRECT",
		"IP-CIDR,10.0.0.0/8,DIRECT,no-resolve",
		"IP-CIDR6,2001:db8::/32,Tokyo_01",
		"MATCH,Berlin_H2",
		"enhanced-mode: fake-ip",
		"fake-ip-range: 198.18.0.1/16",
		"stack: mixed",
		"mtu: 1420",
		"geox-url:",
		"store-selected: true",
	}
	for _, want := range wants {
		if !strings.Contains(out, want) {
			t.Errorf("rendered config is missing %q\n---\n%s", want, out)
		}
	}
}

func TestRenderKeepsThePlanRuleOrder(t *testing.T) {
	out, err := Render(testPlan(), testRuntime(t))
	if err != nil {
		t.Fatalf("Render: %v", err)
	}
	order := map[string]int{}
	for i, line := range strings.Split(out, "\n") {
		trimmed := strings.TrimSpace(line)
		switch {
		case strings.HasPrefix(trimmed, "- GEOSITE,ads"):
			order["geo"] = i
		case strings.HasPrefix(trimmed, "- DOMAIN-SUFFIX,internal.local"):
			order["domain"] = i
		case strings.HasPrefix(trimmed, "- IP-CIDR6"):
			order["v6"] = i
		case strings.HasPrefix(trimmed, "- MATCH,"):
			order["match"] = i
		}
	}
	if len(order) != 4 {
		t.Fatalf("rules not found as expected: %+v\n%s", order, out)
	}
	if order["geo"] >= order["domain"] || order["domain"] >= order["v6"] || order["v6"] >= order["match"] {
		t.Fatalf("rule order lost: %+v\n%s", order, out)
	}
}

func TestRenderIsDeterministic(t *testing.T) {
	first, err := Render(testPlan(), testRuntime(t))
	if err != nil {
		t.Fatal(err)
	}
	second, err := Render(testPlan(), testRuntime(t))
	if err != nil {
		t.Fatal(err)
	}
	if first != second {
		t.Error("the same plan must render the same config")
	}
}

func TestRenderRefusesTunWithoutDNS(t *testing.T) {
	plan := testPlan()
	plan.DNS.Enabled = false
	if _, err := Render(plan, testRuntime(t)); err == nil {
		t.Fatal("a tun plan without a resolver must be refused before the engine is started")
	}
}

func TestTunUsesSelectedPoolEvenWithoutFakeDNS(t *testing.T) {
	p := testPlan()
	p.Tun.IPv4 = netip.MustParsePrefix("172.20.0.1/30")
	p.Tun.IPv6 = netip.MustParsePrefix("fdfe:dcba:9877::1/126")
	p.DNS.Mode = "redir-host"
	p.DNS.FakeIPRange = "172.20.0.1/16"
	out, err := Render(p, testRuntime(t))
	if err != nil {
		t.Fatal(err)
	}
	var c config
	if err := yaml.Unmarshal([]byte(out), &c); err != nil {
		t.Fatal(err)
	}
	if c.DNS.FakeIPRange != p.DNS.FakeIPRange || len(c.Tun.Inet6Address) != 1 || c.Tun.Inet6Address[0] != p.Tun.IPv6.String() {
		t.Fatalf("DNS=%+v TUN=%+v", c.DNS, c.Tun)
	}
	if runtime.GOOS == "linux" && (*c.Tun.AutoRoute || *c.Tun.AutoDetectInterface) {
		t.Fatal("Linux routing must belong to the core")
	}
}

func TestRenderSendsProxyOnlyServersToTheProxyResolver(t *testing.T) {
	plan := testPlan()
	plan.DNS.Servers = []engine.DNSServer{
		{Tag: "lane", Transport: engine.DNSTLS, Address: "1.1.1.1", Port: 853, ProxyOnly: true},
		{Tag: "lan", Transport: engine.DNSPlain, Address: "192.168.1.1", Port: 53},
	}
	out, err := Render(plan, testRuntime(t))
	if err != nil {
		t.Fatalf("Render: %v", err)
	}
	begin := strings.Index(out, "proxy-server-nameserver:")
	end := strings.Index(out, "direct-nameserver:")
	if begin < 0 || end < begin {
		t.Fatalf("no proxy resolver block\n---\n%s", out)
	}
	block := out[begin:end]
	if !strings.Contains(block, "tls://1.1.1.1:853") {
		t.Errorf("the proxy-only server must resolve proxy hostnames, got %q", block)
	}
	if strings.Contains(block, "192.168.1.1") {
		t.Errorf("an ordinary server must not join the proxy resolver, got %q", block)
	}
}

func TestSanitizeNameNeutralizesEngineNameInjection(t *testing.T) {
	got := sanitizeName("a,Match,DIRECT\nname", "id-1")
	if strings.ContainsAny(got, ",\n ") {
		t.Fatalf("sanitized name still carries separators: %q", got)
	}
	if sanitizeName("", "") != "server" {
		t.Error("an empty name must fall back to a usable value")
	}
}

// TestEngineAcceptsRenderedPlans runs "mihomo -t" to check types and values.
// Unknown keys are ignored upstream, so proxy.go pins key names to engine
// source.
func TestEngineAcceptsRenderedPlans(t *testing.T) {
	path := os.Getenv(Prober.EnvVar)
	if path == "" {
		t.Skipf("set %s to run mihomo against the rendered plans", Prober.EnvVar)
	}
	ctx := context.Background()
	binary, err := Prober.Probe(ctx, path)
	if err != nil {
		t.Fatal(err)
	}
	all := enginetest.Plan(engine.ProtocolVLESS, engine.ProtocolVMess, engine.ProtocolTrojan,
		engine.ProtocolShadowsocks, engine.ProtocolHysteria2, engine.ProtocolTUIC,
		engine.ProtocolWireGuard, engine.ProtocolSOCKS5, engine.ProtocolHTTP, engine.ProtocolDirect)
	all.Outbounds = append(all.Outbounds, enginetest.AmneziaWG())
	xhttp := enginetest.Plan(engine.ProtocolVLESS)
	xhttp.Outbounds[0].Flow = ""
	xhttp.Outbounds[0].Transport = engine.Transport{Type: "xhttp", Path: "/x", Host: "cdn.example.com", Mode: "stream-one"}
	for name, p := range map[string]*engine.Plan{"all protocols and amneziawg": all, "xhttp": xhttp} {
		t.Run(name, func(t *testing.T) {
			rendered, err := Render(p, Runtime{ControllerAddr: "127.0.0.1:9090", Secret: "s", MixedPort: 7890})
			if err != nil {
				t.Fatal(err)
			}
			home := t.TempDir()
			rt := supervise.Runtime{HomeDir: home}
			if err := (driver{}).Prepare(rt, binary); err != nil {
				t.Fatal(err)
			}
			if err := supervise.Check(ctx, supervise.Spec{Name: "mihomo", Path: binary.Path, Args: driver{}.CheckArgs(rt), Dir: home, Config: []byte(rendered)}); err != nil {
				t.Fatal(err)
			}
			if name != "xhttp" && !strings.Contains(rendered, "amnezia-wg-option") {
				t.Fatal("the AmneziaWG block is missing")
			}
		})
	}
}
