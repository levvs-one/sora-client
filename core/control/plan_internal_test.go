package control

import (
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
	"github.com/levvs-one/sora-client/core/parser"
)

// TestRealityAndTransportSurviveTheVault follows one share link from import to
// the engine plan. Before the fix the REALITY key, the transport path and the
// XHTTP mode were stored but never read back, so every REALITY server failed
// to connect on every engine.
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
