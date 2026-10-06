package mihomo

import (
	"errors"
	"fmt"

	"gopkg.in/yaml.v3"

	"github.com/levvs-one/sora-client/core/engine"
)

// globalUA keeps the User-Agent mihomo uses when it downloads geodata.
// Providers filter on it, so Sora keeps the upstream default rather than
// inventing a client string providers would have to whitelist.
const globalUA = "clash.meta"

// Render turns a plan into the YAML mihomo reads.
//
// The result carries credentials, so the supervisor hands it to the engine on
// stdin and never writes it to disk. Nothing from this text may enter a diagnostic archive.
//
// Sora resolves subscriptions itself and passes concrete outbounds to the
// engine: proxy-providers would put subscription URLs into the engine state
// directory and hand the engine a fetch Sora cannot audit or mask.
func Render(p *engine.Plan, rt Runtime) (string, error) {
	if p == nil {
		return "", errors.New("mihomo: nil plan")
	}
	if err := p.Validate(); err != nil {
		return "", fmt.Errorf("mihomo: %w", err)
	}
	if rt.Secret == "" {
		return "", errors.New("mihomo: controller secret is required")
	}
	if rt.ControllerAddr == "" {
		return "", errors.New("mihomo: controller address is required")
	}
	if p.Tun.Enabled && !p.DNS.Enabled {
		// mihomo cannot route through a tun adapter without a resolver of its own,
		// so Sora refuses the combination instead of letting the engine die with a
		// message the user never sees.
		return "", errors.New("mihomo: a tun plan needs a resolver")
	}
	mixed := rt.MixedPort
	if mixed == 0 {
		mixed = DefaultMixedPort
	}

	c := config{
		MixedPort:          mixed,
		AllowLAN:           p.Options.AllowLAN,
		Mode:               orDefault(p.Options.Mode, "rule"),
		LogLevel:           orDefault(p.Options.LogLevel, "warning"),
		ExternalController: rt.ControllerAddr,
		Secret:             rt.Secret,
		GlobalUA:           globalUA,
		GeodataLoader:      "memconservative",
		Profile:            &profile{StoreSelected: true, StoreFakeIP: p.DNS.Mode == string(engine.DNSFakeIP)},
	}
	ipv6 := p.Options.IPv6
	c.IPv6 = &ipv6
	unified := true
	c.UnifiedDelay = &unified
	concurrent := true
	c.TCPConcurrent = &concurrent
	c.FindProcessMode = findProcessMode(p)
	geo := p.Options.GeoData
	c.GeodataMode = &geo
	if p.Options.GeoData {
		auto := true
		c.GeoAutoUpdate = &auto
		c.GeoUpdateInterval = 24
		c.GeoX = sortedMap(map[string]string{
			"geoip":   orDefault(p.Options.GeoIPURL, GeoIPDefaultURL),
			"geosite": orDefault(p.Options.GeoSiteURL, GeoSiteDefaultURL),
		})
	}

	byID, proxies, err := buildProxies(p)
	if err != nil {
		return "", err
	}
	c.Proxies = proxies
	// Rules and groups may name a group as well as an outbound.
	for _, g := range p.Groups {
		byID[g.Name] = sanitizeName(g.Name, "")
	}

	for _, g := range p.Groups {
		grp, err := buildGroup(g, byID, orDefault(p.Options.TestURL, rt.TestURL))
		if err != nil {
			return "", err
		}
		c.ProxyGroups = append(c.ProxyGroups, grp)
	}

	rules, err := buildRules(p.Rules, byID)
	if err != nil {
		return "", err
	}
	c.Rules = rules

	if p.DNS.Enabled {
		c.DNS = buildDNS(p.DNS, p.Options)
	}
	if p.Tun.Enabled {
		c.Tun = buildTun(p.Tun, p.DNS)
	}

	out, err := yaml.Marshal(&c) //nolint:gosec // the config carries the controller secret by design and is never written to disk
	if err != nil {
		return "", fmt.Errorf("mihomo: render config: %w", err)
	}
	if len(out) > MaxConfigBytes {
		return "", fmt.Errorf("mihomo: rendered config is %d bytes, the limit is %d", len(out), MaxConfigBytes)
	}
	return string(out), nil
}

// buildProxies renders every outbound and returns the id to engine-name map
// together with the rendered list. Engine names are unique: mihomo addresses
// proxies and groups by name over its API.
func buildProxies(p *engine.Plan) (map[string]string, []proxy, error) {
	byID := make(map[string]string, len(p.Outbounds))
	used := make(map[string]struct{}, len(p.Outbounds))
	out := make([]proxy, 0, len(p.Outbounds))
	for _, o := range p.Outbounds {
		if o.Protocol == engine.ProtocolDirect {
			// mihomo has no proxy entry for a direct connection: DIRECT is a
			// built-in policy that groups and rules refer to by name. Writing
			// it as a proxy makes the engine refuse the whole configuration.
			byID[o.ID] = "DIRECT"
			continue
		}
		px, err := buildProxy(o)
		if err != nil {
			return nil, nil, err
		}
		name := uniqueName(sanitizeName(o.Name, o.ID), used)
		px.Name = name
		byID[o.ID] = name
		out = append(out, px)
	}
	return byID, out, nil
}

// buildGroup renders one selectable group. Only url-test style groups need a
// probe url; the plan default applies when the group does not carry one.
func buildGroup(g engine.Group, byID map[string]string, testURL string) (proxyGroup, error) {
	if g.Provider != "" {
		return proxyGroup{}, fmt.Errorf("mihomo: group %q carries a subscription url; resolve it before building the plan", g.Name)
	}
	grp := proxyGroup{Name: sanitizeName(g.Name, ""), Type: string(g.Type), Icon: g.Icon}
	hidden := g.Hidden
	grp.Hidden = &hidden
	if len(g.Outbounds) == 0 {
		return proxyGroup{}, fmt.Errorf("mihomo: group %q has no members", g.Name)
	}
	for _, ref := range g.Outbounds {
		name, ok := byID[ref]
		if !ok {
			return proxyGroup{}, fmt.Errorf("mihomo: group %q references unknown outbound %q", g.Name, ref)
		}
		grp.Proxies = append(grp.Proxies, name)
	}
	if g.Type == engine.GroupSelect {
		return grp, nil
	}
	if testURL == "" {
		return proxyGroup{}, fmt.Errorf("mihomo: group %q needs a test url", g.Name)
	}
	grp.URL = testURL
	grp.Interval = orDefaultInt(g.Interval, 300)
	grp.Timeout = 5000
	grp.MaxFailed = 5
	grp.Tolerance = g.Tolerance
	lazy := g.Lazy
	grp.Lazy = &lazy
	return grp, nil
}
