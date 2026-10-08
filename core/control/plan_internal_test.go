package control

import (
	"context"
	"os"
	"testing"

	"google.golang.org/protobuf/proto"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/registry"
	"github.com/levvs-one/sora-client/core/engine/supervise"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
	"github.com/levvs-one/sora-client/core/parser"
)

// TestRealityAndTransportSurviveTheVault checks that REALITY keys, transport
// paths, and XHTTP mode survive import and credential resolution.
func TestRealityAndTransportSurviveTheVault(t *testing.T) {
	link := "vless://b831381d-6324-4d53-ad4f-8cda48b30811@edge.example.com:443?type=xhttp&security=reality" +
		"&pbk=Z84J2IelR9ch3k8VtlVhhs5ycBUlXA7wHBWcBrjqnAw&sid=6ba85179e30d4fc2&sni=www.example.com&fp=chrome" +
		"&path=%2Fx&host=cdn.example.com&mode=stream-one&encryption=none&alpn=h2,http%2F1.1#Edge"
	result, err := parser.LinkParser{}.Parse([]byte(link))
	if err != nil || len(result.Servers) != 1 {
		t.Fatalf("Parse = %+v, %v", result, err)
	}
	document, err := credentialDocument(result.Servers[0])
	if err != nil {
		t.Fatal(err)
	}
	var o engine.Outbound
	if err := applyCredential(&o, parseCredential(document)); err != nil {
		t.Fatal(err)
	}

	if !o.TLS.Reality || o.TLS.RealityPublicKey != "Z84J2IelR9ch3k8VtlVhhs5ycBUlXA7wHBWcBrjqnAw" || o.TLS.RealityShortID != "6ba85179e30d4fc2" {
		t.Errorf("REALITY lost on the way to the engine: %+v", o.TLS)
	}
	if o.Transport.Path != "/x" || o.Transport.Host != "cdn.example.com" || o.Transport.Mode != "stream-one" {
		t.Errorf("transport lost on the way to the engine: %+v", o.Transport)
	}
	if len(o.TLS.ALPN) != 2 || o.Encryption != "none" {
		t.Errorf("alpn %v and encryption %q must survive", o.TLS.ALPN, o.Encryption)
	}
}

func TestRuleDestinationsFollowTheXrayVocabulary(t *testing.T) {
	for destination, want := range map[string]engine.Rule{
		"domain:example.com": {Type: engine.RuleDomainSuffix, Value: "example.com"},
		"full:example.com":   {Type: engine.RuleDomain, Value: "example.com"},
		"geosite:ru":         {Type: engine.RuleGeoSite, Value: "ru"},
		"geoip:private":      {Type: engine.RuleGeoIP, Value: "private"},
	} {
		kind := ruleTypeOf(destination)
		if got := (engine.Rule{Type: kind, Value: ruleValue(kind, destination)}); got != want {
			t.Errorf("%s -> %+v, want %+v", destination, got, want)
		}
	}
}

func TestWireGuardSurvivesTheVault(t *testing.T) {
	for name, source := range map[string]string{
		"conf": "[Interface]\nPrivateKey = cKE7LmCF61IhqqABGhvJ44jWXp8fKymcMAEVAzLDYVk=\nAddress = 10.7.0.2, fd00::2/128\n\n" +
			"[Peer]\nPublicKey = Z84J2IelR9ch3k8VtlVhhs5ycBUlXA7wHBWcBrjqnAw=\nEndpoint = 198.51.100.7:51820\nAllowedIPs = 0.0.0.0/0, ::/0\n",
		"link": "wireguard://cKE7LmCF61IhqqABGhvJ44jWXp8fKymcMAEVAzLDYVk%3D@198.51.100.7:51820" +
			"?publickey=Z84J2IelR9ch3k8VtlVhhs5ycBUlXA7wHBWcBrjqnAw%3D&address=10.7.0.2%2C2001%3Adb8%3A%3A2#WG",
	} {
		t.Run(name, func(t *testing.T) {
			result, err := parser.LinkParser{}.Parse([]byte(source))
			if err != nil || len(result.Servers) != 1 {
				t.Fatalf("Parse = %+v, %v", result, err)
			}
			document, err := credentialDocument(result.Servers[0])
			if err != nil {
				t.Fatal(err)
			}
			var o engine.Outbound
			if err := applyCredential(&o, parseCredential(document)); err != nil {
				t.Fatal(err)
			}
			if o.PrivateKey != "cKE7LmCF61IhqqABGhvJ44jWXp8fKymcMAEVAzLDYVk=" {
				t.Errorf("private key = %q", o.PrivateKey)
			}
			if len(o.Addresses) != 2 || o.Addresses[0] != "10.7.0.2/32" {
				t.Errorf("addresses = %v", o.Addresses)
			}
			if len(o.Peers) != 1 || o.Peers[0].Endpoint != "198.51.100.7:51820" || o.Peers[0].PublicKey == "" {
				t.Errorf("peers = %+v", o.Peers)
			}
		})
	}
}

func TestPlanCarriesDefencesAndEnginePin(t *testing.T) {
	in := &corev1.SessionPlan{
		Outbounds:      []*corev1.OutboundSpec{{Id: "a", Protocol: "direct"}},
		AntiCensorship: &corev1.AntiCensorship{TlsFragment: true, FragmentLength: "50-100"},
		Engines:        []string{"xray"},
		TunnelMode:     corev1.TunnelMode_TUNNEL_MODE_APPLICATION,
	}
	p, err := planFromProto(in, "s", nil)
	if err != nil {
		t.Fatal(err)
	}
	if !p.Options.Fragment.Enabled || p.Options.Fragment.Length != "50-100" || len(p.Engines) != 1 || p.Engines[0] != engine.KindXray {
		t.Fatalf("defences or engine preference lost: %+v %v", p.Options.Fragment, p.Engines)
	}
}

func TestAmneziaWGSurvivesTheVault(t *testing.T) {
	conf := "[Interface]\nPrivateKey = cKE7LmCF61IhqqABGhvJ44jWXp8fKymcMAEVAzLDYVk=\nAddress = 10.8.0.2/32\n" +
		"Jc = 4\nJmin = 40\nJmax = 70\nS1 = 15\nS2 = 25\nS3 = 10\nS4 = 5\nH1 = 100000-100100\nH2 = 200000\nH3 = 300000\nH4 = 400000\n" +
		"I1 = <b 0xf6ab3267fa><c><t><r 10>\n\n[Peer]\nPublicKey = Z84J2IelR9ch3k8VtlVhhs5ycBUlXA7wHBWcBrjqnAw=\nEndpoint = 198.51.100.7:51820\nAllowedIPs = 0.0.0.0/0\n"
	result, err := parser.LinkParser{}.Parse([]byte(conf))
	if err != nil || len(result.Servers) != 1 {
		t.Fatalf("Parse = %+v, %v", result, err)
	}
	document, err := credentialDocument(result.Servers[0])
	if err != nil {
		t.Fatal(err)
	}
	var o engine.Outbound
	if err := applyCredential(&o, parseCredential(document)); err != nil {
		t.Fatal(err)
	}
	want := engine.AmneziaWG{Jc: 4, Jmin: 40, Jmax: 70, S1: 15, S2: 25, S3: 10, S4: 5,
		H1: "100000-100100", H2: "200000", H3: "300000", H4: "400000", I1: "<b 0xf6ab3267fa><c><t><r 10>"}
	if o.Amnezia == nil || *o.Amnezia != want {
		t.Fatalf("amneziawg = %+v, want %+v", o.Amnezia, want)
	}

	if err := applyCredential(&o, map[string]string{"amneziawg": `{"jc":"four"}`}); err == nil {
		t.Fatal("a parameter that is not a number must fail the plan")
	}
}

func TestPlanKeepsEngineControlAndTheLocalProxyPrivate(t *testing.T) {
	base := func(mode corev1.TunnelMode, lp *corev1.LocalProxy) *corev1.SessionPlan {
		return &corev1.SessionPlan{TunnelMode: mode, LocalProxy: lp,
			Outbounds: []*corev1.OutboundSpec{{Id: "a", Protocol: "direct"}}}
	}
	p, err := planFromProto(base(corev1.TunnelMode_TUNNEL_MODE_SYSTEM, nil), "s", nil)
	if err != nil {
		t.Fatal(err)
	}
	if !p.PrivateControl || p.LocalProxy.Enabled {
		t.Errorf("by default a tun session has private control and no listener: %+v %+v", p.PrivateControl, p.LocalProxy)
	}
	p, err = planFromProto(base(corev1.TunnelMode_TUNNEL_MODE_APPLICATION, nil), "s", nil)
	if err != nil || !p.LocalProxy.Enabled {
		t.Errorf("the system proxy mode needs its listener: %+v, %v", p.LocalProxy, err)
	}
	login := &corev1.LocalProxy{Enabled: true, Username: "me", Password: "local-proxy-password"}
	if p, err = planFromProto(base(corev1.TunnelMode_TUNNEL_MODE_SYSTEM, login), "s", nil); err != nil || p.LocalProxy.Username != "me" {
		t.Errorf("a tun session may share a locked listener: %+v, %v", p.LocalProxy, err)
	}
	if _, err := planFromProto(base(corev1.TunnelMode_TUNNEL_MODE_APPLICATION, login), "s", nil); err == nil {
		t.Error("a login the system proxy cannot carry must be refused")
	}
	if _, err := planFromProto(base(corev1.TunnelMode_TUNNEL_MODE_SYSTEM, &corev1.LocalProxy{Enabled: true, Username: "me"}), "s", nil); err == nil {
		t.Error("half a login must be refused")
	}
}

func TestPlanCarriesGroupsAndAppliesThePreset(t *testing.T) {
	in := &corev1.SessionPlan{
		TunnelMode: corev1.TunnelMode_TUNNEL_MODE_SYSTEM,
		Outbounds:  []*corev1.OutboundSpec{{Id: "a", Protocol: "direct"}, {Id: "b", Protocol: "direct"}},
		Groups: []*corev1.GroupSpec{
			{Name: "Proxy", Type: corev1.GroupType_GROUP_TYPE_SELECT, Members: []string{"Auto", "a", "b"}},
			{Name: "Auto", Type: corev1.GroupType_GROUP_TYPE_URL_TEST, Members: []string{"a", "b"}},
		},
		Routes:  []*corev1.RoutingRule{{Destination: "domain:example.org", OutboundId: "b"}},
		Routing: &corev1.RoutingOptions{Preset: "ru", ProxyTarget: "Proxy", BlockAds: true},
	}
	p, err := planFromProto(in, "s", nil)
	if err != nil {
		t.Fatal(err)
	}
	if len(p.Groups) != 2 || p.Groups[0].Outbounds[0] != "Auto" {
		t.Fatalf("groups = %+v: a group may hold a group listed after it", p.Groups)
	}
	if p.Rules[0].Value != "example.org" || p.Rules[1].Target != "reject" {
		t.Fatalf("the user's route first, then the ad block: %+v", p.Rules[:2])
	}
	if last := p.Rules[len(p.Rules)-1]; last.Type != engine.RuleMatchAll || last.Target != "Proxy" {
		t.Fatalf("the rest goes to the group: %+v", last)
	}

	for name, mutate := range map[string]func(*corev1.SessionPlan){
		"cycle":            func(sp *corev1.SessionPlan) { sp.Groups[1].Members = []string{"Proxy"} },
		"unknown member":   func(sp *corev1.SessionPlan) { sp.Groups[1].Members = []string{"ghost"} },
		"group named a":    func(sp *corev1.SessionPlan) { sp.Groups[1].Name = "a" },
		"unknown target":   func(sp *corev1.SessionPlan) { sp.Routing.ProxyTarget = "ghost" },
		"unknown preset":   func(sp *corev1.SessionPlan) { sp.Routing.Preset = "mars" },
		"type not set":     func(sp *corev1.SessionPlan) { sp.Groups[0].Type = corev1.GroupType_GROUP_TYPE_UNSPECIFIED },
		"duplicate groups": func(sp *corev1.SessionPlan) { sp.Groups[1].Name = "Proxy" },
	} {
		broken := proto.Clone(in).(*corev1.SessionPlan)
		mutate(broken)
		if _, err := planFromProto(broken, "s", nil); err == nil {
			t.Errorf("%s must be refused", name)
		}
	}
}

// TestEveryEngineAcceptsAPlanWithGroupsAndAPreset follows a contract plan with
// a select group, an automatic group and a preset to each engine's validator.
func TestEveryEngineAcceptsAPlanWithGroupsAndAPreset(t *testing.T) {
	dir := os.Getenv("SORA_ENGINES_DIR")
	if dir == "" {
		t.Skip("set SORA_ENGINES_DIR to a directory with sing-box, xray, mihomo and the geo databases")
	}
	ctx := context.Background()
	reg := registry.Discover(ctx, dir, supervise.Config{HomeDir: t.TempDir()})
	for _, kind := range []string{"sing-box", "xray", "mihomo"} {
		t.Run(kind, func(t *testing.T) {
			in := &corev1.SessionPlan{
				TunnelMode: corev1.TunnelMode_TUNNEL_MODE_APPLICATION,
				Engines:    []string{kind},
				// sing-box and Xray are controlled over
				// loopback ports only.
				NetworkControlAllowed: kind != "mihomo",
				Outbounds:             []*corev1.OutboundSpec{{Id: "a", Protocol: "direct"}, {Id: "b", Protocol: "direct"}},
				Groups: []*corev1.GroupSpec{
					{Name: "Proxy", Type: corev1.GroupType_GROUP_TYPE_SELECT, Members: []string{"Auto", "a", "b"}},
					{Name: "Auto", Type: corev1.GroupType_GROUP_TYPE_URL_TEST, Members: []string{"a", "b"}},
				},
				Routing: &corev1.RoutingOptions{Preset: "ru", ProxyTarget: "Proxy", BlockAds: true},
			}
			p, err := planFromProto(in, "s", nil)
			if err != nil {
				t.Fatal(err)
			}
			eng, err := reg.Factory()(ctx, p)
			if err != nil {
				t.Fatal(err)
			}
			defer func() { _ = eng.Close() }()
			if err := eng.Validate(ctx, p); err != nil {
				t.Fatal(err)
			}
		})
	}
}

func TestPlanCarriesABypassOutbound(t *testing.T) {
	in := &corev1.SessionPlan{
		TunnelMode: corev1.TunnelMode_TUNNEL_MODE_SYSTEM,
		Outbounds: []*corev1.OutboundSpec{{Id: "zapret", Protocol: "bypass",
			Bypass: &corev1.BypassStrategy{SplitPos: []string{"1", "midsld"}, Disorder: true}}},
		Routes: []*corev1.RoutingRule{{Destination: "geosite:youtube", OutboundId: "zapret"}},
	}
	p, err := planFromProto(in, "s", nil)
	if err != nil {
		t.Fatal(err)
	}
	if b := p.Outbounds[0].Bypass; b == nil || !b.Disorder || len(b.SplitPos) != 2 {
		t.Fatalf("bypass = %+v", p.Outbounds[0])
	}
	in.Outbounds[0].Bypass = &corev1.BypassStrategy{SplitPos: []string{"1 --debug=@/tmp/x"}}
	if _, err := planFromProto(in, "s", nil); err == nil {
		t.Fatal("a split position carrying an option must be refused")
	}
}

func TestTunPlanGetsResolversWhenItNamesNone(t *testing.T) {
	plan := func(mode corev1.TunnelMode, servers ...string) *corev1.SessionPlan {
		return &corev1.SessionPlan{
			TunnelMode: mode,
			Outbounds:  []*corev1.OutboundSpec{{Id: "a", Protocol: "direct"}},
			DnsPolicy:  &corev1.DnsPolicy{Servers: servers},
		}
	}
	p, err := planFromProto(plan(corev1.TunnelMode_TUNNEL_MODE_SYSTEM), "s", nil)
	if err != nil {
		t.Fatal(err)
	}
	if !p.DNS.Enabled || len(p.DNS.Servers) != 2 || p.DNS.Servers[0].Transport != engine.DNSHTTPS {
		t.Fatalf("a tun plan without resolvers must get the defaults: %+v", p.DNS)
	}
	p, err = planFromProto(plan(corev1.TunnelMode_TUNNEL_MODE_SYSTEM, "tls://dns.example:853"), "s", nil)
	if err != nil {
		t.Fatal(err)
	}
	if len(p.DNS.Servers) != 1 || p.DNS.Servers[0].Address != "dns.example" {
		t.Fatalf("the person's resolver replaces the defaults: %+v", p.DNS)
	}
	p, err = planFromProto(plan(corev1.TunnelMode_TUNNEL_MODE_APPLICATION), "s", nil)
	if err != nil {
		t.Fatal(err)
	}
	if p.DNS.Enabled {
		t.Fatalf("a proxy plan resolves through the system unless asked: %+v", p.DNS)
	}
}

func TestPlanCarriesTheIPv6Choice(t *testing.T) {
	in := &corev1.SessionPlan{
		TunnelMode: corev1.TunnelMode_TUNNEL_MODE_APPLICATION,
		Outbounds:  []*corev1.OutboundSpec{{Id: "a", Protocol: "direct"}},
	}
	p, err := planFromProto(in, "s", nil)
	if err != nil {
		t.Fatal(err)
	}
	if p.Options.IPv6 {
		t.Fatal("IPv6 is off unless asked for")
	}
	in.Ipv6 = true
	if p, _ = planFromProto(in, "s", nil); !p.Options.IPv6 {
		t.Fatal("the IPv6 choice must reach the engine options")
	}
}

func TestAProfileSurvivesTheVault(t *testing.T) {
	profile := `{"remarks":"x","outbounds":[{"protocol":"vless","tag":"proxy"}],"routing":{"rules":[]}}`
	packed, err := packProfile(profile)
	if err != nil {
		t.Fatal(err)
	}
	back, err := unpackProfile(packed)
	if err != nil || string(back) != profile {
		t.Fatalf("round trip = %q, %v", back, err)
	}
	if _, err := unpackProfile("not base64"); err == nil {
		t.Fatal("an unreadable profile must be refused")
	}
}

func TestARuleCanNameAProgram(t *testing.T) {
	in := &corev1.SessionPlan{
		TunnelMode: corev1.TunnelMode_TUNNEL_MODE_SYSTEM,
		Outbounds:  []*corev1.OutboundSpec{{Id: "a", Protocol: "direct"}},
		Routes:     []*corev1.RoutingRule{{Destination: "process:telegram-desktop", OutboundId: "direct"}},
	}
	p, err := planFromProto(in, "s", nil)
	if err != nil {
		t.Fatal(err)
	}
	if r := p.Rules[0]; r.Type != engine.RuleProcess || r.Value != "telegram-desktop" {
		t.Fatalf("rule = %+v", r)
	}
}
