// Command sora-core is the Sora network core.
//
// It is the whole product without an interface: it owns the credentials, supervises
// the engine, changes the system settings a tunnel needs, and serves the control
// plane that any client speaks. The desktop interface is one such client. Nothing in
// this package depends on a client existing, which is what makes the core testable
// and scriptable on its own.
package main

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"net"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	"google.golang.org/grpc"

	"github.com/levvs-one/sora-client/core/control"
	"github.com/levvs-one/sora-client/core/diagnostics"
	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/registry"
	"github.com/levvs-one/sora-client/core/engine/supervise"
	"github.com/levvs-one/sora-client/core/errs"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
	"github.com/levvs-one/sora-client/core/guard"
	"github.com/levvs-one/sora-client/core/ipc"
	"github.com/levvs-one/sora-client/core/probe"
	"github.com/levvs-one/sora-client/core/secret"
	"github.com/levvs-one/sora-client/core/session"
	"github.com/levvs-one/sora-client/core/subscription"
)

// Version is the contract this build serves. It is the same number the interface
// checks, and a build that changes the contract changes it here and in the
// generated code together.
var Version = control.Version{Major: 1, Minor: 2, MinSupportedMinor: 1}

// Options is everything a running core needs to know about itself.
type Options struct {
	// DataDir holds the token, the secret store and the engine home directory.
	DataDir string
	// EnginesDir is where the engine binaries are looked for first.
	EnginesDir string
	// Engine pins one engine kind. Empty lets the core pick, per plan, the
	// first engine in preference order that can carry the plan.
	Engine engine.Kind
	// LocalPort is the loopback port the tunnel is served on and the system proxy
	// is pointed at. Zero picks a free one.
	LocalPort int
	// Bypass lists destinations that skip the tunnel.
	Bypass []string
	// Log receives what the core does. Nil means the default handler.
	Log *slog.Logger
	// Factory overrides the engine. Nil means mihomo, and a test uses it to run
	// the whole service without a binary and without touching the machine.
	Factory session.Factory
	// NoDiagnostics builds a core that cannot produce a report.
	NoDiagnostics bool
	// AllowFileKeys falls back to a key file when the machine key store refuses
	// to protect the master key. It is off by default and it says so in the log:
	// a key file is weaker than the platform store, and the operator is the one
	// who has to accept that, not the core.
	AllowFileKeys bool
}

// App is a built core. Building it opens the store, the token and the endpoint;
// serving it runs the control plane. The two are separate so that a check can
// build everything, report on it and close it again without ever listening.
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
	// The data directory is created here, owner-only, before anything is written
	// into it. Creating it per component would work too, and would leave the
	// question of who owns it to whoever happened to be first.
	if err := os.MkdirAll(opts.DataDir, 0o700); err != nil {
		return nil, errs.Wrap(err, errs.CodeInternal, errs.KeySecretStoreUnavailable)
	}
	app := &App{opts: opts, log: log}

	local, err := localAddress(opts.LocalPort)
	if err != nil {
		return nil, err
	}
	app.local = local

	// The token is what stands between a local process and the tunnel, so it is
	// generated once, stored with owner-only rights and printed by nothing but an
	// explicit request.
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
		app.engines = registry.Discover(ctx, opts.EnginesDir)
		port, _ := portOf(local)
		factory, err = app.engines.Factory(supervise.Config{
			HomeDir:   filepath.Join(opts.DataDir, "engine"),
			LocalPort: port,
		}, opts.Engine)
		if err != nil {
			return nil, err
		}
		if !app.engines.Usable() {
			// A core without an engine is still a core: it answers status,
			// diagnostics and the import, and it says plainly that it cannot
			// connect. Refusing to start would leave an operator with nothing to
			// look at and no way to see why.
			log.Warn("no engine binary found; connecting fails until one is installed",
				"engines_dir", opts.EnginesDir)
		}
	}

	firewall, err := guard.PlatformFirewall(os.Getuid(), opts.Bypass)
	if err != nil {
		_ = store.Close()
		return nil, err
	}
	system, err := guard.New(guard.Options{
		ProxyAddress: local,
		EnginePorts:  []uint16{uint16(opts.LocalPort)},
	}, guard.PlatformProxy(), firewall)
	if err != nil {
		_ = store.Close()
		return nil, err
	}
	redactor := engine.NewRedactor()
	manager := session.NewManager(session.ManagerConfig{
		Factory:  factory,
		Guard:    system,
		Backoff:  engine.Backoff{Initial: time.Second, Max: time.Minute, Factor: 2},
		Budget:   func() *engine.RestartBudget { return engine.NewRestartBudget(5, 10*time.Minute, nil) },
		Redactor: redactor,
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
	plane, err := control.New(control.Config{
		Version:       Version,
		Authenticator: auth,
		Sessions:      manager,
		Secrets:       store,
		Prober:        probe.New(probe.Config{}),
		Fetcher:       subscription.New(subscription.Options{}),
	})
	if err != nil {
		_ = store.Close()
		return nil, err
	}
	plane.SetDiagnostics(app.report)
	app.plane = plane

	listener, err := ipc.Listen(ctx, ipc.Options{})
	if err != nil {
		_ = store.Close()
		return nil, err
	}
	app.listener = listener
	app.address = listener.Address()
	app.server = grpc.NewServer(
		// The contract allows a plan of at most four megabytes; a larger request is
		// refused by the transport before anything is allocated for it.
		grpc.MaxRecvMsgSize(control.MaxRecvMsgBytes),
		grpc.MaxSendMsgSize(control.MaxSendMsgBytes),
	)
	corev1.RegisterCoreControlServer(app.server, plane)
	return app, nil
}

// protectorFor decides how the master key of the store is protected, and it says
// out loud when the answer is the weaker one.
//
// The machine key store is the right answer and it is the only one that is on by
// default. It is also the answer that fails on a machine where the account has no
// profile key to bind to: a service account created by a script, a profile that was
// never loaded, a machine whose user profile store was rebuilt. In that case a
// core that refused to start would be a core nobody could diagnose, so the failure
// is checked here, once, at build time, and reported as what it is.
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
	err := a.server.Serve(a.listener)
	if ctx.Err() != nil {
		// The listener closes with the context, so a server that stops because the
		// service was told to stop has done its job.
		return nil
	}
	if errors.Is(err, grpc.ErrServerStopped) {
		return nil
	}
	return err
}

// Close shuts the core down: the session first, so the system settings go back
// where they were, then the endpoint, then the store.
func (a *App) Close() error {
	var problems []error
	// The shutdown budget is detached from the caller's context on purpose: a core
	// that is stopping must be able to restore the proxy even when whoever asked it
	// to stop has already gone.
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

// Address is the endpoint clients dial.
func (a *App) Address() string { return a.address }

// TunnelAddress is the loopback address the system proxy is pointed at.
func (a *App) TunnelAddress() string { return a.local }

// localAddress decides the loopback address of the tunnel. The guard needs it
// before the engine runs, so it is decided here and never per session.
func localAddress(port int) (string, error) {
	if port == 0 {
		free, err := freePort()
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

// portOf reads the port back out of an address.
func portOf(address string) (int, error) {
	_, portText, err := net.SplitHostPort(address)
	if err != nil {
		return 0, err
	}
	return strconv.Atoi(portText)
}

// freePort asks the kernel for a port nothing holds right now. The window between
// the answer and the engine binding it is small and local, and the engine fails
// loudly if it loses the race, which is better than a port decided twice.
func freePort() (int, error) {
	listener, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		return 0, errs.Wrap(err, errs.CodeInternal, errs.KeyEngineStartFailed)
	}
	port, err := portOf(listener.Addr().String())
	if err != nil {
		_ = listener.Close()
		return 0, err
	}
	if err := listener.Close(); err != nil {
		return 0, errs.Wrap(err, errs.CodeInternal, errs.KeyEngineStartFailed)
	}
	return port, nil
}
