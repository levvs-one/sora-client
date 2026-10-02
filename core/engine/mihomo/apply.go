package mihomo

import (
	"context"
	"errors"
	"fmt"
	"strconv"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
)

// Apply starts the engine with the plan or moves a running engine onto it.
//
// A running engine is reconfigured through the controller so that the tunnel
// and the listeners are not torn down: a user who adds a subscription must not
// lose the flows they already have.
func (e *Engine) Apply(ctx context.Context, p *engine.Plan) error {
	if p == nil {
		return errors.New("mihomo: nil plan")
	}
	if err := p.Validate(); err != nil {
		return e.redactor.Err(err)
	}
	if err := e.checkCapabilities(p); err != nil {
		return err
	}

	e.mu.Lock()
	e.redactor.Add(p.Secrets()...)
	e.plan = p
	proc, client, rt := e.proc, e.client, e.rt
	e.mu.Unlock()

	if proc != nil && !proc.Exited() {
		e.setState(engine.StateApplying)
		rendered, err := Render(p, rt)
		if err != nil {
			e.setState(engine.StateRunning)
			return e.redactor.Err(err)
		}
		if err := client.ReloadPayload(ctx, rendered); err != nil {
			e.setState(engine.StateRunning)
			return e.redactor.Err(fmt.Errorf("mihomo: hot apply failed: %w", err))
		}
		e.setState(engine.StateRunning)
		e.bus.Publish(engine.Event{Kind: engine.EventState, State: engine.StateRunning, Message: "plan applied"})
		return nil
	}

	if err := e.start(ctx, p); err != nil {
		e.setState(engine.StateFailed)
		e.bus.Publish(engine.Event{Kind: engine.EventFatal, State: engine.StateFailed, Err: e.redactor.Err(err)})
		return e.redactor.Err(err)
	}
	return nil
}

// start brings the engine up from nothing and begins supervision.
func (e *Engine) start(ctx context.Context, p *engine.Plan) error {
	// The core reserves the port the system proxy will point at and hands it over
	// here, because the guard is armed before the engine starts: a switch that is
	// pointed at a port the engine then chooses for itself is a switch pointing at
	// nothing. A port the core did not reserve is still chosen per start, which is
	// what a caller that never points a proxy at this engine wants.
	mixed := e.cfg.LocalPort
	if mixed == 0 {
		free, err := FreePort()
		if err != nil {
			return err
		}
		mixed = free
	}
	control, err := FreePort()
	if err != nil {
		return err
	}
	secret, err := RandomSecret()
	if err != nil {
		return err
	}
	rt := Runtime{
		HomeDir:        e.cfg.HomeDir,
		ControllerAddr: "127.0.0.1:" + strconv.Itoa(control),
		Secret:         secret,
		MixedPort:      mixed,
		WriteConfigTo:  e.cfg.DebugConfigPath,
		TestURL:        e.cfg.ProbeURL,
	}
	rendered, err := Render(p, rt)
	if err != nil {
		return e.redactor.Err(err)
	}
	if err := TestConfig(ctx, e.cfg.Binary, e.cfg.HomeDir, rendered); err != nil {
		return e.redactor.Err(err)
	}

	e.setState(engine.StateStarting)
	proc, err := Start(ctx, e.cfg.Binary, rt, rendered)
	if err != nil {
		return e.redactor.Err(err)
	}
	client := NewClient(rt.ControllerAddr, rt.Secret, 5*time.Second)
	info, err := WaitReady(ctx, client, proc, e.cfg.StartTimeout)
	if err != nil {
		_ = proc.Stop(context.Background(), e.cfg.StopGrace)
		return e.redactor.Err(err)
	}
	if version, verr := engine.ParseVersion(info.Version); verr == nil {
		e.mu.Lock()
		e.version = version
		e.mu.Unlock()
	}

	e.mu.Lock()
	e.proc, e.rt, e.client = proc, rt, client
	e.mu.Unlock()

	e.setState(engine.StateRunning)
	e.budget.Reset()
	e.bus.Publish(engine.Event{Kind: engine.EventState, State: engine.StateRunning,
		Message: "mihomo " + e.version.String() + " is running"})
	go e.watch(proc)
	return nil
}

// checkCapabilities refuses a plan this engine cannot carry, before the user
// sees a connected state that silently drops traffic.
func (e *Engine) checkCapabilities(p *engine.Plan) error {
	caps := engine.Catalog[engine.KindMihomo]
	var missing []string
	for _, o := range p.Outbounds {
		if !caps.SupportsProtocol(o.Protocol) {
			missing = append(missing, string(o.Protocol))
		}
	}
	for feature := range p.RequiredFeatures() {
		if !caps.Supports(feature) {
			missing = append(missing, string(feature))
		}
	}
	if len(missing) > 0 {
		return fmt.Errorf("mihomo: this build cannot carry %v", missing)
	}
	return nil
}

// watch keeps one process supervised: when it dies unexpectedly, the plan is
// applied again inside the restart budget.
func (e *Engine) watch(proc *Process) {
	err := proc.Wait(e.ctx)
	e.mu.Lock()
	current, stopping, plan := e.proc == proc, e.stopping, e.plan
	e.mu.Unlock()
	if !current || stopping {
		return
	}
	if err == nil || errors.Is(err, context.Canceled) {
		e.setState(engine.StateStopped)
		return
	}

	masked := e.redactor.Err(err)
	e.bus.Publish(engine.Event{Kind: engine.EventEngineDown, State: engine.StateRecovering,
		Err: masked, Message: tailOf(proc.Stderr().String(), 5)})
	if plan == nil {
		e.setState(engine.StateStopped)
		return
	}
	if !e.budget.Allow() {
		e.setState(engine.StateFailed)
		e.bus.Publish(engine.Event{Kind: engine.EventFatal, State: engine.StateFailed, Err: masked,
			Message: fmt.Sprintf("more than %d restarts within %s", e.cfg.RestartBudget, e.cfg.RestartWindow)})
		return
	}

	e.setState(engine.StateRecovering)
	delay := e.backoff.Delay(e.budget.Used() - 1)
	e.bus.Publish(engine.Event{Kind: engine.EventRestart, State: engine.StateRecovering,
		Message: "restarting in " + delay.String()})
	timer := time.NewTimer(delay)
	defer timer.Stop()
	select {
	case <-e.ctx.Done():
		return
	case <-timer.C:
	}
	if restartErr := e.start(e.ctx, plan); restartErr != nil {
		e.setState(engine.StateFailed)
		e.bus.Publish(engine.Event{Kind: engine.EventFatal, State: engine.StateFailed, Err: e.redactor.Err(restartErr)})
	}
}
