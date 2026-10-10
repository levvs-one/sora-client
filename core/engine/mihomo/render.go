package mihomo

import (
	"errors"
	"fmt"
	"strings"

	"gopkg.in/yaml.v3"

	"github.com/levvs-one/sora-client/core/engine"
)

// globalUA retains mihomo's upstream User-Agent because geodata providers
// filter clients by it.
const globalUA = "clash.meta"

// Render produces credential-bearing YAML for stdin, never disk or diagnostics.
// Sora resolves subscriptions itself; proxy-providers would persist bearer URLs
// and bypass core fetch auditing and redaction.
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
		// mihomo requires its own resolver for TUN routing; reject
		// invalid combinations before startup.
		return "", errors.New("mihomo: a tun plan needs a resolver")
	}
	// Leave unrequested listeners closed because all local applications can
	// reach loopback.
	mixed := 0
	if p.LocalProxy.Enabled {
		mixed = rt.MixedPort
	}

	c := config{
		MixedPort:     mixed,
		AllowLAN:      p.Options.AllowLAN,
		Mode:          orDefault(p.Options.Mode, "rule"),
		LogLevel:      orDefault(p.Options.LogLevel, "warning"),
		Secret:        rt.Secret,
		GlobalUA:      globalUA,
		GeodataLoader: "memconservative",
		Profile:       &profile{StoreSelected: true, StoreFakeIP: p.DNS.Mode == string(engine.DNSFakeIP)},
	}
	switch addr := rt.ControllerAddr; {
	case strings.HasPrefix(addr, "unix:"):
		c.ControllerUnix = strings.TrimPrefix(addr, "unix:")
	case strings.HasPrefix(addr, "pipe:"):
		c.ControllerPipe = strings.TrimPrefix(addr, "pipe:")
	default:
		c.ExternalController = addr
	}
	if p.LocalProxy.Username != "" {
		c.Authentication = []string{p.LocalProxy.Username + ":" + p.LocalProxy.Password}
	}
	ipv6 := p.Options.IPv6
	c.IPv6 = &ipv6
	unified := true
	c.UnifiedDelay = &unified
	concurrent := true
	c.TCPConcurrent = &concurrent
	c.FindProcessMode = findProcessMode(p)
	// Use shipped geoip.dat and geosite.dat, shared with Xray, to avoid
	// startup downloads from blocked hosts. Options.GeoData enables
	// periodic updates.
	geodata := true
	c.GeodataMode = &geodata
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
	// Collect group names too because rules and group members can reference
	// groups.
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
		c.DNS, err = buildDNS(p.DNS, p.Options, byID)
		if err != nil {
			return "", err
		}
	}
	if p.Tun.Enabled {
		// Top-level tun derives IPv4 from fake-ip-range. A named listener
		// accepts an independent adapter subnet on Linux and Windows.
		c.Listeners = []*tunConfig{buildTun(p.Tun, p.DNS)}
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

// buildProxies returns rendered outbounds and their ID-to-name map. Names are
// unique because mihomo addresses proxies and groups by name.
func buildProxies(p *engine.Plan) (map[string]string, []proxy, error) {
	byID := make(map[string]string, len(p.Outbounds))
	used := make(map[string]struct{}, len(p.Outbounds))
	out := make([]proxy, 0, len(p.Outbounds))
	for _, o := range p.Outbounds {
		// Named direct proxies preserve display and latency checks;
		// built-in DIRECT remains the "direct" rule target.
		px := proxy{Type: "direct"}
		if o.Protocol != engine.ProtocolDirect {
			var err error
			if px, err = buildProxy(o); err != nil {
				return nil, nil, err
			}
		}
		name := uniqueName(sanitizeName(o.Name, o.ID), used)
		px.Name = name
		byID[o.ID] = name
		out = append(out, px)
	}
	return byID, out, nil
}

// buildGroup renders a selectable group. Probe groups use their own URL or the
// plan default.
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
	// A group-specific test URL overrides the plan default, as in sing-box.
	grp.URL = orDefault(g.URL, testURL)
	grp.Interval = orDefaultInt(g.Interval, 300)
	grp.Timeout = 5000
	grp.MaxFailed = 5
	grp.Tolerance = g.Tolerance
	lazy := g.Lazy
	grp.Lazy = &lazy
	return grp, nil
}
