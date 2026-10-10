package session

import (
	"context"
	"errors"
	"testing"
)

func TestCompositeGuardRetriesEveryOwnedPartAfterRestorationFailure(t *testing.T) {
	first, last := &fakeGuard{}, &fakeGuard{}
	guard := NewCompositeGuard(first, last)
	ctx := context.Background()
	if err := guard.Apply(ctx, Settings{KillSwitch: true}); err != nil {
		t.Fatal(err)
	}
	last.restoreEr = errors.New("temporary firewall error")
	if err := guard.Restore(ctx); err == nil {
		t.Fatal("restoration failure was hidden")
	}
	if first.Current().KillSwitch || !last.Current().KillSwitch {
		t.Fatal("failed part or remaining cleanup was lost")
	}
	last.restoreEr = nil
	if err := guard.Restore(ctx); err != nil {
		t.Fatal(err)
	}
	if last.Current().KillSwitch {
		t.Fatal("retry did not release the failed part")
	}
}

func TestPartialApplyKeepsOwnershipWhenRollbackFails(t *testing.T) {
	first := &fakeGuard{restoreEr: errors.New("rollback failed")}
	last := &fakeGuard{applyErr: errors.New("proxy apply failed")}
	guard := NewCompositeGuard(first, last)
	ctx := context.Background()
	manager, _ := testManager(t, guard)
	if _, err := manager.Connect(ctx, testPlan("partial"), Settings{KillSwitch: true}); err == nil {
		t.Fatal("partial failure was hidden")
	}
	if manager.Current() == nil || !first.Current().KillSwitch {
		t.Fatal("partial guard apply lost cleanup ownership")
	}
	first.restoreEr = nil
	if err := manager.Disconnect(ctx); err != nil {
		t.Fatal(err)
	}
	if first.Current().KillSwitch {
		t.Fatal("retry did not restore partially applied settings")
	}
}
