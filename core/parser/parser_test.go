package parser

import (
	"encoding/base64"
	"strings"
	"testing"
)

func TestParseLinks(t *testing.T) {
	tests := []struct{ name, input, protocol string }{
		{"vless", "vless://123e4567-e89b-12d3-a456-426614174000@example.com:443?security=tls&type=ws&path=%2F#🇩🇪%20Berlin", "vless"},
		{"trojan", "trojan://secret@example.com:443?sni=example.com#Trojan", "trojan"},
		{"shadowsocks", "ss://YWVzLTI1Ni1nY206cGFzcw@example.com:8388#SS", "ss"},
		{"hysteria2", "hysteria2://secret@example.com:443?sni=example.com#H2", "hysteria2"},
		{"tuic", "tuic://123e4567-e89b-12d3-a456-426614174000:pass@example.com:443", "tuic"},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			r, err := (LinkParser{}).Parse([]byte(tt.input))
			if err != nil {
				t.Fatal(err)
			}
			if len(r.Servers) != 1 || r.Servers[0].Protocol != tt.protocol {
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
