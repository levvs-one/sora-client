// Package registry knows every engine Sora can drive, finds the builds this
// machine has, picks one per plan by capability and measures servers through
// the engine that carries them.
package registry

import (
	"context"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"runtime"
	"slices"
	"sync"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/bypass"
	"github.com/levvs-one/sora-client/core/engine/mihomo"
	"github.com/levvs-one/sora-client/core/engine/singbox"
	"github.com/levvs-one/sora-client/core/engine/supervise"
	"github.com/levvs-one/sora-client/core/engine/xray"
	"github.com/levvs-one/sora-client/core/engine/xraytun"
	"github.com/levvs-one/sora-client/core/errs"
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
	// tpws is zapret's proxy for bypass outbounds; empty when not
	// installed.
	tpws string

	mu   sync.Mutex
	last engine.Selection
}

// Discover searches environment overrides, enginesDir, and PATH for each
// engine. Missing builds are recorded without failing discovery. Instances
// inherit base and use separate directories under base.HomeDir.
func Discover(ctx context.Context, enginesDir string, base supervise.Config) *Registry {
	r := &Registry{binaries: map[engine.Kind]supervise.Binary{}, preference: engine.DefaultPreference, base: base}
	if enginesDir != "" {
		candidate := filepath.Join(enginesDir, "tpws")
		if info, err := os.Stat(candidate); err == nil && info.Mode().IsRegular() && info.Mode().Perm()&0o111 != 0 { //nolint:gosec // the engines directory is set by the service, not by a client
			r.tpws = candidate
		}
	}
	for _, kind := range engine.DefaultPreference {
		b, err := drivers[kind].prober.Discover(ctx, enginesDir)
		if err != nil {
			// Probe errors contain local paths; expose them only
			// through sora-core -check, not diagnostics.
			r.availability = append(r.availability, engine.Availability{Kind: kind, Reason: "not installed"})
			continue
		}
		r.binaries[kind] = b
		r.availability = append(r.availability, engine.Availability{Kind: kind, Path: b.Path, Version: b.Version, BuildTags: b.BuildTags, Usable: true})
	}
	return r
}

// Availability returns discovery results for all known engines.
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

// BypassAvailable reports whether the serverless engine can run on this platform.
func (r *Registry) BypassAvailable() bool {
	return runtime.GOOS == "linux" && r.tpws != "" && r.Usable()
}

// LastSelection returns the latest engine choice and rejection reasons for
// diagnostics.
func (r *Registry) LastSelection() engine.Selection {
	r.mu.Lock()
	defer r.mu.Unlock()
	return r.last
}

// Pin restricts the service to one engine, overriding plan preference order.
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

// order selects service pin, request order, or default order, in that priority.
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

// Factory creates the first engine in preference order that supports the entire
// plan.
func (r *Registry) Factory() func(context.Context, *engine.Plan) (engine.Engine, error) {
	return func(_ context.Context, p *engine.Plan) (engine.Engine, error) {
		if p == nil {
			return nil, errors.New("registry: nil plan")
		}
		order, err := r.order(p.Engines)
		if err != nil {
			return nil, err
		}
		if len(p.Engines) == 0 && p.PrivateControl {
			order = engine.PrivatePreference
		}
		withBypass := bypass.Has(p)
		// Missing installations use the missing-engine key rather than
		// an invalid-plan error.
		if withBypass && r.tpws == "" {
			return nil, errs.Newf(errs.CodeFailedPrecondition, errs.KeyEngineBinaryMissing,
				"registry: bypass outbounds need zapret's tpws in the engines directory")
		}
		// Select capabilities against the SOCKS5 plan produced by
		// bypass rewriting.
		selectPlan := bypass.Rewrite(p, nil)
		bridge := len(order) == 1 && order[0] == engine.KindXray && p.Tun.Enabled &&
			slices.Contains([]string{"system", "mixed", "mips"}, p.Tun.Stack)
		if bridge {
			packetEngine, installed := r.binaries[engine.KindMihomo]
			if !installed {
				return nil, errs.Newf(errs.CodeFailedPrecondition, errs.KeyEngineBinaryMissing,
					"registry: Xray's selected TUN stack needs mihomo in the engines directory")
			}
			if packetEngine.Version.Less(engine.Version{Major: 1, Minor: 19, Patch: 32}) {
				return nil, errs.Newf(errs.CodeFailedPrecondition, errs.KeyPlanEngineUnsupported,
					"registry: Xray's selected TUN stack needs mihomo 1.19.32 or newer")
			}
			// Admit Xray's actual transports and routing independently of the
			// packet stack supplied by the second installed engine.
			selectPlan.Tun.Stack = "gvisor"
			if selectPlan.DNS.Mode == string(engine.DNSFakeIP) {
				selectPlan.DNS.Mode = "rule"
			}
		}
		sel, err := engine.SelectEngine(selectPlan, r.availability, order)
		r.mu.Lock()
		r.last = sel
		r.mu.Unlock()
		if err != nil {
			for _, kind := range order {
				if _, installed := r.binaries[kind]; installed {
					return nil, errs.Wrap(err, errs.CodeFailedPrecondition, errs.KeyPlanEngineUnsupported)
				}
			}
			return nil, errs.Wrap(err, errs.CodeFailedPrecondition, errs.KeyEngineBinaryMissing)
		}
		cfg := r.base
		cfg.Binary = r.binaries[sel.Kind]
		cfg.HomeDir = filepath.Join(r.base.HomeDir, string(sel.Kind))
		var built engine.Engine
		if bridge {
			tcfg := r.base
			tcfg.Binary = r.binaries[engine.KindMihomo]
			tcfg.HomeDir = filepath.Join(r.base.HomeDir, "xray-tun")
			built, err = xraytun.New(cfg, tcfg)
		} else {
			built, err = drivers[sel.Kind].build(cfg)
		}
		if err != nil || !withBypass {
			return built, err
		}
		return bypass.Wrap(built, r.tpws, filepath.Join(r.base.HomeDir, "zapret"), r.base.Logs), nil
	}
}

// Measure streams request timings through each outbound's first compatible
// engine. Unsupported outbounds return ErrNoEngine for TCP fallback; the
// channel closes after all results.
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
			// Suppress measurement engine logs; results already
			// report probe outcomes.
			cfg.Logs = nil
			if err := drivers[kind].measure(ctx, cfg, group, opts, out); err != nil {
				// Startup failures must produce a result for
				// every affected server.
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

// measureThroughController starts one temporary Clash API engine for all
// outbounds and times each through the controller.
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
		// Plain unique probe names keep controller lookup consistent
		// with rendered names.
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
