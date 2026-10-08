package session

import (
	"context"
	"net"
	"net/netip"
	"strings"
	"sync"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/errs"
)

// Session deadlines bound readiness waits and shutdown for slow engines.
const (
	// DefaultStatsInterval samples counters at the contract's maximum rate
	// of one tick per second.
	DefaultStatsInterval = time.Second
	// DefaultStopGrace allows clean shutdown before killing the engine,
	// reducing the risk of leftover TUN devices.
	DefaultStopGrace = 3 * time.Second
	// groupLooks reads fallback groups every fifth counter tick: mihomo
	// checks its members far less often, so a faster look finds nothing new.
	groupLooks = 5
)

// Config requires Plan and Engine; other fields have usable defaults.
type Config struct {
	// Plan is the engine-independent description of the session. The
	// session
	// never mutates it after Start.
	Plan *engine.Plan
	// Engine must be constructed but not applied. Start calls Apply.
	Engine engine.Engine
	// Guard owns the system settings. NoopGuard is used when it is nil.
	Guard Guard
	// Journal keeps the event history. A journal with default capacity is
	// created when it is nil.
	Journal *Journal
	// JournalCapacity is the history size of a journal the session creates.
	JournalCapacity int
	// StatsInterval samples the engine counters.
	StatsInterval time.Duration
	// StopGrace bounds the engine shutdown.
	StopGrace time.Duration
	// Network supplies fingerprints for connection renewal on change. Nil
	// disables watching.
	Network func() string
	// NetworkInterval is how often Network is read.
	NetworkInterval time.Duration
	// Settings defines system state owned while running; fill it before
	// Start.
	Settings Settings

	// Redactor masks journal messages using plan values, including details
	// built outside the engine's own redactor.
	Redactor *engine.Redactor

	// Now supplies timestamps. Tests replace it to get stable output.
	Now func() time.Time

	// TunUp waits for the TUN adapter, using network-interface checks by
	// default. A running engine without its adapter must not be reported
	// connected because traffic may bypass the tunnel.
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

// Session owns a tunnel's engine, guard, state machine, and independent
// context, allowing cleanup after the initiating client disconnects.
type Session struct {
	cfg   Config
	eng   engine.Engine
	guard Guard
	log   *Journal

	mu       sync.Mutex
	state    State
	status   Status
	stopping bool
	// guardApplied tracks changes owned by this session so cleanup retries
	// them without removing unrelated rules.
	guardApplied bool
	// guardMu serializes kill-switch changes and shutdown restoration.
	guardMu   sync.Mutex
	engineSub func()
	ctx       context.Context
	cancel    context.CancelFunc
	done      chan struct{}
}

// New constructs a stopped session. Start changes the system after plan
// validation and engine construction.
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

// ID returns the identifier clients use to query this session.
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

// Status returns state, cause, and change time for status queries and event-gap
// recovery.
func (s *Session) Status() Status {
	s.mu.Lock()
	defer s.mu.Unlock()
	return s.status
}

// Start waits for readiness or permanent failure. Retryable failures enter
// reconnecting and continue in the background without requiring another
// Connect.
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

	// Subscribe before returning so failures between Apply and the first
	// poll cannot be lost.
	events, cancelSub := s.eng.Events().Subscribe()
	s.mu.Lock()
	s.engineSub = cancelSub
	s.mu.Unlock()
	go s.supervise(events)
	return nil
}

// Done closes after supervision ends and system settings are restored.
func (s *Session) Done() <-chan struct{} { return s.done }

// Stop shuts down the engine, restores the guard, and transitions to
// disconnected. Repeated calls are safe from user, shutdown, and failure paths.
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
	// Stop the engine before restoring the guard to prevent packets using
	// settings being removed.
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

// restoreGuard reverts only settings this session armed, leaving unrelated
// rules intact after early startup failures.
func (s *Session) restoreGuard(ctx context.Context) error {
	s.guardMu.Lock()
	defer s.guardMu.Unlock()
	s.mu.Lock()
	applied := s.guardApplied
	s.mu.Unlock()
	if !applied {
		return nil
	}
	if err := s.guard.Restore(ctx); err != nil {
		// Retain ownership after restoration failure so subsequent
		// cleanup retries it.
		return err
	}
	s.mu.Lock()
	s.guardApplied = false
	s.mu.Unlock()
	return nil
}

// SetKillSwitch applies changes immediately, serialized with restoration to
// prevent rearming after shutdown. Disabling remains allowed after failure
// because failed sessions retain the block.
func (s *Session) SetKillSwitch(ctx context.Context, enabled bool) error {
	s.guardMu.Lock()
	defer s.guardMu.Unlock()
	s.mu.Lock()
	if s.stopping || (enabled && s.state.terminal()) || (!enabled && s.state == StateDisconnected) {
		state := s.state
		s.mu.Unlock()
		return errs.Newf(errs.CodeFailedPrecondition, errs.KeySessionRequired,
			"session: cannot change the kill switch while %s", state)
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

// supervise is the session's single background loop for engine events,
// counters, and terminal failures. It continues independently of the UI.
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

	// Only fallback groups are watched: a move there means a server stopped
	// answering or came back, and plans without one never poll.
	var (
		fallbacks map[string]string
		looksAt   <-chan time.Time
	)
	for _, g := range s.cfg.Plan.Groups {
		if g.Type == engine.GroupFallback {
			if fallbacks == nil {
				fallbacks = map[string]string{}
			}
			fallbacks[g.Name] = ""
		}
	}
	if fallbacks != nil {
		looks := time.NewTicker(groupLooks * s.cfg.StatsInterval)
		defer looks.Stop()
		looksAt = looks.C
	}

	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			s.publishCounters(ctx)
		case <-looksAt:
			// While the engine restarts, a look may reach the process
			// that is going away or one not yet checked.
			if s.State() == StateConnected {
				s.noticeFallbacks(ctx, fallbacks)
			}
		case <-network:
			if why := watch.changed(); why != "" {
				s.renewConnections(ctx, why)
			}
		case ev, ok := <-events:
			if !ok {
				return
			}
			s.publishEngineEvent(ev)
			// Only the engine supervisor restarts processes within
			// its budget; session supervision must not create a
			// competing process.
			switch ev.Kind {
			case engine.EventEngineDown:
				reason, key := errs.CodeUnavailable, errs.KeyEngineStopped
				if ev.Err != nil {
					reason, key = errs.CodeOf(ev.Err), errs.KeyOf(ev.Err)
				}
				s.setStateReconnecting(reason, key, 0)
			case engine.EventState:
				if ev.State == engine.StateRunning && s.State() == StateReconnecting {
					// A restarted engine starts its fallback groups over
					// on the first member; that is not the main server
					// answering again.
					for g := range fallbacks {
						fallbacks[g] = ""
					}
					s.setState(StateConnected, errs.Code(""), errs.Key(""), "")
				}
			case engine.EventFatal:
				s.fail(errs.Newf(errs.CodeUnavailable, errs.KeyEngineStopped,
					"session: the engine reported a fatal error"))
				return
			}
		}
	}
}

// publishEngineEvent converts engine events and redacts again with session plan
// values before journaling.
func (s *Session) publishEngineEvent(ev engine.Event) {
	out := Event{Kind: EventLog, Detail: s.mask(ev.Message)}
	switch ev.Kind {
	case engine.EventState:
		// Log engine states separately; only session states belong to
		// the client lifecycle.
		out.Detail = s.mask(strings.TrimSpace(string(ev.State) + " " + ev.Message))
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

// probeOutcomeOf converts group latency state to a result. Unmeasured groups
// are unreachable, not zero-latency, to avoid treating them as fastest.
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

// noticeFallbacks journals the fallback groups whose member changed since the
// last look. The first answer only records where each group stands, and a
// look that fails while the engine restarts is skipped. A member that did not
// answer its last check is passed over: mihomo shows the first member when
// none answers, and that is not the main server coming back.
func (s *Session) noticeFallbacks(ctx context.Context, last map[string]string) {
	groups, err := s.eng.Groups(ctx)
	if err != nil {
		return
	}
	for _, g := range groups {
		before, watched := last[g.Name]
		if !watched || g.Selected == "" || g.Selected == before || g.LatencyMS[g.Selected] <= 0 {
			continue
		}
		last[g.Name] = g.Selected
		if before != "" {
			s.log.Append(Event{Kind: EventGroup, Switch: &GroupSwitch{Group: g.Name, Previous: before, Selected: g.Selected}})
		}
	}
}

// publishCounters records sampled traffic totals. Temporary read failures
// during restart are skipped until the next tick.
func (s *Session) publishCounters(ctx context.Context) {
	counters, err := s.Counters(ctx)
	if err != nil {
		return
	}
	s.log.Append(Event{Kind: EventCounters, Counters: counters})
}

// mask redacts credentials and server identifiers before journaling.
func (s *Session) mask(text string) string {
	if s.cfg.Redactor == nil {
		return text
	}
	return s.cfg.Redactor.String(text)
}

// fail records the cause, enters failed, and ends supervision. Stop, also
// called by the control plane after failure, cleans up the engine and guard.
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

// settingsLocked reads settings with the session lock already held, avoiding
// recursive lock acquisition.
func (s *Session) settingsLocked() Settings {
	fake, _ := netip.ParsePrefix(s.cfg.Plan.DNS.FakeIPRange)
	return Settings{
		FakeIPRange: fake,
		TunNetworks: s.cfg.Plan.Tun.Networks(),
		KillSwitch:  s.status.KillSwitch,
		Bypass:      append([]string(nil), s.status.Bypass...),
		TunnelMode:  s.status.TunnelMode,
	}
}

// Select pins a group member and journals the change for reconnecting clients.
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

// setStateLocked records legal transitions while the caller holds the lock.
// Invalid transitions are discarded to preserve the client state contract.
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

// setStateReconnecting records the retry attempt and delay so clients can
// report when reconnection is expected.
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
