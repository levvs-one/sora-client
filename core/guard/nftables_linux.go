//go:build linux

package guard

import (
	"context"
	"os/exec"
	"strings"
	"sync"

	"github.com/levvs-one/sora-client/core/errs"
)

// Nftables blocks or unblocks traffic that does not belong to the tunnel. On Linux
// it is a table of this package's own, installed in the output hook and removed
// again when the session ends.
type Nftables struct {
	mu      sync.Mutex
	uid     int
	bypass  []string
	command string
	armed   bool
}

// NewNftables returns a kill switch that allows the engine owned by uid and keeps
// the given networks reachable. An empty bypass list falls back to private space,
// because a kill switch that cuts a machine off from its own network is a bug, not
// a strictness.
func NewNftables(uid int, bypass []string) (*Nftables, error) {
	if uid < 0 {
		return nil, errs.Newf(errs.CodeInvalidArgument, errs.KeyGuardFirewallFail,
			"guard: the engine has no user id")
	}
	if len(bypass) == 0 {
		bypass = DefaultBypassNetworks()
	}
	return &Nftables{uid: uid, bypass: bypass, command: "nft"}, nil
}

// Arm installs the table. Arming twice replaces the table, so the state does not
// depend on how many times the session asked for it.
func (n *Nftables) Arm(ctx context.Context, _ []uint16) error {
	n.mu.Lock()
	defer n.mu.Unlock()
	if err := n.apply(ctx, NftRuleset(n.uid, n.bypass)); err != nil {
		return err
	}
	n.armed = true
	return nil
}

// Disarm removes the table. Removing it twice is the same as removing it once.
func (n *Nftables) Disarm(ctx context.Context) error {
	n.mu.Lock()
	defer n.mu.Unlock()
	if err := n.apply(ctx, NftRemove()); err != nil {
		return err
	}
	n.armed = false
	return nil
}

// Armed reports whether this process installed the table.
func (n *Nftables) Armed(context.Context) (bool, error) {
	n.mu.Lock()
	defer n.mu.Unlock()
	return n.armed, nil
}

// Name identifies the implementation in a diagnostics line.
func (n *Nftables) Name() string { return "nftables" }

// apply feeds a ruleset to nft over standard input. The text goes through the pipe
// rather than the command line because a ruleset is far longer than any command
// line and because an argument list is visible to every process on the machine.
func (n *Nftables) apply(ctx context.Context, ruleset string) error {
	process := exec.CommandContext(ctx, n.command, "-f", "-")
	process.Stdin = strings.NewReader(ruleset)
	output, err := process.CombinedOutput()
	if err != nil {
		// nft prints the reason on standard output; it names a table, a chain or a
		// syntax position, none of which is a secret.
		return errs.Newf(errs.CodePermissionDenied, errs.KeyGuardFirewallFail,
			"guard: nft refused the ruleset: %s", FirstLine(string(output)))
	}
	return nil
}

// firstLine keeps an error message to one line, because a details line is rendered
// as one line everywhere else in the core.
func firstLine(text string) string {
	if index := strings.IndexAny(text, "\r\n"); index >= 0 {
		return strings.TrimSpace(text[:index])
	}
	return strings.TrimSpace(text)
}

// PlatformFirewall returns the kill switch this platform has. Linux blocks traffic
// with its own table; the other platforms are handled by the caller, because a
// correct mechanism there is not the same problem.
func PlatformFirewall(engineUID int, bypass []string) (Firewall, error) {
	return NewNftables(engineUID, bypass)
}
