package mihomo

import (
	"context"
	"errors"
	"io"
	"net/netip"
	"os"
	"path/filepath"
	"regexp"
	"runtime"
	"strings"

	"gopkg.in/yaml.v3"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/clashapi"
	"github.com/levvs-one/sora-client/core/engine/supervise"
	"github.com/levvs-one/sora-client/core/engine/tunroute"
)

// Prober recognizes "mihomo -v" output such as "Mihomo Meta v1.19.32 linux
// amd64 with go1.26.8".
var Prober = supervise.Prober{
	Kind:    engine.KindMihomo,
	Name:    "mihomo",
	EnvVar:  "SORA_MIHOMO_BIN",
	Args:    []string{"-v"},
	Pattern: regexp.MustCompile(`(?i)^Mihomo(?:\s+Meta)?\s+v?(\d+\.\d+\.\d+[0-9A-Za-z.\-]*)\s+(\w+)\s+(\w+)`),
}

// New creates a mihomo engine without starting it. Apply starts the process.
func New(cfg supervise.Config) (*clashapi.Engine, error) {
	sup, err := supervise.New(cfg, driver{})
	if err != nil {
		return nil, err
	}
	return clashapi.NewEngine(sup), nil
}

// driver defines mihomo configuration and arguments. "-f -" loads configuration
// from stdin, keeping credentials off disk.
type driver struct{}

func (driver) Kind() engine.Kind { return engine.KindMihomo }

// PlanNames inverts the names buildProxies and the groups were given.
func (driver) PlanNames(p *engine.Plan) map[string]string {
	byID, _, err := buildProxies(p)
	if err != nil {
		return nil
	}
	out := make(map[string]string, len(byID)+len(p.Groups))
	for id, name := range byID {
		out[name] = id
	}
	for _, g := range p.Groups {
		out[sanitizeName(g.Name, "")] = g.Name
	}
	return out
}

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

// Reload replaces live configuration without restarting the tunnel or
// listeners.
func (driver) Reload(ctx context.Context, rt supervise.Runtime, cfg []byte) error {
	var rendered config
	if err := yaml.Unmarshal(cfg, &rendered); err != nil {
		return err
	}
	if rendered.DNS != nil && rendered.DNS.EnhancedMode == "fake-ip" {
		pool, err := netip.ParsePrefix(rendered.DNS.FakeIPRange)
		if err != nil {
			return err
		}
		previous, err := os.ReadFile(filepath.Join(rt.HomeDir, "fakeip-pool"))
		if err != nil || string(previous) != pool.Masked().String() {
			// Reload can clone the old in-memory pool. Restart so reset happens
			// while no process holds cache.db open.
			return supervise.ErrReloadUnsupported
		}
	}
	return clashapi.For(rt).ReloadPayload(ctx, string(cfg))
}

// geodataFiles maps shipped database names to mihomo's engine-home filenames.
var geodataFiles = map[string]string{"geoip.dat": "GeoIP.dat", "geosite.dat": "GeoSite.dat"}

// Prepare copies newer shipped databases into the engine home. Missing files
// are allowed for plans without geo rules; geo plans fail validation without
// downloading.
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

// PrepareStart invalidates unversioned caches and caches from a different pool.
// Remove the database before recording the pool so an interrupted reset retries.
// This also resets stored group selections once when upgrading a legacy cache.
func (driver) PrepareStart(p *engine.Plan, rt supervise.Runtime) error {
	if !p.DNS.Enabled || p.DNS.Mode != string(engine.DNSFakeIP) {
		return nil
	}
	pool, err := netip.ParsePrefix(orDefault(p.DNS.FakeIPRange, "198.18.0.1/16"))
	if err != nil {
		return err
	}
	marker := filepath.Join(rt.HomeDir, "fakeip-pool")
	previous, err := os.ReadFile(marker) //nolint:gosec // fixed marker name inside the engine home
	if err != nil && !errors.Is(err, os.ErrNotExist) {
		return err
	}
	if string(previous) == pool.Masked().String() {
		return nil
	}
	if err := os.Remove(filepath.Join(rt.HomeDir, "cache.db")); err != nil && !errors.Is(err, os.ErrNotExist) {
		return err
	}
	return os.WriteFile(marker, []byte(pool.Masked().String()), 0o600)
}

// copyFile uses a temporary file so engines never read a partially written
// database.
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

// Route owns Linux policy routing so every engine shares the same exclusions.
func (driver) Route(ctx context.Context, p *engine.Plan) error {
	if runtime.GOOS != "linux" {
		return nil
	}
	return tunroute.Route(ctx, p.Tun, os.Getuid())
}

func (driver) Unroute(ctx context.Context) error { return tunroute.Unroute(ctx) }
