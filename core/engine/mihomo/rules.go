package mihomo

import (
	"fmt"
	"runtime"
	"strings"

	"github.com/levvs-one/sora-client/core/engine"
)

// ruleTypes maps contract rule types onto the mihomo rule vocabulary.
var ruleTypes = map[engine.RuleType]string{
	engine.RuleDomain:        "DOMAIN",
	engine.RuleDomainSuffix:  "DOMAIN-SUFFIX",
	engine.RuleDomainKeyword: "DOMAIN-KEYWORD",
	engine.RuleIPCIDR:        "IP-CIDR",
	engine.RuleIPSuffix:      "IP-SUFFIX",
	engine.RuleGeoIP:         "GEOIP",
	engine.RuleGeoSite:       "GEOSITE",
	engine.RuleRuleSet:       "RULE-SET",
	engine.RulePort:          "DST-PORT",
	engine.RuleSrcPort:       "SRC-PORT",
	engine.RuleProcess:       "PROCESS-NAME",
	engine.RuleProtocol:      "NETWORK",
}

// buildRules preserves plan order because mihomo evaluates rules from top to
// bottom.
func buildRules(rules []engine.Rule, byID map[string]string) ([]string, error) {
	out := make([]string, 0, len(rules)+1)
	for _, r := range rules {
		if r.Type == engine.RuleMatchAll {
			target, err := ruleTarget(r.Target, byID)
			if err != nil {
				return nil, err
			}
			out = append(out, "MATCH,"+target)
			continue
		}
		kind, ok := ruleTypes[r.Type]
		if !ok {
			return nil, fmt.Errorf("mihomo: rule type %q is not supported", r.Type)
		}
		if r.Type == engine.RuleIPCIDR && strings.Contains(r.Value, ":") {
			kind = "IP-CIDR6"
		}
		target, err := ruleTarget(r.Target, byID)
		if err != nil {
			return nil, err
		}
		line := kind + "," + r.Value + "," + target
		if r.NoResolve && (r.Type == engine.RuleIPCIDR || r.Type == engine.RuleIPSuffix || r.Type == engine.RuleGeoIP) {
			line += ",no-resolve"
		}
		out = append(out, line)
	}
	if len(out) == 0 || !strings.HasPrefix(out[len(out)-1], "MATCH,") {
		out = append(out, "MATCH,DIRECT")
	}
	return out, nil
}

// ruleTarget maps a plan target onto the name mihomo knows.
func ruleTarget(target string, byID map[string]string) (string, error) {
	switch target {
	case "direct":
		return "DIRECT", nil
	case "reject":
		return "REJECT", nil
	case "pass":
		return "ACCEPT", nil
	case "dns":
		return "NO-ADAPT", nil
	}
	name, ok := byID[target]
	if !ok {
		return "", fmt.Errorf("mihomo: rule target %q is not an outbound of this plan", target)
	}
	return name, nil
}

// buildDNS renders resolvers. default-nameserver bootstraps resolver hostnames
// and must never use a proxy.
func buildDNS(d engine.DNS, o engine.Options, byID map[string]string) (*dnsConfig, error) {
	out := &dnsConfig{
		Enable:         true,
		IPv6:           &o.IPv6,
		CacheAlgorithm: "lru",
	}
	switch d.Mode {
	case string(engine.DNSFakeIP):
		out.EnhancedMode = "fake-ip"
		out.FakeIPRange = orDefault(d.FakeIPRange, "198.18.0.1/16")
		out.FakeIPFilter = []string{"*.lan", "*.local"}
	default:
		out.EnhancedMode = "redir-host"
	}
	var direct, remote, system, bootstrap []string
	for _, s := range d.Servers {
		addr := s.Address
		if s.Port != 0 && s.Transport != engine.DNSSystem {
			addr = fmt.Sprintf("%s:%d", s.Address, s.Port)
		}
		switch s.Transport {
		case engine.DNSTCP:
			addr = "tcp://" + addr
		case engine.DNSTLS:
			addr = "tls://" + addr
		case engine.DNSHTTPS:
			addr = "https://" + addr + "/dns-query"
		case engine.DNSQUIC:
			addr = "quic://" + addr
		case engine.DNSSystem:
			system = append(system, "system")
		}
		if s.Dialer == "" || s.Dialer == "direct" {
			bootstrap = append(bootstrap, addr)
		} else {
			name, ok := byID[s.Dialer]
			if !ok {
				return nil, fmt.Errorf("mihomo: DNS resolver %q references unknown outbound %q", s.Tag, s.Dialer)
			}
			addr += "#" + name
		}
		if s.ProxyOnly {
			remote = append(remote, addr)
		} else {
			direct = append(direct, addr)
		}
	}
	out.Nameserver = firstNonEmpty(direct, remote, system, []string{"223.5.5.5"})
	// Map proxy-only resolvers to proxy-server-nameserver for proxy
	// hostname resolution.
	out.ProxyServerNameserver = firstNonEmpty(remote, direct, system, []string{"223.5.5.5"})
	out.DefaultNameserver = firstNonEmpty(system, bootstrap, []string{"223.5.5.5"})
	out.DirectNameserver = firstNonEmpty(system, direct)
	if len(d.NameserverPolicy) > 0 {
		out.NameserverPolicy = d.NameserverPolicy
	}
	if len(d.HijackTun) > 0 {
		out.Listen = strings.Join(d.HijackTun, ",")
	}
	return out, nil
}

// buildTun defaults to the upstream-recommended mixed stack: system TCP and
// gVisor UDP.
func buildTun(t engine.Tun, d engine.DNS) *tunConfig {
	stack := orDefault(t.Stack, "mixed")
	out := &tunConfig{
		Name:      "sora-tun",
		Type:      "tun",
		Stack:     stack,
		Device:    t.DeviceName,
		MTU:       orDefaultInt(t.MTU, 1500),
		DNSHijack: orDefaultList(d.HijackTun, []string{"any:53"}),
	}
	auto := t.AutoRoute && runtime.GOOS != "linux"
	out.AutoRoute = &auto
	detect := runtime.GOOS != "linux"
	out.AutoDetectInterface = &detect
	strict := t.StrictRoute
	out.StrictRoute = &strict
	addresses := t.Addresses()
	out.Inet4Address = addresses[:1]
	out.Inet6Address = addresses[1:]
	if runtime.GOOS == "linux" {
		// Its IPv6 bound-interface rule exists even with auto-route=false;
		// keep it in Sora's table so crash cleanup can identify it exactly.
		out.IPRoute2TableIndex = 5340
	}

	out.RouteAddress = t.RouteAddressSets
	out.IncludePackage = t.IncludeApps
	out.ExcludePackage = t.ExcludeApps
	return out
}

// findProcessMode enables process lookup only for process rules; Windows lookup
// is slow and otherwise unnecessary.
func findProcessMode(p *engine.Plan) string {
	if p.Options.FindProcess {
		return "strict"
	}
	for _, r := range p.Rules {
		if r.Type == engine.RuleProcess {
			return "strict"
		}
	}
	return "off"
}

func firstNonEmpty(lists ...[]string) []string {
	for _, l := range lists {
		if len(l) > 0 {
			return l
		}
	}
	return nil
}

func orDefaultList(v, fallback []string) []string {
	if len(v) == 0 {
		return fallback
	}
	return v
}
