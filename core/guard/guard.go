// Package guard applies and reverts the system change a tunnel owns: the kill
// switch.
//
// Everything here is written from one rule: the core may only change what it can
// put back. A guard records what it armed and, on every exit path, lifts it
// again. The kill switch is a firewall rule set with a name this package owns,
// and it knows nothing about tunnels.
package guard

import (
	"context"
	"sync"

	"github.com/levvs-one/sora-client/core/errs"
	"github.com/levvs-one/sora-client/core/session"
)

// Compile-time proof that the guard is the shape a session expects. A session that
// stops compiling because of a change here is a change that would have broken the
// tunnel lifecycle, and it should fail here rather than in a service.
var _ session.Guard = (*Guard)(nil)

// NoopFirewall is the firewall of a platform where the tunnel is owned by the
// system rather than by a rule this process can add: the Android VpnService owns
// its routes, and there is nothing to block or unblock from here.
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

// FirewallOptions says what a kill switch lets through besides the tunnel.
type FirewallOptions struct {
	// EngineUID is the account the engines run as; Linux matches them by it.
	EngineUID int
	// EnginesDir holds the engine executables; Windows matches them by file.
	EnginesDir string
	// Bypass are the networks that stay reachable; empty means private space.
	Bypass []string
}

// Options says where the engine listens: a kill switch must keep the engine's
// own ports open or the tunnel can never come back.
type Options struct {
	// EnginePorts are the local ports the kill switch must never block.
	EnginePorts []uint16
}

// Guard is the guard a session uses: it owns the kill switch and lifts it when
// a session ends. The system proxy is not here: it belongs to the person signed
// in, and the interface, which runs as that person, sets it.
type Guard struct {
	mu        sync.Mutex
	firewall  Firewall
	opts      Options
	applied   session.Settings
	restoring bool
}

// New builds a guard over its firewall. A nil firewall is replaced by one that
// does nothing, so a platform without one still gets a guard.
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
			// The block is still in force: the guard keeps knowing it, so the
			// next restore or the next session lifts it.
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
