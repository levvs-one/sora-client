package guard

import (
	"net/netip"
	"strings"

	"github.com/levvs-one/sora-client/core/engine"
)

// nftables owns the kill switch on Linux. The ruleset lives in a table this
// package creates and deletes by name, so arming and disarming are the same two
// operations every time and a crash leaves either a complete table or none.
//
// The rules are deliberately narrow. Traffic that already belongs to a
// connection, traffic on the loopback interface, and traffic of the engine
// process itself are allowed; everything else going out is dropped. Matching the
// engine by its user id is what makes a kill switch possible at all: the engine
// must be able to reach its servers while every other process on the machine
// cannot reach anything. A rule set that allowed everything would switch nothing
// off, and one that allowed nothing would switch the tunnel off with it.
const (
	// nftTable is the table this package owns. The name is prefixed so that a
	// human reading `nft list ruleset` knows at a glance which rules belong to a
	// client and which belong to the system.
	nftTable = "sora"
	// nftChain is the output hook the table installs.
	nftChain = "output"
)

// NftRuleset renders the ruleset that arms the kill switch for an engine owned by
// a given user id. It is exported because the rules are the promise this package
// makes to a user, and a test that reads them on any machine is worth more than a
// test that needs a privileged host to run.
//
// The bypass list keeps the local network reachable, because a kill switch that
// cuts a machine off from its own printer and router is a bug and not strictness.
// An empty list falls back to the private and link-local space.
func NftRuleset(engineUID int, bypass []string) string {
	networks := bypass
	if len(networks) == 0 {
		networks = DefaultBypassNetworks()
	}
	var b strings.Builder
	b.WriteString("table inet " + nftTable + " {\n")
	b.WriteString("\tchain " + nftChain + " {\n")
	b.WriteString("\t\ttype filter hook output priority filter; policy accept;\n")
	b.WriteString("\t\tmeta skuid " + itoa(engineUID) + " accept comment \"sora: the engine keeps its own traffic\"\n")
	b.WriteString("\t\toif lo accept comment \"sora: the local engine is on loopback\"\n")
	// A tun session sends everyone's traffic out of its adapter; the kill
	// switch exists to stop traffic that goes around it, not through it.
	b.WriteString("\t\toifname \"" + engine.TunDevice + "\" accept comment \"sora: through the tunnel\"\n")
	b.WriteString("\t\tct state established,related accept comment \"sora: an existing connection finishes\"\n")
	for _, network := range networks {
		// nft refuses a whole ruleset that matches an IPv4 network against
		// IPv6 addresses or the other way round, so each network gets the rule
		// of its own family.
		family := "ip"
		if prefix, err := netip.ParsePrefix(network); err == nil && prefix.Addr().Is6() {
			family = "ip6"
		} else if addr, err := netip.ParseAddr(network); err == nil && addr.Is6() {
			family = "ip6"
		}
		b.WriteString("\t\t" + family + " daddr " + network + " accept comment \"sora: local network bypass\"\n")
	}
	b.WriteString("\t\tcounter drop comment \"sora: kill switch\"\n")
	b.WriteString("\t}\n")
	b.WriteString("}\n")
	return b.String()
}

// NftRemove renders the command that removes the table. Removing a table that is
// not there succeeds, which is what makes a restore safe to run twice.
func NftRemove() string {
	return "delete table inet " + nftTable + "\n"
}

// DefaultBypassNetworks are the destinations that stay reachable while the kill
// switch is armed: the ranges that can only be reached inside the local network,
// plus the loopback the engine itself listens on.
func DefaultBypassNetworks() []string {
	return []string{
		"127.0.0.0/8",
		"10.0.0.0/8",
		"172.16.0.0/12",
		"192.168.0.0/16",
		"169.254.0.0/16",
		"fc00::/7",
		"fe80::/10",
	}
}

// FirstLine keeps a message from an external tool to one line, because a details
// line is rendered as one line everywhere else in the core.
func FirstLine(text string) string {
	if index := strings.IndexAny(text, "\r\n"); index >= 0 {
		return strings.TrimSpace(text[:index])
	}
	return strings.TrimSpace(text)
}

// itoa renders a small positive number without pulling in strconv for one call.
func itoa(value int) string {
	if value == 0 {
		return "0"
	}
	negative := value < 0
	if negative {
		value = -value
	}
	var digits [20]byte
	index := len(digits)
	for value > 0 {
		index--
		digits[index] = byte('0' + value%10)
		value /= 10
	}
	if negative {
		index--
		digits[index] = '-'
	}
	return string(digits[index:])
}
