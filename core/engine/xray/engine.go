// Package xray drives XTLS/Xray-core as an engine of Sora.
//
// Xray is a separate binary started as a child process with the configuration
// on stdin ("run -c stdin:"). It carries what the other engines do not: XHTTP,
// VLESS Encryption and the Xray flavour of REALITY. Its control surface is
// smaller, and the package fills the gaps honestly:
//
//   - counters and the latency of automatic groups come from the loopback
//     metrics listener (expvar at /debug/vars);
//   - Xray has no runtime selector, so a select group is pinned in the
//     routing table and a new choice restarts the engine;
//   - Delay starts a short-lived second Xray with one SOCKS inbound routed to
//     the measured outbound and times a real request through it.
package xray

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"maps"
	"net"
	"net/http"
	"net/url"
	"regexp"
	"strconv"
	"sync"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/supervise"
)

// Prober recognizes an Xray build. "xray version" prints, for example,
// "Xray 26.3.27 (Xray, Penetrates Everything.) d2758a0 (go1.26.1 linux/amd64)".
var Prober = supervise.Prober{
	Kind:    engine.KindXray,
	Name:    "xray",
	EnvVar:  "SORA_XRAY_BIN",
	Args:    []string{"version"},
	Pattern: regexp.MustCompile(`^Xray v?(\d+\.\d+\.\d+[0-9A-Za-z.\-]*)\s.*\(go[^ ]+ (\w+)/(\w+)\)`),
}

// Engine runs Xray under the shared supervisor.
type Engine struct {
	*supervise.Supervisor
	cfg    supervise.Config
	driver *driver

	mu       sync.Mutex
	counters engine.Counters
}

// New builds an Xray engine. Nothing is started: Apply does the work.
func New(cfg supervise.Config) (*Engine, error) {
	d := &driver{sel: Selection{}}
	sup, err := supervise.New(cfg, d)
	if err != nil {
		return nil, err
	}
	return &Engine{Supervisor: sup, cfg: cfg, driver: d}, nil
}

type driver struct {
	mu  sync.Mutex
	sel Selection
}

func (*driver) Kind() engine.Kind { return engine.KindXray }

func (d *driver) Render(p *engine.Plan, rt supervise.Runtime) ([]byte, error) {
	return Render(p, rt, d.selection())
}

func (d *driver) selection() Selection {
	d.mu.Lock()
	defer d.mu.Unlock()
	return maps.Clone(d.sel)
}

func (*driver) RunArgs(supervise.Runtime) []string   { return []string{"run", "-c", "stdin:"} }
func (*driver) CheckArgs(supervise.Runtime) []string { return []string{"run", "-test", "-c", "stdin:"} }

// Handshake waits for the metrics listener. Xray does not report its version
// there, so the probed version stays in effect.
func (*driver) Handshake(ctx context.Context, rt supervise.Runtime) (string, error) {
	_, err := readVars(ctx, rt.ControlAddr)
	return "", err
}

func (*driver) Reload(context.Context, supervise.Runtime, []byte) error {
	return supervise.ErrReloadUnsupported
}

// vars is the part of /debug/vars Sora reads.
type vars struct {
	Stats struct {
		Inbound  map[string]traffic `json:"inbound"`
		Outbound map[string]traffic `json:"outbound"`
	} `json:"stats"`
	Observatory map[string]struct {
		Alive bool `json:"alive"`
		Delay int  `json:"delay"`
	} `json:"observatory"`
	Memstats struct {
		Alloc uint64 `json:"Alloc"`
	} `json:"memstats"`
}

type traffic struct {
	Uplink   uint64 `json:"uplink"`
	Downlink uint64 `json:"downlink"`
}

func readVars(ctx context.Context, addr string) (vars, error) {
	ctx, cancel := context.WithTimeout(ctx, 3*time.Second)
	defer cancel()
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, "http://"+addr+"/debug/vars", nil)
	if err != nil {
		return vars{}, err
	}
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return vars{}, fmt.Errorf("xray: metrics are not reachable: %w", err)
	}
	defer func() { _ = resp.Body.Close() }()
	if resp.StatusCode != http.StatusOK {
		return vars{}, fmt.Errorf("xray: metrics answered %d", resp.StatusCode)
	}
	var v vars
	if err := json.NewDecoder(io.LimitReader(resp.Body, 8<<20)).Decode(&v); err != nil {
		return vars{}, fmt.Errorf("xray: decode metrics: %w", err)
	}
	return v, nil
}

// Counters returns the traffic of the mixed inbound, which is all the traffic
// applications sent through Sora. On a metrics hiccup the last value is
// returned with the error, so the interface keeps its chart.
func (e *Engine) Counters(ctx context.Context) (engine.Counters, error) {
	rt, err := e.Running()
	if err != nil {
		return engine.Counters{}, err
	}
	v, verr := readVars(ctx, rt.ControlAddr)
	e.mu.Lock()
	defer e.mu.Unlock()
	if verr != nil {
		return e.counters, e.Redactor().Err(verr)
	}
	in := v.Stats.Inbound[tagInbound]
	e.counters = engine.Counters{BytesUp: in.Uplink, BytesDown: in.Downlink, MemoryBytes: v.Memstats.Alloc, At: time.Now()}
	return e.counters, nil
}

// Groups reports the groups of the plan with their live state: the pinned
// member of a select group and the fastest live member of an automatic one.
func (e *Engine) Groups(ctx context.Context) ([]engine.GroupStatus, error) {
	rt, err := e.Running()
	if err != nil {
		return nil, err
	}
	p := e.Plan()
	if p == nil {
		return nil, supervise.ErrNotRunning
	}
	v, err := readVars(ctx, rt.ControlAddr)
	if err != nil {
		return nil, e.Redactor().Err(err)
	}
	names, tags := map[string]string{}, map[string]string{}
	for i, o := range p.Outbounds {
		names[o.ID] = displayName(o)
		tags[o.ID] = outboundTag(i)
	}
	sel := e.driver.selection()
	out := make([]engine.GroupStatus, 0, len(p.Groups))
	for _, g := range p.Groups {
		status := engine.GroupStatus{Name: g.Name, Type: g.Type, Hidden: g.Hidden, Icon: g.Icon,
			TestURL: g.URL, LatencyMS: map[string]int{}, UpdatedAt: time.Now()}
		best := -1
		for _, id := range g.Outbounds {
			name := orDefault(names[id], id)
			status.All = append(status.All, name)
			if probe, ok := v.Observatory[tags[id]]; ok && probe.Alive {
				status.LatencyMS[name] = probe.Delay
				if best < 0 || probe.Delay < best {
					best, status.Selected = probe.Delay, name
				}
			}
		}
		if g.Type == engine.GroupSelect && len(g.Outbounds) > 0 {
			pinned := g.Outbounds[0]
			if s, ok := sel[g.Name]; ok {
				pinned = s
			}
			status.Selected = orDefault(names[pinned], pinned)
		}
		out = append(out, status)
	}
	return out, nil
}

// Select pins a member of a select group and restarts the engine on the new
// routing table. target may be a plan id or a display name.
func (e *Engine) Select(ctx context.Context, group, target string) error {
	p := e.Plan()
	if p == nil {
		return supervise.ErrNotRunning
	}
	member, err := resolveMember(p, group, target)
	if err != nil {
		return err
	}
	e.driver.mu.Lock()
	previous, had := e.driver.sel[group]
	e.driver.sel[group] = member
	e.driver.mu.Unlock()
	if err := e.Apply(ctx, p); err != nil {
		e.driver.mu.Lock()
		if had {
			e.driver.sel[group] = previous
		} else {
			delete(e.driver.sel, group)
		}
		e.driver.mu.Unlock()
		return err
	}
	e.Events().Publish(engine.Event{Kind: engine.EventGroup, Group: &engine.GroupStatus{Name: group, Selected: target}})
	return nil
}

func resolveMember(p *engine.Plan, group, target string) (string, error) {
	for _, g := range p.Groups {
		if g.Name != group {
			continue
		}
		if g.Type != engine.GroupSelect {
			return "", fmt.Errorf("xray: group %q is not a select group", group)
		}
		for _, id := range g.Outbounds {
			if id == target {
				return id, nil
			}
			if o, ok := p.OutboundByID(id); ok && displayName(o) == target {
				return id, nil
			}
		}
		return "", fmt.Errorf("xray: %q is not a member of group %q", target, group)
	}
	return "", fmt.Errorf("xray: no group %q", group)
}

func displayName(o engine.Outbound) string { return orDefault(o.Name, o.ID) }

// Delay measures one outbound with a real request. A second Xray carries just
// that outbound behind a SOCKS inbound, so the measurement neither touches the
// user's routing nor waits for the observatory.
func (e *Engine) Delay(ctx context.Context, name, testURL string, timeout time.Duration) (time.Duration, error) {
	p := e.Plan()
	if p == nil {
		return 0, supervise.ErrNotRunning
	}
	var target *engine.Outbound
	for i := range p.Outbounds {
		if p.Outbounds[i].ID == name || displayName(p.Outbounds[i]) == name {
			target = &p.Outbounds[i]
			break
		}
	}
	if target == nil {
		return 0, fmt.Errorf("xray: no outbound %q", name)
	}
	if testURL == "" {
		testURL = e.ProbeURL()
	}
	if timeout <= 0 {
		timeout = 5 * time.Second
	}
	d, err := measure(ctx, e.cfg, target, p.Options, testURL, timeout)
	return d, e.Redactor().Err(err)
}

func measure(ctx context.Context, cfg supervise.Config, o *engine.Outbound, opts engine.Options, testURL string, timeout time.Duration) (time.Duration, error) {
	port, err := supervise.FreePort()
	if err != nil {
		return 0, err
	}
	metrics, err := supervise.FreePort()
	if err != nil {
		return 0, err
	}
	probe := &engine.Plan{
		SessionID: "delay",
		Outbounds: []engine.Outbound{*o},
		Rules:     []engine.Rule{{Type: engine.RuleMatchAll, Target: o.ID}},
		Options:   engine.Options{LogLevel: "error", Fragment: opts.Fragment},
	}
	rt := supervise.Runtime{HomeDir: cfg.HomeDir, LocalPort: port, ControlAddr: "127.0.0.1:" + strconv.Itoa(metrics)}
	raw, err := Render(probe, rt, nil)
	if err != nil {
		return 0, err
	}
	ctx, cancel := context.WithTimeout(ctx, timeout+cfg.StartTimeout)
	defer cancel()
	proc, err := supervise.Start(ctx, supervise.Spec{Name: "xray", Path: cfg.Binary.Path, Args: []string{"run", "-c", "stdin:"}, Dir: cfg.HomeDir, Config: raw})
	if err != nil {
		return 0, err
	}
	defer func() { _ = proc.Stop(context.WithoutCancel(ctx), 0) }()
	if err := waitListening(ctx, proc, rt.LocalPort); err != nil {
		return 0, err
	}

	proxy := &url.URL{Scheme: "socks5h", Host: "127.0.0.1:" + strconv.Itoa(port)}
	client := &http.Client{Timeout: timeout, Transport: &http.Transport{Proxy: http.ProxyURL(proxy), DisableKeepAlives: true}}
	req, err := http.NewRequestWithContext(ctx, http.MethodHead, testURL, nil)
	if err != nil {
		return 0, err
	}
	start := time.Now()
	resp, err := client.Do(req)
	if err != nil {
		return 0, fmt.Errorf("xray: latency test failed: %w", err)
	}
	_ = resp.Body.Close()
	if resp.StatusCode >= 500 {
		return 0, fmt.Errorf("xray: latency test answered %d", resp.StatusCode)
	}
	return time.Since(start), nil
}

func waitListening(ctx context.Context, proc *supervise.Process, port int) error {
	addr := "127.0.0.1:" + strconv.Itoa(port)
	var dialer net.Dialer
	for {
		conn, err := dialer.DialContext(ctx, "tcp", addr)
		if err == nil {
			return conn.Close()
		}
		if reason := proc.Err(); reason != nil {
			return reason
		}
		select {
		case <-ctx.Done():
			return errors.Join(ctx.Err(), errors.New(proc.Output().Last(3)))
		case <-time.After(50 * time.Millisecond):
		}
	}
}
