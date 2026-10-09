//go:build windows

package guard

import (
	"net/netip"
	"testing"

	"github.com/tailscale/wf"
)

func TestWFPTunnelFiltersAllowInboundReauthorization(t *testing.T) {
	networks := []netip.Prefix{netip.MustParsePrefix("192.0.2.0/30"), netip.MustParsePrefix("2001:db8:5340::/126")}
	w := &WFP{enginesDir: t.TempDir(), tunNetworks: networks, bypass: []netip.Prefix{netip.MustParsePrefix("0.0.0.0/0")}}
	var rules []*wf.Rule
	if err := w.rules(func(rule *wf.Rule) error { rules = append(rules, rule); return nil }, wf.SublayerID{}); err != nil {
		t.Fatal(err)
	}
	for i, layer := range outbound {
		outgoing, incoming, legacyBlock := 0, 0, 0
		for _, rule := range rules {
			if rule.Layer != layer {
				continue
			}
			if rule.Name == "Sora: tunnel destination outside the tunnel" {
				for _, c := range rule.Conditions {
					if c.Value == netip.MustParsePrefix("172.19.0.0/16") {
						legacyBlock++
						if layer != wf.LayerALEAuthConnectV4 || rule.Action != wf.ActionBlock || rule.Weight <= weightPermit {
							t.Fatal("legacy IPv4 destination block has wrong family, action or precedence")
						}
					}
				}
			}
			if rule.Weight != weightTunnelPermit {
				continue
			}
			if rule.Action != wf.ActionPermit {
				t.Fatal("tunnel rule must permit")
			}
			var local, next, arrival, reauth bool
			for _, c := range rule.Conditions {
				switch c.Field {
				case wf.FieldIPLocalAddress:
					local = c.Op == wf.MatchTypeEqual && c.Value == networks[i]
				case wf.FieldNexthopInterfaceType:
					next = c.Op == wf.MatchTypeEqual && c.Value == uint32(53)
				case wf.FieldArrivalInterfaceType:
					arrival = c.Op == wf.MatchTypeEqual && c.Value == uint32(53)
				case wf.FieldFlags:
					reauth = c.Op == wf.MatchTypeFlagsAllSet && c.Value == wf.ConditionFlagIsReauthorize
				default:
					t.Fatalf("unexpected tunnel condition %v", c.Field)
				}
			}
			// On inbound reauthorization next-hop is FWP_EMPTY. The arrival
			// permit must stand alone and still require the selected local subnet.
			if local && next && !arrival && len(rule.Conditions) == 2 {
				outgoing++
			} else if local && arrival && reauth && !next && len(rule.Conditions) == 3 {
				incoming++
			} else {
				t.Fatalf("unsafe or unusable tunnel permit: %+v", rule.Conditions)
			}
		}
		if outgoing != 1 || incoming != 1 || (i == 0 && legacyBlock != 1) || (i == 1 && legacyBlock != 0) {
			t.Fatalf("%v: outgoing=%d incoming=%d legacy=%d", layer, outgoing, incoming, legacyBlock)
		}
	}
}
