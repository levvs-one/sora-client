package singbox

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
