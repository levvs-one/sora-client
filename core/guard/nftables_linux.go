//go:build linux

package guard

import (
	"context"
	"os/exec"
	"strings"
	"sync"

	"github.com/levvs-one/sora-client/core/errs"
)

// Nftables manages a Linux output-hook table, removing it when the session
// ends.
type Nftables struct {
	mu      sync.Mutex
	uid     int
	bypass  []string
	command string
	armed   bool
}

// NewNftables permits engine traffic owned by uid and the supplied bypass
// networks. Empty bypass uses private ranges to keep local resources reachable.
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

// Arm installs or replaces the table, making repeated calls idempotent.
func (n *Nftables) Arm(ctx context.Context, _ []uint16) error {
	n.mu.Lock()
	defer n.mu.Unlock()
	if err := n.apply(ctx, NftRuleset(n.uid, n.bypass)); err != nil {
		return err
	}
	n.armed = true
	return nil
}

// Disarm removes the table and succeeds if already removed.
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

// apply sends nft rules on stdin to avoid command-line length limits and
// exposing rules in process arguments.
func (n *Nftables) apply(ctx context.Context, ruleset string) error {
	process := exec.CommandContext(ctx, n.command, "-f", "-") //nolint:gosec // n.command is the nft binary found at construction; the ruleset arrives on stdin
	process.Stdin = strings.NewReader(ruleset)
	output, err := process.CombinedOutput()
	if err != nil {
		// nft output names table, chain, or syntax failures and
		// contains no secrets.
		return errs.Newf(errs.CodePermissionDenied, errs.KeyGuardFirewallFail,
			"guard: nft refused the ruleset: %s", FirstLine(string(output)))
	}
	return nil
}

// PlatformFirewall returns the Linux nftables kill switch.
func PlatformFirewall(opts FirewallOptions) (Firewall, error) {
	return NewNftables(opts.EngineUID, opts.Bypass)
}
