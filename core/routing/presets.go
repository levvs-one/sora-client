// Package routing provides direct-destination presets with proxy fallback. User
// rules precede presets and retain priority.
package routing

import (
	"fmt"
	"slices"

	"github.com/levvs-one/sora-client/core/engine"
)

// Preset is one routing preset.
type Preset struct {
	ID string
	// Direct lists what bypasses the proxy, in the order engines check it.
	Direct []engine.Rule
}

// Geo rules are checked against shipped Xray geoip.dat/geosite.dat and SagerNet
// rule sets. GeoIP never resolves names, avoiding disclosure of visited domains
// to local DNS.
var presets = []Preset{
	{ID: "global", Direct: []engine.Rule{
		geoip("private"),
	}},
	{ID: "ru", Direct: []engine.Rule{
		geoip("private"),
		// Use direct routing for Russian banks, government services,
		// and shops that reject foreign addresses.
		geosite("category-gov-ru"), geosite("category-bank-ru"),
		geosite("category-ru"), geosite("tld-ru"),
		geosite("yandex"), geosite("vk"), geosite("mailru"),
		geoip("ru"),
	}},
	{ID: "ir", Direct: []engine.Rule{
		geoip("private"), geosite("category-ir"), geoip("ir"),
	}},
	{ID: "cn", Direct: []engine.Rule{
		geoip("private"), geosite("cn"), geoip("cn"),
	}},
}

func geoip(cc string) engine.Rule {
	return engine.Rule{Type: engine.RuleGeoIP, Value: cc, Target: "direct", NoResolve: true}
}

func geosite(tag string) engine.Rule {
	return engine.Rule{Type: engine.RuleGeoSite, Value: tag, Target: "direct"}
}

// adsRule blocks known advertising and tracking domains.
var adsRule = engine.Rule{Type: engine.RuleGeoSite, Value: "category-ads-all", Target: "reject"}

// Presets returns every preset, in a stable order.
func Presets() []Preset {
	out := make([]Preset, len(presets))
	for i, p := range presets {
		out[i] = Preset{ID: p.ID, Direct: slices.Clone(p.Direct)}
	}
	return out
}

// Options configures preset application.
type Options struct {
	// Preset is a preset id; empty applies none.
	Preset string
	// ProxyTarget is the outbound or group the rest of the traffic goes to.
	ProxyTarget string
	// BlockAds rejects advertising and tracking domains before anything
	// else.
	BlockAds bool
}

// Apply preserves user rules, then adds ad blocking, preset rules, and proxy
// fallback. A user catch-all ends the list because later rules cannot match.
func Apply(user []engine.Rule, opts Options) ([]engine.Rule, error) {
	out := slices.Clone(user)
	if slices.ContainsFunc(user, func(r engine.Rule) bool { return r.Type == engine.RuleMatchAll }) {
		return out, nil
	}
	// Add proxy fallback even without a preset because engines otherwise
	// send unmatched traffic directly.
	if opts.Preset == "" && !opts.BlockAds && opts.ProxyTarget == "" {
		return out, nil
	}
	if opts.ProxyTarget == "" {
		return nil, fmt.Errorf("routing: a preset needs the outbound or group the rest of the traffic goes to")
	}
	if opts.BlockAds {
		out = append(out, adsRule)
	}
	if opts.Preset != "" {
		i := slices.IndexFunc(presets, func(p Preset) bool { return p.ID == opts.Preset })
		if i < 0 {
			return nil, fmt.Errorf("routing: unknown preset %q", opts.Preset)
		}
		out = append(out, presets[i].Direct...)
	}
	return append(out, engine.Rule{Type: engine.RuleMatchAll, Target: opts.ProxyTarget}), nil
}
