// Package singbox drives SagerNet/sing-box as an engine of Sora.
//
// sing-box is a separate GPL binary started as a child process. The rendered
// JSON goes in on stdin ("run -c stdin"), and the engine is controlled over its
// Clash compatible API (experimental.clash_api) bound to the loopback
// interface with a per-start secret. sing-box cannot reload a configuration
// through that API, so a new plan restarts the engine.
package singbox

import (
	"context"
	"regexp"
	"strings"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/clashapi"
	"github.com/levvs-one/sora-client/core/engine/supervise"
)

// Prober recognizes a sing-box build. "sing-box version" prints, for example,
// "sing-box version 1.14.2" followed by the environment line.
var Prober = supervise.Prober{
	Kind:    engine.KindSingBox,
	Name:    "sing-box",
	EnvVar:  "SORA_SINGBOX_BIN",
	Args:    []string{"version"},
	Pattern: regexp.MustCompile(`^sing-box version v?(\d+\.\d+\.\d+[0-9A-Za-z.\-]*)`),
}

// New builds a sing-box engine. Nothing is started: Apply does the work.
func New(cfg supervise.Config) (*clashapi.Engine, error) {
	sup, err := supervise.New(cfg, driver{})
	if err != nil {
		return nil, err
	}
	return clashapi.NewEngine(sup), nil
}

type driver struct{}

func (driver) Kind() engine.Kind { return engine.KindSingBox }

func (driver) Render(p *engine.Plan, rt supervise.Runtime) ([]byte, error) { return Render(p, rt) }

func (driver) RunArgs(rt supervise.Runtime) []string {
	return []string{"run", "-c", "stdin", "-D", rt.HomeDir, "--disable-color"}
}

func (driver) CheckArgs(rt supervise.Runtime) []string {
	return []string{"check", "-c", "stdin", "-D", rt.HomeDir, "--disable-color"}
}

// Handshake reads GET /version, which answers "sing-box 1.14.2".
func (driver) Handshake(ctx context.Context, rt supervise.Runtime) (string, error) {
	info, err := clashapi.For(rt).Version(ctx)
	return strings.TrimPrefix(info.Version, "sing-box "), err
}

func (driver) Reload(context.Context, supervise.Runtime, []byte) error {
	return supervise.ErrReloadUnsupported
}
