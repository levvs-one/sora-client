package xray

import (
	"encoding/json"
	"fmt"
	"strconv"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/supervise"
)

// Tags of what the session adds to a profile. They cannot collide with a
// provider's tags, which never start with "sora-".
const (
	profileDNS    = "sora-dns"
	profileDirect = "sora-direct"
	profileBlock  = "sora-block"
)

// profileOwned are the parts of a provider's configuration the session owns:
// no listener of the provider opens on the machine, and the log, stats and
// controller are the core's. The rest — outbounds, balancers, the observatory
// that feeds them, routing — runs as the provider wrote it.
var profileOwned = []string{"inbounds", "log", "api", "stats", "metrics", "policy", "remarks", "meta", "reverse"}

// "reverse" is dropped with them: a bridge would give the provider's server a
// way back into the machine and its local network. Keys that name files are
// dropped at any depth, because the engine runs with the service's rights: a
// TLS key log path would let a subscription write into any file it can reach,
// a certificate path would make it read one.
var profileFileKeys = map[string]bool{"masterKeyLog": true, "certificateFile": true, "keyFile": true}

// stripFiles removes the keys of profileFileKeys from a decoded JSON value.
func stripFiles(v any) {
	switch t := v.(type) {
	case obj:
		stripFiles(map[string]any(t))
	case map[string]any:
		for key, child := range t {
			if profileFileKeys[key] {
				delete(t, key)
				continue
			}
			stripFiles(child)
		}
	case []any:
		for _, child := range t {
			stripFiles(child)
		}
	}
}

// renderProfile runs the configuration a provider wrote for one server inside
// the frame of the session. The session's own rules — the DNS of a tun, the ad
// block, the routing preset — come first; the provider's rules follow, and
// whatever none of them matches goes where the provider's configuration sends
// it, its first outbound.
func renderProfile(p *engine.Plan, rt supervise.Runtime) ([]byte, error) {
	profile := p.Outbounds[0]
	var cfg obj
	if err := json.Unmarshal(profile.Profile, &cfg); err != nil {
		return nil, fmt.Errorf("xray: profile %s: %w", profile.ID, err)
	}
	for _, key := range profileOwned {
		delete(cfg, key)
	}
	stripFiles(cfg)
	outbounds, _ := cfg["outbounds"].([]any)
	cfg["outbounds"] = append(outbounds,
		obj{"tag": profileDNS, "protocol": "dns"},
		obj{"tag": profileDirect, "protocol": "freedom"},
		obj{"tag": profileBlock, "protocol": "blackhole"},
	)

	var ours []any
	if p.Tun.Enabled {
		ours = append(ours, obj{"inboundTag": []string{tagTun}, "network": "udp", "port": "53", "outboundTag": profileDNS})
	}
	for _, rule := range p.Rules {
		var target string
		switch rule.Target {
		case "direct":
			target = profileDirect
		case "reject", "block":
			target = profileBlock
		default:
			// A rule toward the profile itself, the catch-all included, is
			// what the provider's routing already decides.
			continue
		}
		m, err := match(rule)
		if err != nil {
			return nil, err
		}
		m["outboundTag"] = target
		ours = append(ours, m)
	}
	routing, _ := cfg["routing"].(map[string]any)
	if routing == nil {
		routing = obj{}
	}
	provider, _ := routing["rules"].([]any)
	routing["rules"] = append(ours, provider...)
	cfg["routing"] = routing

	if p.DNS.Enabled {
		r := renderer{plan: p}
		dns, err := r.dns()
		if err != nil {
			return nil, err
		}
		cfg["dns"] = dns
	}
	cfg["inbounds"] = sessionInbounds(p, rt)
	frame(cfg, p, rt)
	return json.Marshal(cfg)
}

// probeProfile renders the outbounds of a profile for a latency measurement
// through one local port: tags get a prefix of their own so several profiles
// share one configuration, and links between them follow. The measured
// outbound is the profile's first, the one its traffic goes to by default.
func probeProfile(o engine.Outbound, index int) (outbounds []obj, first string, err error) {
	var cfg struct {
		Outbounds []obj `json:"outbounds"`
	}
	if err := json.Unmarshal(o.Profile, &cfg); err != nil || len(cfg.Outbounds) == 0 {
		return nil, "", fmt.Errorf("xray: profile %s has no outbounds", o.ID)
	}
	for _, ob := range cfg.Outbounds {
		stripFiles(ob)
	}
	prefix := "p" + strconv.Itoa(index+1) + "-"
	rename := func(tag string) string { return prefix + tag }
	for i, ob := range cfg.Outbounds {
		tag, _ := ob["tag"].(string)
		if tag == "" {
			tag = "untagged-" + strconv.Itoa(i)
		}
		ob["tag"] = rename(tag)
		if ss, ok := ob["streamSettings"].(map[string]any); ok {
			if so, ok := ss["sockopt"].(map[string]any); ok {
				if dialer, ok := so["dialerProxy"].(string); ok && dialer != "" {
					so["dialerProxy"] = rename(dialer)
				}
			}
		}
		if px, ok := ob["proxySettings"].(map[string]any); ok {
			if tag, ok := px["tag"].(string); ok && tag != "" {
				px["tag"] = rename(tag)
			}
		}
		outbounds = append(outbounds, ob)
	}
	first, _ = cfg.Outbounds[0]["tag"].(string)
	return outbounds, first, nil
}
