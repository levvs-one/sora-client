package session

import (
	"context"
	"errors"
	"sync"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/errs"
)

// fakeEngine records engine requests and injects failures without processes,
// devices, or network access.
type fakeEngine struct {
	mu       sync.Mutex
	bus      *engine.EventBus
	state    engine.State
	applies  int
	stops    int
	closes   int
	validate error
	apply    error
	stopErr  error
	counters engine.Counters
}

func newFakeEngine() *fakeEngine {
	return &fakeEngine{bus: engine.NewEventBus(16), state: engine.StateIdle}
}

func (f *fakeEngine) Kind() engine.Kind                 { return engine.KindMihomo }
func (f *fakeEngine) Capabilities() engine.Capabilities { return engine.Catalog[engine.KindMihomo] }
func (f *fakeEngine) Events() *engine.EventBus          { return f.bus }
func (f *fakeEngine) Version() engine.Version {
	return engine.Version{Raw: "1.19.32", Major: 1, Minor: 19, Patch: 32}
}

func (f *fakeEngine) State() engine.State {
	f.mu.Lock()
	defer f.mu.Unlock()
	return f.state
}

func (f *fakeEngine) Validate(context.Context, *engine.Plan) error {
	f.mu.Lock()
	defer f.mu.Unlock()
	return f.validate
}

func (f *fakeEngine) Apply(context.Context, *engine.Plan) error {
	f.mu.Lock()
	f.applies++
	err := f.apply
	if err == nil {
		f.state = engine.StateRunning
	} else {
		f.state = engine.StateFailed
	}
	f.mu.Unlock()
	return err
}

func (f *fakeEngine) Stop(context.Context) error {
	f.mu.Lock()
	defer f.mu.Unlock()
	f.stops++
	if f.stopErr == nil {
		f.state = engine.StateStopped
	}
	return f.stopErr
}

func (f *fakeEngine) Close() error {
	f.mu.Lock()
	defer f.mu.Unlock()
	f.closes++
	return nil
}

func (f *fakeEngine) Groups(context.Context) ([]engine.GroupStatus, error) { return nil, nil }
func (f *fakeEngine) Select(context.Context, string, string) error         { return nil }
func (f *fakeEngine) Delay(context.Context, string, string, time.Duration) (time.Duration, error) {
	return 0, nil
}

func (f *fakeEngine) Counters(context.Context) (engine.Counters, error) {
	f.mu.Lock()
	defer f.mu.Unlock()
	if f.state != engine.StateRunning {
		return engine.Counters{}, errors.New("engine is not running")
	}
	return f.counters, nil
}

func (f *fakeEngine) counts() (applies, stops, closes int) {
	f.mu.Lock()
	defer f.mu.Unlock()
	return f.applies, f.stops, f.closes
}

// fakeGuard records the settings it was asked for and can be told to fail.
type fakeGuard struct {
	mu        sync.Mutex
	applied   []Settings
	restores  int
	applyErr  error
	restoreEr error
	current   Settings
}

func (g *fakeGuard) Apply(_ context.Context, s Settings) error {
	g.mu.Lock()
	defer g.mu.Unlock()
	if g.applyErr != nil {
		return g.applyErr
	}
	g.applied = append(g.applied, s)
	g.current = s
	return nil
}

func (g *fakeGuard) Restore(context.Context) error {
	g.mu.Lock()
	defer g.mu.Unlock()
	if g.restoreEr != nil {
		return g.restoreEr
	}
	g.restores++
	g.current = Settings{}
	return nil
}

func (g *fakeGuard) Current() Settings {
	g.mu.Lock()
	defer g.mu.Unlock()
	return g.current
}

func (g *fakeGuard) Name() string { return "fake" }

func (g *fakeGuard) snapshot() (int, int) {
	g.mu.Lock()
	defer g.mu.Unlock()
	return len(g.applied), g.restores
}

func testPlan(id string) *engine.Plan {
	return &engine.Plan{
		SessionID: id,
		Outbounds: []engine.Outbound{{
			ID:       "out-1",
			Name:     "Berlin",
			Protocol: engine.ProtocolVLESS,
			Server:   "de1.example.com",
			Port:     443,
		}},
		Groups: []engine.Group{{Name: "auto", Type: engine.GroupSelect, Outbounds: []string{"out-1"}}},
	}
}

func testConfig(eng engine.Engine, guard Guard) Config {
	return Config{
		Plan:          testPlan("session-1"),
		Engine:        eng,
		Guard:         guard,
		StatsInterval: 5 * time.Millisecond,
	}
}

func TestSessionStartsAppliesAndStopsCleanly(t *testing.T) {
	eng, guard := newFakeEngine(), &fakeGuard{}
	session, err := New(testConfig(eng, guard))
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}
	if session.State() != StateDisconnected {
		t.Errorf("a fresh session is %s, want disconnected", session.State())
	}
	if err := session.Start(context.Background()); err != nil {
		t.Fatalf("Start() error = %v", err)
	}
	if session.State() != StateConnected {
		t.Errorf("after Start the state is %s, want connected", session.State())
	}
	if applied, _ := guard.snapshot(); applied != 1 {
		t.Errorf("the guard was applied %d times, want once", applied)
	}
	events := session.Journal().Since(0, 16)
	if len(events) < 2 {
		t.Fatalf("the journal holds %d events, want the connecting and connected states", len(events))
	}
	if events[0].State != StateConnecting || events[len(events)-1].State != StateConnected {
		t.Errorf("journal states = %s .. %s, want connecting .. connected",
			events[0].State, events[len(events)-1].State)
	}

	if err := session.Stop(context.Background()); err != nil {
		t.Fatalf("Stop() error = %v", err)
	}
	if session.State() != StateDisconnected {
		t.Errorf("after Stop the state is %s", session.State())
	}
	if _, restores := guard.snapshot(); restores != 1 {
		t.Errorf("the guard was restored %d times, want once", restores)
	}
	applies, stops, closes := eng.counts()
	if applies != 1 || stops != 1 || closes != 1 {
		t.Errorf("engine saw apply=%d stop=%d close=%d, want 1 each", applies, stops, closes)
	}
	if err := session.Stop(context.Background()); err != nil {
		t.Errorf("stopping twice = %v", err)
	}
	if _, stops, _ = eng.counts(); stops != 1 {
		t.Errorf("stopping twice stopped the engine %d times", stops)
	}
}

func TestSessionRejectsAnInvalidPlan(t *testing.T) {
	eng, guard := newFakeEngine(), &fakeGuard{}
	broken := testConfig(eng, guard)
	broken.Plan = &engine.Plan{SessionID: "session-1"}
	if _, err := New(broken); errs.KeyOf(err) != errs.KeyPlanOutbounds {
		t.Errorf("a plan with no outbounds gives %v, key = %q", err, errs.KeyOf(err))
	}
	missing := testConfig(eng, guard)
	missing.Plan = nil
	if _, err := New(missing); errs.KeyOf(err) != errs.KeyPlanEmpty {
		t.Errorf("a nil plan gives %v, key = %q", err, errs.KeyOf(err))
	}
}

func TestSessionFailsWithoutTouchingTheSystemWhenThePlanIsRejected(t *testing.T) {
	eng, guard := newFakeEngine(), &fakeGuard{}
	eng.validate = errors.New("engine rejected the configuration")
	session, err := New(testConfig(eng, guard))
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}
	if err := session.Start(context.Background()); errs.KeyOf(err) != errs.KeyPlanOutbounds {
		t.Fatalf("Start() = %v, key = %q", err, errs.KeyOf(err))
	}
	if session.State() != StateFailed {
		t.Errorf("state = %s, want failed", session.State())
	}
	if applied, _ := guard.snapshot(); applied != 0 {
		t.Errorf("the guard was applied %d times although the plan never passed", applied)
	}
	if applies, _, _ := eng.counts(); applies != 0 {
		t.Errorf("the engine was applied %d times although the plan never passed", applies)
	}
}

func TestSessionRestoresTheSystemWhenTheEngineWillNotStart(t *testing.T) {
	eng, guard := newFakeEngine(), &fakeGuard{}
	eng.apply = errors.New("engine binary is missing")
	session, err := New(testConfig(eng, guard))
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}
	if err := session.Start(context.Background()); errs.KeyOf(err) != errs.KeyEngineStartFailed {
		t.Fatalf("Start() = %v, key = %q", err, errs.KeyOf(err))
	}
	applied, restores := guard.snapshot()
	if applied != 1 || restores != 1 {
		t.Errorf("guard applied=%d restored=%d, want 1 and 1", applied, restores)
	}
	if session.State() != StateFailed {
		t.Errorf("state = %s, want failed", session.State())
	}
}

func TestSessionFollowsTheSupervisorThroughARestart(t *testing.T) {
	eng, guard := newFakeEngine(), &fakeGuard{}
	session, err := New(testConfig(eng, guard))
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}
	if err := session.Start(context.Background()); err != nil {
		t.Fatalf("Start() error = %v", err)
	}
	defer func() { _ = session.Stop(context.Background()) }()
	eng.bus.Publish(engine.Event{Kind: engine.EventEngineDown, Err: errors.New("process exited")})
	waitFor(t, 2*time.Second, func() bool { return session.State() == StateReconnecting })
	// The supervisor brings the engine back; the session only follows.
	eng.bus.Publish(engine.Event{Kind: engine.EventState, State: engine.StateRunning})
	waitFor(t, 2*time.Second, func() bool { return session.State() == StateConnected })
	if applies, _, _ := eng.counts(); applies != 1 {
		t.Errorf("the session applied the engine %d times; a restart is the supervisor's, not a second process", applies)
	}
}

func TestSessionFailsWhenTheSupervisorGivesUp(t *testing.T) {
	eng, guard := newFakeEngine(), &fakeGuard{}
	session, err := New(testConfig(eng, guard))
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}
	if err := session.Start(context.Background()); err != nil {
		t.Fatalf("Start() error = %v", err)
	}
	defer func() { _ = session.Stop(context.Background()) }()
	eng.bus.Publish(engine.Event{Kind: engine.EventEngineDown, Err: errors.New("process exited")})
	eng.bus.Publish(engine.Event{Kind: engine.EventFatal, State: engine.StateFailed, Err: errors.New("more than 5 restarts")})
	waitFor(t, 2*time.Second, func() bool { return session.State() == StateFailed })
}

func TestAnEngineStateIsNoSessionState(t *testing.T) {
	eng, guard := newFakeEngine(), &fakeGuard{}
	session, err := New(testConfig(eng, guard))
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}
	if err := session.Start(context.Background()); err != nil {
		t.Fatalf("Start() error = %v", err)
	}
	defer func() { _ = session.Stop(context.Background()) }()
	// Hot reload engine states must not change the session's connected
	// state in the journal.
	eng.bus.Publish(engine.Event{Kind: engine.EventState, State: engine.StateApplying})
	eng.bus.Publish(engine.Event{Kind: engine.EventState, State: engine.StateRunning, Message: "plan applied"})
	time.Sleep(50 * time.Millisecond)
	for _, ev := range session.Journal().Since(0, 64) {
		if ev.Kind == EventState && ev.State != StateConnecting && ev.State != StateConnected {
			t.Errorf("the journal reports the session %s after an engine state", ev.State)
		}
	}
	if session.State() != StateConnected {
		t.Errorf("state = %s, want connected", session.State())
	}
}

func TestSessionReportsEngineEventsInTheJournal(t *testing.T) {
	eng, guard := newFakeEngine(), &fakeGuard{}
	session, err := New(testConfig(eng, guard))
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}
	if err := session.Start(context.Background()); err != nil {
		t.Fatalf("Start() error = %v", err)
	}
	defer func() { _ = session.Stop(context.Background()) }()

	eng.bus.Publish(engine.Event{Kind: engine.EventLog, Message: "dial tcp 203.0.113.7:443"})
	waitFor(t, time.Second, func() bool {
		for _, ev := range session.Journal().Since(0, 0) {
			if ev.Kind == EventLog && ev.LogLine == "dial tcp 203.0.113.7:443" {
				return true
			}
		}
		return false
	})
}

func TestKillSwitchFollowsTheSession(t *testing.T) {
	eng, guard := newFakeEngine(), &fakeGuard{}
	cfg := testConfig(eng, guard)
	cfg.Settings = Settings{KillSwitch: true, TunnelMode: "system", Bypass: []string{"localhost"}}
	session, err := New(cfg)
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}
	if err := session.Start(context.Background()); err != nil {
		t.Fatalf("Start() error = %v", err)
	}
	status := session.Status()
	if !status.KillSwitch || status.TunnelMode != "system" {
		t.Errorf("status = %+v, want the requested settings", status)
	}
	if err := session.SetKillSwitch(context.Background(), false); err != nil {
		t.Fatalf("SetKillSwitch(false) error = %v", err)
	}
	if guard.Current().KillSwitch {
		t.Error("the guard still reports an armed kill switch")
	}
	if err := session.Stop(context.Background()); err != nil {
		t.Fatalf("Stop() error = %v", err)
	}
	if err := session.SetKillSwitch(context.Background(), true); errs.KeyOf(err) != errs.KeySessionRequired {
		t.Errorf("arming the kill switch on a stopped session = %v, key = %q", err, errs.KeyOf(err))
	}
}

// waitFor polls until cond succeeds or times out, allowing the session
// goroutine to update state independently.
func waitFor(t *testing.T, budget time.Duration, cond func() bool) {
	t.Helper()
	deadline := time.Now().Add(budget)
	for time.Now().Before(deadline) {
		if cond() {
			return
		}
		time.Sleep(2 * time.Millisecond)
	}
	t.Fatalf("condition did not hold within %s", budget)
}

func TestSessionRefusesAnEngineThatRunsWithoutItsAdapter(t *testing.T) {
	eng, guard := newFakeEngine(), &fakeGuard{}
	cfg := testConfig(eng, guard)
	cfg.Plan.Tun = engine.Tun{Enabled: true, DeviceName: engine.TunDevice}
	var asked string
	cfg.TunUp = func(_ context.Context, device string) error {
		asked = device
		return errs.Newf(errs.CodeFailedPrecondition, errs.KeyPlanTunnel, "no adapter")
	}
	session, err := New(cfg)
	if err != nil {
		t.Fatal(err)
	}
	err = session.Start(context.Background())
	if errs.KeyOf(err) != errs.KeyPlanTunnel {
		t.Fatalf("Start() = %v, want the tunnel refusal", err)
	}
	if asked != engine.TunDevice {
		t.Errorf("the session waited for %q, want %q", asked, engine.TunDevice)
	}
	if session.State() == StateConnected {
		t.Error("a session without its adapter must not report connected")
	}
	eng.mu.Lock()
	stops := eng.stops
	eng.mu.Unlock()
	if stops == 0 {
		t.Error("the engine kept running after the adapter failed to come up")
	}
	if _, restored := guard.snapshot(); restored == 0 {
		t.Error("the guard was not restored")
	}
}
