package session

import (
	"context"
	"sync"

	"github.com/levvs-one/sora-client/core/errs"
)

// Settings are the system-wide changes a session owns while it runs. They are
// values, not actions: the session decides what it needs, the platform guard
// decides how to do it, and the previous state is restored on every exit.
type Settings struct {
	// KillSwitch blocks traffic that does not belong to the session. It stays
	// armed while the engine is down, which is the entire reason it exists.
	KillSwitch bool
	// SystemProxy points the system proxy settings at the local engine.
	SystemProxy bool
	// Bypass lists destinations that must skip the tunnel.
	Bypass []string
	// TunnelMode is the tunnel the plan asked for: system, application or none.
	TunnelMode string
}

// Guard applies and reverts the system changes of a session.
//
// The contract is strict on purpose. Apply is idempotent, Restore must be safe
// to call more than once, and a session may never assume a setting survived a
// crash: a guard that cannot restore what it changed must report the failure
// rather than leave the machine in a half-configured state.
type Guard interface {
	// Apply brings the system to the requested settings.
	Apply(ctx context.Context, s Settings) error
	// Restore returns the system to the state it had before Apply. Calling it
	// without a prior Apply must succeed and change nothing.
	Restore(ctx context.Context) error
	// Current reports the settings the guard believes are in force.
	Current() Settings
	// Name identifies the implementation in diagnostics.
	Name() string
}

// NoopGuard is the guard of a platform that has no system-wide settings to
// change, such as an Android tunnel owned by the system. It keeps the session
// code free of nil checks and reports honestly that nothing is owned.
type NoopGuard struct{}

// Apply records nothing and succeeds.
func (NoopGuard) Apply(context.Context, Settings) error { return nil }

// Restore succeeds without touching anything.
func (NoopGuard) Restore(context.Context) error { return nil }

// Current reports empty settings.
func (NoopGuard) Current() Settings { return Settings{} }

// Name identifies the implementation in diagnostics.
func (NoopGuard) Name() string { return "noop" }

// compositeGuard applies several guards as one, so a platform can combine, for
// example, a proxy guard with a firewall guard and still be restored in reverse
// order. Restoration runs in reverse because a later guard may depend on an
// earlier one: removing the firewall before the proxy would leave a window
// where traffic is proxied but unfiltered.
type compositeGuard struct {
	mu     sync.Mutex
	parts  []Guard
	active int
}

// NewCompositeGuard combines guards into one. The first guard is applied first
// and restored last.
func NewCompositeGuard(parts ...Guard) Guard {
	kept := make([]Guard, 0, len(parts))
	for _, part := range parts {
		if part != nil {
			kept = append(kept, part)
		}
	}
	if len(kept) == 0 {
		return NoopGuard{}
	}
	if len(kept) == 1 {
		return kept[0]
	}
	return &compositeGuard{parts: kept}
}

// Apply applies every guard in order and rolls back the ones already applied if
// a later guard fails, so a failed session never leaves half a configuration.
func (c *compositeGuard) Apply(ctx context.Context, s Settings) error {
	c.mu.Lock()
	defer c.mu.Unlock()
	applied := 0
	for _, part := range c.parts {
		if err := part.Apply(ctx, s); err != nil {
			for i := applied - 1; i >= 0; i-- {
				_ = c.parts[i].Restore(ctx)
			}
			return errs.Wrap(err, errs.CodeOf(err), errs.KeyOf(err))
		}
		applied++
	}
	c.active = applied
	return nil
}

// Restore restores every applied guard in reverse order and reports the first
// failure after trying them all: a machine left with a proxy pointing at a dead
// port is worse than a reported error, so every part is attempted.
func (c *compositeGuard) Restore(ctx context.Context) error {
	c.mu.Lock()
	defer c.mu.Unlock()
	var first error
	for i := c.active - 1; i >= 0; i-- {
		if err := c.parts[i].Restore(ctx); err != nil && first == nil {
			first = err
		}
	}
	c.active = 0
	return first
}

// Current reports the settings of the first guard, which is the one that owns
// the outermost system change.
func (c *compositeGuard) Current() Settings {
	c.mu.Lock()
	defer c.mu.Unlock()
	if len(c.parts) == 0 {
		return Settings{}
	}
	return c.parts[0].Current()
}

// Name names every guard, in apply order, for a diagnostics line.
func (c *compositeGuard) Name() string {
	name := ""
	for i, part := range c.parts {
		if i > 0 {
			name += "+"
		}
		name += part.Name()
	}
	return name
}
