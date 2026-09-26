package soraerr

import "testing"

func TestRedactionFilter(t *testing.T) {
	filter := NewRedactionFilter("server.example", "secret-value")
	input := "server.example 192.0.2.1 [2001:db8::1] secret-value uuid=123e4567-e89b-12d3-a456-426614174000 https://user:pass@example.test/path?token=abc vless://uuid@example.test:443"
	got := filter.Filter(input)
	for _, want := range []string{"<secret>", "<ip>", "<uuid>", "<url>"} {
		if !contains(got, want) {
			t.Fatalf("redacted output %q does not contain %q", got, want)
		}
	}
	for _, forbidden := range []string{"server.example", "192.0.2.1", "secret-value", "123e4567"} {
		if contains(got, forbidden) {
			t.Fatalf("redacted output contains %q: %q", forbidden, got)
		}
	}
}

func contains(s, sub string) bool {
	for i := 0; i+len(sub) <= len(s); i++ {
		if s[i:i+len(sub)] == sub {
			return true
		}
	}
	return false
}
