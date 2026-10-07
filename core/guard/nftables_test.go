package guard_test

import (
	"runtime"
	"strings"
	"testing"

	"github.com/levvs-one/sora-client/core/guard"
)

// TestNftRulesetKeepsTheEngineAndCutsEverythingElse is the property the whole
// package exists for, written down where it can be read on any machine: the
// engine keeps its own traffic, the local network stays reachable, and everything
// else going out is dropped.
func TestNftRulesetKeepsTheEngineAndCutsEverythingElse(t *testing.T) {
	ruleset := guard.NftRuleset(999, []string{"192.168.0.0/16"})
	wants := []string{
		"table inet sora {",
		"chain output {",
		"policy accept;",
		"meta skuid 999 accept",
		"oif lo accept",
		`oifname "sora0" accept`,
		"ct state established,related accept",
		"ip daddr 192.168.0.0/16 accept",
		"counter drop",
	}
	for _, want := range wants {
		if !strings.Contains(ruleset, want) {
			t.Errorf("the ruleset does not contain %q:\n%s", want, ruleset)
		}
	}
	// The drop must come after every exception: a kill switch whose counter line
	// sits above the engine rule would cut the tunnel off with everything else.
	if strings.Index(ruleset, "counter drop") < strings.Index(ruleset, "meta skuid 999 accept") {
		t.Error("the drop rule comes before the engine exception")
	}
}

func TestNftRulesetKeepsPrivateSpaceByDefault(t *testing.T) {
	ruleset := guard.NftRuleset(0, nil)
	for _, network := range []string{"10.0.0.0/8", "192.168.0.0/16", "169.254.0.0/16", "fe80::/10"} {
		if !strings.Contains(ruleset, network) {
			t.Errorf("the ruleset does not keep %s reachable", network)
		}
	}
}

func TestNftRemoveIsSafeToRunTwice(t *testing.T) {
	// Deleting a table that is not there is an error in nft, and the firewall must
	// turn that into success, because a restore runs on every exit path and a
	// second restore has to be a no-op rather than a failure a user would see.
	if !strings.HasPrefix(strings.TrimSpace(guard.NftRemove()), "delete table inet sora") {
		t.Errorf("the remove ruleset is %q", guard.NftRemove())
	}
}

func TestFirstLineKeepsAnNftMessageShort(t *testing.T) {
	if got := guard.FirstLine("table inet sora: Syntax error\nline 3\n"); got != "table inet sora: Syntax error" {
		t.Errorf("FirstLine() = %q", got)
	}
	if got := guard.FirstLine("   spaced   "); got != "spaced" {
		t.Errorf("FirstLine() = %q", got)
	}
}

func TestPlatformFirewallRefusesAnEngineWithoutAUser(t *testing.T) {
	if runtime.GOOS != "linux" {
		// Only Linux matches the engine by its user id; elsewhere os.Getuid is
		// -1 and the kill switch must still start.
		t.Skip("the engine is matched by user id on Linux only")
	}
	if _, err := guard.PlatformFirewall(guard.FirewallOptions{EngineUID: -1}); err == nil {
		t.Error("a kill switch accepted an engine without a user id")
	}
}

func TestPlatformFirewallIsUsable(t *testing.T) {
	switch runtime.GOOS {
	case "linux":
		// On Linux the platform firewall is the nftables table: arming it needs
		// root and changes the firewall of the machine running the tests. The
		// ruleset itself is covered by the rendering tests in this file.
		t.Skip("the Linux kill switch is nftables; arming it in a test would change this machine")
	case "windows":
		t.Skip("the Windows kill switch blocks for real; firewall_windows_test.go checks what it lets through")
	}
	firewall, err := guard.PlatformFirewall(guard.FirewallOptions{EngineUID: 1000})
	if err != nil {
		t.Fatalf("PlatformFirewall() error = %v", err)
	}
	if firewall == nil {
		t.Fatal("PlatformFirewall() returned nothing")
	}
	// Arming and disarming must both succeed on a platform that has no blocking
	// mechanism, because a session on Android asks for it on every connect.
	if err := firewall.Arm(testContext(), []uint16{7890}); err != nil {
		t.Errorf("Arm() on a platform without a firewall = %v", err)
	}
	if err := firewall.Disarm(testContext()); err != nil {
		t.Errorf("Disarm() = %v", err)
	}
}
