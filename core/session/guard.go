package session

import (
	"context"
	"net/netip"
	"sync"

	"github.com/levvs-one/sora-client/core/errs"
)

// Settings describes session-owned system changes. The platform guard applies
// them and restores prior state on every exit path.
type Settings struct {
	TunNetworks []netip.Prefix
	// KillSwitch blocks non-session traffic and stays armed while the
	// engine is down.
	KillSwitch bool
	// Bypass lists destinations that must skip the tunnel.
	Bypass []string
	// TunnelMode is the tunnel the plan asked for: system, application or
	// none.
	TunnelMode string
}

// Guard applies and restores session system changes. Apply is idempotent;
// Restore tolerates repeated calls. Restoration failures must be reported, and
// settings must not be assumed to survive crashes.
type Guard interface {
	// Apply brings the system to the requested settings.
	Apply(ctx context.Context, s Settings) error
	// Restore returns the system to the state it had before Apply. Calling
	// it
	// without a prior Apply must succeed and change nothing.
	Restore(ctx context.Context) error
	// Current reports the settings the guard believes are in force.
	Current() Settings
	// Name identifies the implementation in diagnostics.
	Name() string
}

// NoopGuard supports system-owned tunnels such as Android, where this process
// manages no system settings.
type NoopGuard struct{}

// Apply records nothing and succeeds.
func (NoopGuard) Apply(context.Context, Settings) error { return nil }

// Restore succeeds without touching anything.
func (NoopGuard) Restore(context.Context) error { return nil }

// Current reports empty settings.
func (NoopGuard) Current() Settings { return Settings{} }

// Name identifies the implementation in diagnostics.
func (NoopGuard) Name() string { return "noop" }

// compositeGuard applies guards in order and restores in reverse to respect
// dependencies. Restoring firewall before proxy could leave proxied traffic
// unfiltered.
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

// Apply runs guards in order and rolls back earlier guards if a later one
// fails.
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

// Restore tries all applied guards in reverse order and returns the first
// failure, ensuring one error does not skip remaining cleanup.
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

// Current returns the first guard's settings, representing the outermost system
// change.
func (c *compositeGuard) Current() Settings {
	c.mu.Lock()
	defer c.mu.Unlock()
	if len(c.parts) == 0 {
		return Settings{}
	}
	return c.parts[0].Current()
}

// Name lists guard names in apply order for diagnostics.
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
