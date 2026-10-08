// Command sora-core runs the Sora network core without a UI. It owns
// credentials, supervises engines, manages tunnel settings, and serves the
// control API independently of clients.
package main

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"net"
	"os"
	"path/filepath"
	"runtime"
	"runtime/debug"
	"strconv"
	"strings"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/protobuf/types/known/timestamppb"

	"github.com/levvs-one/sora-client/core/control"
	"github.com/levvs-one/sora-client/core/diagnostics"
	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/registry"
	"github.com/levvs-one/sora-client/core/engine/supervise"
	"github.com/levvs-one/sora-client/core/engine/tunroute"
	"github.com/levvs-one/sora-client/core/errs"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
	"github.com/levvs-one/sora-client/core/guard"
	"github.com/levvs-one/sora-client/core/ipc"
	"github.com/levvs-one/sora-client/core/logs"
	"github.com/levvs-one/sora-client/core/probe"
	"github.com/levvs-one/sora-client/core/secret"
	"github.com/levvs-one/sora-client/core/session"
	"github.com/levvs-one/sora-client/core/subscription"
)

// Version defines the API contract served by this build. Contract changes must
// update this value and the generated code together.
var Version = control.Version{Major: 1, Minor: 6, MinSupportedMinor: 1}

// Options configures a core instance.
type Options struct {
	// DataDir holds the token, the secret store and the engine home
	// directory.
	DataDir string
	// EnginesDir is searched first for engine binaries.
	EnginesDir string
	// Engine pins an engine kind. Empty selects the first compatible engine
	// in preference order for each plan.
	Engine engine.Kind
	// LocalPort is the tunnel's loopback port, used by the system proxy.
	// Zero selects a free port.
	LocalPort int
	// Bypass lists destinations that skip the tunnel.
	Bypass []string
	// Socket sets the control endpoint. Empty uses the platform address,
	// which requires root for manual runs.
	Socket string
	// Log receives core logs. Nil uses the default handler.
	Log *slog.Logger
	// Factory overrides engine creation. Nil uses mihomo; tests can supply
	// an engine without a binary or system changes.
	Factory session.Factory
	// NoDiagnostics builds a core that cannot produce a report.
	NoDiagnostics bool
	// AllowFileKeys enables a logged fallback when the platform key store
	// fails. Disabled by default because file keys provide weaker
	// protection.
	AllowFileKeys bool
}

// App holds an initialized core. Construction opens the store, token, and
// endpoint; Serve starts the control API, allowing readiness checks without
// listening.
type App struct {
	opts     Options
	log      *slog.Logger
	store    *secret.Store
	sessions *session.Manager
	plane    *control.Server
	listener *ipc.Listener
	server   *grpc.Server
	report   *diagnostics.Collector
	address  string
	local    string
	engines  *registry.Registry
}

// New builds a core from its options.
func New(ctx context.Context, opts Options) (*App, error) {
	if strings.TrimSpace(opts.DataDir) == "" {
		return nil, errs.Newf(errs.CodeInvalidArgument, errs.KeySecretStoreUnavailable,
			"core: no data directory")
	}
	log := opts.Log
	if log == nil {
		log = slog.New(slog.NewTextHandler(os.Stderr, &slog.HandlerOptions{Level: slog.LevelInfo}))
	}
	// The log center keeps core and engine logs in memory; the existing log
	// output remains active.
	center := logs.New(logs.DefaultSettings())
	log = slog.New(logs.NewHandler(center, log.Handler()))
	// Create the owner-only directory before any component writes to it, so
	// ownership is consistent.
	if err := os.MkdirAll(opts.DataDir, 0o700); err != nil {
		return nil, errs.Wrap(err, errs.CodeInternal, errs.KeySecretStoreUnavailable)
	}
	if err := secureDataDir(opts.DataDir); err != nil {
		return nil, errs.Wrap(err, errs.CodeInternal, errs.KeySecretStoreUnavailable)
	}
	app := &App{opts: opts, log: log}

	local, err := localAddress(opts.LocalPort)
	if err != nil {
		return nil, err
	}
	app.local = local
	// Engines and the kill switch must use the same port, chosen before
	// either starts.
	tunnelPort, err := portOf(local)
	if err != nil {
		return nil, errs.Wrap(err, errs.CodeInternal, errs.KeyEngineStartFailed)
	}

	// The control token persists with owner-only permissions and is printed
	// only on explicit request.
	auth, err := control.LoadOrCreateToken(opts.DataDir)
	if err != nil {
		return nil, err
	}
	store, err := secret.Open(filepath.Join(opts.DataDir, "secrets"), secret.Options{
		Protector: protectorFor(opts, log),
	})
	if err != nil {
		return nil, err
	}
	app.store = store

	factory := opts.Factory
	if factory == nil {
		if err := tunroute.Cleanup(ctx); err != nil {
			_ = store.Close()
			return nil, err
		}
		app.engines = registry.Discover(ctx, opts.EnginesDir, supervise.Config{
			HomeDir: filepath.Join(opts.DataDir, "engine"), LocalPort: int(tunnelPort), Logs: center,
		})
		if err := app.engines.Pin(opts.Engine); err != nil {
			return nil, err
		}
		factory = app.engines.Factory()
		if !app.engines.Usable() {
			// Keep status, diagnostics, and import available when
			// no engine is installed.
			log.Warn("no engine binary found; connecting fails until one is installed",
				"engines_dir", opts.EnginesDir)
		}
	}

	firewall, err := guard.PlatformFirewall(guard.FirewallOptions{
		EngineUID: os.Getuid(), EnginesDir: opts.EnginesDir, Bypass: opts.Bypass,
	})
	if err != nil {
		_ = store.Close()
		return nil, err
	}
	system, err := guard.New(guard.Options{
		EnginePorts: []uint16{tunnelPort},
	}, firewall)
	if err != nil {
		_ = store.Close()
		return nil, err
	}
	redactor := engine.NewRedactor()
	manager := session.NewManager(session.ManagerConfig{
		Factory:  factory,
		Guard:    system,
		Redactor: redactor,
		Network:  session.NetworkFingerprint,
	})
	app.sessions = manager

	if !opts.NoDiagnostics {
		collector, err := diagnostics.New(diagnostics.Options{
			Source:   &source{app: app},
			Redactor: redactor,
		})
		if err != nil {
			_ = store.Close()
			return nil, err
		}
		app.report = collector
	}
	// Keep a nil registry as a nil interface to avoid calling through a nil
	// pointer.
	var measurer control.Measurer
	if app.engines != nil {
		measurer = app.engines
	}
	plane, err := control.New(control.Config{
		Version:       Version,
		Authenticator: auth,
		Sessions:      manager,
		Secrets:       store,
		Prober:        probe.New(probe.Config{}),
		Measurer:      measurer,
		Logs:          center,
		About:         app.about,
		Fetcher:       subscription.New(subscription.Options{}),
	})
	if err != nil {
		_ = store.Close()
		return nil, err
	}
	plane.SetDiagnostics(app.report)
	app.plane = plane

	listener, err := ipc.Listen(ctx, ipc.Options{Address: opts.Socket})
	if err != nil {
		_ = store.Close()
		return nil, err
	}
	app.listener = listener
	app.address = listener.Address()
	app.server = grpc.NewServer(
		// The transport rejects requests above the four-megabyte plan
		// limit before allocating their payload.
		grpc.MaxRecvMsgSize(control.MaxRecvMsgBytes),
		grpc.MaxSendMsgSize(control.MaxSendMsgBytes),
	)
	corev1.RegisterCoreControlServer(app.server, plane)
	return app, nil
}

// protectorFor selects master-key protection and checks it during construction.
// Missing profile keys can break the platform store; only explicit opt-in
// permits a logged file-key fallback.
func protectorFor(opts Options, log *slog.Logger) secret.Protector {
	platform := platformProtector()
	_, err := platform.Protect([]byte("sora-core protector probe"))
	if err == nil {
		return platform
	}
	if !opts.AllowFileKeys {
		return platform
	}
	log.Warn("the machine key store is unavailable; falling back to a key file",
		"mechanism_wanted", platform.Name(),
		"problem", errs.Detail(err),
		"consequence", "the master key is protected by file permissions instead")
	return secret.FileProtector{}
}

// about describes this build for the "About" screen of the interface.
func (a *App) about() *corev1.About {
	out := &corev1.About{
		CoreVersion: buildVersion,
		Platform:    runtime.GOOS + "/" + runtime.GOARCH,
		GoVersion:   runtime.Version(),
		License:     "GPL-3.0-only",
		SourceUrl:   "https://github.com/levvs-one/sora-client",
	}
	if port, err := portOf(a.local); err == nil {
		out.LocalProxy = &corev1.Endpoint{Host: "127.0.0.1", Port: uint32(port)}
	}
	if info, ok := debug.ReadBuildInfo(); ok {
		for _, setting := range info.Settings {
			switch setting.Key {
			case "vcs.revision":
				out.Commit = setting.Value
			case "vcs.time":
				if at, err := time.Parse(time.RFC3339, setting.Value); err == nil {
					out.CommitTime = timestamppb.New(at)
				}
			}
		}
	}
	if a.engines != nil {
		for _, engine := range a.engines.Availability() {
			out.Engines = append(out.Engines, &corev1.EngineBuild{
				Kind: string(engine.Kind), Installed: engine.Usable, Version: engine.Version.String(),
			})
		}
	}
	return out
}

// source feeds the diagnostics collector from the running core.
type source struct{ app *App }

func (s *source) Status() session.Status { return s.app.sessions.Status() }

func (s *source) RecentEvents(limit int) []session.Event {
	current := s.app.sessions.Current()
	if current == nil {
		return nil
	}
	events := current.Journal().Since(0, limit)
	if len(events) > limit {
		events = events[len(events)-limit:]
	}
	return events
}

func (s *source) EngineLines() []string {
	lines := []string{
		"component: sora-core",
		"contract: " + fmt.Sprintf("%d.%d", Version.Major, Version.Minor),
		"platform: " + platformName(),
		"tunnel: " + s.app.local,
		"endpoint: " + s.app.address,
	}
	if s.app.engines == nil {
		return append(lines, "engine: provided by the caller")
	}
	for _, a := range s.app.engines.Availability() {
		if a.Usable {
			lines = append(lines, "engine "+string(a.Kind)+": "+a.Version.Raw)
		} else {
			lines = append(lines, "engine "+string(a.Kind)+": not installed")
		}
	}
	if sel := s.app.engines.LastSelection(); sel.Kind != "" {
		lines = append(lines, "engine selected: "+string(sel.Kind))
	}
	for _, why := range s.app.engines.LastSelection().Rejected {
		lines = append(lines, "engine passed over: "+why)
	}
	return lines
}

// Serve runs the control plane until the context ends.
func (a *App) Serve(ctx context.Context) error {
	a.log.Info("core listening", "endpoint", a.address, "tunnel", a.local)
	// Subscription updates must continue without a connected UI.
	go a.plane.Run(ctx)
	err := a.server.Serve(a.listener)
	if ctx.Err() != nil {
		// Closing the listener on cancellation is a normal service
		// shutdown.
		return nil //nolint:nilerr // the error is the closed listener of a requested stop
	}
	if errors.Is(err, grpc.ErrServerStopped) {
		return nil
	}
	return err
}

// Close restores session settings, then closes the endpoint and secret store.
func (a *App) Close() error {
	var problems []error
	// Shutdown needs an independent deadline to restore the proxy after
	// caller cancellation.
	stopCtx, cancel := context.WithTimeout(context.WithoutCancel(context.Background()), 20*time.Second)
	defer cancel()
	if err := a.sessions.Shutdown(stopCtx); err != nil {
		problems = append(problems, err)
	}
	if a.server != nil {
		a.server.GracefulStop()
	}
	if a.listener != nil {
		if err := a.listener.Close(); err != nil && !errors.Is(err, net.ErrClosed) {
			problems = append(problems, err)
		}
	}
	if a.store != nil {
		if err := a.store.Close(); err != nil {
			problems = append(problems, err)
		}
	}
	return errors.Join(problems...)
}

// Address returns the endpoint clients dial.
func (a *App) Address() string { return a.address }

// TunnelAddress returns the loopback address used by the system proxy.
func (a *App) TunnelAddress() string { return a.local }

// localAddress selects the tunnel's loopback address before the engine starts,
// so the guard can use it across sessions.
func localAddress(port int) (string, error) {
	if port == 0 {
		free, err := supervise.FreePort()
		if err != nil {
			return "", err
		}
		port = free
	}
	if port < 1 || port > 0xffff {
		return "", errs.Newf(errs.CodeInvalidArgument, errs.KeyEngineStartFailed,
			"core: %d is not a port", port)
	}
	return net.JoinHostPort("127.0.0.1", strconv.Itoa(port)), nil
}

// portOf extracts the port from an address.
func portOf(address string) (uint16, error) {
	_, portText, err := net.SplitHostPort(address)
	if err != nil {
		return 0, err
	}
	port, err := strconv.ParseUint(portText, 10, 16)
	return uint16(port), err
}
