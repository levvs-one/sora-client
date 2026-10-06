package engine

import (
	"errors"
	"fmt"
	"net"
	"strconv"
	"strings"
)

// OutboundByID returns the outbound with the given id.
func (p *Plan) OutboundByID(id string) (Outbound, bool) {
	for _, o := range p.Outbounds {
		if o.ID == id {
			return o, true
		}
	}
	return Outbound{}, false
}

// Protocols returns the set of protocols the plan needs from an engine.
func (p *Plan) Protocols() map[Protocol]bool {
	out := make(map[Protocol]bool, len(p.Outbounds))
	for _, o := range p.Outbounds {
		out[o.Protocol] = true
	}
	return out
}

// RequiredFeatures returns the features the plan asks an engine to provide.
func (p *Plan) RequiredFeatures() map[Feature]bool {
	out := map[Feature]bool{}
	if p.Tun.Enabled {
		out[FeatureTun] = true
	}
	if p.DNS.Mode == string(DNSFakeIP) {
		out[FeatureFakeIP] = true
	}
	for _, r := range p.Rules {
		if r.Type == RuleRuleSet {
			out[FeatureRuleSets] = true
		}
	}
	for _, g := range p.Groups {
		if g.Provider != "" {
			out[FeatureProxyProviders] = true
		}
		switch g.Type {
		case GroupURLTest:
			out[FeatureURLTest] = true
		case GroupFallback:
			out[FeatureFallbackGroup] = true
		case GroupLoadBalance:
			out[FeatureLoadBalance] = true
		}
	}
	for _, o := range p.Outbounds {
		if o.Transport.Type == "xhttp" {
			out[FeatureXHTTP] = true
		}
		if o.Encryption != "" && o.Encryption != "none" {
			out[FeatureVLESSEncrypt] = true
		}
		if o.Amnezia != nil {
			out[FeatureAmneziaWG] = true
		}
	}
	if p.Options.Fragment.Enabled {
		out[FeatureTLSFragment] = true
	}
	if p.PrivateControl {
		out[FeaturePrivateControl] = true
	}
	if len(p.Tun.IncludeApps) > 0 || len(p.Tun.ExcludeApps) > 0 {
		out[FeaturePerAppRouting] = true
	}
	return out
}

func isBuiltInTarget(t string) bool {
	switch t {
	case "direct", "reject", "pass", "dns":
		return true
	}
	return false
}

func (g Group) validate() error {
	var errs []error
	errs = append(errs, validateDisplayName("group", g.Name))
	switch g.Type {
	case GroupSelect, GroupURLTest, GroupFallback, GroupLoadBalance:
	default:
		errs = append(errs, fmt.Errorf("group %q: unknown type %q", g.Name, g.Type))
	}
	if len(g.Outbounds) == 0 {
		errs = append(errs, fmt.Errorf("group %q: no members", g.Name))
	}
	if g.Interval < 0 || g.Interval > 86400 {
		errs = append(errs, fmt.Errorf("group %q: interval must be between 0 and 86400 seconds", g.Name))
	}
	return errors.Join(errs...)
}

// needsProbe reports whether the group measures latency by itself.
func (g Group) needsProbe() bool {
	return g.Type == GroupURLTest || g.Type == GroupFallback || g.Type == GroupLoadBalance
}

func (r Rule) validate() error {
	var errs []error
	switch r.Type {
	case RuleDomain, RuleDomainSuffix, RuleDomainKeyword, RuleIPCIDR, RuleIPSuffix,
		RuleGeoIP, RuleGeoSite, RuleRuleSet, RulePort, RuleSrcPort, RuleProcess,
		RuleProtocol, RuleMatchAll:
	default:
		errs = append(errs, fmt.Errorf("rule: unknown type %q", r.Type))
	}
	if r.Type != RuleMatchAll && strings.TrimSpace(r.Value) == "" {
		errs = append(errs, fmt.Errorf("rule %s: empty value", r.Type))
	}
	if strings.ContainsAny(r.Value, "\r\n\t") {
		errs = append(errs, fmt.Errorf("rule %s: value contains control characters", r.Type))
	}
	switch r.Type {
	case RuleIPCIDR:
		if _, _, err := net.ParseCIDR(r.Value); err != nil {
			errs = append(errs, fmt.Errorf("rule ip-cidr: %q is not a CIDR", r.Value))
		}
	case RulePort, RuleSrcPort:
		if _, err := strconv.Atoi(r.Value); err != nil {
			errs = append(errs, fmt.Errorf("rule %s: %q is not a port", r.Type, r.Value))
		}
	}
	return errors.Join(errs...)
}
