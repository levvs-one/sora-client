package session

import (
	"context"
	"net"
	"net/netip"
	"slices"
	"strings"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/errs"
)

// DefaultNetworkInterval is how often a connected session looks at the network.
// A look is one call that lists the interfaces, cheap enough to make every two
// seconds, and two seconds is short enough that a person who changed networks
// finds their connections working again before they notice they were not.
const DefaultNetworkInterval = 2 * time.Second

// NetworkFingerprint names the networks the machine is on: the up interfaces
// other than loopback and the tunnel, with their IPv4 addresses and the /64 of
// their global IPv6 ones. It changes when Wi-Fi changes, a cable is plugged in or
// a lease brings a new address, and not when IPv6 privacy addresses rotate inside
// the same network. Empty means no network at all.
func NetworkFingerprint() string {
	interfaces, err := net.Interfaces()
	if err != nil {
		return ""
	}
	var parts []string
	for _, iface := range interfaces {
		if iface.Flags&net.FlagUp == 0 || iface.Flags&net.FlagLoopback != 0 || iface.Name == engine.TunDevice {
			continue
		}
		addrs, err := iface.Addrs()
		if err != nil {
			continue
		}
		for _, a := range addrs {
			network, ok := a.(*net.IPNet)
			if !ok {
				continue
			}
			addr, ok := netip.AddrFromSlice(network.IP)
			if !ok {
				continue
			}
			addr = addr.Unmap()
			if slices.ContainsFunc(tunPrefixes, func(p netip.Prefix) bool { return p.Contains(addr) }) {
				continue
			}
			switch {
			case addr.Is4():
				parts = append(parts, iface.Name+" "+addr.String())
			case addr.IsGlobalUnicast():
				prefix, _ := addr.Prefix(64)
				parts = append(parts, iface.Name+" "+prefix.String())
			}
		}
	}
	slices.Sort(parts)
	return strings.Join(slices.Compact(parts), ",")
}

var tunPrefixes = func() []netip.Prefix {
	out := make([]netip.Prefix, len(engine.TunNetworks))
	for i, n := range engine.TunNetworks {
		out[i] = netip.MustParsePrefix(n)
	}
	return out
}()

// networkWatch notices that the way out changed under a running session: another
// network, or the machine waking from sleep. Connections opened over the old
// path are dead either way, and an application waits minutes for a dead TCP
// connection to time out unless someone closes it.
type networkWatch struct {
	probe    func() string
	interval time.Duration
	last     string
	// The last look on each clock: lastWall without the monotonic reading,
	// lastMono with it.
	lastWall, lastMono time.Time
}

// sleepGap is how much more the wall clock has to advance than the monotonic
// one between two looks to count as a sleep. A look that came late because
// the session was busy moves both clocks alike and is no sleep.
const sleepGap = 30 * time.Second

func newNetworkWatch(probe func() string, interval time.Duration) *networkWatch {
	now := time.Now()
	return &networkWatch{probe: probe, interval: interval, last: probe(), lastWall: now.Round(0), lastMono: now}
}

// changed reports why the session should renew its connections, or "".
func (w *networkWatch) changed() string {
	now := time.Now()
	// The monotonic clock stops while the machine sleeps and the wall clock
	// does not.
	slept := now.Round(0).Sub(w.lastWall)-now.Sub(w.lastMono) > sleepGap
	w.lastWall, w.lastMono = now.Round(0), now
	current := w.probe()
	moved := current != w.last && current != ""
	w.last = current
	switch {
	case slept:
		return "the machine woke from sleep"
	case moved:
		return "the network changed"
	}
	return ""
}

// renewConnections drops the connections a changed network left dead, so every
// application opens new ones at once. An engine that cannot drop them all is
// moved onto the plan again, which Xray does by starting over.
func (s *Session) renewConnections(ctx context.Context, why string) {
	if s.State() != StateConnected {
		return
	}
	s.log.Append(Event{Kind: EventLog, Detail: why + "; connections reopen"})
	if tracker, ok := s.eng.(engine.ConnectionTracker); ok {
		if err := tracker.CloseConnections(ctx); err == nil {
			return
		}
	}
	if err := s.eng.Apply(ctx, s.cfg.Plan); err != nil {
		s.log.Append(Event{
			Kind:   EventError,
			Reason: errs.CodeUnavailable,
			Key:    errs.KeyEngineStartFailed,
			Detail: s.mask(err.Error()),
		})
	}
}
