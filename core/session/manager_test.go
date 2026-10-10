package session

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/errs"
)

func testManager(t *testing.T, guard Guard) (*Manager, *fakeEngine) {
	t.Helper()
	eng := newFakeEngine()
	manager := NewManager(ManagerConfig{
		Factory: func(context.Context, *engine.Plan) (engine.Engine, error) { return eng, nil },
		Guard:   guard,
	})
	return manager, eng
}

func TestManagerKeepsOneSessionAtATime(t *testing.T) {
	guard := &fakeGuard{}
	manager, eng := testManager(t, guard)
	ctx := context.Background()

	first, err := manager.Connect(ctx, testPlan("session-1"), Settings{KillSwitch: true})
	if err != nil {
		t.Fatalf("first Connect() error = %v", err)
	}
	if manager.Current() != first {
		t.Error("the manager does not hold the session it started")
	}

	second, err := manager.Connect(ctx, testPlan("session-2"), Settings{KillSwitch: true})
	if err != nil {
		t.Fatalf("second Connect() error = %v", err)
	}
	if first.State() != StateDisconnected {
		t.Errorf("the first session is %s, want disconnected after the second connect", first.State())
	}
	if manager.Current() != second {
		t.Error("the manager kept the replaced session")
	}
	if status := manager.Status(); status.SessionID != "session-2" {
		t.Errorf("status session = %q, want session-2", status.SessionID)
	}
	if _, stops, _ := eng.counts(); stops != 1 {
		t.Errorf("the replaced session stopped the engine %d times, want once", stops)
	}
	if err := manager.Disconnect(ctx); err != nil {
		t.Fatalf("Disconnect() error = %v", err)
	}
	if manager.Current() != nil {
		t.Error("the manager still holds a session after Disconnect")
	}
	if err := manager.Disconnect(ctx); err != nil {
		t.Errorf("disconnecting twice = %v", err)
	}
}

func TestManagerReportsAFailedStart(t *testing.T) {
	guard := &fakeGuard{}
	manager, eng := testManager(t, guard)
	eng.apply = errors.New("engine binary is missing")

	session, err := manager.Connect(context.Background(), testPlan("session-1"), Settings{})
	if err == nil {
		t.Fatal("Connect() must fail when the engine refuses the plan")
	}
	if session != nil {
		t.Error("Connect() returned a session together with an error")
	}
	if manager.Current() != nil {
		t.Error("a failed session became the current one")
	}
	if status := manager.Status(); status.State != StateFailed {
		t.Errorf("status state = %s, want failed", status.State)
	}
	applied, restores := guard.snapshot()
	if applied != restores {
		t.Errorf("guard applied=%d restored=%d, they must match", applied, restores)
	}
}

func TestManagerSurvivesAnEngineFactoryFailure(t *testing.T) {
	manager := NewManager(ManagerConfig{
		Factory: func(context.Context, *engine.Plan) (engine.Engine, error) {
			return nil, errs.Newf(errs.CodeNotFound, errs.KeyEngineBinaryMissing, "no engine for this platform")
		},
	})
	_, err := manager.Connect(context.Background(), testPlan("session-1"), Settings{})
	if errs.KeyOf(err) != errs.KeyEngineBinaryMissing {
		t.Fatalf("Connect() = %v, key = %q", err, errs.KeyOf(err))
	}
	if manager.Current() != nil {
		t.Error("a factory failure left a session behind")
	}
	if status := manager.Status(); status.State != StateDisconnected {
		t.Errorf("status state = %s, want disconnected", status.State)
	}
}

func TestManagerKeepsTheTunnelWhenAnEngineSwitchIsRejected(t *testing.T) {
	eng := newFakeEngine()
	manager := NewManager(ManagerConfig{
		Factory: func(_ context.Context, p *engine.Plan) (engine.Engine, error) {
			if p.SessionID == "unsupported" {
				return nil, errs.Newf(errs.CodeFailedPrecondition, errs.KeyEngineBinaryMissing, "sing-box cannot carry XHTTP")
			}
			return eng, nil
		},
	})
	ctx := context.Background()
	first, err := manager.Connect(ctx, testPlan("running"), Settings{})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = manager.Disconnect(ctx) })
	if _, err := manager.Connect(ctx, testPlan("unsupported"), Settings{}); errs.KeyOf(err) != errs.KeyEngineBinaryMissing {
		t.Fatalf("switch = %v", err)
	}
	if manager.Current() != first || first.State() != StateConnected {
		t.Fatal("a rejected engine switch lost the running tunnel")
	}
	if err := manager.Disconnect(ctx); err != nil {
		t.Fatal(err)
	}
	if manager.Status().State != StateDisconnected || eng.State() != engine.StateStopped {
		t.Fatal("disconnect after a rejected switch did not stop the tunnel")
	}
}

func TestManagerRetriesRestorationAfterAFailedDisconnect(t *testing.T) {
	guard := &fakeGuard{}
	manager, _ := testManager(t, guard)
	ctx := context.Background()
	first, err := manager.Connect(ctx, testPlan("running"), Settings{KillSwitch: true})
	if err != nil {
		t.Fatal(err)
	}
	guard.restoreEr = errors.New("temporary firewall failure")
	if err := manager.Disconnect(ctx); err == nil {
		t.Fatal("a failed restoration must be reported")
	}
	if manager.Current() != first {
		t.Fatal("failed cleanup lost the session that owns the firewall")
	}
	guard.restoreEr = nil
	if err := manager.Disconnect(ctx); err != nil {
		t.Fatal(err)
	}
	if manager.Current() != nil || guard.Current().KillSwitch {
		t.Fatal("the second disconnect did not release the firewall")
	}
}

func TestInvalidReplacementKeepsTheCurrentSession(t *testing.T) {
	old, next := newFakeEngine(), newFakeEngine()
	next.validate = errors.New("invalid replacement configuration")
	manager := NewManager(ManagerConfig{Factory: func(_ context.Context, p *engine.Plan) (engine.Engine, error) {
		if p.SessionID == "bad" {
			return next, nil
		}
		return old, nil
	}})
	ctx := context.Background()
	first, err := manager.Connect(ctx, testPlan("running"), Settings{})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = manager.Disconnect(ctx) })
	if _, err := manager.Connect(ctx, testPlan("bad"), Settings{}); err == nil {
		t.Fatal("an invalid replacement must fail")
	}
	if manager.Current() != first || old.State() != engine.StateRunning {
		t.Fatal("validation of a replacement stopped the current engine")
	}
}

func TestManagerRejectsConcurrentCommands(t *testing.T) {
	release = make(chan struct{})
	manager := NewManager(ManagerConfig{
		Factory: func(context.Context, *engine.Plan) (engine.Engine, error) {
			// Block the factory to check that concurrent commands
			// cannot enter the active operation.
			<-release
			return newFakeEngine(), nil
		},
	})
	// Read busy under the same lock used for writes.
	busy := func() bool {
		manager.mu.Lock()
		defer manager.mu.Unlock()
		return manager.busy
	}
	go func() {
		_, _ = manager.Connect(context.Background(), testPlan("session-1"), Settings{})
	}()
	waitFor(t, time.Second, busy)
	if _, err := manager.Connect(context.Background(), testPlan("session-2"), Settings{}); errs.KeyOf(err) != errs.KeySessionBusy {
		t.Errorf("a second Connect() = %v, key = %q", err, errs.KeyOf(err))
	}
	if err := manager.Disconnect(context.Background()); errs.KeyOf(err) != errs.KeySessionBusy {
		t.Errorf("Disconnect() during a connect = %v, key = %q", err, errs.KeyOf(err))
	}
	close(release)
	waitFor(t, time.Second, func() bool { return !busy() })
}

func TestFailedStartupKeepsTheOwnerOfUnrestoredSettings(t *testing.T) {
	guard := &fakeGuard{restoreEr: errors.New("temporary cleanup failure")}
	manager, eng := testManager(t, guard)
	eng.apply = errors.New("startup failure")
	ctx := context.Background()
	if _, err := manager.Connect(ctx, testPlan("failed"), Settings{KillSwitch: true}); errs.KeyOf(err) != errs.KeyGuardRestoreFailed {
		t.Fatalf("cleanup failure must remain actionable: %v", err)
	}
	if manager.Current() == nil || !guard.Current().KillSwitch {
		t.Fatal("failed startup lost ownership of remaining settings")
	}
	guard.restoreEr = nil
	if err := manager.Disconnect(ctx); err != nil {
		t.Fatal(err)
	}
	if manager.Current() != nil || guard.Current().KillSwitch {
		t.Fatal("disconnect did not restore settings left by failed startup")
	}
}

// release gates the blocking engine factory of the concurrency test.
var release chan struct{}
