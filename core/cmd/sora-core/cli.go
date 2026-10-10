package main

import (
	"context"
	"flag"
	"fmt"
	"os"
	"os/signal"
	"path/filepath"
	"runtime"
	"strings"
	"syscall"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/errs"
)

// flags holds operator settings with defaults for a standard installation.
type flags struct {
	dataDir     string
	enginesDir  string
	engine      string
	localPort   int
	bypass      string
	socket      string
	logLevel    string
	check       bool
	fileKeys    bool
	showVersion bool
	install     bool
	uninstall   bool
	showToken   bool
}

func main() {
	// Windows services must respond to SCM instead of using the console.
	if handled, err := runService(os.Args[1:]); handled {
		if err != nil {
			os.Exit(1)
		}
		return
	}
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	err := run(ctx, os.Args[1:])
	stop()
	if err != nil {
		// Exit codes identify failure classes for scripts; the key and
		// detail identify the cause.
		code := 1
		if errs.CodeOf(err) == errs.CodeInvalidArgument {
			code = 2
		}
		fmt.Fprintf(os.Stderr, "sora-core: %s: %s\n", errs.KeyOf(err), errs.Detail(err))
		os.Exit(code)
	}
}

func run(ctx context.Context, arguments []string) error {
	set := flag.NewFlagSet("sora-core", flag.ContinueOnError)
	var f flags
	set.StringVar(&f.dataDir, "data-dir", defaultDataDir(), "where the token, the secrets and the engine state live")
	set.StringVar(&f.enginesDir, "engines-dir", filepath.Join(defaultDataDir(), "engines"), "where the engine binaries are looked for")
	set.StringVar(&f.engine, "engine", "", "pin one engine: sing-box, xray or mihomo; empty picks one per plan")
	set.IntVar(&f.localPort, "tunnel-port", 0, "loopback port the tunnel is served on; 0 picks a free one")
	set.StringVar(&f.bypass, "bypass", "", "comma separated destinations that skip the tunnel")
	set.StringVar(&f.socket, "socket", "", "control plane socket; empty is the platform address")
	set.StringVar(&f.logLevel, "log-level", "info", "debug, info, warn or error")
	set.BoolVar(&f.check, "check", false, "build everything, report on it and exit without serving")
	set.BoolVar(&f.fileKeys, "allow-file-keys", false, "fall back to a key file when the machine key store is unavailable")
	set.BoolVar(&f.showVersion, "version", false, "print the contract and build version and exit")
	set.BoolVar(&f.install, "install-service", false, "Windows: register this executable as the SoraCore service with the other flags, start it and exit")
	set.BoolVar(&f.uninstall, "uninstall-service", false, "Windows: stop and remove the SoraCore service and exit")
	set.BoolVar(&f.showToken, "print-token", false, "print the control plane token and exit")
	if err := set.Parse(arguments); err != nil {
		return errs.Wrap(err, errs.CodeInvalidArgument, errs.KeyUnauthenticated)
	}
	if f.uninstall {
		return uninstallService()
	}
	if f.install {
		// Pass persistent service settings without forwarding the
		// install flag.
		return installService([]string{"-data-dir", f.dataDir, "-engines-dir", f.enginesDir})
	}
	if f.showVersion {
		fmt.Printf("sora-core %s (contract %d.%d, min supported %d, %s/%s)\n",
			buildVersion, Version.Major, Version.Minor, Version.MinSupportedMinor, runtime.GOOS, runtime.GOARCH)
		return nil
	}

	if f.showToken {
		token, err := printToken(f.dataDir)
		if err != nil {
			return err
		}
		fmt.Println(token)
		return nil
	}
	logger, err := newLogger(f.logLevel)
	if err != nil {
		return err
	}
	options := Options{
		Diagnostic:    f.check,
		DataDir:       f.dataDir,
		EnginesDir:    f.enginesDir,
		Engine:        engine.Kind(f.engine),
		LocalPort:     f.localPort,
		Bypass:        splitList(f.bypass),
		Socket:        f.socket,
		Log:           logger,
		AllowFileKeys: f.fileKeys,
	}
	app, err := New(ctx, options)
	if err != nil {
		if f.check {
			// A readiness check must report build failures even on
			// a broken installation.
			fmt.Println("result: the core cannot be built on this machine")
			fmt.Println("problem: " + string(errs.KeyOf(err)) + ": " + errs.Detail(err))
			return nil
		}
		return err
	}
	defer func() {
		if closeErr := app.Close(); closeErr != nil {
			logger.Error("shutdown was not clean", "error", errs.Detail(closeErr))
		}
	}()
	if f.check {
		lines, ok := checkReport(app)
		for _, line := range lines {
			fmt.Println(line)
		}
		if !ok {
			// A nonzero exit code lets scripts detect an unready
			// installation.
			return errs.Newf(errs.CodeFailedPrecondition, errs.KeyEngineStartFailed,
				"core: the installation is not ready")
		}
		return nil
	}
	return app.Serve(ctx)
}

// buildVersion is set at build time; unstamped builds report "dev".
var buildVersion = "dev"

// defaultDataDir returns the per-user directory for manual runs. Services
// receive an explicit directory.
func defaultDataDir() string {
	if dir := strings.TrimSpace(os.Getenv("SORA_DATA_DIR")); dir != "" {
		return dir
	}
	if dir, err := os.UserConfigDir(); err == nil {
		return filepath.Join(dir, "sora", "core")
	}
	return filepath.Join(".", ".sora-core")
}

// splitList parses a comma-separated list and skips empty entries.
func splitList(value string) []string {
	var out []string
	for _, part := range strings.Split(value, ",") {
		if trimmed := strings.TrimSpace(part); trimmed != "" {
			out = append(out, trimmed)
		}
	}
	return out
}
