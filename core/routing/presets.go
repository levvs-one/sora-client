// Package routing holds the routing presets a session can start from. A
// preset is data: which destinations go direct, and that everything else goes
// through the proxy. The rules the user writes come before the preset, so a
// preset never overrides a choice the user made.
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

// Every geo rule here was checked against the databases Sora ships
// (geosite.dat and geoip.dat of the pinned Xray build) and against the
// SagerNet rule sets sing-box downloads. GeoIP rules never resolve a name:
// resolving every domain only to learn whether its address is local would
// send every visited name to the local resolver, which is exactly the
// observation a tunnel exists to prevent.
var presets = []Preset{
	{ID: "global", Direct: []engine.Rule{
		geoip("private"),
	}},
	{ID: "ru", Direct: []engine.Rule{
		geoip("private"),
		// Russian banks, government services and many shops refuse foreign
		// addresses, so they are reached from the user's own network.
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

// Options choose how a preset is applied.
type Options struct {
	// Preset is a preset id; empty applies none.
	Preset string
	// ProxyTarget is the outbound or group the rest of the traffic goes to.
	ProxyTarget string
	// BlockAds rejects advertising and tracking domains before anything else.
	BlockAds bool
}

// Apply returns the rules of a session: the user's rules first, untouched,
// then the ad block, then the preset, then everything else to the proxy
// target. A user rule that sends everything somewhere ends the list, since
// nothing after it could match.
func Apply(user []engine.Rule, opts Options) ([]engine.Rule, error) {
	out := slices.Clone(user)
	if slices.ContainsFunc(user, func(r engine.Rule) bool { return r.Type == engine.RuleMatchAll }) {
		return out, nil
	}
	// A plan that names a target sends the rest there even without a preset:
	// without a final rule every engine goes direct, which for a person who
	// picked a server is traffic outside the tunnel.
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
