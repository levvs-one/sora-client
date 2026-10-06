// Package engine defines the boundary between the Sora control plane and the
// forwarding engines Sora can drive (mihomo, sing-box, Xray).
//
// Code above this package passes Plan values and never touches an engine
// specific configuration file. Every engine reports the protocols and the
// features it really supports, so the control plane picks an engine by
// capability instead of by guesswork.
package engine

import (
	"context"
	"fmt"
	"strconv"
	"strings"
	"time"
)

// Kind identifies a forwarding engine implementation.
type Kind string

// Engine kinds Sora drives.
const (
	KindMihomo  Kind = "mihomo"
	KindSingBox Kind = "sing-box"
	KindXray    Kind = "xray"
)

// Feature is a capability the control plane may require from an engine.
type Feature string

// Features a plan may ask for. The capability matrix of catalog.go decides
// which engine provides them.
const (
	FeatureTun            Feature = "tun"
	FeatureFakeIP         Feature = "fake-ip"
	FeatureRuleSets       Feature = "rule-sets"
	FeatureProxyProviders Feature = "proxy-providers"
	FeatureURLTest        Feature = "url-test"
	FeatureLatencyTest    Feature = "latency-test"
	FeatureHotApply       Feature = "hot-apply"
	FeatureGeoData        Feature = "geodata"
	FeaturePerAppRouting  Feature = "per-app-routing"
	FeatureFallbackGroup  Feature = "fallback-group"
	FeatureLoadBalance    Feature = "load-balance"
	FeatureTLSFragment    Feature = "tls-fragment"
	FeatureXHTTP          Feature = "xhttp"
	FeatureVLESSEncrypt   Feature = "vless-encryption"
	FeatureAmneziaWG      Feature = "amneziawg"
)

// Capabilities is what one engine build can actually do.
type Capabilities struct {
	Kind       Kind
	MinVersion string
	Protocols  map[Protocol]bool
	Features   map[Feature]bool
}

// SupportsProtocol reports whether the engine can build an outbound for p.
func (c Capabilities) SupportsProtocol(p Protocol) bool { return c.Protocols[p] }

// Supports reports whether the engine provides f.
func (c Capabilities) Supports(f Feature) bool { return c.Features[f] }

// State of a managed engine instance.
type State string

// States of a managed engine instance. Stopped and Failed are terminal: the
// engine leaves them only when Start is called again.
const (
	StateIdle       State = "idle"
	StateStarting   State = "starting"
	StateRunning    State = "running"
	StateApplying   State = "applying"
	StateRecovering State = "recovering"
	StateStopping   State = "stopping"
	StateStopped    State = "stopped"
	StateFailed     State = "failed"
)

// Version is a parsed engine version.
type Version struct {
	Raw        string
	Major      int
	Minor      int
	Patch      int
	PreRelease string
}

// Less reports whether v sorts before other.
func (v Version) Less(other Version) bool {
	if v.Major != other.Major {
		return v.Major < other.Major
	}
	if v.Minor != other.Minor {
		return v.Minor < other.Minor
	}
	return v.Patch < other.Patch
}

func (v Version) String() string { return v.Raw }

// ParseVersion accepts "1.19.32", "v1.19.32" and "v1.19.32-beta.3".
func ParseVersion(raw string) (Version, error) {
	s := strings.TrimSpace(strings.TrimPrefix(strings.TrimSpace(raw), "v"))
	if s == "" {
		return Version{}, fmt.Errorf("engine: empty version")
	}
	pre := ""
	if i := strings.IndexAny(s, "-+"); i >= 0 {
		pre, s = s[i+1:], s[:i]
	}
	parts := strings.Split(s, ".")
	if len(parts) != 3 {
		return Version{}, fmt.Errorf("engine: malformed version %q", raw)
	}
	nums := make([]int, 3)
	for i, p := range parts {
		n, err := strconv.Atoi(p)
		if err != nil || n < 0 {
			return Version{}, fmt.Errorf("engine: malformed version %q", raw)
		}
		nums[i] = n
	}
	return Version{
		Raw: strings.TrimSpace(raw), Major: nums[0], Minor: nums[1], Patch: nums[2], PreRelease: pre,
	}, nil
}

// Engine is one managed forwarding engine. Apply is idempotent: applying the
// same plan twice must not interrupt traffic more than the engine requires,
// and applying a new plan must converge to that plan.
type Engine interface {
	Kind() Kind
	Capabilities() Capabilities
	State() State
	Version() Version

	// Validate reports every problem that would stop this plan from running.
	Validate(ctx context.Context, p *Plan) error
	// Apply starts the engine or moves a running engine to the given plan.
	Apply(ctx context.Context, p *Plan) error
	// Stop shuts the engine down and removes it from the system.
	Stop(ctx context.Context) error
	// Close releases all resources. Close is safe to call after Stop.
	Close() error

	// Groups returns the selectable groups with their live state.
	Groups(ctx context.Context) ([]GroupStatus, error)
	// Select pins target inside a selectable group.
	Select(ctx context.Context, group, target string) error
	// Delay measures one proxy through the engine.
	Delay(ctx context.Context, name, url string, timeout time.Duration) (time.Duration, error)
	// Counters returns traffic counters of the running session.
	Counters(ctx context.Context) (Counters, error)

	// Events returns the engine event bus.
	Events() *EventBus
}
