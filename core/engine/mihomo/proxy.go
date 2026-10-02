package mihomo

import (
	"fmt"
	"strings"
	"unicode"

	"github.com/levvs-one/sora-client/core/engine"
)

// buildProxy maps one outbound onto a mihomo proxy entry. The name is filled
// in by the caller, because uniqueness can only be decided across the plan.
func buildProxy(o engine.Outbound) (proxy, error) {
	udp := o.Protocol != engine.ProtocolHTTP && o.Protocol != engine.ProtocolSOCKS5
	px := proxy{Type: "ss", Tag: o.ID, UDP: &udp, IPVer: "dual"}
	if o.Server == "" {
		return proxy{}, fmt.Errorf("mihomo: outbound %s has no server", o.ID)
	}
	px.Server = o.Server
	px.Port = int(o.Port)

	switch o.Protocol {
	case engine.ProtocolShadowsocks:
		px.Type = "ss"
		px.Cipher = orDefault(o.Cipher, "aes-256-gcm")
		px.Password = o.Password
		if o.Obfs != "" {
			px.Obfs = o.Obfs
			px.ObfsParam = o.ObfsParam
		}
	case engine.ProtocolVMess:
		px.Type = "vmess"
		px.UUID = o.UUID
		px.Cipher = orDefault(o.Cipher, "auto")
	case engine.ProtocolVLESS:
		px.Type = "vless"
		px.UUID = o.UUID
		px.Flow = o.Flow
	case engine.ProtocolTrojan:
		px.Type = "trojan"
		px.Password = o.Password
	case engine.ProtocolHysteria2:
		px.Type = "hysteria2"
		px.Password = o.Password
		if o.Obfs != "" {
			px.Obfs = o.Obfs
			px.ObfsPassword = o.ObfsParam
		}
	case engine.ProtocolTUIC:
		px.Type = "tuic"
		px.UUID = o.UUID
		px.Password = o.Password
	case engine.ProtocolWireGuard:
		px.Type = "wireguard"
		px.PrivateKey = o.PrivateKey
		px.MTU = 1420
		for _, peer := range o.Peers {
			px.Peers = append(px.Peers, wireguardPeer{
				PublicKey:           peer.PublicKey,
				PresharedKey:        peer.PreSharedKey,
				Endpoint:            peer.Endpoint,
				AllowedIPs:          peer.AllowedIPs,
				PersistentKeepalive: peer.PersistentKeepalive,
			})
		}
		if len(px.Peers) == 0 {
			return proxy{}, fmt.Errorf("mihomo: wireguard outbound %s has no peer", o.ID)
		}
	case engine.ProtocolSOCKS5:
		px.Type = "socks5"
		px.Username = o.UserID
		px.Password = o.Password
		return px, nil
	case engine.ProtocolHTTP:
		px.Type = "http"
		px.Username = o.UserID
		px.Password = o.Password
		return px, nil
	default:
		return proxy{}, fmt.Errorf("mihomo: protocol %q is not supported", o.Protocol)
	}

	applyTransport(&px, o.Transport)
	if err := applyTLS(&px, o); err != nil {
		return proxy{}, err
	}
	return px, nil
}

// applyTransport writes the transport keys. mihomo reads a flat key set per
// transport, so the values stay next to the transport name.
func applyTransport(px *proxy, t engine.Transport) {
	switch t.Type {
	case "", "tcp", "raw":
		px.Network = "tcp"
	case "ws", "websocket":
		px.Network = "ws"
		px.WSPath = t.Path
		if len(t.Headers) > 0 {
			px.WSHeaders = t.Headers
		}
	case "grpc", "gRPC":
		px.Network = "grpc"
		px.GRPCService = t.Service
	case "h2", "http", "http/2":
		px.Network = "h2"
		px.H2Path = t.Path
		if t.Host != "" {
			px.H2Host = t.Host
		}
	case "xhttp", "xup", "httpupgrade":
		px.Network = t.Type
		px.HTTPath = t.Path
		if len(t.Headers) > 0 {
			px.Headers = t.Headers
		}
	default:
		px.Network = t.Type
		px.HTTPath = t.Path
	}
}

// applyTLS writes TLS, SNI, ALPN, uTLS fingerprint and Reality parameters.
func applyTLS(px *proxy, o engine.Outbound) error {
	if o.Protocol == engine.ProtocolWireGuard {
		return nil
	}
	enabled := o.TLS.Enabled
	switch o.Protocol {
	case engine.ProtocolTrojan, engine.ProtocolHysteria2, engine.ProtocolTUIC:
		enabled = true
	}
	px.TLS = &enabled
	if o.TLS.ServerName != "" {
		px.SNI = o.TLS.ServerName
	}
	if len(o.TLS.ALPN) > 0 {
		px.ALPN = o.TLS.ALPN
	}
	if o.TLS.Fingerprint != "" {
		px.Fingerprint = o.TLS.Fingerprint
	}
	if o.TLS.Insecure {
		skip := true
		px.SkipCertVerify = &skip
	}
	if o.TLS.Reality {
		if o.TLS.RealityPublicKey == "" {
			return fmt.Errorf("mihomo: outbound %s uses reality without a public key", o.ID)
		}
		px.Reality = &reality{PublicKey: o.TLS.RealityPublicKey, ShortID: o.TLS.RealityShortID}
	}
	return nil
}

// sanitizeName turns an untrusted display name into an engine name. mihomo
// addresses proxies by name in URLs and rule lines, so a name carrying a
// comma, a slash or a control character would change routing or break the API.
func sanitizeName(name, fallback string) string {
	src := name
	if src == "" {
		src = fallback
	}
	var b strings.Builder
	for _, r := range src {
		switch {
		case unicode.IsLetter(r) || unicode.IsDigit(r):
			b.WriteRune(r)
		case r == '-', r == '_', r == '.':
			b.WriteRune(r)
		case r == ' ':
			b.WriteRune('_')
		}
		if b.Len() > 96 {
			break
		}
	}
	out := strings.Trim(b.String(), "-_.")
	if out == "" {
		out = "server"
	}
	return out
}

// uniqueName appends a counter until the name is free.
func uniqueName(name string, used map[string]struct{}) string {
	candidate := name
	for i := 2; ; i++ {
		if _, taken := used[candidate]; !taken {
			used[candidate] = struct{}{}
			return candidate
		}
		candidate = fmt.Sprintf("%s-%d", name, i)
	}
}

func orDefault(v, fallback string) string {
	if strings.TrimSpace(v) == "" {
		return fallback
	}
	return v
}

func orDefaultInt(v, fallback int) int {
	if v <= 0 {
		return fallback
	}
	return v
}

func sortedMap(m map[string]string) map[string]string {
	out := make(map[string]string, len(m))
	keys := make([]string, 0, len(m))
	for k := range m {
		keys = append(keys, k)
	}
	for _, k := range keys {
		out[k] = m[k]
	}
	return out
}
