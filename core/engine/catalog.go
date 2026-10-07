package engine

import (
	"errors"
	"fmt"
	"sort"
	"strings"
)

// Availability describes an engine build found on this machine.
type Availability struct {
	Kind    Kind
	Path    string
	Version Version
	Usable  bool
	Reason  string
}

// Catalog holds the capability matrix of the engines Sora knows about. The
// matrix is static knowledge about upstream engines; Availability is what the
// machine actually has. Every entry was checked against the engine's own
// validator: mihomo v1.19.32 (-t), sing-box v1.14.2 (check) and Xray-core
// v26.3.27 (run -test). See docs/architecture/engines.md.
var Catalog = map[Kind]Capabilities{
	KindMihomo: {
		Kind:       KindMihomo,
		MinVersion: "1.19.0",
		Protocols: map[Protocol]bool{
			ProtocolVLESS: true, ProtocolVMess: true, ProtocolTrojan: true,
			ProtocolShadowsocks: true, ProtocolHysteria2: true, ProtocolTUIC: true,
			ProtocolWireGuard: true, ProtocolSOCKS5: true, ProtocolHTTP: true,
			ProtocolDirect: true,
		},
		Features: map[Feature]bool{
			FeatureTun: true, FeatureFakeIP: true, FeatureRuleSets: true,
			FeatureProxyProviders: true, FeatureURLTest: true, FeatureLatencyTest: true,
			FeatureHotApply: true, FeatureGeoData: true, FeatureFallbackGroup: true,
			FeatureLoadBalance: true, FeatureXHTTP: true, FeatureVLESSEncrypt: true,
			FeatureAmneziaWG: true, FeaturePrivateControl: true,
		},
	},
	KindSingBox: {
		Kind: KindSingBox,
		// 1.12 introduced the DNS server and rule action formats the renderer
		// writes; the legacy formats are gone in 1.14.
		MinVersion: "1.12.0",
		Protocols: map[Protocol]bool{
			ProtocolVLESS: true, ProtocolVMess: true, ProtocolTrojan: true,
			ProtocolShadowsocks: true, ProtocolHysteria2: true, ProtocolTUIC: true,
			ProtocolWireGuard: true, ProtocolSOCKS5: true, ProtocolHTTP: true,
			ProtocolAnyTLS: true, ProtocolDirect: true,
		},
		Features: map[Feature]bool{
			FeatureTun: true, FeatureFakeIP: true, FeatureRuleSets: true,
			FeatureURLTest: true, FeatureLatencyTest: true, FeatureGeoData: true,
			FeaturePerAppRouting: true, FeatureTLSFragment: true,
		},
	},
	KindXray: {
		Kind: KindXray,
		// Hysteria2, XHTTP and VLESS Encryption are recent; the floor is the
		// build they were verified on, and Sora ships that build itself.
		MinVersion: "26.3.27",
		Protocols: map[Protocol]bool{
			ProtocolVLESS: true, ProtocolVMess: true, ProtocolTrojan: true,
			ProtocolShadowsocks: true, ProtocolHysteria2: true, ProtocolWireGuard: true,
			ProtocolSOCKS5: true, ProtocolHTTP: true, ProtocolDirect: true, ProtocolXrayProfile: true,
		},
		Features: map[Feature]bool{
			// Xray's tun inbound has no routes of its own; the core installs
			// them (see engine/tunroute).
			FeatureTun: true, FeatureURLTest: true, FeatureLoadBalance: true, FeatureLatencyTest: true,
			FeatureGeoData: true, FeatureTLSFragment: true,
			FeatureXHTTP: true, FeatureVLESSEncrypt: true, FeaturePrivateControl: true,
		},
	},
}

// DefaultPreference is the engine order Sora tries when the user has not
// pinned one. sing-box comes first: the smallest memory footprint, a tun
// stack that works the same on every platform and a native Android build.
// Xray carries what nobody else does (XHTTP, VLESS Encryption). mihomo is the
// most complete rule engine and carries fallback groups and providers.
var DefaultPreference = []Kind{KindSingBox, KindXray, KindMihomo}

// PrivatePreference is the order for a plan that allows no controller other
// programs could find. mihomo comes before Xray there: it keeps its controller
// on a private socket, and with it the connection center and the counters,
// while Xray runs without one.
var PrivatePreference = []Kind{KindSingBox, KindMihomo, KindXray}

// ErrNoEngine reports that no available engine carries an outbound or a plan.
var ErrNoEngine = errors.New("engine: no available engine carries this")

// Selection is the engine chosen for a plan.
type Selection struct {
	Kind   Kind
	Reason string
	// Rejected explains every engine that was skipped, in preference order.
	// The interface shows it when the user wonders why another engine was
	// picked or why an engine cannot be chosen at all.
	Rejected []string
}

// SelectEngine picks the first engine in preference order that can carry the
// whole plan. The reason and the missing capabilities are returned so the
// interface can explain the choice instead of showing a bare error.
func SelectEngine(p *Plan, available []Availability, preference []Kind) (Selection, error) {
	if p == nil {
		return Selection{}, fmt.Errorf("engine: nil plan")
	}
	if len(p.Outbounds) == 0 {
		return Selection{}, fmt.Errorf("engine: plan has no outbounds")
	}
	byKind := make(map[Kind]Availability, len(available))
	for _, a := range available {
		byKind[a.Kind] = a
	}
	var rejected []string
	for _, kind := range preference {
		avail, ok := byKind[kind]
		if !ok || !avail.Usable {
			why := "not installed"
			if ok && avail.Reason != "" {
				why = avail.Reason
			}
			rejected = append(rejected, string(kind)+": "+why)
			continue
		}
		caps, ok := Catalog[kind]
		if !ok {
			rejected = append(rejected, string(kind)+": no capability matrix")
			continue
		}
		if lowest, err := ParseVersion(caps.MinVersion); err == nil && avail.Version.Less(lowest) {
			rejected = append(rejected, fmt.Sprintf("%s: version %s is older than %s", kind, avail.Version, caps.MinVersion))
			continue
		}
		missing := caps.Missing(p)
		if len(missing) > 0 {
			rejected = append(rejected, fmt.Sprintf("%s: cannot carry %s", kind, strings.Join(missing, ", ")))
			continue
		}
		return Selection{
			Kind:     kind,
			Reason:   fmt.Sprintf("%s carries %d outbounds and %d groups", kind, len(p.Outbounds), len(p.Groups)),
			Rejected: rejected,
		}, nil
	}
	return Selection{Rejected: rejected}, fmt.Errorf("engine: no engine can carry this plan (%s)", strings.Join(rejected, "; "))
}

// Missing lists, sorted, every protocol and feature of p this engine cannot
// carry. An empty answer means the engine can run the whole plan.
func (c Capabilities) Missing(p *Plan) []string {
	var missing []string
	for proto := range p.Protocols() {
		if !c.SupportsProtocol(proto) {
			missing = append(missing, "protocol "+string(proto))
		}
	}
	for f := range p.RequiredFeatures() {
		if !c.Supports(f) {
			missing = append(missing, "feature "+string(f))
		}
	}
	sort.Strings(missing)
	return missing
}
