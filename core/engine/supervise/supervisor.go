package supervise

import (
	"context"
	"errors"
	"fmt"
	"os"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/logs"
)

// ErrReloadUnsupported makes the supervisor restart the engine to apply a plan.
// Existing flows are lost during restart.
var ErrReloadUnsupported = errors.New("supervise: engine cannot reload a running configuration")

// ErrNotRunning is returned by controller calls while no engine is running.
var ErrNotRunning = errors.New("supervise: engine is not running")

// Runtime holds supervisor-selected values for one start, separate from the
// reusable plan.
type Runtime struct {
	HomeDir string
	// LocalPort is the loopback mixed (HTTP and SOCKS5) listener of the
	// tunnel.
	LocalPort int
	// LocalProxy indicates whether LocalPort is open, allowing
	// controller-free drivers to check readiness through the listener.
	LocalProxy bool
	// ControlAddr is host:port of the loopback controller or metrics
	// endpoint.
	ControlAddr string
	// Secret authenticates controller requests because every local user can
	// reach loopback.
	Secret string
	// ProbeURL is the default latency endpoint for groups without one.
	ProbeURL string
}

// Driver supplies engine-specific configuration, arguments, and the readiness
// handshake.
type Driver interface {
	Kind() engine.Kind
	// Render turns the plan into the configuration the engine reads on
	// stdin.
	Render(p *engine.Plan, rt Runtime) ([]byte, error)
	// RunArgs and CheckArgs are the command lines that run and validate a
	// configuration read from stdin.
	RunArgs(rt Runtime) []string
	CheckArgs(rt Runtime) []string
	// Handshake is polled until it succeeds and returns the version the
	// running engine reports about itself.
	Handshake(ctx context.Context, rt Runtime) (string, error)
	// Reload moves a running engine onto cfg without a restart, or returns
	// ErrReloadUnsupported.
	Reload(ctx context.Context, rt Runtime, cfg []byte) error
}

// PrivateController supplies a Unix socket or named pipe instead of a loopback
// controller.
type PrivateController interface {
	// ControlAddress returns the address for one start. private forbids
	// discoverable controllers; empty disables the controller.
	ControlAddress(rt Runtime, private bool) (string, error)
}

// Router installs routes for engines that create only a TUN adapter. Route runs
// after every start because restarts recreate adapters; Unroute runs after
// final shutdown.
type Router interface {
	Route(ctx context.Context, p *engine.Plan) error
	Unroute(ctx context.Context) error
}

// Namer maps renderer-assigned engine names to plan outbound IDs and group
// names through PlanNames.
type Namer interface {
	PlanNames(p *engine.Plan) map[string]string
}

// LogParser parses engine output. Unrecognized lines are recorded unchanged at
// info level.
type LogParser interface {
	ParseLog(line string) (at time.Time, level logs.Level, message string)
}

// Preparer installs engine-home files before configuration, including databases
// that would otherwise be downloaded.
type Preparer interface {
	Prepare(rt Runtime, b Binary) error
}

// Config configures one supervised engine instance.
type Config struct {
	Binary  Binary
	HomeDir string
	// LocalPort is reserved before system proxy configuration. Zero selects
	// a port per start and is suitable only when no proxy points to a fixed
	// port.
	LocalPort     int
	ProbeURL      string
	StartTimeout  time.Duration
	StopGrace     time.Duration
	Redactor      *engine.Redactor
	RestartBudget int
	RestartWindow time.Duration
	// Logs receives the engine output, masked, when set.
	Logs *logs.Center
}

// Supervisor implements engine lifecycle through a Driver. Engines add groups,
// selection, latency, and counters using Runtime.
type Supervisor struct {
	cfg      Config
	driver   Driver
	bus      *engine.EventBus
	redactor *engine.Redactor
	backoff  engine.Backoff
	budget   *engine.RestartBudget

	mu       sync.Mutex
	state    engine.State
	version  engine.Version
	rt       Runtime
	plan     *engine.Plan
	proc     *Process
	stopping bool

	ctx    context.Context
	cancel context.CancelFunc
}

// New creates a supervisor without starting it. Apply starts the engine.
func New(cfg Config, driver Driver) (*Supervisor, error) {
	kind := driver.Kind()
	if cfg.Binary.Path == "" {
		return nil, fmt.Errorf("%s: engine binary is required", kind)
	}
	if cfg.HomeDir == "" {
		return nil, fmt.Errorf("%s: engine home directory is required", kind)
	}
	if cfg.StartTimeout <= 0 {
		cfg.StartTimeout = 15 * time.Second
	}
	if cfg.StopGrace <= 0 {
		cfg.StopGrace = 3 * time.Second
	}
	if cfg.ProbeURL == "" {
		cfg.ProbeURL = engine.TestURLProduction
	}
	if cfg.Redactor == nil {
		cfg.Redactor = engine.NewRedactor()
	}
	if cfg.RestartBudget <= 0 {
		cfg.RestartBudget = 5
	}
	if cfg.RestartWindow <= 0 {
		cfg.RestartWindow = 10 * time.Minute
	}
	ctx, cancel := context.WithCancel(context.Background())
	return &Supervisor{
		cfg:      cfg,
		driver:   driver,
		bus:      engine.NewEventBus(128),
		redactor: cfg.Redactor,
		backoff:  engine.DefaultBackoff(),
		budget:   engine.NewRestartBudget(cfg.RestartBudget, cfg.RestartWindow, nil),
		state:    engine.StateIdle,
		version:  cfg.Binary.Version,
		ctx:      ctx,
		cancel:   cancel,
	}, nil
}

// Kind reports which engine this supervisor drives.
func (s *Supervisor) Kind() engine.Kind { return s.driver.Kind() }

// Capabilities returns the capability matrix of the engine.
func (s *Supervisor) Capabilities() engine.Capabilities {
	caps := engine.Catalog[s.driver.Kind()]
	caps.MinVersion = s.Version().String()
	return caps
}

// State returns the current lifecycle state.
func (s *Supervisor) State() engine.State {
	s.mu.Lock()
	defer s.mu.Unlock()
	return s.state
}

// Version returns the handshake version, or the probed version before a
// successful handshake.
func (s *Supervisor) Version() engine.Version {
	s.mu.Lock()
	defer s.mu.Unlock()
	return s.version
}

// Events returns the bus this engine publishes on.
func (s *Supervisor) Events() *engine.EventBus { return s.bus }

// Redactor masks the secrets of the applied plans.
func (s *Supervisor) Redactor() *engine.Redactor { return s.redactor }

// ProbeURL is the default latency endpoint.
func (s *Supervisor) ProbeURL() string { return s.cfg.ProbeURL }

// Running returns the runtime of the live engine, or ErrNotRunning.
func (s *Supervisor) Running() (Runtime, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.proc == nil || s.proc.Exited() {
		return Runtime{}, fmt.Errorf("%s: %w", s.driver.Kind(), ErrNotRunning)
	}
	return s.rt, nil
}

// Plan returns the plan the engine runs, or nil.
func (s *Supervisor) Plan() *engine.Plan {
	s.mu.Lock()
	defer s.mu.Unlock()
	return s.plan
}

// PlanNames maps live engine names to plan IDs and groups. Nil means no engine
// is running or names already match plan IDs.
func (s *Supervisor) PlanNames() map[string]string {
	n, ok := s.driver.(Namer)
	p := s.Plan()
	if !ok || p == nil {
		return nil
	}
	return n.PlanNames(p)
}

// Validate renders the plan and checks it with the engine binary.
func (s *Supervisor) Validate(ctx context.Context, p *engine.Plan) error {
	if err := s.admit(p); err != nil {
		return err
	}
	rt := Runtime{HomeDir: s.cfg.HomeDir, LocalPort: 1, ControlAddr: "127.0.0.1:1", Secret: "validation-only", ProbeURL: s.cfg.ProbeURL}
	cfg, err := s.driver.Render(p, rt)
	if err != nil {
		return s.redactor.Err(err)
	}
	return s.redactor.Err(s.check(ctx, rt, cfg))
}

// admit rejects malformed or unsupported plans before startup to avoid
// reporting connected while dropping traffic.
func (s *Supervisor) admit(p *engine.Plan) error {
	if p == nil {
		return fmt.Errorf("%s: nil plan", s.driver.Kind())
	}
	if err := p.Validate(); err != nil {
		return s.redactor.Err(err)
	}
	if missing := engine.Catalog[s.driver.Kind()].Missing(p); len(missing) > 0 {
		return fmt.Errorf("%s: this engine cannot carry %s", s.driver.Kind(), strings.Join(missing, ", "))
	}
	return nil
}

func (s *Supervisor) check(ctx context.Context, rt Runtime, cfg []byte) error {
	if p, ok := s.driver.(Preparer); ok {
		if err := os.MkdirAll(rt.HomeDir, 0o700); err != nil {
			return err
		}
		if err := p.Prepare(rt, s.cfg.Binary); err != nil {
			return fmt.Errorf("%s: prepare engine home: %w", s.driver.Kind(), err)
		}
	}
	return Check(ctx, Spec{Name: string(s.driver.Kind()), Path: s.cfg.Binary.Path,
		Args: s.driver.CheckArgs(rt), Dir: s.cfg.HomeDir, Config: cfg})
}

// Apply starts or reconfigures the engine. Supported live reloads preserve
// existing flows.
func (s *Supervisor) Apply(ctx context.Context, p *engine.Plan) error {
	if err := s.admit(p); err != nil {
		return err
	}
	s.mu.Lock()
	s.redactor.Add(p.Secrets()...)
	s.plan = p
	s.stopping = false
	proc, rt := s.proc, s.rt
	s.mu.Unlock()

	if proc != nil && !proc.Exited() {
		err := s.reload(ctx, rt, p)
		if !errors.Is(err, ErrReloadUnsupported) {
			return err
		}
		s.mu.Lock()
		s.proc = nil
		s.mu.Unlock()
		if err := proc.Stop(ctx, s.cfg.StopGrace); err != nil {
			return s.redactor.Err(err)
		}
	}
	if err := s.start(ctx, p); err != nil {
		masked := s.redactor.Err(err)
		s.setState(engine.StateFailed)
		if s.cfg.Logs != nil {
			s.cfg.Logs.Write(time.Time{}, logs.LevelError, string(s.driver.Kind()), masked.Error())
		}
		s.bus.Publish(engine.Event{Kind: engine.EventFatal, State: engine.StateFailed, Err: masked})
		return masked
	}
	return nil
}

func (s *Supervisor) reload(ctx context.Context, rt Runtime, p *engine.Plan) error {
	s.setState(engine.StateApplying)
	defer s.setState(engine.StateRunning)
	cfg, err := s.driver.Render(p, rt)
	if err != nil {
		return s.redactor.Err(err)
	}
	if err := s.driver.Reload(ctx, rt, cfg); err != nil {
		if errors.Is(err, ErrReloadUnsupported) {
			return err
		}
		return s.redactor.Err(fmt.Errorf("%s: hot apply failed: %w", s.driver.Kind(), err))
	}
	s.bus.Publish(engine.Event{Kind: engine.EventState, State: engine.StateRunning, Message: "plan applied"})
	return nil
}

// start brings the engine up from nothing and begins supervision.
func (s *Supervisor) start(ctx context.Context, p *engine.Plan) error {
	rt, err := s.reserve(p.PrivateControl)
	rt.LocalProxy = p.LocalProxy.Enabled
	if err != nil {
		return err
	}
	cfg, err := s.driver.Render(p, rt)
	if err != nil {
		return err
	}
	if err := s.check(ctx, rt, cfg); err != nil {
		return err
	}

	s.setState(engine.StateStarting)
	kind := s.driver.Kind()
	proc, err := Start(s.ctx, Spec{Name: string(kind), Path: s.cfg.Binary.Path,
		Args: s.driver.RunArgs(rt), Dir: s.cfg.HomeDir, Config: cfg, Lines: s.logLine})
	if err != nil {
		return err
	}
	reported, err := s.waitReady(ctx, rt, proc)
	if err == nil && p.Tun.Enabled {
		if r, ok := s.driver.(Router); ok {
			err = r.Route(ctx, p)
		}
	}
	if err != nil {
		_ = proc.Stop(context.WithoutCancel(ctx), s.cfg.StopGrace)
		s.unroute(context.WithoutCancel(ctx))
		return err
	}

	s.mu.Lock()
	if v, verr := engine.ParseVersion(reported); verr == nil {
		s.version = v
	}
	s.proc, s.rt = proc, rt
	version := s.version
	s.mu.Unlock()

	s.setState(engine.StateRunning)
	s.bus.Publish(engine.Event{Kind: engine.EventState, State: engine.StateRunning,
		Message: string(kind) + " " + version.String() + " is running"})
	go s.watch(proc)
	return nil
}

// logLine records engine output after masking secrets from applied plans.
func (s *Supervisor) logLine(line string) {
	if s.cfg.Logs == nil {
		return
	}
	at, level, message := time.Time{}, logs.LevelInfo, line
	if p, ok := s.driver.(LogParser); ok {
		at, level, message = p.ParseLog(line)
	}
	s.cfg.Logs.Write(at, level, string(s.driver.Kind()), s.redactor.String(message))
}

// reserve picks the ports and the secret of one start.
func (s *Supervisor) reserve(privateControl bool) (Runtime, error) {
	local := s.cfg.LocalPort
	if local == 0 {
		free, err := FreePort()
		if err != nil {
			return Runtime{}, err
		}
		local = free
	}
	control, err := FreePort()
	if err != nil {
		return Runtime{}, err
	}
	secret, err := RandomSecret()
	if err != nil {
		return Runtime{}, err
	}
	rt := Runtime{
		HomeDir: s.cfg.HomeDir, LocalPort: local, ControlAddr: "127.0.0.1:" + strconv.Itoa(control),
		Secret: secret, ProbeURL: s.cfg.ProbeURL,
	}
	if private, ok := s.driver.(PrivateController); ok {
		if err := os.MkdirAll(rt.HomeDir, 0o700); err != nil {
			return Runtime{}, err
		}
		addr, err := private.ControlAddress(rt, privateControl)
		if err != nil {
			return Runtime{}, err
		}
		rt.ControlAddr = addr
	}
	return rt, nil
}

// waitReady polls until handshake success, timeout, or process exit. Dead-child
// errors include engine output instead of a generic readiness failure.
func (s *Supervisor) waitReady(ctx context.Context, rt Runtime, proc *Process) (string, error) {
	ctx, cancel := context.WithTimeout(ctx, s.cfg.StartTimeout)
	defer cancel()
	ticker := time.NewTicker(100 * time.Millisecond)
	defer ticker.Stop()
	var lastErr error
	for {
		version, err := s.driver.Handshake(ctx, rt)
		if err == nil {
			return version, nil
		}
		lastErr = err
		if proc.Exited() {
			reason := proc.Err()
			if reason == nil {
				reason = fmt.Errorf("%s: engine exited with status 0 before readiness: %s", s.driver.Kind(), proc.Output().Last(8))
			}
			return "", reason
		}
		select {
		case <-ctx.Done():
			return "", fmt.Errorf("%s: engine API did not come up: %w: %s", s.driver.Kind(), lastErr, proc.Output().Last(5))
		case <-ticker.C:
		}
	}
}

// watch restarts unexpected exits with backoff within the restart budget.
// Exhaustion sets the failed state.
func (s *Supervisor) watch(proc *Process) {
	err := proc.Wait(s.ctx)
	s.mu.Lock()
	current, stopping, plan := s.proc == proc, s.stopping, s.plan
	s.mu.Unlock()
	if !current || stopping {
		return
	}
	if errors.Is(err, context.Canceled) {
		s.setState(engine.StateStopped)
		return
	}

	if err == nil {
		err = fmt.Errorf("%s: engine exited unexpectedly with status 0", s.driver.Kind())
	}
	masked := s.redactor.Err(err)
	if s.cfg.Logs != nil {
		s.cfg.Logs.Write(time.Time{}, logs.LevelError, string(s.driver.Kind()),
			fmt.Sprintf("engine exited unexpectedly: %s", proc.cmd.ProcessState.String()))
		for _, line := range strings.Split(proc.Output().Last(8), "\n") {
			s.cfg.Logs.Write(time.Time{}, logs.LevelError, string(s.driver.Kind()), s.redactor.String(line))
		}
	}
	s.bus.Publish(engine.Event{Kind: engine.EventEngineDown, State: engine.StateRecovering,
		Err: masked, Message: s.redactor.String(proc.Output().Last(5))})
	if plan == nil {
		s.setState(engine.StateStopped)
		return
	}
	if !s.budget.Allow() {
		s.unroute(context.WithoutCancel(s.ctx))
		s.setState(engine.StateFailed)
		s.bus.Publish(engine.Event{Kind: engine.EventFatal, State: engine.StateFailed, Err: masked,
			Message: fmt.Sprintf("more than %d restarts within %s", s.cfg.RestartBudget, s.cfg.RestartWindow)})
		return
	}

	s.setState(engine.StateRecovering)
	delay := s.backoff.Delay(s.budget.Used() - 1)
	s.bus.Publish(engine.Event{Kind: engine.EventRestart, State: engine.StateRecovering,
		Message: "restarting in " + delay.String()})
	timer := time.NewTimer(delay)
	defer timer.Stop()
	select {
	case <-s.ctx.Done():
		return
	case <-timer.C:
	}
	if restartErr := s.start(s.ctx, plan); restartErr != nil {
		if s.cfg.Logs != nil {
			s.cfg.Logs.Write(time.Time{}, logs.LevelError, string(s.driver.Kind()), s.redactor.String(restartErr.Error()))
		}
		s.setState(engine.StateFailed)
		s.bus.Publish(engine.Event{Kind: engine.EventFatal, State: engine.StateFailed, Err: s.redactor.Err(restartErr)})
	}
}

// Stop shuts the engine down and forgets the plan.
func (s *Supervisor) Stop(ctx context.Context) error {
	s.mu.Lock()
	s.stopping = true
	proc := s.proc
	s.proc, s.plan = nil, nil
	s.mu.Unlock()

	var err error
	if proc != nil {
		err = proc.Stop(ctx, s.cfg.StopGrace)
	}
	s.unroute(ctx)
	s.setState(engine.StateStopped)
	return s.redactor.Err(err)
}

// unroute removes installed routes and logs errors without preventing shutdown.
func (s *Supervisor) unroute(ctx context.Context) {
	r, ok := s.driver.(Router)
	if !ok {
		return
	}
	if err := r.Unroute(ctx); err != nil && s.cfg.Logs != nil {
		s.cfg.Logs.Write(time.Time{}, logs.LevelWarning, string(s.driver.Kind()), s.redactor.String(err.Error()))
	}
}

// Close stops the engine and releases the supervision context.
func (s *Supervisor) Close() error {
	err := s.Stop(context.Background())
	s.cancel()
	return err
}

// setState records and announces a lifecycle change.
func (s *Supervisor) setState(state engine.State) {
	s.mu.Lock()
	changed := s.state != state
	s.state = state
	s.mu.Unlock()
	if changed {
		s.bus.Publish(engine.Event{Kind: engine.EventState, State: state})
	}
}
