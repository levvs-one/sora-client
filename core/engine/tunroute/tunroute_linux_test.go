//go:build linux

package tunroute

import (
	"encoding/json"
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
		"-4 rule add from 172.20.0.1 lookup 5340 priority 5333",
		"-4 rule add iif lo lookup main suppress_prefixlength 1 priority 5338",
		"-4 rule add iif lo ipproto udp dport 53 lookup 5340 priority 5335",
		"-4 rule add iif lo ipproto tcp dport 53 lookup 5340 priority 5335",
		"-4 rule add iif lo ipproto udp dport 53 goto 5338 priority 5336",
		"-4 rule add iif lo ipproto tcp dport 53 goto 5338 priority 5336",
		"-6 addr replace fdfe:dcba:9877::1/126 dev sora0",
		"-6 rule add from fdfe:dcba:9877::1 lookup 5340 priority 5333",
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

func TestCleanupIdentifiesOwnersAndLegacyRules(t *testing.T) {
	for _, tc := range []struct {
		name, data string
		owned      bool
	}{
		{"DNS skip", `{"priority":5336,"src":"all","iif":"lo","ipproto":"ipproto-17","dport":53,"table":"","goto":5338,"protocol":"242"}`, true},
		{"tagged", `{"priority":5333,"src":"192.0.2.1","table":"5340","protocol":"242"}`, true},
		{"legacy bound", `{"priority":5333,"src":"all","oif":"uplink","table":"254"}`, true},
		{"legacy DNS", `{"priority":5337,"src":"all","iif":"lo","ipproto":"ipproto-17","dport":53,"dport_mask":"0xffff","table":"5340"}`, true},
		{"legacy main", `{"priority":5338,"src":"all","iif":"lo","table":"254","suppress_prefixlen":0}`, true},
		{"mihomo detached", `{"priority":32765,"src":"all","oif":"sora0","oif_detached":null,"table":"2022"}`, true},
		{"foreign table", `{"priority":5333,"src":"all","table":"7000"}`, false},
		{"foreign protocol", `{"priority":5333,"src":"all","oif":"uplink","table":"254","protocol":"99"}`, false},
		{"foreign selector", `{"priority":5333,"src":"all","oif":"uplink","table":"254","fwmark":"0x7000"}`, false},
		{"foreign tunnel", `{"priority":32765,"src":"all","oif":"happ-xray","table":"2022"}`, false},
		{"system main", `{"priority":32766,"src":"all","table":"254"}`, false},
	} {
		t.Run(tc.name, func(t *testing.T) {
			var rule map[string]json.RawMessage
			if err := json.Unmarshal([]byte(tc.data), &rule); err != nil {
				t.Fatal(err)
			}
			if got := ownedRule(rule); (got != "") != tc.owned {
				t.Fatalf("cleanup selector = %q, owned = %v", got, tc.owned)
			}
		})
	}
}

func TestBypassKeepsBoundSocketsAndForeignTunnelSources(t *testing.T) {
	steps := bypassSteps("happ-xray", []netip.Prefix{netip.MustParsePrefix("172.19.0.1/30"), netip.MustParsePrefix("fd00::1/126")}, []string{"-4", "-6"})
	want := []string{
		"-4 rule add oif happ-xray lookup main priority 5337",
		"-4 rule add from 172.19.0.1 lookup main priority 5337",
		"-6 rule add oif happ-xray lookup main priority 5337",
		"-6 rule add from fd00::1 lookup main priority 5337",
	}
	if !slices.Equal(steps, want) {
		t.Fatalf("steps = %v, want %v", steps, want)
	}
	if priorityDNS >= priorityBound || priorityDNS >= priorityForeign || priorityEngine >= priorityDNS || priorityReturn >= priorityEngine {
		t.Fatal("return and engine rules must precede DNS; foreign exemptions must follow DNS")
	}
	physical := bypassSteps("uplink", nil, []string{"-4"})
	if len(physical) != 1 || strings.Contains(strings.Join(physical, "\n"), "from ") {
		t.Fatal("ordinary uplink sources must not bypass the tunnel")
	}
}
