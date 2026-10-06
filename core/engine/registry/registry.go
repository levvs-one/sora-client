// Package registry knows every engine Sora can drive, finds the builds this
// machine has and picks one per plan by capability.
package registry

import (
	"context"
	"fmt"
	"path/filepath"
	"slices"
	"sync"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/mihomo"
	"github.com/levvs-one/sora-client/core/engine/singbox"
	"github.com/levvs-one/sora-client/core/engine/supervise"
	"github.com/levvs-one/sora-client/core/engine/xray"
)

// driver ties an engine kind to its prober and its constructor.
type driver struct {
	prober supervise.Prober
	build  func(supervise.Config) (engine.Engine, error)
}

var drivers = map[engine.Kind]driver{
	engine.KindSingBox: {singbox.Prober, func(c supervise.Config) (engine.Engine, error) { return singbox.New(c) }},
	engine.KindXray:    {xray.Prober, func(c supervise.Config) (engine.Engine, error) { return xray.New(c) }},
	engine.KindMihomo:  {mihomo.Prober, func(c supervise.Config) (engine.Engine, error) { return mihomo.New(c) }},
}

// Registry is the result of one discovery.
type Registry struct {
	binaries     map[engine.Kind]supervise.Binary
	availability []engine.Availability

	mu   sync.Mutex
	last engine.Selection
}

// Discover probes every known engine in enginesDir, the per-engine environment
// override and PATH. A missing engine is recorded with the reason, not
// treated as an error: one engine is enough to connect.
func Discover(ctx context.Context, enginesDir string) *Registry {
	r := &Registry{binaries: map[engine.Kind]supervise.Binary{}}
	for _, kind := range engine.DefaultPreference {
		b, err := drivers[kind].prober.Discover(ctx, enginesDir)
		if err != nil {
			// The probe error names local paths, which must not reach a diagnostic
			// report; the operator finds the details with "sora-core -check".
			r.availability = append(r.availability, engine.Availability{Kind: kind, Reason: "not installed"})
			continue
		}
		r.binaries[kind] = b
		r.availability = append(r.availability, engine.Availability{Kind: kind, Path: b.Path, Version: b.Version, Usable: true})
	}
	return r
}

// Availability lists every known engine with what this machine has of it.
func (r *Registry) Availability() []engine.Availability { return slices.Clone(r.availability) }

// Binaries returns the usable builds in preference order.
func (r *Registry) Binaries() []supervise.Binary {
	var out []supervise.Binary
	for _, kind := range engine.DefaultPreference {
		if b, ok := r.binaries[kind]; ok {
			out = append(out, b)
		}
	}
	return out
}

// Usable reports whether at least one engine can be started.
func (r *Registry) Usable() bool { return len(r.binaries) > 0 }

// LastSelection is the choice made for the most recent plan, with the reasons
// every other engine was passed over. Diagnostics show it.
func (r *Registry) LastSelection() engine.Selection {
	r.mu.Lock()
	defer r.mu.Unlock()
	return r.last
}

// Factory returns the engine factory of the core service. Each plan gets the
// first engine in preference order that carries all of it; a pinned kind
// narrows the preference to that engine alone. Every engine has its own home
// directory under base.HomeDir, because their state files differ.
func (r *Registry) Factory(base supervise.Config, pinned engine.Kind) (func(context.Context, *engine.Plan) (engine.Engine, error), error) {
	preference := engine.DefaultPreference
	if pinned != "" {
		if _, known := drivers[pinned]; !known {
			return nil, fmt.Errorf("registry: unknown engine %q", pinned)
		}
		preference = []engine.Kind{pinned}
	}
	return func(_ context.Context, p *engine.Plan) (engine.Engine, error) {
		sel, err := engine.SelectEngine(p, r.availability, preference)
		r.mu.Lock()
		r.last = sel
		r.mu.Unlock()
		if err != nil {
			return nil, err
		}
		cfg := base
		cfg.Binary = r.binaries[sel.Kind]
		cfg.HomeDir = filepath.Join(base.HomeDir, string(sel.Kind))
		return drivers[sel.Kind].build(cfg)
	}, nil
}
