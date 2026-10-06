package mihomo

import (
	"context"
	"io"
	"os"
	"path/filepath"
	"regexp"
	"strings"

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
	args := []string{"-d", rt.HomeDir, "-f", "-"}
	addr := rt.ControlAddr
	switch {
	case strings.HasPrefix(addr, "unix:"):
		return append(args, "-ext-ctl-unix", strings.TrimPrefix(addr, "unix:"))
	case strings.HasPrefix(addr, "pipe:"):
		return append(args, "-ext-ctl-pipe", strings.TrimPrefix(addr, "pipe:"))
	}
	return append(args, "-ext-ctl", addr)
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

// geodataFiles maps the database names Sora ships next to the engines onto
// the names mihomo looks for in its home directory.
var geodataFiles = map[string]string{"geoip.dat": "GeoIP.dat", "geosite.dat": "GeoSite.dat"}

// Prepare copies the shipped databases into the engine home when they are
// newer than the copy there. A missing database is not an error: the plan may
// have no geo rules, and a plan that has them fails the validator with a clear
// message instead of a download.
func (driver) Prepare(rt supervise.Runtime, b supervise.Binary) error {
	dir := filepath.Dir(b.Path)
	for shipped, local := range geodataFiles {
		src := filepath.Join(dir, shipped)
		info, err := os.Stat(src)
		if err != nil {
			continue
		}
		dst := filepath.Join(rt.HomeDir, local)
		if have, err := os.Stat(dst); err == nil && have.Size() == info.Size() && !have.ModTime().Before(info.ModTime()) {
			continue
		}
		if err := copyFile(src, dst); err != nil {
			return err
		}
	}
	return nil
}

// copyFile writes src to dst through a temporary file, so an engine never
// reads a half-written database.
func copyFile(src, dst string) error {
	in, err := os.Open(src) //nolint:gosec // src is a database next to the probed engine binary
	if err != nil {
		return err
	}
	defer func() { _ = in.Close() }()
	tmp, err := os.CreateTemp(filepath.Dir(dst), ".geodata-*")
	if err != nil {
		return err
	}
	defer func() { _ = os.Remove(tmp.Name()) }()
	if _, err := io.Copy(tmp, in); err != nil {
		_ = tmp.Close()
		return err
	}
	if err := tmp.Close(); err != nil {
		return err
	}
	return os.Rename(tmp.Name(), dst)
}
