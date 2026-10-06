package mihomo

import (
	"context"
	"regexp"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/clashapi"
	"github.com/levvs-one/sora-client/core/engine/supervise"
)

// Prober recognizes a mihomo build. "mihomo -v" prints, for example,
// "Mihomo Meta v1.19.32 linux amd64 with go1.26.8 Wed Sep 30 16:55:16 UTC 2026".
var Prober = supervise.Prober{
	Kind:    engine.KindMihomo,
	Name:    "mihomo",
	EnvVar:  "SORA_MIHOMO_BIN",
	Args:    []string{"-v"},
	Pattern: regexp.MustCompile(`(?i)^Mihomo(?:\s+Meta)?\s+v?(\d+\.\d+\.\d+[0-9A-Za-z.\-]*)\s+(\w+)\s+(\w+)`),
}

// New builds a mihomo engine driven over its external controller. Nothing is
// started: Apply does the work.
func New(cfg supervise.Config) (*clashapi.Engine, error) {
	sup, err := supervise.New(cfg, driver{})
	if err != nil {
		return nil, err
	}
	return clashapi.NewEngine(sup), nil
}

// driver is the mihomo grammar and command line. The configuration goes in on
// stdin: mihomo reads "-f -" as "read the configuration from standard input".
type driver struct{}

func (driver) Kind() engine.Kind { return engine.KindMihomo }

func (driver) Render(p *engine.Plan, rt supervise.Runtime) ([]byte, error) {
	text, err := Render(p, Runtime{
		HomeDir: rt.HomeDir, ControllerAddr: rt.ControlAddr, Secret: rt.Secret,
		MixedPort: rt.LocalPort, TestURL: rt.ProbeURL,
	})
	return []byte(text), err
}

func (driver) RunArgs(rt supervise.Runtime) []string {
	return []string{"-d", rt.HomeDir, "-f", "-", "-ext-ctl", rt.ControlAddr}
}

func (driver) CheckArgs(rt supervise.Runtime) []string {
	return []string{"-d", rt.HomeDir, "-f", "-", "-t"}
}

func (driver) Handshake(ctx context.Context, rt supervise.Runtime) (string, error) {
	info, err := clashapi.For(rt).Version(ctx)
	return info.Version, err
}

// Reload replaces the live configuration through the controller, so the tunnel
// and the listeners are not torn down.
func (driver) Reload(ctx context.Context, rt supervise.Runtime, cfg []byte) error {
	return clashapi.For(rt).ReloadPayload(ctx, string(cfg))
}
