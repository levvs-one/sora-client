// Package singbox runs sing-box as a supervised child process and implements
// engine.Engine on top of its HTTP REST API (compatible with Clash API).
package singbox

import (
	"context"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strconv"
	"strings"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/errs"
)

const (
	// DefaultControllerPort is the fallback when the kernel gives us nothing.
	// In practice we always ask the kernel for a free port.
	DefaultControllerPort = 9090
	// ControllerSecretBytes is the length of the REST API secret.
	ControllerSecretBytes = 16
	// MinPort/MaxPort is the ephemeral range we pick controller/listener ports from.
	MinPort = 20000
	MaxPort = 60999
)

// Binary is a probed sing-box build.
type Binary struct {
	Path    string
	Version engine.Version
	Goos    string
	Goarch  string
}

// Discover finds a sing-box binary. Search order: SORA_SINGBOX env override,
// then the Sora engines directory, then PATH. No downloads here.
func Discover(enginesDir string) (Binary, error) {
	if p := strings.TrimSpace(os.Getenv("SORA_SINGBOX")); p != "" {
		b, err := Probe(context.Background(), p, 10*time.Second)
		if err == nil {
			return b, nil
		}
	}
	if enginesDir != "" {
		candidates, _ := filepath.Glob(filepath.Join(enginesDir, "sing-box*"))
		for _, c := range candidates {
			b, err := Probe(context.Background(), c, 10*time.Second)
			if err == nil {
				return b, nil
			}
		}
	}
	if p, err := exec.LookPath("sing-box"); err == nil {
		return Probe(context.Background(), p, 10*time.Second)
	}
	return Binary{}, errs.Newf(errs.CodeNotFound, errs.KeyEngineBinaryMissing,
		"sing-box: no binary found (set SORA_SINGBOX or put sing-box in engines dir or PATH)")
}

// Probe runs the binary with --version and parses the output.
func Probe(ctx context.Context, path string, timeout time.Duration) (Binary, error) {
	ctx, cancel := context.WithTimeout(ctx, timeout)
	defer cancel()
	cmd := exec.CommandContext(ctx, path, "version")
	out, err := cmd.Output()
	if err != nil {
		return Binary{}, errs.Wrap(err, errs.CodeUnavailable, errs.KeyEngineStartFailed)
	}
	ver, err := engine.ParseVersion(string(out))
	if err != nil {
		return Binary{}, errs.Wrap(err, errs.CodeUnavailable, errs.KeyEngineStartFailed)
	}
	if ver.Major < 1 || (ver.Major == 1 && ver.Minor < 8) {
		return Binary{}, errs.Newf(errs.CodeUnavailable, errs.KeyEngineStartFailed,
			"sing-box: version %s is too old, need >= 1.8.0", ver.Raw)
	}
	return Binary{Path: path, Version: ver, Goos: runtime.GOOS, Goarch: runtime.GOARCH}, nil
}

// TestConfig validates a config by running sing-box check.
func TestConfig(ctx context.Context, b Binary, homeDir, jsonText string) error {
	tmp := filepath.Join(homeDir, "test-config-"+strconv.FormatInt(time.Now().UnixNano(), 10)+".json")
	if err := os.WriteFile(tmp, []byte(jsonText), 0o600); err != nil {
		return errs.Wrap(err, errs.CodeInternal, errs.KeyEngineStartFailed)
	}
	defer os.Remove(tmp)
	ctx, cancel := context.WithTimeout(ctx, 10*time.Second)
	defer cancel()
	cmd := exec.CommandContext(ctx, b.Path, "check", "-c", tmp, "-D", homeDir)
	if out, err := cmd.CombinedOutput(); err != nil {
		return errs.Newf(errs.CodeInvalidArgument, errs.KeyEngineStartFailed,
			"sing-box config check failed: %s: %s", err, string(out))
	}
	return nil
}
