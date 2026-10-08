//go:build linux

package tunroute

import (
	"net/netip"
	"slices"
	"strings"
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
)

func TestRouteUsesSelectedAddressesAndLocalTraffic(t *testing.T) {
	tun := engine.Tun{Enabled: true, DeviceName: "sora0", IPv4: netip.MustParsePrefix("172.20.0.1/30"), IPv6: netip.MustParsePrefix("fdfe:dcba:9877::1/126")}
	steps := routeSteps(tun, []string{"-4", "-6"})
	want := []string{
		"-4 addr replace 172.20.0.1/30 dev sora0",
		"-4 route replace default dev sora0 src 172.20.0.1 table 5340",
		"-4 rule add from 172.20.0.1 lookup 5340 priority 5335",
		"-6 addr replace fdfe:dcba:9877::1/126 dev sora0",
		"-6 rule add from fdfe:dcba:9877::1 lookup 5340 priority 5335",
	}
	for _, rule := range want {
		if !slices.Contains(steps, rule) {
			t.Errorf("missing %s", rule)
		}
	}
	for _, step := range steps {
		if strings.Contains(step, "172.19.") {
			t.Errorf("static address retained: %s", step)
		}
		if strings.Contains(step, "rule add") && !strings.Contains(step, "from ") && !strings.Contains(step, "iif lo") {
			t.Errorf("rule captures forwarded traffic: %s", step)
		}
	}
}

func TestBypassKeepsBoundSocketsAndForeignTunnelSources(t *testing.T) {
	steps := bypassSteps("happ-xray", []netip.Prefix{netip.MustParsePrefix("172.19.0.1/30"), netip.MustParsePrefix("fd00::1/126")}, []string{"-4", "-6"})
	want := []string{
		"-4 rule add oif happ-xray lookup main priority 5333",
		"-4 rule add from 172.19.0.1 lookup main priority 5334",
		"-6 rule add oif happ-xray lookup main priority 5333",
		"-6 rule add from fd00::1 lookup main priority 5334",
	}
	if !slices.Equal(steps, want) {
		t.Fatalf("steps = %v, want %v", steps, want)
	}
	if priorityBound >= priorityReturn || priorityForeign >= priorityReturn {
		t.Fatal("bypass must precede tunnel return rules")
	}
	physical := bypassSteps("uplink", nil, []string{"-4"})
	if len(physical) != 1 || strings.Contains(physical[0], "from ") {
		t.Fatal("ordinary uplink sources must not bypass the tunnel")
	}
}
