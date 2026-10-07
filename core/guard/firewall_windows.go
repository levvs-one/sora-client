//go:build windows

package guard

import (
	"context"
	"net/netip"
	"os"
	"path/filepath"
	"sync"

	"github.com/tailscale/wf"
	"golang.org/x/sys/windows"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/errs"
)

// WFP is the kill switch on Windows: filters of the Windows Filtering Platform
// in a sublayer of its own. Whatever goes out is blocked unless it is the
// engine or the core itself, goes through the tunnel adapter, stays on the
// machine or on its local network, or is DHCP and neighbour discovery the
// network needs to stay up.
//
// The session is dynamic: Windows removes every filter when the session closes
// or the core process ends, however it ends. A crashed core lets traffic out
// rather than leaving the machine cut off with nothing left to lift the block —
// the same trade WireGuard and Tailscale make.
type WFP struct {
	mu         sync.Mutex
	enginesDir string
	bypass     []netip.Prefix
	session    *wf.Session
}

// PlatformFirewall returns the kill switch this platform has. Windows has no
// user id to match the engine by, so the engine is matched by its executable.
func PlatformFirewall(opts FirewallOptions) (Firewall, error) {
	bypass := opts.Bypass
	if len(bypass) == 0 {
		bypass = DefaultBypassNetworks()
	}
	prefixes := make([]netip.Prefix, 0, len(bypass))
	for _, network := range bypass {
		prefix, err := netip.ParsePrefix(network)
		if err != nil {
			return nil, errs.Newf(errs.CodeInvalidArgument, errs.KeyGuardFirewallFail,
				"guard: the bypass network %q is not a network", network)
		}
		prefixes = append(prefixes, prefix.Masked())
	}
	return &WFP{enginesDir: opts.EnginesDir, bypass: prefixes}, nil
}

// Rule weights inside the sublayer: every permit outranks the final block.
const (
	weightPermit = 10
	weightBlock  = 0
)

var outbound = []wf.LayerID{wf.LayerALEAuthConnectV4, wf.LayerALEAuthConnectV6}

// Arm installs the filters. Arming an armed switch changes nothing.
func (w *WFP) Arm(context.Context, []uint16) error {
	w.mu.Lock()
	defer w.mu.Unlock()
	if w.session != nil {
		return nil
	}
	session, err := wf.New(&wf.Options{
		Name:        "Sora kill switch",
		Description: "Blocks traffic that does not go through the Sora tunnel",
		Dynamic:     true,
	})
	if err != nil {
		return refused(err)
	}
	if err := w.install(session); err != nil {
		_ = session.Close()
		return refused(err)
	}
	w.session = session
	return nil
}

// Disarm removes the filters by closing the session that owns them.
func (w *WFP) Disarm(context.Context) error {
	w.mu.Lock()
	defer w.mu.Unlock()
	if w.session == nil {
		return nil
	}
	err := w.session.Close()
	w.session = nil
	if err != nil {
		return refused(err)
	}
	return nil
}

// Armed reports whether this process holds the filters.
func (w *WFP) Armed(context.Context) (bool, error) {
	w.mu.Lock()
	defer w.mu.Unlock()
	return w.session != nil, nil
}

// Name identifies the implementation in a diagnostics line.
func (w *WFP) Name() string { return "wfp" }

func (w *WFP) install(session *wf.Session) error {
	guid, err := windows.GenerateGUID()
	if err != nil {
		return err
	}
	sublayer := wf.SublayerID(guid)
	// The highest weight: this sublayer is consulted before the ones other
	// programs add, and a block here holds whatever they permit.
	if err := session.AddSublayer(&wf.Sublayer{ID: sublayer, Name: "Sora kill switch", Weight: 0xffff}); err != nil {
		return err
	}
	add := func(name string, action wf.Action, weight uint64, conditions ...*wf.Match) error {
		for _, layer := range outbound {
			if !applies(layer, conditions) {
				continue
			}
			guid, err := windows.GenerateGUID()
			if err != nil {
				return err
			}
			if err := session.AddRule(&wf.Rule{
				ID: wf.RuleID(guid), Name: "Sora: " + name, Layer: layer, Sublayer: sublayer,
				Weight: weight, Conditions: conditions, Action: action,
			}); err != nil {
				return err
			}
		}
		return nil
	}
	permit := func(name string, conditions ...*wf.Match) error {
		return add(name, wf.ActionPermit, weightPermit, conditions...)
	}

	apps, err := w.executables()
	if err != nil {
		return err
	}
	for _, file := range apps {
		id, err := wf.AppID(file)
		if err != nil {
			return err
		}
		if err := permit(filepath.Base(file), &wf.Match{Field: wf.FieldALEAppID, Op: wf.MatchTypeEqual, Value: id}); err != nil {
			return err
		}
	}
	if err := permit("loopback", &wf.Match{Field: wf.FieldFlags, Op: wf.MatchTypeFlagsAllSet, Value: wf.ConditionFlagIsLoopback}); err != nil {
		return err
	}
	for _, network := range engine.TunNetworks {
		if err := permit("through the tunnel", &wf.Match{Field: wf.FieldIPLocalAddress, Op: wf.MatchTypeEqual, Value: netip.MustParsePrefix(network)}); err != nil {
			return err
		}
	}
	for _, network := range w.bypass {
		if err := permit("local network", &wf.Match{Field: wf.FieldIPRemoteAddress, Op: wf.MatchTypeEqual, Value: network}); err != nil {
			return err
		}
	}
	// DHCP and neighbour discovery keep the physical network configured; without
	// them a lease that expires while the switch is armed takes the tunnel
	// down with it.
	udp := &wf.Match{Field: wf.FieldIPProtocol, Op: wf.MatchTypeEqual, Value: wf.IPProtoUDP}
	if err := permit("DHCP",
		udp,
		&wf.Match{Field: wf.FieldIPLocalPort, Op: wf.MatchTypeEqual, Value: uint16(68)},
		&wf.Match{Field: wf.FieldIPRemotePort, Op: wf.MatchTypeEqual, Value: uint16(67)},
		&wf.Match{Field: wf.FieldIPRemoteAddress, Op: wf.MatchTypeEqual, Value: netip.MustParsePrefix("255.255.255.255/32")},
	); err != nil {
		return err
	}
	// The servers' multicast group: the rule is IPv6 only, and port 546 on its
	// own would let any program reach any address on 547.
	if err := permit("DHCPv6",
		udp,
		&wf.Match{Field: wf.FieldIPLocalPort, Op: wf.MatchTypeEqual, Value: uint16(546)},
		&wf.Match{Field: wf.FieldIPRemotePort, Op: wf.MatchTypeEqual, Value: uint16(547)},
		&wf.Match{Field: wf.FieldIPRemoteAddress, Op: wf.MatchTypeEqual, Value: netip.MustParsePrefix("ff02::1:2/128")},
	); err != nil {
		return err
	}
	for _, kind := range []uint16{133, 135, 136} {
		// For ICMP the local port field carries the message type.
		if err := permit("neighbour discovery",
			&wf.Match{Field: wf.FieldIPProtocol, Op: wf.MatchTypeEqual, Value: wf.IPProtoICMPV6},
			&wf.Match{Field: wf.FieldIPLocalPort, Op: wf.MatchTypeEqual, Value: kind},
		); err != nil {
			return err
		}
	}
	return add("everything else", wf.ActionBlock, weightBlock)
}

// executables are the programs whose traffic is the tunnel's own: every engine
// in the engines directory, and the core, which updates subscriptions and
// measures servers.
func (w *WFP) executables() ([]string, error) {
	self, err := os.Executable()
	if err != nil {
		return nil, err
	}
	files := []string{self}
	engines, err := filepath.Glob(filepath.Join(w.enginesDir, "*.exe"))
	if err != nil {
		return nil, err
	}
	return append(files, engines...), nil
}

// applies keeps an address condition to the layer of its family: an IPv4
// network on the IPv6 layer is refused by the filtering engine.
func applies(layer wf.LayerID, conditions []*wf.Match) bool {
	for _, c := range conditions {
		if prefix, ok := c.Value.(netip.Prefix); ok {
			if prefix.Addr().Is4() != (layer == wf.LayerALEAuthConnectV4) {
				return false
			}
		}
		if c.Value == wf.IPProtoICMPV6 && layer == wf.LayerALEAuthConnectV4 {
			return false
		}
	}
	return true
}

func refused(err error) error {
	return errs.Newf(errs.CodePermissionDenied, errs.KeyGuardFirewallFail,
		"guard: the filtering platform refused the kill switch: %v", err)
}
