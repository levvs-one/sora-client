// Package bypass runs zapret tpws to reshape direct TLS and HTTP handshakes
// against DPI. It shares one loopback SOCKS5 proxy per strategy and rewrites
// bypass outbounds to SOCKS5, supporting all engines, rules, and groups.
package bypass

import (
	"context"
	"errors"
	"fmt"
	"net"
	"slices"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/supervise"
	"github.com/levvs-one/sora-client/core/logs"
)

// Source names tpws in the log center.
const Source = "zapret"

// Has reports whether a plan carries a bypass outbound.
func Has(p *engine.Plan) bool {
	return p != nil && slices.ContainsFunc(p.Outbounds, func(o engine.Outbound) bool { return o.Protocol == engine.ProtocolBypass })
}

// Args returns listener and strategy arguments for tpws. Plans cannot set file,
// user, or daemon options.
func Args(s engine.BypassStrategy, port int) []string {
	args := []string{"--socks", "--bind-addr=127.0.0.1", "--port=" + strconv.Itoa(port)}
	if len(s.SplitPos) > 0 {
		args = append(args, "--split-pos="+strings.Join(s.SplitPos, ","))
	}
	if s.Disorder {
		args = append(args, "--disorder")
	}
	if s.OOB {
		args = append(args, "--oob")
	}
	if s.TLSRecord != "" {
		args = append(args, "--tlsrec="+s.TLSRecord)
	}
	if s.HostCase {
		args = append(args, "--hostcase")
	}
	if s.DomainCase {
		args = append(args, "--domcase")
	}
	if s.MethodEOL {
		args = append(args, "--methodeol")
	}
	return args
}

// key identifies a strategy so matching outbounds share one tpws process.
func key(s engine.BypassStrategy) string { return strings.Join(Args(s, 0), " ") }

// Rewrite replaces bypass outbounds with SOCKS5 proxies. ports maps strategy
// keys to ports; absent keys use port 1 for validation without a running proxy.
func Rewrite(p *engine.Plan, ports map[string]int) *engine.Plan {
	out := *p
	out.Outbounds = slices.Clone(p.Outbounds)
	for i, o := range out.Outbounds {
		if o.Protocol != engine.ProtocolBypass {
			continue
		}
		port := ports[key(*o.Bypass)]
		if port == 0 {
			port = 1
		}
		out.Outbounds[i] = engine.Outbound{ID: o.ID, Name: o.Name, Protocol: engine.ProtocolSOCKS5,
			Server: "127.0.0.1", Port: uint16(port)} //nolint:gosec // a loopback port from FreePort
	}
	return &out
}

// Engine runs an engine with the tpws processes its plan needs.
type Engine struct {
	engine.Engine
	tpws string
	home string
	logs *logs.Center

	mu    sync.Mutex
	procs map[string]*proxy
}

type proxy struct {
	port   int
	proc   *supervise.Process
	cancel context.CancelFunc
}

// Wrap adds bypass outbounds to an engine. tpws is the path of the binary.
func Wrap(inner engine.Engine, tpws, home string, center *logs.Center) *Engine {
	return &Engine{Engine: inner, tpws: tpws, home: home, logs: center, procs: map[string]*proxy{}}
}

// Validate checks the plan the engine will run.
func (e *Engine) Validate(ctx context.Context, p *engine.Plan) error {
	return e.Engine.Validate(ctx, Rewrite(p, nil))
}

// Apply starts the tpws processes of the plan, stops the ones it no longer
// needs, and applies the rewritten plan to the engine.
func (e *Engine) Apply(ctx context.Context, p *engine.Plan) error {
	needed := map[string]engine.BypassStrategy{}
	for _, o := range p.Outbounds {
		if o.Protocol == engine.ProtocolBypass && o.Bypass != nil {
			needed[key(*o.Bypass)] = *o.Bypass
		}
	}
	e.mu.Lock()
	for k, px := range e.procs {
		if _, keep := needed[k]; !keep {
			px.stop()
			delete(e.procs, k)
		}
	}
	ports := map[string]int{}
	var err error
	for k, strategy := range needed {
		px, ok := e.procs[k]
		if !ok {
			if px, err = e.start(strategy); err != nil {
				break
			}
			e.procs[k] = px
		}
		ports[k] = px.port
	}
	e.mu.Unlock()
	if err != nil {
		return err
	}
	return e.Engine.Apply(ctx, Rewrite(p, ports))
}

// start supervises one tpws process, restarting it on the same port with
// increasing delays so engine outbounds remain valid.
func (e *Engine) start(strategy engine.BypassStrategy) (*proxy, error) {
	port, err := supervise.FreePort()
	if err != nil {
		return nil, err
	}
	ctx, cancel := context.WithCancel(context.Background())
	px := &proxy{port: port, cancel: cancel}
	spec := supervise.Spec{Name: "tpws", Path: e.tpws, Args: Args(strategy, port), Dir: e.home, Lines: e.logLine}
	if px.proc, err = supervise.Start(ctx, spec); err != nil {
		cancel()
		return nil, err
	}
	if err := waitListening(ctx, px.proc, port); err != nil {
		px.stop()
		return nil, err
	}
	go e.keep(ctx, px, spec)
	return px, nil
}

func (e *Engine) keep(ctx context.Context, px *proxy, spec supervise.Spec) {
	backoff := engine.DefaultBackoff()
	for attempt := 0; ; attempt++ {
		e.mu.Lock()
		proc := px.proc
		e.mu.Unlock()
		if err := proc.Wait(ctx); ctx.Err() != nil {
			return
		} else if e.logs != nil {
			e.logs.Write(time.Time{}, logs.LevelWarning, Source, fmt.Sprintf("tpws stopped (%v); starting it again", err))
		}
		if backoff.Wait(ctx, attempt) != nil {
			return
		}
		next, err := supervise.Start(ctx, spec)
		if err != nil {
			continue
		}
		e.mu.Lock()
		px.proc = next
		e.mu.Unlock()
	}
}

func (px *proxy) stop() {
	px.cancel()
	_ = px.proc.Stop(context.Background(), time.Second)
}

func (e *Engine) logLine(line string) {
	if e.logs != nil {
		e.logs.Write(time.Time{}, logs.LevelInfo, Source, line)
	}
}

// Stop stops the engine and every tpws.
func (e *Engine) Stop(ctx context.Context) error {
	err := e.Engine.Stop(ctx)
	e.stopAll()
	return err
}

// Close closes the engine and stops every tpws.
func (e *Engine) Close() error {
	err := e.Engine.Close()
	e.stopAll()
	return err
}

func (e *Engine) stopAll() {
	e.mu.Lock()
	defer e.mu.Unlock()
	for k, px := range e.procs {
		px.stop()
		delete(e.procs, k)
	}
}

var dialer net.Dialer

func waitListening(ctx context.Context, proc *supervise.Process, port int) error {
	ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
	defer cancel()
	addr := "127.0.0.1:" + strconv.Itoa(port)
	for {
		if conn, err := (&dialer).DialContext(ctx, "tcp", addr); err == nil {
			return conn.Close()
		}
		if err := proc.Err(); err != nil {
			return err
		}
		select {
		case <-ctx.Done():
			return errors.New("bypass: tpws did not start listening")
		case <-time.After(20 * time.Millisecond):
		}
	}
}
