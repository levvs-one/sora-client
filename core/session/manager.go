package session

import (
	"context"
	"sync"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/errs"
)

// Factory builds the engine that will carry a plan. The control plane injects
// one so the session package never has to know which engine build a machine
// has, and so a test can run a session with an engine that does nothing.
type Factory func(ctx context.Context, plan *engine.Plan) (engine.Engine, error)

// ManagerConfig configures a Manager. Every field except the factory has a
// default, and the defaults are the ones a desktop core wants.
type ManagerConfig struct {
	// Factory builds the engine for a plan. It is required.
	Factory Factory
	// Guard owns the system settings while a session runs. A new session gets
	// the same guard, and the session restores it on every exit path, so two
	// sessions can never hold system settings at the same time.
	Guard Guard
	// JournalCapacity is the history size of each session journal.
	JournalCapacity int
	// Backoff schedules reconnect attempts.
	Backoff engine.Backoff
	// Budget builds the restart budget of one session. Each session gets its
	// own budget: a budget shared between sessions would let the attempts of a
	// session that failed ten minutes ago block the next connection.
	Budget func() *engine.RestartBudget
	// StatsInterval samples the engine counters.
	StatsInterval time.Duration
	// StopGrace bounds the engine shutdown.
	StopGrace time.Duration
	// Redactor masks secrets in the journal.
	Redactor *engine.Redactor
	// Now supplies timestamps.
	Now func() time.Time
	// TunUp waits for the adapter of a tun plan; see Config.TunUp.
	TunUp func(ctx context.Context, device string) error
}

// Manager owns at most one session. The invariant is simple and absolute: a
// machine has one tunnel, and the core decides which. A second Connect replaces
// the first, and the first is stopped and restored before the second touches the
// system, because two sessions would fight over the proxy, the firewall and the
// tun device.
type Manager struct {
	cfg ManagerConfig

	mu      sync.Mutex
	current *Session
	last    Status
	busy    bool
}

// NewManager returns a manager. The factory is validated here, so a
// misconfigured core fails at startup instead of on the first connection.
func NewManager(cfg ManagerConfig) *Manager {
	if cfg.Factory == nil {
		panic("session: manager needs an engine factory")
	}
	if cfg.JournalCapacity <= 0 {
		cfg.JournalCapacity = DefaultJournalCapacity
	}
	if cfg.StatsInterval <= 0 {
		cfg.StatsInterval = DefaultStatsInterval
	}
	if cfg.StopGrace <= 0 {
		cfg.StopGrace = DefaultStopGrace
	}
	if cfg.Backoff.Initial <= 0 {
		cfg.Backoff = engine.DefaultBackoff()
	}
	if cfg.Now == nil {
		cfg.Now = time.Now
	}
	if cfg.Budget == nil {
		now := cfg.Now
		cfg.Budget = func() *engine.RestartBudget {
			return engine.NewRestartBudget(5, 10*time.Minute, now)
		}
	}
	if cfg.Guard == nil {
		cfg.Guard = NoopGuard{}
	}
	return &Manager{cfg: cfg, last: Status{State: StateDisconnected, ChangedAt: cfg.Now()}}
}

// Connect starts a session for the plan. Any previous session is stopped first
// and its system settings are restored, so the machine is never configured twice.
func (m *Manager) Connect(ctx context.Context, plan *engine.Plan, settings Settings) (*Session, error) {
	m.mu.Lock()
	if m.busy {
		m.mu.Unlock()
		return nil, errs.Newf(errs.CodeFailedPrecondition, errs.KeySessionBusy,
			"session: another connect or disconnect is running")
	}
	m.busy = true
	previous := m.current
	m.current = nil
	m.mu.Unlock()

	defer m.release()

	stopCtx := context.WithoutCancel(ctx)
	if previous != nil {
		if err := previous.Stop(stopCtx); err != nil {
			m.setLast(previous.Status())
			return nil, err
		}
	}

	built, err := m.cfg.Factory(ctx, plan)
	if err != nil {
		return nil, err
	}
	created, err := New(Config{
		Plan:          plan,
		Engine:        built,
		Guard:         m.cfg.Guard,
		Journal:       NewJournal(m.cfg.JournalCapacity),
		Backoff:       m.cfg.Backoff,
		RestartBudget: m.cfg.Budget(),
		StatsInterval: m.cfg.StatsInterval,
		StopGrace:     m.cfg.StopGrace,
		Redactor:      m.cfg.Redactor,
		Settings:      settings,
		Now:           m.cfg.Now,
		TunUp:         m.cfg.TunUp,
	})
	if err != nil {
		_ = built.Close()
		return nil, err
	}
	if err := created.Start(ctx); err != nil {
		// A session that failed to start may still own an engine that created
		// a device, so it is stopped rather than dropped on the floor. The
		// status is read before the stop, because the failure is the answer a
		// client asked for and a stopped session reports only that it is gone.
		status := created.Status()
		_ = created.Stop(stopCtx)
		m.setLast(status)
		return nil, err
	}

	m.mu.Lock()
	m.current = created
	m.last = created.Status()
	m.mu.Unlock()
	return created, nil
}

// Disconnect stops the current session. It succeeds when there is none, so a
// client may call it defensively at startup.
func (m *Manager) Disconnect(ctx context.Context) error {
	m.mu.Lock()
	if m.busy {
		m.mu.Unlock()
		return errs.Newf(errs.CodeFailedPrecondition, errs.KeySessionBusy,
			"session: another connect or disconnect is running")
	}
	m.busy = true
	current := m.current
	m.current = nil
	m.mu.Unlock()

	defer m.release()

	if current == nil {
		return nil
	}
	err := current.Stop(ctx)
	m.setLast(current.Status())
	return err
}

// Current returns the running session, or nil when there is none.
func (m *Manager) Current() *Session {
	m.mu.Lock()
	defer m.mu.Unlock()
	return m.current
}

// Status returns the state of the last session the manager saw. It answers
// GetStatus even after the session has ended.
func (m *Manager) Status() Status {
	m.mu.Lock()
	defer m.mu.Unlock()
	return m.last
}

// Shutdown stops everything and returns once the machine is back to normal. The
// core calls it on service stop, on SIGTERM and before a self-update.
func (m *Manager) Shutdown(ctx context.Context) error {
	return m.Disconnect(ctx)
}

// release clears the busy flag that serialises connect and disconnect.
func (m *Manager) release() {
	m.mu.Lock()
	m.busy = false
	m.mu.Unlock()
}

// setLast records the status a client will see after the session is gone.
func (m *Manager) setLast(status Status) {
	m.mu.Lock()
	m.last = status
	m.mu.Unlock()
}
