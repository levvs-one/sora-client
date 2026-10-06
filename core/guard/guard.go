// Package guard applies and reverts the system changes a tunnel owns: the
// system proxy and the kill switch.
//
// Everything here is written from one rule: the core may only change what it can
// put back. A guard records what it found, changes one thing at a time, and on
// every exit path returns the machine to the state it had. That is why the parts
// are small, testable and separate: the proxy is one registry key on Windows, the
// kill switch is a firewall rule with a name this package owns, and neither knows
// anything about tunnels.
package guard

import (
	"context"
	"strings"
	"sync"

	"github.com/levvs-one/sora-client/core/errs"
	"github.com/levvs-one/sora-client/core/session"
)

// Compile-time proof that the guard is the shape a session expects. A session that
// stops compiling because of a change here is a change that would have broken the
// tunnel lifecycle, and it should fail here rather than in a service.
var _ session.Guard = (*Guard)(nil)

// NoopProxy is the proxy of a platform with no system-wide proxy setting, such as
// Linux and Android. It reports nothing and changes nothing, which is honest: the
// guard still restores what it armed, and there was nothing here to arm.
type NoopProxy struct{}

// Apply succeeds without changing anything.
func (NoopProxy) Apply(context.Context, string) error { return nil }

// Restore succeeds without changing anything.
func (NoopProxy) Restore(context.Context) error { return nil }

// Current reports that no system proxy is configured.
func (NoopProxy) Current(context.Context) (string, error) { return "", nil }

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

// Proxy changes the system-wide proxy setting of the desktop.
type Proxy interface {
	// Apply points the system proxy at address, remembering the previous value.
	// Applying twice with the same address changes nothing.
	Apply(ctx context.Context, address string) error
	// Restore puts back the value that was in force before the first Apply. It
	// succeeds when Apply was never called.
	Restore(ctx context.Context) error
	// Current reports where the system proxy points, empty when it is off.
	Current(ctx context.Context) (string, error)
}

// Firewall blocks or unblocks traffic that does not belong to the tunnel.
type Firewall interface {
	// Arm blocks traffic while the tunnel is down. It is idempotent.
	Arm(ctx context.Context, enginePorts []uint16) error
	// Disarm removes the block. It succeeds when nothing is armed.
	Disarm(ctx context.Context) error
	// Armed reports whether the block is in force.
	Armed(ctx context.Context) (bool, error)
}

// Options says where the engine listens. The guard needs it because those are the
// two values that depend on the machine rather than on the user: a desktop proxy
// points at the local mixed port, and a kill switch must keep the engine's own
// ports open or the tunnel can never come back.
type Options struct {
	// ProxyAddress is the host:port a desktop system proxy is pointed at.
	ProxyAddress string
	// EnginePorts are the local ports the kill switch must never block.
	EnginePorts []uint16
}

// Guard is the guard a session uses: it owns the proxy and the kill switch and
// restores both, in that order, when a session ends.
//
// The order matters. The engine stops first, then the proxy is restored, and only
// then is the block lifted: a machine that is unblocked while the proxy still
// points at a dead port looks connected and passes nothing.
type Guard struct {
	mu        sync.Mutex
	proxy     Proxy
	firewall  Firewall
	opts      Options
	applied   session.Settings
	restoring bool
}

// New builds a guard over its parts. Nil parts are replaced by ones that do
// nothing, so a platform without a firewall still gets a guard that restores the
// proxy correctly. An empty ProxyAddress is refused, because a guard that points a
// system proxy at nothing is worse than no guard at all.
func New(opts Options, proxy Proxy, firewall Firewall) (*Guard, error) {
	if strings.TrimSpace(opts.ProxyAddress) == "" {
		return nil, errs.Newf(errs.CodeInvalidArgument, errs.KeyGuardProxyFailed,
			"guard: no address for the local proxy")
	}
	if len(opts.EnginePorts) == 0 {
		return nil, errs.Newf(errs.CodeInvalidArgument, errs.KeyGuardFirewallFail,
			"guard: no engine ports to keep open")
	}
	if proxy == nil {
		proxy = NoopProxy{}
	}
	if firewall == nil {
		firewall = NoopFirewall{}
	}
	return &Guard{proxy: proxy, firewall: firewall, opts: opts}, nil
}

// Apply brings the system to the requested settings.
func (g *Guard) Apply(ctx context.Context, settings session.Settings) error {
	g.mu.Lock()
	defer g.mu.Unlock()
	if g.restoring {
		return errs.Newf(errs.CodeFailedPrecondition, errs.KeyGuardFirewallFail,
			"guard: the guard is being restored")
	}
	// The kill switch is armed before the proxy is pointed at the engine, so there
	// is no window in which traffic is proxied through a tunnel that may die
	// without anything noticing.
	if settings.KillSwitch && !g.applied.KillSwitch {
		if err := g.firewall.Arm(ctx, g.opts.EnginePorts); err != nil {
			return errs.Wrap(err, errs.CodeInternal, errs.KeyGuardFirewallFail)
		}
	}
	if settings.SystemProxy && !g.applied.SystemProxy {
		if err := g.proxy.Apply(ctx, g.opts.ProxyAddress); err != nil {
			// The block was just armed and the proxy failed: leaving the block in
			// place would cut the machine off with no tunnel to serve it.
			_ = g.firewall.Disarm(ctx)
			return errs.Wrap(err, errs.CodeInternal, errs.KeyGuardProxyFailed)
		}
	}
	g.applied = settings
	return nil
}

// Restore returns the system to the state it had before the first Apply. Both
// parts are attempted even when the first one fails: a machine left with a proxy
// pointing at a dead port is worse than a reported error.
func (g *Guard) Restore(ctx context.Context) error {
	g.mu.Lock()
	defer g.mu.Unlock()
	g.restoring = true
	defer func() { g.restoring = false }()

	var first error
	if g.applied.SystemProxy {
		if err := g.proxy.Restore(ctx); err != nil {
			first = errs.Wrap(err, errs.CodeInternal, errs.KeyGuardRestoreFailed)
		}
	}
	if g.applied.KillSwitch {
		if err := g.firewall.Disarm(ctx); err != nil && first == nil {
			first = errs.Wrap(err, errs.CodeInternal, errs.KeyGuardRestoreFailed)
		}
	}
	g.applied = session.Settings{}
	return first
}

// Current reports the settings the guard believes are in force.
func (g *Guard) Current() session.Settings {
	g.mu.Lock()
	defer g.mu.Unlock()
	return g.applied
}

// Name identifies the guard in a diagnostics line.
func (g *Guard) Name() string { return "sora-guard" }
