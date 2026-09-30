package mihomo

import (
	"context"
	"errors"
	"sync"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
)

// Config is what one engine instance needs from the core service.
type Config struct {
	// Binary is a probed engine build.
	Binary Binary
	// HomeDir is the private working directory of the engine, mode 0700.
	HomeDir string
	// DebugConfigPath writes the rendered config to a file for debugging.
	// Empty keeps the config off the disk, which is the normal case.
	DebugConfigPath string
	// ProbeURL is the default latency endpoint for the plan.
	ProbeURL string
	// StartTimeout bounds the wait for the controller to answer.
	StartTimeout time.Duration
	// StopGrace bounds the wait before the process is killed.
	StopGrace time.Duration
	// Redactor masks secrets in everything the engine reports.
	Redactor *engine.Redactor
	// RestartBudget is how many restarts are allowed inside RestartWindow.
	RestartBudget int
	RestartWindow time.Duration
}

// Engine runs mihomo as a supervised child process and implements
// engine.Engine on top of its controller API.
type Engine struct {
	cfg      Config
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
	client   *Client
	stopping bool
	counters engine.Counters

	ctx    context.Context
	cancel context.CancelFunc
}

// New builds an engine instance. Nothing is started: Apply does the work.
func New(cfg Config) (*Engine, error) {
	if cfg.Binary.Path == "" {
		return nil, errors.New("mihomo: engine binary is required")
	}
	if cfg.HomeDir == "" {
		return nil, errors.New("mihomo: engine home directory is required")
	}
	if cfg.StartTimeout <= 0 {
		cfg.StartTimeout = 15 * time.Second
	}
	if cfg.StopGrace <= 0 {
		cfg.StopGrace = 3 * time.Second
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
	version, err := engine.ParseVersion(cfg.Binary.Version.String())
	if err != nil {
		return nil, err
	}
	ctx, cancel := context.WithCancel(context.Background())
	return &Engine{
		cfg:      cfg,
		bus:      engine.NewEventBus(128),
		redactor: cfg.Redactor,
		backoff:  engine.DefaultBackoff(),
		budget:   engine.NewRestartBudget(cfg.RestartBudget, cfg.RestartWindow, nil),
		state:    engine.StateIdle,
		version:  version,
		ctx:      ctx,
		cancel:   cancel,
	}, nil
}

// Kind reports which engine this instance drives.
func (e *Engine) Kind() engine.Kind { return engine.KindMihomo }

// Capabilities returns the mihomo capability matrix.
func (e *Engine) Capabilities() engine.Capabilities {
	caps := engine.Catalog[engine.KindMihomo]
	caps.MinVersion = e.version.String()
	return caps
}

// State is the current lifecycle state.
func (e *Engine) State() engine.State {
	e.mu.Lock()
	defer e.mu.Unlock()
	return e.state
}

// Version is the probed engine version.
func (e *Engine) Version() engine.Version { return e.version }

// Events returns the bus this engine publishes on.
func (e *Engine) Events() *engine.EventBus { return e.bus }

// Validate renders the plan and lets the engine binary judge it with -t. This
// is the check that catches a key Sora got wrong, because the engine is the
// only party that knows its own grammar.
func (e *Engine) Validate(ctx context.Context, p *engine.Plan) error {
	rendered, err := Render(p, e.probeRuntime())
	if err != nil {
		return e.redactor.Err(err)
	}
	if err := TestConfig(ctx, e.cfg.Binary, e.cfg.HomeDir, rendered); err != nil {
		return e.redactor.Err(err)
	}
	return nil
}

// probeRuntime is a runtime used only for offline validation: no port has to
// be free and no secret is ever used.
func (e *Engine) probeRuntime() Runtime {
	return Runtime{
		HomeDir:        e.cfg.HomeDir,
		ControllerAddr: "127.0.0.1:1",
		Secret:         "validation-only",
		MixedPort:      1,
		TestURL:        e.cfg.ProbeURL,
	}
}
