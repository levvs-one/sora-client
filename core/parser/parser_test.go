package parser

import (
	"encoding/base64"
	"strings"
	"testing"
)

func TestParseLinks(t *testing.T) {
	// Normalize schemes and apply protocol-specific security defaults.
	tests := []struct{ name, input, protocol, security string }{
		{"vless", "vless://123e4567-e89b-12d3-a456-426614174000@example.com:443?security=tls&type=ws&path=%2F#🇩🇪%20Berlin", "vless", "tls"},
		{"vless plain", "vless://123e4567-e89b-12d3-a456-426614174000@example.com:443", "vless", "none"},
		{"trojan", "trojan://secret@example.com:443?sni=example.com#Trojan", "trojan", "tls"},
		{"shadowsocks", "ss://YWVzLTI1Ni1nY206cGFzcw@example.com:8388#SS", "shadowsocks", "none"},
		{"hysteria2", "hysteria2://secret@example.com:443?sni=example.com#H2", "hysteria2", "tls"},
		{"hy2", "hy2://secret@example.com:443#H2", "hysteria2", "tls"},
		{"tuic", "tuic://123e4567-e89b-12d3-a456-426614174000:pass@example.com:443", "tuic", "tls"},
		{"socks", "socks://user:pass@example.com:1080", "socks5", "none"},
		{"socks5", "socks5://example.com:1080", "socks5", "none"},
		{"https", "https://user:pass@example.com:443", "http", "tls"},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			r, err := (LinkParser{}).Parse([]byte(tt.input))
			if err != nil {
				t.Fatal(err)
			}
			if len(r.Servers) != 1 || r.Servers[0].Protocol != tt.protocol || r.Servers[0].Security != tt.security {
				t.Fatalf("unexpected result: %#v", r)
			}
		})
	}
}

func TestBase64Wrapped(t *testing.T) {
	raw := "vless://123e4567-e89b-12d3-a456-426614174000@example.com:443\n"
	enc := base64.StdEncoding.EncodeToString([]byte(raw))
	enc = strings.Join([]string{enc[:8], enc[8:]}, "\n")
	r, err := (LinkParser{}).Parse([]byte(enc))
	if err != nil || r.Report.Imported != 1 {
		t.Fatalf("result=%#v err=%v", r, err)
	}
}

func TestRejectsHTTPSubscription(t *testing.T) {
	if _, err := (LinkParser{}).Parse([]byte("http://example.com/sub")); err == nil {
		t.Fatal("expected rejection")
	}
}
func TestLimit(t *testing.T) {
	r, err := (LinkParser{MaxItems: 1}).Parse([]byte("vless://123e4567-e89b-12d3-a456-426614174000@a.example:443\nvless://123e4567-e89b-12d3-a456-426614174000@b.example:443"))
	if err != nil {
		t.Fatal(err)
	}
	if r.Report.Unsupported != 1 {
		t.Fatalf("%#v", r.Report)
	}
}
func FuzzDetect(f *testing.F) {
	f.Add([]byte("vless://x.example:443"))
	f.Fuzz(func(_ *testing.T, b []byte) { _, _ = (ImportDetector{}).Detect(b) })
}
func FuzzParseLink(f *testing.F) {
	f.Add("vless://123e4567-e89b-12d3-a456-426614174000@example.com:443")
	f.Fuzz(func(_ *testing.T, s string) { _, _ = (LinkParser{MaxItems: 100}).Parse([]byte(s)) })
}
func BenchmarkParseBase64Subscription(b *testing.B) {
	var lines strings.Builder
	for i := 0; i < 5000; i++ {
		lines.WriteString("vless://123e4567-e89b-12d3-a456-426614174000@example.com:443?type=tcp\n")
	}
	encoded := base64.StdEncoding.EncodeToString([]byte(lines.String()))
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_, _ = (LinkParser{}).Parse([]byte(encoded))
	}
}

// TestXrayConfigurationsBecomeProfiles checks one profile per configuration in
// Remnawave-style subscription lists.
func TestXrayConfigurationsBecomeProfiles(t *testing.T) {
	config := func(name string) string {
		return `{"remarks":"` + name + `","inbounds":[{"listen":"127.0.0.1","port":10808,"protocol":"socks"}],
		"outbounds":[{"tag":"proxy","protocol":"vless","settings":{"vnext":[{"address":"185.92.222.239","port":443,
		"users":[{"id":"123e4567-e89b-12d3-a456-426614174000","encryption":"none"}]}]},
		"streamSettings":{"network":"xhttp","security":"reality","realitySettings":{"publicKey":"k","shortId":"s"}}},
		{"protocol":"freedom","tag":"direct"}],"routing":{"rules":[{"domain":["domain:openai.com"],"outboundTag":"proxy"}]}}`
	}
	r, err := (LinkParser{}).Parse([]byte("[" + config("🇳🇱 Нидерланды") + "," + config("Авто") + "]"))
	if err != nil {
		t.Fatal(err)
	}
	if len(r.Servers) != 2 {
		t.Fatalf("servers = %d, report %+v", len(r.Servers), r.Report)
	}
	a, b := r.Servers[0], r.Servers[1]
	if a.Protocol != "xray-profile" || a.DisplayName != "🇳🇱 Нидерланды" || a.Host != "185.92.222.239" || a.Port != 443 {
		t.Fatalf("profile = %+v", a)
	}
	if a.Transport != "xhttp" || a.Security != "reality" || a.CountryCode != "🇳🇱" {
		t.Fatalf("transport, security and country come from the profile: %+v", a)
	}
	if a.Options["profile"] == "" {
		t.Fatal("the configuration travels whole")
	}
	if a.StableKey() == b.StableKey() {
		t.Fatal("two profiles on one server must keep two identities")
	}
}
