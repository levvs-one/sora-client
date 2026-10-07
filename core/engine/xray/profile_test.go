package xray

import (
	"encoding/json"
	"os"
	"os/exec"
	"path/filepath"
	"slices"
	"strings"
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/supervise"
)

// profile is the shape of a Remnawave profile: several outbounds with links
// between them, a balancer over an observatory, and the provider's rules.
const profile = `{"remarks":"Авто","log":{"loglevel":"debug"},
 "inbounds":[{"listen":"127.0.0.1","port":10808,"protocol":"socks","tag":"socks"}],
 "outbounds":[
  {"tag":"auto-a","protocol":"vless","settings":{"vnext":[{"address":"192.0.2.10","port":443,"users":[{"id":"123e4567-e89b-12d3-a456-426614174000","encryption":"none"}]}]},
   "streamSettings":{"network":"xhttp","xhttpSettings":{"path":"/p","mode":"auto","extra":{"xmux":{"maxConnections":2}}},"security":"reality",
   "realitySettings":{"serverName":"www.example.com","fingerprint":"firefox","publicKey":"Z84J2IelR9ch3k8VtlVhhs5ycBUlXA7wHBWcBrjqnAw","shortId":"6ba85179e30d4fc2"}}},
  {"tag":"direct","protocol":"freedom"},{"tag":"block","protocol":"blackhole"}],
 "routing":{"domainStrategy":"AsIs","balancers":[{"tag":"auto","selector":["auto-"],"strategy":{"type":"leastPing"}}],
  "rules":[{"domain":["domain:openai.com"],"balancerTag":"auto"},{"network":"tcp,udp","balancerTag":"auto"}]},
 "observatory":{"subjectSelector":["auto-"],"probeUrl":"https://www.gstatic.com/generate_204","probeInterval":"10s"}}`

func profilePlan(tun bool) *engine.Plan {
	return &engine.Plan{
		SessionID: "s",
		Outbounds: []engine.Outbound{{ID: "p", Name: "Авто", Protocol: engine.ProtocolXrayProfile, Server: "192.0.2.10", Port: 443, Profile: json.RawMessage(profile)}},
		Rules: []engine.Rule{
			{Type: engine.RuleGeoSite, Value: "category-ads-all", Target: "reject"},
			{Type: engine.RuleDomainSuffix, Value: "ru", Target: "direct"},
			{Type: engine.RuleMatchAll, Target: "p"},
		},
		Tun:        engine.Tun{Enabled: tun, DeviceName: engine.TunDevice},
		LocalProxy: engine.LocalProxy{Enabled: !tun},
		DNS:        engine.DNS{Enabled: tun, Servers: []engine.DNSServer{{Tag: "d", Transport: engine.DNSHTTPS, Address: "1.1.1.1"}}},
		Options:    engine.Options{LogLevel: "warning"},
	}
}

func TestAProfileRunsAsWrittenInsideTheSession(t *testing.T) {
	out, err := Render(profilePlan(true), supervise.Runtime{LocalPort: 4000, ControlAddr: ""}, nil)
	if err != nil {
		t.Fatal(err)
	}
	var cfg map[string]any
	if err := json.Unmarshal(out, &cfg); err != nil {
		t.Fatal(err)
	}
	text := string(out)
	if strings.Contains(text, "10808") {
		t.Error("a provider's inbound must never open a listener")
	}
	if _, ok := cfg["metrics"]; ok {
		t.Error("a private plan runs Xray without a metrics listener")
	}
	routing := cfg["routing"].(map[string]any)
	rules := routing["rules"].([]any)
	first := rules[0].(map[string]any)
	if first["outboundTag"] != profileDNS {
		t.Errorf("the tun's DNS comes first: %v", first)
	}
	last := rules[len(rules)-1].(map[string]any)
	if last["balancerTag"] != "auto" {
		t.Errorf("the provider's rules follow ours, its catch-all last: %v", last)
	}
	if len(routing["balancers"].([]any)) != 1 || cfg["observatory"] == nil {
		t.Error("the provider's balancer and observatory stay")
	}
	tags := []string{}
	for _, o := range cfg["outbounds"].([]any) {
		tags = append(tags, o.(map[string]any)["tag"].(string))
	}
	for _, want := range []string{"auto-a", profileDNS, profileDirect, profileBlock} {
		if !slices.Contains(tags, want) {
			t.Errorf("outbound %q is missing from %v", want, tags)
		}
	}

	// The engine itself is the judge of the result.
	dir := os.Getenv("SORA_ENGINES_DIR")
	if dir == "" {
		t.Skip("set SORA_ENGINES_DIR to check the result with Xray")
	}
	// "run -test" creates a tun adapter for real, which needs the right to;
	// the tun variant is covered by the structure above and by the end to end
	// run in a network namespace.
	for _, tun := range []bool{false} {
		out, err := Render(profilePlan(tun), supervise.Runtime{HomeDir: t.TempDir(), LocalPort: 4000, ControlAddr: "127.0.0.1:4001"}, nil)
		if err != nil {
			t.Fatal(err)
		}
		cmd := exec.CommandContext(t.Context(), filepath.Join(dir, "xray"), "run", "-test", "-c", "stdin:")
		cmd.Stdin = strings.NewReader(string(out))
		cmd.Env = append(os.Environ(), "XRAY_LOCATION_ASSET="+dir)
		if msg, err := cmd.CombinedOutput(); err != nil {
			t.Fatalf("xray refused the profile (tun=%v): %v\n%s", tun, err, msg)
		}
	}
}

func TestAProfileIsMeasuredThroughItsFirstOutbound(t *testing.T) {
	o := profilePlan(false).Outbounds[0]
	out, err := RenderProbe([]engine.Outbound{o}, []int{5000})
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(string(out), `"outboundTag":"p1-auto-a"`) || strings.Contains(string(out), "10808") {
		t.Fatalf("probe = %s", out)
	}
}
