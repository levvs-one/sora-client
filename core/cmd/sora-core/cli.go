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

// flags are what an operator sets once. Everything else has a default that works
// on a normal installation, because a service that needs eight options to start is
// a service nobody starts.
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
	// Started by the Windows service manager, the core answers it instead of
	// a console; everywhere else this returns at once.
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
		// The exit code is what a script reads, so it says what kind of failure
		// this was; the key says which one, and the detail says in one line why.
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
		// The service runs with the data and engines directories given here;
		// the install flag itself is not passed on.
		return installService([]string{"-data-dir", f.dataDir, "-engines-dir", f.enginesDir})
	}
	if f.showVersion {
		fmt.Printf("sora-core %s (contract %d.%d, min supported %d, %s/%s)\n",
			buildVersion, Version.Major, Version.Minor, Version.MinSupportedMinor, runtime.GOOS, runtime.GOARCH)
		return nil
	}

	logger, err := newLogger(f.logLevel)
	if err != nil {
		return err
	}
	options := Options{
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
			// A check exists for the case where the installation is broken, so it
			// reports the failure instead of repeating it as an error. An operator
			// reading this learns what is wrong and where; an operator reading a
			// stack of wrapped errors learns that something is.
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
	if f.showToken {
		token, err := printToken(f.dataDir)
		if err != nil {
			return err
		}
		fmt.Println(token)
		return nil
	}
	if f.check {
		lines, ok := checkReport(app)
		for _, line := range lines {
			fmt.Println(line)
		}
		if !ok {
			// The report is on the screen and the exit code is the answer a script
			// reads. A check that exits 0 while saying "not ready" is a check nobody
			// can run in a pipeline.
			return errs.Newf(errs.CodeFailedPrecondition, errs.KeyEngineStartFailed,
				"core: the installation is not ready")
		}
		return nil
	}
	return app.Serve(ctx)
}

// buildVersion is stamped by the build; an unstamped build says so rather than
// claiming a version nobody set.
var buildVersion = "dev"

// defaultDataDir is the per-user data directory of the core. A service runs as
// its own account and is told where its data is; this is what a person running it
// by hand gets.
func defaultDataDir() string {
	if dir := strings.TrimSpace(os.Getenv("SORA_DATA_DIR")); dir != "" {
		return dir
	}
	if dir, err := os.UserConfigDir(); err == nil {
		return filepath.Join(dir, "sora", "core")
	}
	return filepath.Join(".", ".sora-core")
}

// splitList reads a comma separated list and drops the empty entries, so a value
// with a trailing comma is not a destination.
func splitList(value string) []string {
	var out []string
	for _, part := range strings.Split(value, ",") {
		if trimmed := strings.TrimSpace(part); trimmed != "" {
			out = append(out, trimmed)
		}
	}
	return out
}
