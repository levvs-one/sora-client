package engine

import (
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
// machine actually has. Versions checked here: mihomo v1.19.32,
// sing-box v1.11.x, Xray-core v25.x. See docs/research.
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
			FeatureHotApply: true, FeatureGeoData: true,
		},
	},
	KindSingBox: {
		Kind:       KindSingBox,
		MinVersion: "1.11.0",
		Protocols: map[Protocol]bool{
			ProtocolVLESS: true, ProtocolVMess: true, ProtocolTrojan: true,
			ProtocolShadowsocks: true, ProtocolHysteria2: true, ProtocolTUIC: true,
			ProtocolWireGuard: true, ProtocolSOCKS5: true, ProtocolHTTP: true,
			ProtocolDirect: true,
		},
		Features: map[Feature]bool{
			FeatureTun: true, FeatureFakeIP: true, FeatureRuleSets: true,
			FeatureURLTest: true, FeatureLatencyTest: true, FeatureHotApply: true,
			FeaturePerAppRouting: true,
		},
	},
	KindXray: {
		Kind:       KindXray,
		MinVersion: "24.0.0",
		Protocols: map[Protocol]bool{
			ProtocolVLESS: true, ProtocolVMess: true, ProtocolTrojan: true,
			ProtocolShadowsocks: true, ProtocolSOCKS5: true, ProtocolHTTP: true,
			ProtocolDirect: true,
		},
		Features: map[Feature]bool{
			FeatureTun: true, FeatureLatencyTest: true, FeatureGeoData: true,
		},
	},
}

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
