package session

import (
	"context"
	"strings"
	"sync"
	"sync/atomic"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
)

// sequence answers a fixed run of fingerprints, then keeps the last one.
func sequence(values ...string) func() string {
	var mu sync.Mutex
	return func() string {
		mu.Lock()
		defer mu.Unlock()
		v := values[0]
		if len(values) > 1 {
			values = values[1:]
		}
		return v
	}
}

func TestNetworkWatchSeesAnotherNetworkAndAReturn(t *testing.T) {
	w := newNetworkWatch(sequence("wifi-a", "wifi-a", "wifi-b", "", "wifi-b"), time.Hour)
	var got []string
	for range 4 {
		got = append(got, w.changed())
	}
	want := []string{"", "the network changed", "", "the network changed"}
	for i := range want {
		if got[i] != want[i] {
			t.Errorf("look %d = %q, want %q", i+1, got[i], want[i])
		}
	}
}

func TestNetworkWatchSeesASleep(t *testing.T) {
	w := newNetworkWatch(sequence("wifi-a"), time.Second)
	// A sleep: an hour on the wall clock between two looks, none on the
	// monotonic one.
	w.lastWall = w.lastWall.Add(-time.Hour)
	if why := w.changed(); why != "the machine woke from sleep" {
		t.Errorf("after an hour away: %q", why)
	}
	if why := w.changed(); why != "" {
		t.Errorf("right after: %q", why)
	}
}

func TestALateLookIsNoSleep(t *testing.T) {
	w := newNetworkWatch(sequence("wifi-a"), time.Second)
	// A minute on both clocks: the session was busy, the machine was awake.
	w.lastWall = w.lastWall.Add(-time.Minute)
	w.lastMono = w.lastMono.Add(-time.Minute)
	if why := w.changed(); why != "" {
		t.Errorf("a late look counted as %q", why)
	}
}

func TestNetworkFingerprintLeavesOutLoopbackAndTheTunnel(t *testing.T) {
	fp := NetworkFingerprint()
	for _, unwanted := range []string{"127.0.0.1", engine.TunDevice + " "} {
		if strings.Contains(fp, unwanted) {
			t.Errorf("the fingerprint %q holds %q", fp, unwanted)
		}
	}
}

// trackingEngine is the fake engine that can also drop every connection.
type trackingEngine struct {
	*fakeEngine
	resets atomic.Int32
}

func (e *trackingEngine) Connections(context.Context) ([]engine.Connection, error) { return nil, nil }
func (e *trackingEngine) CloseConnection(context.Context, string) error            { return nil }
func (e *trackingEngine) CloseConnections(context.Context) error {
	e.resets.Add(1)
	return nil
}

func TestASessionDropsConnectionsWhenTheNetworkChanges(t *testing.T) {
	eng := &trackingEngine{fakeEngine: newFakeEngine()}
	cfg := testConfig(eng, &fakeGuard{})
	cfg.Network = sequence("wifi-a", "wifi-a", "wifi-b")
	cfg.NetworkInterval = 5 * time.Millisecond
	s, err := New(cfg)
	if err != nil {
		t.Fatal(err)
	}
	if err := s.Start(context.Background()); err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = s.Stop(context.Background()) })
	deadline := time.Now().Add(2 * time.Second)
	for eng.resets.Load() == 0 && time.Now().Before(deadline) {
		time.Sleep(5 * time.Millisecond)
	}
	if n := eng.resets.Load(); n != 1 {
		t.Errorf("connections were dropped %d times, want once", n)
	}
	if applies, _, _ := eng.counts(); applies != 1 {
		t.Errorf("the engine was applied %d times; an engine that can drop connections is not restarted", applies)
	}
}

func TestAnEngineThatCannotDropConnectionsStartsOver(t *testing.T) {
	eng := newFakeEngine()
	cfg := testConfig(eng, &fakeGuard{})
	cfg.Network = sequence("wifi-a", "wifi-b")
	cfg.NetworkInterval = 5 * time.Millisecond
	s, err := New(cfg)
	if err != nil {
		t.Fatal(err)
	}
	if err := s.Start(context.Background()); err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = s.Stop(context.Background()) })
	deadline := time.Now().Add(2 * time.Second)
	for time.Now().Before(deadline) {
		if applies, _, _ := eng.counts(); applies >= 2 {
			return
		}
		time.Sleep(5 * time.Millisecond)
	}
	t.Error("the engine was not moved onto the plan again after the network changed")
}
