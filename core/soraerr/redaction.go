package soraerr

import (
	"net"
	"regexp"
	"strings"
	"sync"
)

var (
	redactIP = regexp.MustCompile(`(?i)(?:::ffff:)?(?:\d{1,3}\.){3}\d{1,3}|\[(?:[0-9a-f]{0,4}:){2,7}[0-9a-f]{0,4}\]`)
	redactUUID = regexp.MustCompile(`(?i)\b[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\b`)
	redactURL = regexp.MustCompile(`(?i)\b(?:https?|vless|vmess|trojan|ss|socks5?)://[^\s]+`)
	redactParam = regexp.MustCompile(`(?i)(password|passwd|token|uuid|access[_-]?token|secret)=([^&\s]+)`)
	redactBase64 = regexp.MustCompile(`\b[A-Za-z0-9+/]{64,}={0,2}\b`)
)

// RedactionFilter removes connection secrets and server-identifying data.
type RedactionFilter struct { mu sync.RWMutex; secrets []string }

// NewRedactionFilter creates a filter with the supplied secret values.
func NewRedactionFilter(secrets ...string) *RedactionFilter { f := &RedactionFilter{}; f.AddSecrets(secrets...); return f }

// DefaultRedaction is the process-wide filter used by constructors.
var DefaultRedaction = NewRedactionFilter()

// AddSecrets registers values that must be replaced before output.
func (f *RedactionFilter) AddSecrets(secrets ...string) { f.mu.Lock(); defer f.mu.Unlock(); for _, secret := range secrets { if secret != "" { f.secrets = append(f.secrets, secret) } } }

// Filter returns deterministic, redacted text and is safe for concurrent use.
func (f *RedactionFilter) Filter(input string) string {
	if input == "" { return "" }
	f.mu.RLock(); secrets := append([]string(nil), f.secrets...); f.mu.RUnlock()
	out := input
	for _, secret := range secrets { out = strings.ReplaceAll(out, secret, "<secret>") }
	out = redactURL.ReplaceAllString(out, "<url>")
	out = redactParam.ReplaceAllString(out, "$1=<secret>")
	out = redactUUID.ReplaceAllString(out, "<uuid>")
	out = redactIP.ReplaceAllStringFunc(out, func(s string) string { if strings.Contains(s, ":") { return "<ip>" }; if net.ParseIP(s) != nil { return "<ip>" }; return s })
	return redactBase64.ReplaceAllString(out, "<blob>")
}
