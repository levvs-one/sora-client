// Package singbox runs sing-box as a supervised child process and implements
// engine.Engine on top of its HTTP REST API (compatible with Clash API).
package singbox

import (
	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/errs"
)

// Runtime holds the per-start parameters that the core reserves.
type Runtime struct {
	HomeDir        string
	ControllerAddr string
	Secret         string
	MixedPort      int
	ProbeURL       string
	Secrets        map[string][]byte // reference -> credential material
}

// Engine runs sing-box as a supervised child process.
type Engine struct {
	cfg      Config
	bus      *engine.EventBus
	redactor *engine.Redactor
	proc     *process
	client   *Client
}

type Config struct {
	Binary    Binary
	HomeDir   string
	MixedPort int
	ProbeURL  string
	Redactor  *engine.Redactor
}

// New creates a sing-box engine.
func New(cfg Config) (*Engine, error) {
	if cfg.Binary.Path == "" {
		return nil, errs.Newf(errs.CodeFailedPrecondition, errs.KeyEngineBinaryMissing,
			"singbox: no binary configured")
	}
	if cfg.HomeDir == "" {
		return nil, errs.Newf(errs.CodeFailedPrecondition, errs.KeyEngineStartFailed,
			"singbox: no home directory")
	}
	if cfg.MixedPort <= 0 {
		return nil, errs.Newf(errs.CodeInvalidArgument, errs.KeyEngineStartFailed,
			"singbox: mixed port not reserved")
	}
	if cfg.Redactor == nil {
		cfg.Redactor = engine.NewRedactor()
	}
	return &Engine{
		cfg:      cfg,
		bus:      engine.NewEventBus(8),
		redactor: cfg.Redactor,
	}, nil
}
