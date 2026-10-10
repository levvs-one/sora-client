// Package enginetest builds shared plans for validation by each engine binary.
package enginetest

import (
	"fmt"
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
)

// Outbound returns a test outbound for p with keys matching engine-required
// lengths.
func Outbound(p engine.Protocol) engine.Outbound {
	const (
		uuid    = "b831381d-6324-4d53-ad4f-8cda48b30811"
		pubKey  = "Z84J2IelR9ch3k8VtlVhhs5ycBUlXA7wHBWcBrjqnAw"
		privKey = "cKE7LmCF61IhqqABGhvJ44jWXp8fKymcMAEVAzLDYVk="
		wgPeer  = "Z84J2IelR9ch3k8VtlVhhs5ycBUlXA7wHBWcBrjqnAw="
	)
	o := engine.Outbound{ID: string(p), Name: "Test " + string(p), Protocol: p, Server: "edge.example.com", Port: 443}
	switch p {
	case engine.ProtocolVLESS:
		o.UUID, o.Flow = uuid, "xtls-rprx-vision"
		o.TLS = engine.TLS{Enabled: true, Reality: true, ServerName: "www.example.com", Fingerprint: "chrome",
			RealityPublicKey: pubKey, RealityShortID: "6ba85179e30d4fc2"}
	case engine.ProtocolVMess:
		o.UUID = uuid
		o.Transport = engine.Transport{Type: "ws", Path: "/ws", Host: "cdn.example.com"}
		o.TLS = engine.TLS{Enabled: true, ServerName: "cdn.example.com"}
	case engine.ProtocolTrojan:
		o.Password = "trojan-test-password"
		o.Transport = engine.Transport{Type: "grpc", Service: "tunnel"}
		o.TLS = engine.TLS{Enabled: true, ServerName: "edge.example.com", ALPN: []string{"h2"}}
	case engine.ProtocolShadowsocks:
		o.Cipher, o.Password = "2022-blake3-aes-128-gcm", "MTIzNDU2Nzg5MDEyMzQ1Ng=="
	case engine.ProtocolHysteria2:
		o.Password, o.Obfs, o.ObfsParam = "hy2-test-password", "salamander", "obfs-test-password"
		o.TLS = engine.TLS{Enabled: true, ServerName: "edge.example.com"}
	case engine.ProtocolTUIC:
		o.UUID, o.Password = uuid, "tuic-test-password"
		o.TLS = engine.TLS{Enabled: true, ServerName: "edge.example.com", ALPN: []string{"h3"}}
	case engine.ProtocolAnyTLS:
		o.Password = "anytls-test-password"
		o.TLS = engine.TLS{Enabled: true, ServerName: "edge.example.com"}
	case engine.ProtocolWireGuard:
		o.Server, o.Port = "198.51.100.7", 51820
		o.PrivateKey, o.Addresses = privKey, []string{"10.7.0.2/32"}
		o.Peers = []engine.WireGuardPeer{{PublicKey: wgPeer, Endpoint: "198.51.100.7:51820", PersistentKeepalive: 25}}
	case engine.ProtocolSOCKS5, engine.ProtocolHTTP:
		o.UserID, o.Password = "user", "proxy-test-password"
	case engine.ProtocolDirect:
		o.Server, o.Port = "", 0
	}
	return o
}

// Plan includes every protocol, select and automatic groups, geo/domain rules,
// and three DNS transports. TUN is disabled so validators can run without
// device privileges.
func Plan(protocols ...engine.Protocol) *engine.Plan {
	p := &engine.Plan{
		SessionID:  "enginetest",
		LocalProxy: engine.LocalProxy{Enabled: true},
		Options:    engine.Options{LogLevel: "warning", Mode: "rule", TestURL: engine.TestURLProduction},
		DNS: engine.DNS{Enabled: true, Servers: []engine.DNSServer{
			{Tag: "local", Transport: engine.DNSSystem, Address: "system"},
			{Tag: "doh", Transport: engine.DNSHTTPS, Address: "1.1.1.1", ProxyOnly: true},
			{Tag: "dot", Transport: engine.DNSTLS, Address: "dns.google"},
		}},
	}
	ids := make([]string, 0, len(protocols))
	for _, proto := range protocols {
		p.Outbounds = append(p.Outbounds, Outbound(proto))
		ids = append(ids, string(proto))
	}
	p.Groups = []engine.Group{
		{Name: "Auto", Type: engine.GroupURLTest, Outbounds: ids, Interval: 300, Tolerance: 50},
		{Name: "Proxy", Type: engine.GroupSelect, Outbounds: append([]string{"Auto"}, ids...)},
	}
	p.Rules = []engine.Rule{
		{Type: engine.RuleGeoIP, Value: "private", Target: "direct", NoResolve: true},
		{Type: engine.RuleDomainSuffix, Value: "ru", Target: "direct"},
		{Type: engine.RuleGeoSite, Value: "category-ads-all", Target: "reject"},
		{Type: engine.RuleIPCIDR, Value: "203.0.113.0/24", Target: "Proxy"},
		{Type: engine.RulePort, Value: "853", Target: "Proxy"},
		{Type: engine.RuleMatchAll, Target: "Proxy"},
	}
	return p
}

// AmneziaWG returns a WireGuard outbound with AmneziaWG 2.0 parameters,
// including a header range and a signature packet.
func AmneziaWG() engine.Outbound {
	o := Outbound(engine.ProtocolWireGuard)
	o.ID, o.Name = "amneziawg", "Test amneziawg"
	o.Amnezia = &engine.AmneziaWG{
		Jc: 4, Jmin: 40, Jmax: 70, S1: 15, S2: 25, S3: 10, S4: 5,
		H1: "100000-100100", H2: "200000-200100", H3: "300000", H4: "400000",
		I1: "<b 0xf6ab3267fa><c><b 0xf6ab><t><r 10><wt 10>",
	}
	return o
}

// TrustCertificate uses the real engines with a test-local CA after SafeEnv
// filtering. It never changes the host certificate store or production trust.
func TrustCertificate(t *testing.T, certificate string) {
	t.Helper()
	if runtime.GOOS != "linux" {
		t.Skip("local CA wrapper requires Linux")
	}
	quote := func(value string) string { return "'" + strings.ReplaceAll(value, "'", "'\\''") + "'" }
	dir := t.TempDir()
	for _, core := range []struct{ name, env string }{
		{"sing-box", "SORA_SINGBOX_BIN"}, {"xray", "SORA_XRAY_BIN"}, {"mihomo", "SORA_MIHOMO_BIN"},
	} {
		binary := os.Getenv(core.env)
		if binary == "" {
			binary = filepath.Join(os.Getenv("SORA_ENGINES_DIR"), core.name)
		}
		wrapper := filepath.Join(dir, core.name)
		script := fmt.Sprintf("#!/bin/sh\nSSL_CERT_FILE=%s exec %s \"$@\"\n", quote(certificate), quote(binary))
		if err := os.WriteFile(wrapper, []byte(script), 0700); err != nil { //nolint:gosec // test-local wrapper must be executable
			t.Fatal(err)
		}
		t.Setenv(core.env, wrapper)
	}
}
