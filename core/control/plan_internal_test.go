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
	applyCredential(&o, parseCredential(document))

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
			applyCredential(&o, parseCredential(document))
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
		Engine:         "xray",
		TunnelMode:     corev1.TunnelMode_TUNNEL_MODE_APPLICATION,
	}
	p, err := planFromProto(in, "s", nil)
	if err != nil {
		t.Fatal(err)
	}
	if !p.Options.Fragment.Enabled || p.Options.Fragment.Length != "50-100" || p.Engine != engine.KindXray {
		t.Fatalf("defences or engine pin lost: %+v %q", p.Options.Fragment, p.Engine)
	}
}
