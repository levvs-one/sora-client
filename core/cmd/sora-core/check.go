package main

import (
	"log/slog"
	"os"
	"path/filepath"
	"runtime"
	"strings"

	"github.com/levvs-one/sora-client/core/errs"
)

// checkReport reports tunnel readiness without changing the installation.
func checkReport(app *App) ([]string, bool) {
	lines := []string{
		"endpoint: " + app.address,
		"tunnel: " + app.local,
		"data: " + app.opts.DataDir,
		"platform: " + platformName(),
		"guard: proxy and kill switch are available on this platform",
	}
	ready := true
	if app.engines == nil || !app.engines.Usable() {
		ready = false
		lines = append(lines,
			"engines: none found",
			"  install sing-box, xray or mihomo into "+app.opts.EnginesDir,
		)
	} else {
		for _, b := range app.engines.Binaries() {
			lines = append(lines, "engine: "+string(b.Kind)+" "+b.Version.Raw+" ("+b.Goos+"/"+b.Goarch+") "+b.Path)
		}
	}
	if runtime.GOOS != "windows" && runtime.GOOS != "linux" {
		lines = append(lines,
			"kill switch: not enforced on "+runtime.GOOS,
			"  the system proxy still points at a local engine that is not running",
		)
	}
	lines = append(lines, readyText(ready))
	return lines, ready
}

func readyText(ready bool) string {
	if ready {
		return "result: ready"
	}
	return "result: an engine is required before a tunnel can be started"
}

// printToken reads the data directory's control token. Only this explicit
// operation prints it.
func printToken(dir string) (string, error) {
	raw, err := os.ReadFile(filepath.Join(dir, "control.token")) //nolint:gosec // a fixed name inside the core data directory
	if err != nil {
		return "", errs.Wrap(err, errs.CodeInternal, errs.KeyUnauthenticated)
	}
	return strings.TrimSpace(string(raw)), nil
}

// newLogger creates a timestamped text logger at the requested level.
func newLogger(level string) (*slog.Logger, error) {
	var parsed slog.Level
	switch strings.ToLower(strings.TrimSpace(level)) {
	case "debug":
		parsed = slog.LevelDebug
	case "", "info":
		parsed = slog.LevelInfo
	case "warn", "warning":
		parsed = slog.LevelWarn
	case "error":
		parsed = slog.LevelError
	default:
		return nil, errs.Newf(errs.CodeInvalidArgument, errs.KeyUnauthenticated,
			"core: %q is not a log level", level)
	}
	return slog.New(slog.NewTextHandler(os.Stderr, &slog.HandlerOptions{Level: parsed})), nil
}
