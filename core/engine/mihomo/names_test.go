package mihomo

import (
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
)

func TestPlanNamesLeadBackToPlanIDs(t *testing.T) {
	p := &engine.Plan{
		Outbounds: []engine.Outbound{
			{ID: "a1", Name: "VLESS · localhost", Protocol: engine.ProtocolDirect},
			{ID: "b2", Name: "VLESS · localhost", Protocol: engine.ProtocolDirect},
		},
		Groups: []engine.Group{{Name: "sora:auto", Type: engine.GroupURLTest, Outbounds: []string{"a1", "b2"}}},
	}
	names := driver{}.PlanNames(p)
	ids := map[string]bool{}
	for _, id := range names {
		ids[id] = true
	}
	for _, want := range []string{"a1", "b2", "sora:auto"} {
		if !ids[want] {
			t.Errorf("no engine name leads back to %q: %v", want, names)
		}
	}
	if len(names) != 3 {
		t.Errorf("two servers with one display name must keep two engine names: %v", names)
	}
}

func TestAGroupKeepsItsOwnTestAddress(t *testing.T) {
	byID := map[string]string{"a": "a"}
	grp, err := buildGroup(engine.Group{Name: "g", Type: engine.GroupFallback, Outbounds: []string{"a"}, URL: "http://own.example/204"}, byID, "http://plan.example/204")
	if err != nil || grp.URL != "http://own.example/204" {
		t.Fatalf("url = %q, %v", grp.URL, err)
	}
	grp, _ = buildGroup(engine.Group{Name: "g", Type: engine.GroupFallback, Outbounds: []string{"a"}}, byID, "http://plan.example/204")
	if grp.URL != "http://plan.example/204" {
		t.Fatalf("without its own, the plan's: %q", grp.URL)
	}
}

func TestAnHTTPSProxyKeepsItsTLS(t *testing.T) {
	px, err := buildProxy(engine.Outbound{
		ID: "p", Protocol: engine.ProtocolHTTP, Server: "proxy.example", Port: 443,
		UserID: "user", Password: "secret",
		TLS: engine.TLS{Enabled: true, ServerName: "proxy.example"},
	})
	if err != nil {
		t.Fatal(err)
	}
	if px.TLS == nil || !*px.TLS || px.SNI != "proxy.example" {
		t.Errorf("an https proxy rendered without TLS: tls=%v sni=%q", px.TLS, px.SNI)
	}
}
