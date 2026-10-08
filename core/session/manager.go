package session

import (
	"context"
	"sync"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/errs"
)

// Factory creates an engine for a plan, keeping discovery and test engines
// outside the session package.
type Factory func(ctx context.Context, plan *engine.Plan) (engine.Engine, error)

// ManagerConfig requires Factory; other fields default to desktop core
// settings.
type ManagerConfig struct {
	// Factory builds the engine for a plan. It is required.
	Factory Factory
	// Guard is shared across sequential sessions and restored on every exit
	// path. Two sessions cannot own system settings concurrently.
	Guard Guard
	// JournalCapacity is the history size of each session journal.
	JournalCapacity int
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
	// Network fingerprints the networks of the machine; see Config.Network.
	Network func() string
}

// Manager owns at most one session. Connect stops and restores the old session
// before the new one changes proxy, firewall, or TUN settings.
type Manager struct {
	cfg ManagerConfig

	mu      sync.Mutex
	current *Session
	last    Status
	busy    bool
}

// NewManager validates the required factory at construction rather than on
// first connection.
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
	if cfg.Now == nil {
		cfg.Now = time.Now
	}
	if cfg.Guard == nil {
		cfg.Guard = NoopGuard{}
	}
	return &Manager{cfg: cfg, last: Status{State: StateDisconnected, ChangedAt: cfg.Now()}}
}

// Connect stops any previous session and restores its settings before starting
// the new plan.
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
		StatsInterval: m.cfg.StatsInterval,
		StopGrace:     m.cfg.StopGrace,
		Redactor:      m.cfg.Redactor,
		Settings:      settings,
		Now:           m.cfg.Now,
		TunUp:         m.cfg.TunUp,
		Network:       m.cfg.Network,
	})
	if err != nil {
		_ = built.Close()
		return nil, err
	}
	if err := created.Start(ctx); err != nil {
		// Stop failed startups because they may still own an engine or
		// device. Capture the failure status before Stop replaces it
		// with disconnected.
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

// Disconnect stops the current session and succeeds if none exists.
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

// Status returns current or last-session state, remaining available after
// session termination.
func (m *Manager) Status() Status {
	m.mu.Lock()
	current, last := m.current, m.last
	m.mu.Unlock()
	// Read live state so failure or reconnection is not reported as an old
	// connected snapshot.
	if current != nil {
		return current.Status()
	}
	return last
}

// Shutdown stops the session and restores system settings for service stop,
// SIGTERM, or self-update.
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
