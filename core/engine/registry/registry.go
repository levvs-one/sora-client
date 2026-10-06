// Package registry knows every engine Sora can drive, finds the builds this
// machine has, picks one per plan by capability and measures servers through
// the engine that carries them.
package registry

import (
	"context"
	"errors"
	"fmt"
	"path/filepath"
	"slices"
	"sync"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/mihomo"
	"github.com/levvs-one/sora-client/core/engine/singbox"
	"github.com/levvs-one/sora-client/core/engine/supervise"
	"github.com/levvs-one/sora-client/core/engine/xray"
)

// measureFunc times a real request through every outbound with one engine.
type measureFunc func(ctx context.Context, cfg supervise.Config, outbounds []engine.Outbound, opts engine.MeasureOptions, out chan<- engine.Measurement) error

// driver ties an engine kind to its prober, its constructor and its way of
// measuring many servers.
type driver struct {
	prober  supervise.Prober
	build   func(supervise.Config) (engine.Engine, error)
	measure measureFunc
}

var drivers = map[engine.Kind]driver{}

func init() {
	buildSingBox := func(c supervise.Config) (engine.Engine, error) { return singbox.New(c) }
	buildMihomo := func(c supervise.Config) (engine.Engine, error) { return mihomo.New(c) }
	drivers[engine.KindSingBox] = driver{singbox.Prober, buildSingBox, measureThroughController(buildSingBox)}
	drivers[engine.KindMihomo] = driver{mihomo.Prober, buildMihomo, measureThroughController(buildMihomo)}
	drivers[engine.KindXray] = driver{xray.Prober, func(c supervise.Config) (engine.Engine, error) { return xray.New(c) }, xray.Measure}
}

// Registry is the result of one discovery.
type Registry struct {
	binaries     map[engine.Kind]supervise.Binary
	availability []engine.Availability
	// preference is the default engine order; the service may narrow it to
	// one pinned engine, and a plan may bring its own order.
	preference []engine.Kind
	// base is the configuration every engine instance starts from.
	base supervise.Config

	mu   sync.Mutex
	last engine.Selection
}

// Discover probes every known engine in enginesDir, the per-engine environment
// override and PATH. A missing engine is recorded, not treated as an error:
// one engine is enough to connect. base is the configuration every engine
// instance starts from; each engine gets its own directory under base.HomeDir.
func Discover(ctx context.Context, enginesDir string, base supervise.Config) *Registry {
	r := &Registry{binaries: map[engine.Kind]supervise.Binary{}, preference: engine.DefaultPreference, base: base}
	for _, kind := range engine.DefaultPreference {
		b, err := drivers[kind].prober.Discover(ctx, enginesDir)
		if err != nil {
			// The probe error names local paths, which must not reach a
			// diagnostic report; "sora-core -check" shows the details.
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

// Binaries returns the usable builds in default preference order.
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

// Pin narrows the default order to one engine, as the -engine flag of the
// service asks. A pinned service ignores the order a plan brings.
func (r *Registry) Pin(kind engine.Kind) error {
	if kind == "" {
		return nil
	}
	if _, known := drivers[kind]; !known {
		return fmt.Errorf("registry: unknown engine %q", kind)
	}
	r.preference = []engine.Kind{kind}
	return nil
}

// order resolves the engine order for one request: the service pin wins,
// then the order the request brings, then the default.
func (r *Registry) order(requested []engine.Kind) ([]engine.Kind, error) {
	if len(r.preference) == 1 || len(requested) == 0 {
		return r.preference, nil
	}
	for _, kind := range requested {
		if _, known := drivers[kind]; !known {
			return nil, fmt.Errorf("registry: unknown engine %q", kind)
		}
	}
	return requested, nil
}

// Factory returns the engine factory of the core service: each plan runs on
// the first engine of its order that carries all of it.
func (r *Registry) Factory() func(context.Context, *engine.Plan) (engine.Engine, error) {
	return func(_ context.Context, p *engine.Plan) (engine.Engine, error) {
		if p == nil {
			return nil, errors.New("registry: nil plan")
		}
		order, err := r.order(p.Engines)
		if err != nil {
			return nil, err
		}
		sel, err := engine.SelectEngine(p, r.availability, order)
		r.mu.Lock()
		r.last = sel
		r.mu.Unlock()
		if err != nil {
			return nil, err
		}
		cfg := r.base
		cfg.Binary = r.binaries[sel.Kind]
		cfg.HomeDir = filepath.Join(r.base.HomeDir, string(sel.Kind))
		return drivers[sel.Kind].build(cfg)
	}
}

// Measure times a real request through every outbound, each through the
// first engine of the order that carries it, and streams the results as they
// arrive. An outbound no available engine carries gets ErrNoEngine, so the
// caller can fall back to a plain connection check. The channel closes when
// every outbound has a result.
func (r *Registry) Measure(ctx context.Context, outbounds []engine.Outbound, opts engine.MeasureOptions) (<-chan engine.Measurement, error) {
	order, err := r.order(opts.Engines)
	if err != nil {
		return nil, err
	}
	byKind := map[engine.Kind][]engine.Outbound{}
	var orphans []engine.Outbound
	for _, o := range outbounds {
		single := &engine.Plan{Outbounds: []engine.Outbound{o}}
		sel, err := engine.SelectEngine(single, r.availability, order)
		if err != nil {
			orphans = append(orphans, o)
			continue
		}
		byKind[sel.Kind] = append(byKind[sel.Kind], o)
	}

	out := make(chan engine.Measurement, len(outbounds))
	var wg sync.WaitGroup
	for kind, group := range byKind {
		wg.Add(1)
		go func() {
			defer wg.Done()
			cfg := r.base
			cfg.Binary = r.binaries[kind]
			cfg.HomeDir = filepath.Join(r.base.HomeDir, "measure-"+string(kind))
			cfg.LocalPort = 0
			if err := drivers[kind].measure(ctx, cfg, group, opts, out); err != nil {
				// The engine never came up; every server of the group gets
				// the reason instead of silently missing from the list.
				for _, o := range group {
					out <- engine.Measurement{OutboundID: o.ID, Engine: kind, Err: err}
				}
			}
		}()
	}
	for _, o := range orphans {
		out <- engine.Measurement{OutboundID: o.ID, Err: engine.ErrNoEngine}
	}
	go func() {
		wg.Wait()
		close(out)
	}()
	return out, nil
}

// measureThroughController measures with an engine controlled over the Clash
// API: one short-lived instance carries every outbound under a probe name, and
// the controller times each of them.
func measureThroughController(build func(supervise.Config) (engine.Engine, error)) measureFunc {
	return func(ctx context.Context, cfg supervise.Config, outbounds []engine.Outbound, opts engine.MeasureOptions, out chan<- engine.Measurement) error {
		if opts.Concurrency <= 0 {
			opts.Concurrency = 8
		}
		if opts.Timeout <= 0 {
			opts.Timeout = 5 * time.Second
		}
		plan := &engine.Plan{
			SessionID: "measure",
			Rules:     []engine.Rule{{Type: engine.RuleMatchAll, Target: "direct"}},
			Options:   engine.Options{LogLevel: "error", TestURL: opts.URL},
		}
		// Probe names are plain and unique, so the engine keeps them as they
		// are and the controller finds each outbound by the name it was given.
		ids := make(map[string]string, len(outbounds))
		for i, o := range outbounds {
			o.Name = fmt.Sprintf("probe-%d", i+1)
			ids[o.Name] = o.ID
			plan.Outbounds = append(plan.Outbounds, o)
		}
		eng, err := build(cfg)
		if err != nil {
			return err
		}
		defer func() { _ = eng.Close() }()
		if err := eng.Apply(ctx, plan); err != nil {
			return err
		}
		sem := make(chan struct{}, opts.Concurrency)
		var wg sync.WaitGroup
		for name, id := range ids {
			wg.Add(1)
			sem <- struct{}{}
			go func() {
				defer wg.Done()
				defer func() { <-sem }()
				d, err := eng.Delay(ctx, name, opts.URL, opts.Timeout)
				out <- engine.Measurement{OutboundID: id, Engine: eng.Kind(), Latency: d, Err: err}
			}()
		}
		wg.Wait()
		return nil
	}
}
