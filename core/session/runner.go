package session

import (
	"context"
	"net"
	"sync"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/errs"
)

// Defaults of a session. They are generous enough for a slow server and short
// enough that a user does not stare at a spinner: the engine answers its
// controller on the loopback interface, so anything slower than this is a
// problem worth showing.
const (
	// DefaultStatsInterval is how often the session samples the engine
	// counters. The contract asks for at most one tick per second.
	DefaultStatsInterval = time.Second
	// DefaultStopGrace is how long the engine may take to stop before it is
	// killed. A clean stop matters more than a fast one, because a killed
	// engine can leave its tun device behind.
	DefaultStopGrace = 3 * time.Second
)

// Config is what one session needs. Every field has a usable default except the
// plan and the engine, because those are the session.
type Config struct {
	// Plan is the engine-independent description of the session. The session
	// never mutates it after Start.
	Plan *engine.Plan
	// Engine carries the traffic. It must already be constructed but not
	// applied: Start calls Apply itself.
	Engine engine.Engine
	// Guard owns the system settings. NoopGuard is used when it is nil.
	Guard Guard
	// Journal keeps the event history. A journal with default capacity is
	// created when it is nil.
	Journal *Journal
	// JournalCapacity is the history size of a journal the session creates.
	JournalCapacity int
	// Backoff schedules reconnect attempts. engine.DefaultBackoff is used when
	// it is the zero value.
	Backoff engine.Backoff
	// RestartBudget limits reconnects inside its window. A budget of five
	// attempts per ten minutes is used when it is nil.
	RestartBudget *engine.RestartBudget
	// StatsInterval samples the engine counters.
	StatsInterval time.Duration
	// StopGrace bounds the engine shutdown.
	StopGrace time.Duration
	// Network fingerprints the networks of the machine; a connected session
	// renews its connections when the fingerprint changes. Nil watches nothing.
	Network func() string
	// NetworkInterval is how often Network is read.
	NetworkInterval time.Duration
	// Settings is filled by the caller before Start: what the session needs to
	// own on the system while it runs.
	Settings Settings

	// Redactor masks secrets in everything the session writes to the journal.
	// The engine has its own redactor; the session needs the plan values too,
	// because a detail line can be built from the plan and not from the engine.
	Redactor *engine.Redactor

	// Now supplies timestamps. Tests replace it to get stable output.
	Now func() time.Time

	// TunUp waits until the adapter of a tun plan is up. An engine may start
	// and keep running without its adapter, for example without the right to
	// create one, and a session that called that connected would tell a
	// person they are protected while their traffic goes around the tunnel.
	// It waits for the network interface by default.
	TunUp func(ctx context.Context, device string) error
}

// tunWait bounds how long an engine may take to bring its adapter up.
const tunWait = 5 * time.Second

func interfaceUp(ctx context.Context, device string) error {
	ctx, cancel := context.WithTimeout(ctx, tunWait)
	defer cancel()
	for {
		if iface, err := net.InterfaceByName(device); err == nil && iface.Flags&net.FlagUp != 0 {
			return nil
		}
		select {
		case <-ctx.Done():
			return errs.Newf(errs.CodeFailedPrecondition, errs.KeyPlanTunnel,
				"session: the engine is running but the adapter %s is not up; the core may lack CAP_NET_ADMIN", device)
		case <-time.After(50 * time.Millisecond):
		}
	}
}

// Session is one running tunnel: the engine, the guard and the state machine
// that keeps them together. A session owns its own context, so the core can drop
// the caller that started it and still end up with a clean machine.
type Session struct {
	cfg   Config
	eng   engine.Engine
	guard Guard
	log   *Journal

	mu       sync.Mutex
	state    State
	status   Status
	stopping bool
	// guardApplied records that this session armed the system guard. The
	// session restores exactly what it armed, so a failure during Start cannot
	// leave a rule behind and a later Stop cannot remove a rule the session
	// never installed.
	guardApplied bool
	engineSub    func()
	ctx          context.Context
	cancel       context.CancelFunc
	done         chan struct{}
}

// New builds a session that is not started yet. Start does the work, so a caller
// can validate a plan and construct the engine before anything on the system
// moves.
func New(cfg Config) (*Session, error) {
	if cfg.Plan == nil {
		return nil, errs.Newf(errs.CodeInvalidArgument, errs.KeyPlanEmpty, "session: no plan")
	}
	if cfg.Engine == nil {
		return nil, errs.Newf(errs.CodeInvalidArgument, errs.KeyEngineStartFailed, "session: no engine")
	}
	if cfg.Guard == nil {
		cfg.Guard = NoopGuard{}
	}
	if cfg.Journal == nil {
		cfg.Journal = NewJournal(cfg.JournalCapacity)
	}
	if cfg.StatsInterval <= 0 {
		cfg.StatsInterval = DefaultStatsInterval
	}
	if cfg.StopGrace <= 0 {
		cfg.StopGrace = DefaultStopGrace
	}
	if cfg.NetworkInterval <= 0 {
		cfg.NetworkInterval = DefaultNetworkInterval
	}
	if cfg.Backoff.Initial <= 0 {
		cfg.Backoff = engine.DefaultBackoff()
	}
	if cfg.RestartBudget == nil {
		cfg.RestartBudget = engine.NewRestartBudget(5, 10*time.Minute, nil)
	}
	if cfg.TunUp == nil {
		cfg.TunUp = interfaceUp
	}
	if cfg.Now == nil {
		cfg.Now = time.Now
	}
	if err := cfg.Plan.Validate(); err != nil {
		return nil, errs.Wrap(err, errs.CodeInvalidArgument, errs.KeyPlanOutbounds)
	}
	return &Session{
		cfg:   cfg,
		eng:   cfg.Engine,
		guard: cfg.Guard,
		log:   cfg.Journal,
		state: StateDisconnected,
		status: Status{
			ChangedAt:  cfg.Now(),
			KillSwitch: cfg.Settings.KillSwitch,
			Bypass:     append([]string(nil), cfg.Settings.Bypass...),
			TunnelMode: cfg.Settings.TunnelMode,
		},
		done: make(chan struct{}),
	}, nil
}

// ID returns the session identifier, which the control plane hands to a client
// so it can read the status of the session it started.
func (s *Session) ID() string { return s.cfg.Plan.SessionID }

// Plan returns the plan this session runs.
func (s *Session) Plan() *engine.Plan { return s.cfg.Plan }

// Journal returns the event journal of this session.
func (s *Session) Journal() *Journal { return s.log }

// State reports the current state.
func (s *Session) State() State {
	s.mu.Lock()
	defer s.mu.Unlock()
	return s.state
}

// Status returns a snapshot of the state, its cause and the moment it changed.
// It is the answer to GetStatus and the fallback for a client that missed
// events on the stream.
func (s *Session) Status() Status {
	s.mu.Lock()
	defer s.mu.Unlock()
	return s.status
}

// Start brings the plan up and returns as soon as the tunnel is up or has failed
// for good. A failure worth retrying is not returned as an error: the session
// moves to reconnecting and keeps working on it in the background, because a
// user who asked to connect should not have to ask again.
func (s *Session) Start(ctx context.Context) error {
	s.mu.Lock()
	if s.state != StateDisconnected {
		state := s.state
		s.mu.Unlock()
		return errs.Newf(errs.CodeFailedPrecondition, errs.KeySessionBusy,
			"session: already %s", state)
	}
	s.ctx, s.cancel = context.WithCancel(context.WithoutCancel(ctx))
	s.status.SessionID = s.ID()
	s.setStateLocked(StateConnecting, errs.Code(""), errs.Key(""), "")
	s.mu.Unlock()

	if err := s.eng.Validate(s.ctx, s.cfg.Plan); err != nil {
		wrapped := errs.Wrap(err, errs.CodeInvalidArgument, errs.KeyPlanOutbounds)
		s.fail(wrapped)
		return wrapped
	}
	if err := s.guard.Apply(s.ctx, s.settings()); err != nil {
		wrapped := errs.Wrap(err, errs.CodeFailedPrecondition, errs.KeyGuardFirewallFail)
		s.fail(wrapped)
		return wrapped
	}
	s.mu.Lock()
	s.guardApplied = true
	s.mu.Unlock()
	err := s.eng.Apply(s.ctx, s.cfg.Plan)
	if err != nil {
		err = errs.Wrap(err, errs.CodeUnavailable, errs.KeyEngineStartFailed)
	} else if tun := s.cfg.Plan.Tun; tun.Enabled && tun.DeviceName != "" {
		if err = s.cfg.TunUp(s.ctx, tun.DeviceName); err != nil {
			_ = s.eng.Stop(context.WithoutCancel(ctx))
		}
	}
	if err != nil {
		wrapped := err
		restoreCtx := context.WithoutCancel(ctx)
		if restoreErr := s.restoreGuard(restoreCtx); restoreErr != nil {
			s.log.Append(Event{
				Kind:   EventError,
				Reason: errs.CodeOf(restoreErr),
				Key:    errs.KeyGuardRestoreFailed,
				Detail: s.mask(restoreErr.Error()),
			})
		}
		s.fail(wrapped)
		return wrapped
	}

	s.setState(StateConnected, errs.Code(""), errs.Key(""), "")

	// The subscription is taken before Start returns, not inside the goroutine:
	// an engine that fails between Apply and the first poll must not lose the
	// event that says so.
	events, cancelSub := s.eng.Events().Subscribe()
	s.mu.Lock()
	s.engineSub = cancelSub
	s.mu.Unlock()
	go s.supervise(events)
	return nil
}

// Done is closed once the supervision loop has finished and the system settings
// are back to what they were.
func (s *Session) Done() <-chan struct{} { return s.done }

// Stop ends the session: the engine stops, the guard is restored and the state
// settles on disconnected. Stop is idempotent and safe to call from a shutdown
// path, from a user command and from a failing supervision loop.
func (s *Session) Stop(ctx context.Context) error {
	s.mu.Lock()
	if s.stopping {
		s.mu.Unlock()
		return nil
	}
	s.stopping = true
	cancel := s.cancel
	s.mu.Unlock()

	if cancel != nil {
		cancel()
	}
	// The engine stops before the guard is restored, so no packet is ever sent
	// through a proxy that is about to be removed.
	stopErr := s.eng.Stop(ctx)
	if err := s.restoreGuard(context.WithoutCancel(ctx)); err != nil && stopErr == nil {
		stopErr = errs.Wrap(err, errs.CodeInternal, errs.KeyGuardRestoreFailed)
	}
	s.setState(StateDisconnected, errs.Code(""), errs.Key(""), "")
	s.mu.Lock()
	if s.engineSub != nil {
		s.engineSub()
		s.engineSub = nil
	}
	_ = s.eng.Close()
	s.mu.Unlock()
	return stopErr
}

// restoreGuard reverts the system settings this session armed, and only those.
// A session that failed before arming anything must not remove a rule that
// belongs to another program, which is why the state is tracked instead of
// assumed.
func (s *Session) restoreGuard(ctx context.Context) error {
	s.mu.Lock()
	if !s.guardApplied {
		s.mu.Unlock()
		return nil
	}
	s.guardApplied = false
	s.mu.Unlock()
	return s.guard.Restore(ctx)
}

// SetKillSwitch turns the kill switch on or off while the session runs. Turning
// it on takes effect immediately, because the moment it protects is exactly the
// moment the engine is not answering.
func (s *Session) SetKillSwitch(ctx context.Context, enabled bool) error {
	s.mu.Lock()
	if s.state.terminal() {
		state := s.state
		s.mu.Unlock()
		return errs.Newf(errs.CodeFailedPrecondition, errs.KeySessionRequired,
			"session: cannot arm the kill switch while %s", state)
	}
	settings := s.settingsLocked()
	settings.KillSwitch = enabled
	s.status.KillSwitch = enabled
	s.mu.Unlock()
	if err := s.guard.Apply(ctx, settings); err != nil {
		return errs.Wrap(err, errs.CodeInternal, errs.KeyGuardFirewallFail)
	}
	s.mu.Lock()
	s.guardApplied = true
	s.mu.Unlock()
	return nil
}

// Counters returns the traffic counters of the running engine.
func (s *Session) Counters(ctx context.Context) (Counters, error) {
	raw, err := s.eng.Counters(ctx)
	if err != nil {
		return Counters{}, err
	}
	return Counters{
		BytesUp:           raw.BytesUp,
		BytesDown:         raw.BytesDown,
		ActiveConnections: raw.ActiveConnections,
		At:                raw.At,
	}, nil
}

// Groups returns the live state of the selectable groups of the engine.
func (s *Session) Groups(ctx context.Context) ([]engine.GroupStatus, error) {
	return s.eng.Groups(ctx)
}

// Connections lists the live connections, where the engine can.
func (s *Session) Connections(ctx context.Context) ([]engine.Connection, error) {
	tracker, ok := s.eng.(engine.ConnectionTracker)
	if !ok {
		return nil, errs.Newf(errs.CodeUnsupported, errs.KeyConnectionsUnavailable,
			"session: the engine cannot list connections")
	}
	return tracker.Connections(ctx)
}

// CloseConnection drops one live connection, where the engine can.
func (s *Session) CloseConnection(ctx context.Context, id string) error {
	tracker, ok := s.eng.(engine.ConnectionTracker)
	if !ok {
		return errs.Newf(errs.CodeUnsupported, errs.KeyConnectionsUnavailable,
			"session: the engine cannot close connections")
	}
	return tracker.CloseConnection(ctx, id)
}

// supervise watches the engine for the whole life of the session. It is the
// only goroutine a session owns, and it is the reason a session survives a window
// closing: engine logs, counters, an engine that died and the decision to give
// up all happen here.
func (s *Session) supervise(events <-chan engine.Event) {
	defer close(s.done)

	s.mu.Lock()
	ctx := s.ctx
	s.mu.Unlock()

	ticker := time.NewTicker(s.cfg.StatsInterval)
	defer ticker.Stop()
	var (
		watch   *networkWatch
		network <-chan time.Time
	)
	if s.cfg.Network != nil {
		watch = newNetworkWatch(s.cfg.Network, s.cfg.NetworkInterval)
		looks := time.NewTicker(s.cfg.NetworkInterval)
		defer looks.Stop()
		network = looks.C
	}

	attempt := 0
	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			s.publishCounters(ctx)
		case <-network:
			if why := watch.changed(); why != "" {
				s.renewConnections(ctx, why)
			}
		case ev, ok := <-events:
			if !ok {
				return
			}
			s.publishEngineEvent(ev)
			switch ev.Kind {
			case engine.EventEngineDown:
				if s.reconnect(ctx, &attempt) {
					return
				}
			case engine.EventFatal:
				s.fail(errs.Newf(errs.CodeUnavailable, errs.KeyEngineStopped,
					"session: the engine reported a fatal error"))
				return
			}
		}
	}
}

// reconnect retries the plan inside the restart budget. It reports whether the
// supervision loop must end, which happens when the session is stopping, when
// the budget is spent, or when a retry is no longer wanted.
func (s *Session) reconnect(ctx context.Context, attempt *int) bool {
	for {
		if ctx.Err() != nil {
			return true
		}
		if !s.cfg.RestartBudget.Allow() {
			s.fail(errs.Newf(errs.CodeUnavailable, errs.KeyEngineRestartSpent,
				"session: the engine kept failing inside the restart budget"))
			return true
		}
		delay := s.cfg.Backoff.Delay(*attempt)
		*attempt++
		s.setStateReconnecting(errs.CodeUnavailable, errs.KeyEngineStopped, delay)

		if err := s.cfg.Backoff.Wait(ctx, *attempt-1); err != nil {
			return true
		}
		if err := s.eng.Apply(ctx, s.cfg.Plan); err != nil {
			s.log.Append(Event{
				Kind:   EventError,
				Reason: errs.CodeUnavailable,
				Key:    errs.KeyEngineStartFailed,
				Detail: s.mask(err.Error()),
			})
			continue
		}
		*attempt = 0
		s.setState(StateConnected, errs.Code(""), errs.Key(""), "")
		return false
	}
}

// publishEngineEvent turns one engine event into a journal event. The engine
// already redacts its own output; the session masks once more, because a
// redactor only knows what it was told.
func (s *Session) publishEngineEvent(ev engine.Event) {
	out := Event{Kind: EventLog, Detail: s.mask(ev.Message)}
	switch ev.Kind {
	case engine.EventState:
		out.Kind = EventState
	case engine.EventCounters:
		out.Kind = EventCounters
		out.Counters = Counters{
			BytesUp:           ev.Counters.BytesUp,
			BytesDown:         ev.Counters.BytesDown,
			ActiveConnections: ev.Counters.ActiveConnections,
			At:                ev.Counters.At,
		}
	case engine.EventGroup, engine.EventRestart:
		out.Kind = EventProbe
		if ev.Group != nil {
			out.Probe = probeOutcomeOf(ev.Group)
			out.Detail = ev.Group.Name
		}
	case engine.EventEngineDown, engine.EventFatal:
		out.Kind = EventError
		out.Reason = errs.CodeUnavailable
		out.Key = errs.KeyEngineStopped
		if ev.Err != nil {
			out.Reason = errs.CodeOf(ev.Err)
			out.Key = errs.KeyOf(ev.Err)
		}
	}
	if out.Kind == EventLog {
		out.LogLine = out.Detail
		out.Detail = ""
	}
	s.log.Append(out)
}

// probeOutcomeOf turns the live state of a group into the measurement it reports.
// A group without a latency map has not been measured yet, which is reported as
// an unreachable result rather than as a zero delay: a zero delay would read as
// "the fastest server" and would pick it.
func probeOutcomeOf(group *engine.GroupStatus) *ProbeOutcome {
	if group == nil {
		return nil
	}
	outcome := &ProbeOutcome{ServerID: group.Name}
	for name, latency := range group.LatencyMS {
		if name == group.Selected || group.Selected == "" {
			outcome.ServerID = name
			outcome.Reachable = latency > 0
			outcome.LatencyMS = latency
			return outcome
		}
	}
	return outcome
}

// publishCounters samples the engine and appends a counters event. A counter
// that cannot be read is not an error: the engine is restarting and the next
// tick will do better.
func (s *Session) publishCounters(ctx context.Context) {
	counters, err := s.Counters(ctx)
	if err != nil {
		return
	}
	s.log.Append(Event{Kind: EventCounters, Counters: counters})
}

// mask runs text through the plan redactor so nothing that identifies a server or
// a credential reaches the journal.
func (s *Session) mask(text string) string {
	if s.cfg.Redactor == nil {
		return text
	}
	return s.cfg.Redactor.String(text)
}

// fail moves the session to failed, records the cause and ends the supervision
// loop. The engine and the guard are cleaned up by Stop, which the control plane
// also calls for a session that failed.
func (s *Session) fail(err error) {
	s.setState(StateFailed, errs.CodeOf(err), errs.KeyOf(err), s.mask(errs.Detail(err)))
	s.log.Append(Event{
		Kind:   EventError,
		Reason: errs.CodeOf(err),
		Key:    errs.KeyOf(err),
		Detail: s.mask(errs.Detail(err)),
	})
}

// settings is the system state the session needs while it runs.
func (s *Session) settings() Settings {
	s.mu.Lock()
	defer s.mu.Unlock()
	return s.settingsLocked()
}

// settingsLocked is settings for callers that already hold the session lock.
// The guard never takes the lock itself, so reading the settings must not be a
// second lock acquisition on a path that already holds it.
func (s *Session) settingsLocked() Settings {
	return Settings{
		KillSwitch: s.status.KillSwitch,
		Bypass:     append([]string(nil), s.status.Bypass...),
		TunnelMode: s.status.TunnelMode,
	}
}

// Select pins a member of a selectable group and records the change, so a
// client that reattaches to the event stream learns which group moved.
func (s *Session) Select(ctx context.Context, group, target string) error {
	if err := s.eng.Select(ctx, group, target); err != nil {
		return err
	}
	s.log.Append(Event{
		Kind:   EventState,
		State:  s.State(),
		Key:    KeySelectionChanged,
		Detail: group + " -> " + target,
	})
	return nil
}

// setState moves the session to a new state and records the change.
func (s *Session) setState(next State, reason errs.Code, key errs.Key, detail string) {
	s.mu.Lock()
	s.setStateLocked(next, reason, key, detail)
	s.mu.Unlock()
}

// setStateLocked moves the session to a new state while the caller holds the
// lock. A transition the state machine does not allow is dropped instead of
// recorded: the state machine is the contract, and a caller that violates it
// must not be able to tell a client something impossible.
func (s *Session) setStateLocked(next State, reason errs.Code, key errs.Key, detail string) bool {
	if !canTransition(s.state, next) {
		return false
	}
	masked := s.mask(detail)
	s.state = next
	s.status = Status{
		State:      next,
		SessionID:  s.status.SessionID,
		Reason:     reason,
		Key:        key,
		Detail:     masked,
		ChangedAt:  s.cfg.Now(),
		KillSwitch: s.status.KillSwitch,
		Bypass:     s.status.Bypass,
		TunnelMode: s.status.TunnelMode,
	}
	s.log.Append(Event{
		Kind:   EventState,
		State:  next,
		Reason: reason,
		Key:    key,
		Detail: masked,
	})
	return true
}

// setStateReconnecting records a reconnect attempt together with the delay the
// core will wait before it, so a client can tell the user when to expect traffic
// back instead of showing an open ended spinner.
func (s *Session) setStateReconnecting(reason errs.Code, key errs.Key, delay time.Duration) {
	s.mu.Lock()
	if !canTransition(s.state, StateReconnecting) {
		s.mu.Unlock()
		return
	}
	s.state = StateReconnecting
	s.status.State = StateReconnecting
	s.status.Reason = reason
	s.status.Key = key
	s.status.ChangedAt = s.cfg.Now()
	s.status.RetryAfter = delay
	s.mu.Unlock()
	s.log.Append(Event{
		Kind:       EventState,
		State:      StateReconnecting,
		Reason:     reason,
		Key:        key,
		RetryAfter: delay,
	})
}
