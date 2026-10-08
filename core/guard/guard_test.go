package guard_test

import (
	"context"
	"errors"
	"testing"

	"github.com/levvs-one/sora-client/core/errs"
	"github.com/levvs-one/sora-client/core/guard"
	"github.com/levvs-one/sora-client/core/session"
)

// memoryFirewall records armed state for tests without modifying the host
// firewall.
type memoryFirewall struct {
	armed   bool
	arms    int
	disarms int
	ports   []uint16
	armErr  error
}

func (f *memoryFirewall) Arm(_ context.Context, ports []uint16) error {
	if f.armErr != nil {
		return f.armErr
	}
	f.arms++
	f.armed = true
	f.ports = append([]uint16(nil), ports...)
	return nil
}

func (f *memoryFirewall) Disarm(context.Context) error {
	f.disarms++
	f.armed = false
	return nil
}

func (f *memoryFirewall) Armed(context.Context) (bool, error) { return f.armed, nil }

func testOptions() guard.Options {
	return guard.Options{EnginePorts: []uint16{7890, 7891}}
}

func TestNewRefusesAGuardThatCouldNotWork(t *testing.T) {
	if _, err := guard.New(guard.Options{}, nil); errs.CodeOf(err) != errs.CodeInvalidArgument {
		t.Errorf("a guard without engine ports = %v", err)
	}
}

func TestGuardArmsOnce(t *testing.T) {
	firewall := &memoryFirewall{}
	system, err := guard.New(testOptions(), firewall)
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}
	settings := session.Settings{KillSwitch: true, TunnelMode: "system"}
	for range 2 {
		if err := system.Apply(context.Background(), settings); err != nil {
			t.Fatalf("Apply() error = %v", err)
		}
	}
	if firewall.arms != 1 || !firewall.armed {
		t.Errorf("the kill switch was armed %d times", firewall.arms)
	}
	if len(firewall.ports) != 2 {
		t.Errorf("the kill switch kept %d ports open, want 2", len(firewall.ports))
	}
}

func TestGuardLiftsTheSwitchWhenItIsTurnedOff(t *testing.T) {
	firewall := &memoryFirewall{}
	system, err := guard.New(testOptions(), firewall)
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}
	if err := system.Apply(context.Background(), session.Settings{KillSwitch: true}); err != nil {
		t.Fatalf("Apply() error = %v", err)
	}
	if err := system.Apply(context.Background(), session.Settings{}); err != nil {
		t.Fatalf("Apply() without the switch = %v", err)
	}
	if firewall.armed || firewall.disarms != 1 {
		t.Errorf("turning the switch off: armed=%v disarms=%d", firewall.armed, firewall.disarms)
	}
}

func TestGuardRestoresOnlyWhatItArmed(t *testing.T) {
	firewall := &memoryFirewall{}
	system, err := guard.New(testOptions(), firewall)
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}
	if err := system.Restore(context.Background()); err != nil {
		t.Fatalf("Restore() without Apply error = %v", err)
	}
	if firewall.disarms != 0 {
		t.Errorf("a guard that armed nothing disarmed %d times", firewall.disarms)
	}
	if err := system.Apply(context.Background(), session.Settings{KillSwitch: true}); err != nil {
		t.Fatalf("Apply() error = %v", err)
	}
	if err := system.Restore(context.Background()); err != nil {
		t.Fatalf("Restore() error = %v", err)
	}
	if firewall.armed || firewall.disarms != 1 {
		t.Errorf("after a restore: armed=%v disarms=%d", firewall.armed, firewall.disarms)
	}
	if got := system.Current(); got.KillSwitch {
		t.Errorf("the guard still reports %+v after a restore", got)
	}
	if err := system.Restore(context.Background()); err != nil {
		t.Errorf("restoring twice = %v", err)
	}
	if firewall.disarms != 1 {
		t.Errorf("restoring twice disarmed %d times", firewall.disarms)
	}
}

func TestGuardReportsAFirewallThatRefuses(t *testing.T) {
	firewall := &memoryFirewall{armErr: errors.New("the filtering engine is busy")}
	system, err := guard.New(testOptions(), firewall)
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}
	err = system.Apply(context.Background(), session.Settings{KillSwitch: true})
	if errs.KeyOf(err) != errs.KeyGuardFirewallFail {
		t.Fatalf("Apply() = %v, key = %q", err, errs.KeyOf(err))
	}
	if system.Current().KillSwitch {
		t.Error("the guard reports a switch that was never armed")
	}
}

func testContext() context.Context { return context.Background() }

func TestGuardNameIsStable(t *testing.T) {
	system, err := guard.New(testOptions(), nil)
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}
	if system.Name() != "sora-guard" {
		t.Errorf("Name() = %q, want sora-guard", system.Name())
	}
}
