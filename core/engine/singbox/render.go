// Package singbox runs sing-box as a supervised child process and implements
// engine.Engine on top of its HTTP REST API (compatible with Clash API).
package singbox

import (
	"encoding/json"
	"net"
	"strconv"
	"strings"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/errs"
)

// Render builds a sing-box JSON config from a plan.
func Render(p *engine.Plan, rt Runtime) (string, error) {
	// Build outbounds: one per plan outbound, plus direct/block/dns fallbacks.
	var outbounds []Outbound

	// Proxy outbounds from the plan.
	for i := range p.Outbounds {
		proxy, err := buildProxyOutbound(&p.Outbounds[i], rt)
		if err != nil {
			return "", err
		}
		outbounds = append(outbounds, proxy)
	}

	// Built-in fallbacks.
	outbounds = append(outbounds,
		Outbound{Type: "direct", Tag: "direct"},
		Outbound{Type: "block", Tag: "block"},
		Outbound{Type: "dns", Tag: "dns-out"},
	)

	// Selector for URL test / latency test groups.
	proxyTags := make([]string, len(p.Outbounds))
	for i, ob := range p.Outbounds {
		proxyTags[i] = ob.ID
	}
	if len(proxyTags) > 0 {
		outbounds = append(outbounds,
			Outbound{
				Type:      "urltest",
				Tag:       "auto",
				Outbounds: proxyTags,
			},
		)
	}

	// Inbounds: tun + mixed (HTTP+SOCKS) on the reserved port.
	inbounds := []Inbound{
		{
			Type:  "tun",
			Tag:   "tun-in",
			Sniff: true,
		},
		{
			Type:       "mixed",
			Tag:        "mixed-in",
			Listen:     "127.0.0.1",
			ListenPort: rt.MixedPort,
			Sniff:      true,
		},
	}

	// DNS
	dns := buildDNS(p.DNS)

	// Route rules from plan.
	route := buildRoute(p.Rules, nil)

	cfg := JSONConfig{
		Log: LogConfig{
			Level:     "info",
			Output:    "stdout",
			Timestamp: true,
		},
		DNS:       dns,
		Inbounds:  inbounds,
		Outbounds: outbounds,
		Route:     route,
	}

	if rt.ControllerAddr != "" {
		host, portStr, _ := net.SplitHostPort(rt.ControllerAddr)
		port, _ := strconv.Atoi(portStr)
		cfg.Experimental.ClashAPI = &ClashAPIConfig{
			Enabled: true,
			Listen:  rt.ControllerAddr,
			Secret:  rt.Secret,
		}
		// Also add API inbound for external controller
		cfg.Inbounds = append(cfg.Inbounds, Inbound{
			Type:       "http",
			Tag:        "api-in",
			Listen:     host,
			ListenPort: port,
		})
	}

	data, err := json.MarshalIndent(cfg, "", "  ")
	if err != nil {
		return "", errs.Wrap(err, errs.CodeInternal, errs.KeyEngineStartFailed)
	}
	return string(data), nil
}

func buildProxyOutbound(ob *engine.Outbound, rt Runtime) (Outbound, error) {
	// The plan carries the credentials directly in the outbound struct.
	// For sing-box we inline the credentials because sing-box doesn't have
	// a separate secret store.

	var proxy Outbound
	proxy.Tag = ob.ID
	proxy.Type = mapProtocol(string(ob.Protocol))
	proxy.Server = ob.Server
	proxy.ServerPort = int(ob.Port)

	// Apply credentials from the outbound struct.
	proxy.UUID = ob.UUID
	proxy.Password = ob.Password
	proxy.Method = ob.Cipher
	proxy.Flow = ob.Flow
	proxy.Method = ob.Obfs
	// ObfsParam, UserID, PrivateKey, PublicKey would be mapped as needed

	// Transport
	if ob.Transport.Type != "" {
		proxy.Transport = &TransportConfig{Type: mapTransport(ob.Transport.Type)}
	}

	// TLS
	if ob.TLS.Enabled {
		proxy.TLS = &TLSConfig{Enabled: true}
		if ob.TLS.ServerName != "" {
			proxy.TLS.ServerName = ob.TLS.ServerName
		}
		if ob.TLS.Insecure {
			proxy.TLS.Insecure = true
		}
		// Reality config would be mapped here if needed
	}

	// Multiplex
	proxy.Multiplex = &MultiplexConfig{
		Enabled:    true,
		Protocol:   "smux",
		MaxStreams: 4,
	}

	return proxy, nil
}

func mapProtocol(p string) string {
	switch strings.ToLower(p) {
	case "vless":
		return "vless"
	case "vmess":
		return "vmess"
	case "trojan":
		return "trojan"
	case "shadowsocks", "ss":
		return "shadowsocks"
	case "hysteria2", "h2":
		return "hysteria2"
	case "tuic":
		return "tuic"
	case "wireguard", "wg":
		return "wireguard"
	case "socks", "socks5":
		return "socks"
	case "http":
		return "http"
	default:
		return p
	}
}

func mapTransport(t string) string {
	switch strings.ToLower(t) {
	case "ws", "websocket":
		return "ws"
	case "grpc":
		return "grpc"
	case "httpupgrade", "h2":
		return "httpupgrade"
	case "quic":
		return "quic"
	case "tcp", "":
		return "tcp"
	default:
		return t
	}
}

func buildDNS(dns engine.DNS) DNSConfig {
	cfg := DNSConfig{
		Strategy: "prefer_ipv4",
		Final:    "system",
	}
	for _, s := range dns.Servers {
		cfg.Servers = append(cfg.Servers, DNSServer{
			Address: s.Address,
		})
	}
	return cfg
}

func buildRoute(rules []engine.Rule, bypass []string) RouteConfig {
	var routeRules []RouteRule

	// Bypass rules -> direct
	for _, b := range bypass {
		routeRules = append(routeRules, RouteRule{
			Type:         "domain_suffix",
			DomainSuffix: []string{b},
			Outbound:     "direct",
		})
	}

	// Plan rules
	for _, r := range rules {
		routeRules = append(routeRules, RouteRule{
			Type:         "domain_suffix",
			DomainSuffix: []string{r.Value},
			Outbound:     r.Target,
		})
	}

	// Default final
	return RouteConfig{
		Rules: routeRules,
		Final: "auto",
	}
}
