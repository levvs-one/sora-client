package xray

import (
	"encoding/json"
	"errors"
	"fmt"
	"net"
	"slices"
	"strconv"
	"strings"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/supervise"
)

// Tags of the outbounds every configuration carries.
const (
	tagDirect   = "direct"
	tagBlock    = "block"
	tagDNS      = "dns-out"
	tagFragment = "fragment"
	tagInbound  = "mixed-in"
)

type obj map[string]any

// set leaves zero values out: Xray reads some empty values as settings.
func (o obj) set(key string, value any) obj {
	switch v := value.(type) {
	case string:
		if v == "" {
			return o
		}
	case int:
		if v == 0 {
			return o
		}
	case bool:
		if !v {
			return o
		}
	case []string:
		if len(v) == 0 {
			return o
		}
	case obj:
		if len(v) == 0 {
			return o
		}
	}
	o[key] = value
	return o
}

// Selection pins the member of every select group. Xray has no runtime
// selector, so the pinned member is written into the routing table and a new
// selection restarts the engine, which takes about a tenth of a second.
type Selection map[string]string

// Render turns a plan into the JSON Xray reads on stdin.
//
// Outbound tags are "o0001", "o0002" and so on: a balancer selects outbounds
// by tag prefix, so tags must never be prefixes of each other, and display
// names would leak into the engine log. Display names stay in the plan.
func Render(p *engine.Plan, rt supervise.Runtime, sel Selection) ([]byte, error) {
	if p == nil {
		return nil, errors.New("xray: nil plan")
	}
	r := renderer{plan: p, sel: sel, tags: map[string]string{}, groups: map[string]engine.Group{}, byGroup: map[string]string{}}
	for i, o := range p.Outbounds {
		r.tags[o.ID] = outboundTag(i)
	}
	for _, g := range p.Groups {
		r.groups[g.Name] = g
	}
	outbounds, err := r.outbounds()
	if err != nil {
		return nil, err
	}
	routing, err := r.routing()
	if err != nil {
		return nil, err
	}
	dns, err := r.dns()
	if err != nil {
		return nil, err
	}

	listen := "127.0.0.1"
	if p.Options.AllowLAN {
		listen = "0.0.0.0"
	}
	cfg := obj{
		"log": obj{"loglevel": logLevel(p.Options.LogLevel)},
		// The socks inbound of Xray also answers plain HTTP proxy requests,
		// which makes it the mixed listener the system proxy points at.
		"inbounds": []obj{{
			"tag": tagInbound, "protocol": "socks", "listen": listen, "port": rt.LocalPort,
			"settings": obj{"udp": true},
			"sniffing": obj{"enabled": true, "destOverride": []string{"http", "tls", "quic"}, "routeOnly": true},
		}},
		"outbounds": outbounds,
		"routing":   routing,
		"dns":       dns,
		// Stats and the metrics listener feed Counters and the latency of
		// automatic groups. The listener is loopback only.
		"stats": obj{},
		"policy": obj{"system": obj{
			"statsInboundUplink": true, "statsInboundDownlink": true,
			"statsOutboundUplink": true, "statsOutboundDownlink": true,
		}},
		"metrics": obj{"tag": "metrics", "listen": rt.ControlAddr},
	}
	if subjects := r.observed(); len(subjects) > 0 {
		cfg["observatory"] = obj{
			"subjectSelector":   subjects,
			"probeURL":          orDefault(p.Options.TestURL, rt.ProbeURL),
			"probeInterval":     "1m",
			"enableConcurrency": true,
		}
	}
	return json.Marshal(cfg)
}

func outboundTag(i int) string { return fmt.Sprintf("o%04d", i+1) }

type renderer struct {
	plan     *engine.Plan
	sel      Selection
	tags     map[string]string
	groups   map[string]engine.Group
	balancer []obj
	byGroup  map[string]string // group name -> balancer tag
}

func (r *renderer) outbounds() ([]obj, error) {
	out := make([]obj, 0, len(r.plan.Outbounds)+4)
	for _, o := range r.plan.Outbounds {
		ob, err := r.outbound(o)
		if err != nil {
			return nil, err
		}
		out = append(out, ob)
	}
	out = append(out,
		obj{"tag": tagDirect, "protocol": "freedom"},
		obj{"tag": tagBlock, "protocol": "blackhole"},
		obj{"tag": tagDNS, "protocol": "dns"},
	)
	if f := r.plan.Options.Fragment; f.Enabled {
		out = append(out, obj{"tag": tagFragment, "protocol": "freedom", "settings": obj{"fragment": obj{
			"packets":  orDefault(f.Packets, "tlshello"),
			"length":   orDefault(f.Length, "100-200"),
			"interval": orDefault(f.Interval, "10-20"),
		}}})
	}
	return out, nil
}

func (r *renderer) outbound(o engine.Outbound) (obj, error) {
	tag := r.tags[o.ID]
	server := obj{"address": o.Server, "port": int(o.Port)}
	var settings obj
	protocol := string(o.Protocol)
	switch o.Protocol {
	case engine.ProtocolDirect:
		return obj{"tag": tag, "protocol": "freedom"}, nil
	case engine.ProtocolVLESS:
		user := obj{"id": o.UUID, "encryption": orDefault(o.Encryption, "none")}.set("flow", o.Flow)
		server["users"] = []obj{user}
		settings = obj{"vnext": []obj{server}}
	case engine.ProtocolVMess:
		server["users"] = []obj{{"id": o.UUID, "security": orDefault(o.Cipher, "auto")}}
		settings = obj{"vnext": []obj{server}}
	case engine.ProtocolTrojan:
		server["password"] = o.Password
		settings = obj{"servers": []obj{server}}
	case engine.ProtocolShadowsocks:
		server["method"], server["password"] = orDefault(o.Cipher, "aes-256-gcm"), o.Password
		settings = obj{"servers": []obj{server}}
	case engine.ProtocolSOCKS5, engine.ProtocolHTTP:
		if o.Protocol == engine.ProtocolSOCKS5 {
			protocol = "socks"
		}
		if o.UserID != "" {
			server["users"] = []obj{{"user": o.UserID, "pass": o.Password}}
		}
		settings = obj{"servers": []obj{server}}
	case engine.ProtocolHysteria2:
		if o.Obfs != "" {
			// Xray ignores keys it does not know, so an obfs setting it cannot
			// read would connect without obfuscation instead of failing.
			return nil, fmt.Errorf("xray: hysteria2 outbound %s uses obfs, which Sora does not render for Xray", o.ID)
		}
		return r.hysteria(o, tag), nil
	case engine.ProtocolWireGuard:
		return wireguard(o, tag)
	default:
		return nil, fmt.Errorf("xray: protocol %q is not supported", o.Protocol)
	}
	stream, err := r.stream(o)
	if err != nil {
		return nil, fmt.Errorf("xray: outbound %s: %w", o.ID, err)
	}
	return obj{"tag": tag, "protocol": protocol, "settings": settings}.set("streamSettings", stream), nil
}

func (r *renderer) stream(o engine.Outbound) (obj, error) {
	s := obj{}
	t := o.Transport
	switch t.Type {
	case "", "tcp":
	case "ws":
		s["network"] = "ws"
		s["wsSettings"] = obj{}.set("path", t.Path).set("host", t.Host)
	case "grpc":
		s["network"] = "grpc"
		s["grpcSettings"] = obj{}.set("serviceName", t.Service)
	case "httpupgrade":
		s["network"] = "httpupgrade"
		s["httpupgradeSettings"] = obj{}.set("path", t.Path).set("host", t.Host)
	case "xhttp":
		s["network"] = "xhttp"
		s["xhttpSettings"] = obj{"mode": orDefault(t.Mode, "auto")}.set("path", t.Path).set("host", t.Host)
	default:
		// Xray removed the h2 transport in favour of XHTTP.
		return nil, fmt.Errorf("transport %q is not supported by Xray", t.Type)
	}
	needsTLS := o.Protocol == engine.ProtocolTrojan
	switch {
	case o.TLS.Reality:
		s["security"] = "reality"
		s["realitySettings"] = obj{
			"serverName": o.TLS.ServerName, "publicKey": o.TLS.RealityPublicKey,
			"fingerprint": orDefault(o.TLS.Fingerprint, "chrome"),
		}.set("shortId", o.TLS.RealityShortID).set("spiderX", o.TLS.SpiderX)
	case o.TLS.Enabled || needsTLS:
		s["security"] = "tls"
		s["tlsSettings"] = obj{}.set("serverName", o.TLS.ServerName).set("alpn", o.TLS.ALPN).
			set("fingerprint", o.TLS.Fingerprint).set("allowInsecure", o.TLS.Insecure)
	}
	if r.plan.Options.Fragment.Enabled && s["security"] != nil {
		// The proxy connection is dialed through the fragment outbound, which
		// splits its TLS ClientHello before it leaves the machine.
		s["sockopt"] = obj{"dialerProxy": tagFragment}
	}
	return s, nil
}

func (*renderer) hysteria(o engine.Outbound, tag string) obj {
	hy := obj{"version": 2, "auth": o.Password}
	tls := obj{}.set("serverName", o.TLS.ServerName).set("alpn", o.TLS.ALPN).set("allowInsecure", o.TLS.Insecure)
	stream := obj{"network": "hysteria", "hysteriaSettings": hy, "security": "tls", "tlsSettings": tls}
	return obj{
		"tag": tag, "protocol": "hysteria",
		"settings":       obj{"version": 2, "address": o.Server, "port": int(o.Port)},
		"streamSettings": stream,
	}
}

func wireguard(o engine.Outbound, tag string) (obj, error) {
	if len(o.Addresses) == 0 {
		return nil, fmt.Errorf("xray: wireguard outbound %s has no interface address", o.ID)
	}
	peers := make([]obj, 0, len(o.Peers))
	for _, p := range o.Peers {
		peers = append(peers, obj{"publicKey": p.PublicKey, "endpoint": p.Endpoint}.
			set("preSharedKey", p.PreSharedKey).set("allowedIPs", p.AllowedIPs).set("keepAlive", p.PersistentKeepalive))
	}
	if len(peers) == 0 {
		return nil, fmt.Errorf("xray: wireguard outbound %s has no peer", o.ID)
	}
	return obj{"tag": tag, "protocol": "wireguard", "settings": obj{
		"secretKey": o.PrivateKey, "address": o.Addresses, "peers": peers, "mtu": 1420,
	}}, nil
}

// target resolves a rule or group target to the routing field Xray expects:
// an outbound tag, or a balancer tag for an automatic group.
func (r *renderer) target(id string, depth int) (field, tag string, err error) {
	switch id {
	case "direct":
		return "outboundTag", tagDirect, nil
	case "reject":
		return "outboundTag", tagBlock, nil
	case "dns":
		return "outboundTag", tagDNS, nil
	}
	if tag, ok := r.tags[id]; ok {
		return "outboundTag", tag, nil
	}
	g, ok := r.groups[id]
	if !ok {
		return "", "", fmt.Errorf("xray: target %q is not an outbound or a group of this plan", id)
	}
	if depth > len(r.groups) {
		return "", "", fmt.Errorf("xray: group %q is part of a cycle", id)
	}
	if len(g.Outbounds) == 0 {
		return "", "", fmt.Errorf("xray: group %q has no members", g.Name)
	}
	switch g.Type {
	case engine.GroupSelect:
		member := g.Outbounds[0]
		if pinned, ok := r.sel[g.Name]; ok && slices.Contains(g.Outbounds, pinned) {
			member = pinned
		}
		return r.target(member, depth+1)
	case engine.GroupURLTest, engine.GroupLoadBalance:
		return "balancerTag", r.balancerFor(g), nil
	}
	return "", "", fmt.Errorf("xray: group type %q is not supported", g.Type)
}

func (r *renderer) balancerFor(g engine.Group) string {
	if tag, ok := r.byGroup[g.Name]; ok {
		return tag
	}
	tag := "b-" + strconv.Itoa(len(r.balancer)+1)
	r.byGroup[g.Name] = tag
	var members []string
	for _, id := range g.Outbounds {
		if t, ok := r.tags[id]; ok {
			members = append(members, t)
		}
	}
	strategy := "leastPing"
	if g.Type == engine.GroupLoadBalance {
		strategy = "roundRobin"
	}
	b := obj{"tag": tag, "selector": members, "strategy": obj{"type": strategy}}
	if len(members) > 0 {
		b["fallbackTag"] = members[0]
	}
	r.balancer = append(r.balancer, b)
	return tag
}

// observed lists the outbounds the observatory measures: the members of
// every automatic group.
func (r *renderer) observed() []string {
	seen := map[string]bool{}
	var out []string
	for _, b := range r.balancer {
		for _, t := range b["selector"].([]string) {
			if !seen[t] {
				seen[t] = true
				out = append(out, t)
			}
		}
	}
	return out
}

func (r *renderer) routing() (obj, error) {
	var rules []obj
	final := obj{"network": "tcp,udp", "outboundTag": tagDirect}
	for _, rule := range r.plan.Rules {
		field, tag, err := r.target(rule.Target, 0)
		if err != nil {
			return nil, err
		}
		if rule.Type == engine.RuleMatchAll {
			final = obj{"network": "tcp,udp", field: tag}
			break
		}
		match, err := match(rule)
		if err != nil {
			return nil, err
		}
		match[field] = tag
		rules = append(rules, match)
	}
	// Xray sends unmatched traffic to the first outbound; the explicit last
	// rule makes the default route the one the plan asked for.
	rules = append(rules, final)
	out := obj{"domainStrategy": "IPIfNonMatch", "rules": rules}
	if len(r.balancer) > 0 {
		out["balancers"] = r.balancer
	}
	return out, nil
}

func match(rule engine.Rule) (obj, error) {
	v := rule.Value
	switch rule.Type {
	case engine.RuleDomain:
		return obj{"domain": []string{"full:" + v}}, nil
	case engine.RuleDomainSuffix:
		return obj{"domain": []string{"domain:" + v}}, nil
	case engine.RuleDomainKeyword:
		return obj{"domain": []string{"keyword:" + v}}, nil
	case engine.RuleGeoSite:
		return obj{"domain": []string{"geosite:" + strings.ToLower(v)}}, nil
	case engine.RuleIPCIDR:
		return obj{"ip": []string{v}}, nil
	case engine.RuleGeoIP:
		cc := strings.ToLower(v)
		if cc == "lan" {
			cc = "private"
		}
		return obj{"ip": []string{"geoip:" + cc}}, nil
	case engine.RulePort:
		return obj{"port": v}, nil
	case engine.RuleSrcPort:
		return obj{"sourcePort": v}, nil
	case engine.RuleProcess:
		return obj{"process": []string{v}}, nil
	case engine.RuleProtocol:
		return obj{"network": strings.ToLower(v)}, nil
	}
	return nil, fmt.Errorf("xray: rule type %q is not supported", rule.Type)
}

// dns renders the resolver list. A resolver the plan marks proxy-only goes
// through the routing table; every other one is dialed directly ("+local").
func (r *renderer) dns() (obj, error) {
	var servers []any
	for _, s := range r.plan.DNS.Servers {
		addr := s.Address
		if s.Port != 0 {
			addr = net.JoinHostPort(s.Address, strconv.Itoa(int(s.Port)))
		}
		local := "+local"
		if s.ProxyOnly {
			local = ""
		}
		switch s.Transport {
		case engine.DNSSystem:
			servers = append(servers, "localhost")
		case engine.DNSPlain, "":
			servers = append(servers, addr)
		case engine.DNSTCP:
			servers = append(servers, "tcp"+local+"://"+addr)
		case engine.DNSTLS:
			servers = append(servers, "tls://"+addr)
		case engine.DNSHTTPS:
			servers = append(servers, "https"+local+"://"+addr+"/dns-query")
		case engine.DNSQUIC:
			servers = append(servers, "quic+local://"+addr)
		default:
			return nil, fmt.Errorf("xray: dns transport %q is not supported", s.Transport)
		}
	}
	if len(servers) == 0 {
		servers = append(servers, "localhost")
	}
	strategy := "UseIPv4"
	if r.plan.Options.IPv6 {
		strategy = "UseIP"
	}
	return obj{"servers": servers, "queryStrategy": strategy}.set("disableCache", r.plan.DNS.DisableCache), nil
}

func logLevel(level string) string {
	switch level {
	case "silent":
		return "none"
	case "debug", "info", "warning", "error":
		return level
	}
	return "warning"
}

func orDefault(v, fallback string) string {
	if v == "" {
		return fallback
	}
	return v
}

// RenderProbe renders a configuration that puts every outbound behind its own
// loopback SOCKS inbound, so one Xray process measures many servers without
// touching the routing of a running session.
func RenderProbe(outbounds []engine.Outbound, ports []int) ([]byte, error) {
	if len(outbounds) != len(ports) {
		return nil, errors.New("xray: one port per outbound is required")
	}
	r := renderer{plan: &engine.Plan{Outbounds: outbounds}, tags: map[string]string{}, groups: map[string]engine.Group{}, byGroup: map[string]string{}}
	inbounds := make([]obj, 0, len(outbounds))
	rendered := make([]obj, 0, len(outbounds))
	rules := make([]obj, 0, len(outbounds))
	for i, o := range outbounds {
		r.tags[o.ID] = outboundTag(i)
		ob, err := r.outbound(o)
		if err != nil {
			return nil, err
		}
		in := "in-" + strconv.Itoa(i+1)
		inbounds = append(inbounds, obj{"tag": in, "protocol": "socks", "listen": "127.0.0.1", "port": ports[i]})
		rendered = append(rendered, ob)
		rules = append(rules, obj{"inboundTag": []string{in}, "outboundTag": r.tags[o.ID]})
	}
	return json.Marshal(obj{
		"log":       obj{"loglevel": "error"},
		"inbounds":  inbounds,
		"outbounds": rendered,
		"routing":   obj{"rules": rules},
	})
}
