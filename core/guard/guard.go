// Package guard manages reversible kill-switch rules owned by the core. It
// records armed state and restores it on every exit path; tunnel implementation
// is separate.
package guard

import (
	"context"
	"sync"

	"github.com/levvs-one/sora-client/core/errs"
	"github.com/levvs-one/sora-client/core/session"
)

var _ session.Guard = (*Guard)(nil)

// NoopFirewall supports system-owned tunnels such as Android VpnService, where
// this process has no firewall rules to manage.
type NoopFirewall struct{}

// Arm succeeds and reports that nothing is blocked.
func (NoopFirewall) Arm(context.Context, []uint16) error { return nil }

// Disarm succeeds without changing anything.
func (NoopFirewall) Disarm(context.Context) error { return nil }

// Armed reports that no rule of this package is in force.
func (NoopFirewall) Armed(context.Context) (bool, error) { return false, nil }

// Firewall blocks or unblocks traffic that does not belong to the tunnel.
type Firewall interface {
	// Arm blocks traffic while the tunnel is down. It is idempotent.
	Arm(ctx context.Context, enginePorts []uint16) error
	// Disarm removes the block. It succeeds when nothing is armed.
	Disarm(ctx context.Context) error
	// Armed reports whether the block is in force.
	Armed(ctx context.Context) (bool, error)
}

// FirewallOptions configures kill-switch exemptions outside the tunnel.
type FirewallOptions struct {
	// EngineUID is the account the engines run as; Linux matches them by
	// it.
	EngineUID int
	// EnginesDir holds the engine executables; Windows matches them by
	// file.
	EnginesDir string
	// Bypass are the networks that stay reachable; empty means private
	// space.
	Bypass []string
}

// Options identifies engine listener ports that must stay reachable for tunnel
// recovery.
type Options struct {
	// EnginePorts are the local ports the kill switch must never block.
	EnginePorts []uint16
}

// Guard owns and restores the session kill switch. The system proxy belongs to
// the signed-in user and is managed by the user UI.
type Guard struct {
	mu        sync.Mutex
	firewall  Firewall
	opts      Options
	applied   session.Settings
	restoring bool
}

// New creates a guard. Nil uses NoopFirewall for platforms without a
// process-managed firewall.
func New(opts Options, firewall Firewall) (*Guard, error) {
	if len(opts.EnginePorts) == 0 {
		return nil, errs.Newf(errs.CodeInvalidArgument, errs.KeyGuardFirewallFail,
			"guard: no engine ports to keep open")
	}
	if firewall == nil {
		firewall = NoopFirewall{}
	}
	return &Guard{firewall: firewall, opts: opts}, nil
}

// Apply brings the system to the requested settings.
func (g *Guard) Apply(ctx context.Context, settings session.Settings) error {
	g.mu.Lock()
	defer g.mu.Unlock()
	if g.restoring {
		return errs.Newf(errs.CodeFailedPrecondition, errs.KeyGuardFirewallFail,
			"guard: the guard is being restored")
	}
	if settings.KillSwitch && !g.applied.KillSwitch {
		if err := g.firewall.Arm(ctx, g.opts.EnginePorts); err != nil {
			return errs.Wrap(err, errs.CodeInternal, errs.KeyGuardFirewallFail)
		}
	}
	if !settings.KillSwitch && g.applied.KillSwitch {
		if err := g.firewall.Disarm(ctx); err != nil {
			return errs.Wrap(err, errs.CodeInternal, errs.KeyGuardFirewallFail)
		}
	}
	g.applied = settings
	return nil
}

// Restore lifts the kill switch if this guard armed it.
func (g *Guard) Restore(ctx context.Context) error {
	g.mu.Lock()
	defer g.mu.Unlock()
	g.restoring = true
	defer func() { g.restoring = false }()

	if g.applied.KillSwitch {
		if err := g.firewall.Disarm(ctx); err != nil {
			// Retain armed state after a failed restore so
			// subsequent cleanup can retry.
			return errs.Wrap(err, errs.CodeInternal, errs.KeyGuardRestoreFailed)
		}
	}
	g.applied = session.Settings{}
	return nil
}

// Current reports the settings the guard believes are in force.
func (g *Guard) Current() session.Settings {
	g.mu.Lock()
	defer g.mu.Unlock()
	return g.applied
}

// Name identifies the guard in a diagnostics line.
func (g *Guard) Name() string { return "sora-guard" }
