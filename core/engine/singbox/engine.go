// Package singbox runs sing-box as a separate GPL child with JSON on stdin
// ("run -c stdin"). Its loopback Clash API uses a per-start secret.
// Configuration changes require a restart because the API cannot reload.
package singbox

import (
	"context"
	"os"
	"regexp"
	"runtime"
	"strings"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/clashapi"
	"github.com/levvs-one/sora-client/core/engine/supervise"
	"github.com/levvs-one/sora-client/core/engine/tunroute"
)

// Prober recognizes "sing-box version" output such as "sing-box version 1.14.2"
// followed by environment details.
var Prober = supervise.Prober{
	Kind:    engine.KindSingBox,
	Name:    "sing-box",
	EnvVar:  "SORA_SINGBOX_BIN",
	Args:    []string{"version"},
	Pattern: regexp.MustCompile(`^sing-box version v?(\d+\.\d+\.\d+[0-9A-Za-z.\-]*)`),
}

// New creates a sing-box engine without starting it. Apply starts it.
func New(cfg supervise.Config) (*clashapi.Engine, error) {
	sup, err := supervise.New(cfg, driver{})
	if err != nil {
		return nil, err
	}
	return clashapi.NewEngine(sup), nil
}

type driver struct{}

func (driver) Kind() engine.Kind { return engine.KindSingBox }

// PlanNames inverts the tags the renderer assigns.
func (driver) PlanNames(p *engine.Plan) map[string]string {
	r := renderer{plan: p, tags: map[string]string{}, used: map[string]bool{"direct": true}}
	if r.assignTags() != nil {
		return nil
	}
	out := make(map[string]string, len(r.tags))
	for id, tag := range r.tags {
		out[tag] = id
	}
	return out
}

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

// Route owns Linux policy routing so every engine shares the same exclusions.
func (driver) Route(ctx context.Context, p *engine.Plan) error {
	if runtime.GOOS != "linux" {
		return nil
	}
	return tunroute.Route(ctx, p.Tun, os.Getuid())
}

func (driver) Unroute(ctx context.Context) error { return tunroute.Unroute(ctx) }
