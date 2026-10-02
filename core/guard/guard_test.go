package guard_test

import (
	"context"
	"errors"
	"testing"

	"github.com/levvs-one/sora-client/core/errs"
	"github.com/levvs-one/sora-client/core/guard"
	"github.com/levvs-one/sora-client/core/session"
)

// memoryProxy is a proxy that records what it was told, so the guard can be tested
// without changing anything on the machine running the tests.
type memoryProxy struct {
	applied  []string
	restores int
	current  string
	applyErr error
}

func (p *memoryProxy) Apply(_ context.Context, address string) error {
	if p.applyErr != nil {
		return p.applyErr
	}
	p.applied = append(p.applied, address)
	p.current = address
	return nil
}

func (p *memoryProxy) Restore(context.Context) error {
	p.restores++
	p.current = ""
	return nil
}

func (p *memoryProxy) Current(context.Context) (string, error) { return p.current, nil }

// memoryFirewall is a firewall that records whether it was armed.
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
	return guard.Options{ProxyAddress: "127.0.0.1:7890", EnginePorts: []uint16{7890, 7891}}
}

func TestNewRefusesAGuardThatCouldNotWork(t *testing.T) {
	if _, err := guard.New(guard.Options{EnginePorts: []uint16{7890}}, nil, nil); errs.CodeOf(err) != errs.CodeInvalidArgument {
		t.Errorf("a guard without a proxy address = %v", err)
	}
	if _, err := guard.New(guard.Options{ProxyAddress: "127.0.0.1:7890"}, nil, nil); errs.CodeOf(err) != errs.CodeInvalidArgument {
		t.Errorf("a guard without engine ports = %v", err)
	}
}

func TestGuardArmsBeforeItPointsTheProxy(t *testing.T) {
	proxy, firewall := &memoryProxy{}, &memoryFirewall{}
	system, err := guard.New(testOptions(), proxy, firewall)
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}
	settings := session.Settings{KillSwitch: true, SystemProxy: true, TunnelMode: "system"}
	if err := system.Apply(context.Background(), settings); err != nil {
		t.Fatalf("Apply() error = %v", err)
	}
	if len(proxy.applied) != 1 || proxy.applied[0] != "127.0.0.1:7890" {
		t.Errorf("the proxy was pointed at %v", proxy.applied)
	}
	if firewall.arms != 1 || !firewall.armed {
		t.Errorf("the kill switch was armed %d times", firewall.arms)
	}
	if len(firewall.ports) != 2 {
		t.Errorf("the kill switch kept %d ports open, want 2", len(firewall.ports))
	}

	if err := system.Apply(context.Background(), settings); err != nil {
		t.Fatalf("second Apply() error = %v", err)
	}
	if len(proxy.applied) != 1 {
		t.Errorf("applying twice pointed the proxy %d times", len(proxy.applied))
	}
	if firewall.arms != 1 {
		t.Errorf("arming twice added the rule %d times", firewall.arms)
	}
}

func TestGuardRestoresOnlyWhatItArmed(t *testing.T) {
	proxy, firewall := &memoryProxy{}, &memoryFirewall{}
	system, err := guard.New(testOptions(), proxy, firewall)
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}
	if err := system.Restore(context.Background()); err != nil {
		t.Fatalf("Restore() without Apply error = %v", err)
	}
	if proxy.restores != 0 || firewall.disarms != 0 {
		t.Errorf("a guard that armed nothing restored something: proxy=%d firewall=%d",
			proxy.restores, firewall.disarms)
	}

	if err := system.Apply(context.Background(), session.Settings{KillSwitch: true, SystemProxy: true}); err != nil {
		t.Fatalf("Apply() error = %v", err)
	}
	if err := system.Restore(context.Background()); err != nil {
		t.Fatalf("Restore() error = %v", err)
	}
	if proxy.restores != 1 || firewall.disarms != 1 {
		t.Errorf("restores: proxy=%d firewall=%d, want one each", proxy.restores, firewall.disarms)
	}
	if firewall.armed {
		t.Error("the kill switch is still armed after a restore")
	}
	if got := system.Current(); got.KillSwitch || got.SystemProxy {
		t.Errorf("the guard still reports %+v after a restore", got)
	}
	if err := system.Restore(context.Background()); err != nil {
		t.Errorf("restoring twice = %v", err)
	}
	if firewall.disarms != 1 {
		t.Errorf("restoring twice disarmed %d times", firewall.disarms)
	}
}

func TestGuardRemovesTheBlockWhenTheProxyFails(t *testing.T) {
	proxy := &memoryProxy{applyErr: errors.New("the key is locked")}
	firewall := &memoryFirewall{}
	system, err := guard.New(testOptions(), proxy, firewall)
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}
	err = system.Apply(context.Background(), session.Settings{KillSwitch: true, SystemProxy: true})
	if errs.KeyOf(err) != errs.KeyGuardProxyFailed {
		t.Fatalf("Apply() = %v, key = %q", err, errs.KeyOf(err))
	}
	if firewall.armed {
		t.Error("the kill switch stayed armed although the proxy could not be set, which would cut the machine off")
	}
}

func TestGuardArmsOnlyWhatWasAskedFor(t *testing.T) {
	proxy, firewall := &memoryProxy{}, &memoryFirewall{}
	system, err := guard.New(testOptions(), proxy, firewall)
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}
	if err := system.Apply(context.Background(), session.Settings{SystemProxy: true}); err != nil {
		t.Fatalf("Apply() error = %v", err)
	}
	if firewall.arms != 0 {
		t.Error("the guard armed a kill switch nobody asked for")
	}
	if err := system.Restore(context.Background()); err != nil {
		t.Fatalf("Restore() error = %v", err)
	}
	if firewall.disarms != 0 {
		t.Error("the guard removed a kill switch it never armed")
	}
}

func TestGuardNameIsStable(t *testing.T) {
	system, err := guard.New(testOptions(), nil, nil)
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}
	if system.Name() != "sora-guard" {
		t.Errorf("Name() = %q, want sora-guard", system.Name())
	}
}
