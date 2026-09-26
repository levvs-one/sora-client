package soraerr

import (
	"context"
	"errors"
	"net"
	"testing"
)

func TestClassify(t *testing.T) {
	var dns *net.DNSError
	tests := []struct {
		name string
		err  error
		want Code
	}{
		{"deadline", context.DeadlineExceeded, CodeDeadlineExceeded},
		{"refused", &net.OpError{Err: errors.New("connection refused")}, CodeUnavailable},
		{"unknown", errors.New("private failure"), CodeInternal},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := Classify(tt.err)
			if got.Code() != tt.want {
				t.Fatalf("code=%v want=%v", got.Code(), tt.want)
			}
			if tt.name == "unknown" && got.Fingerprint() == "" {
				t.Fatal("missing fingerprint")
			}
		})
	}
	_ = dns
}

func TestCatalogEntries(t *testing.T) {
	for _, entry := range Entries() {
		if Catalog(entry.Code).Code != entry.Code {
			t.Fatalf("missing entry for %d", entry.Code)
		}
		for _, key := range []string{entry.UserTitleKey, entry.UserCauseKey} {
			if len(key) < 8 || key[:7] != "errors." {
				t.Fatalf("invalid key %q", key)
			}
		}
	}
}

func FuzzRedaction(f *testing.F) {
	filter := NewRedactionFilter("registered-secret")
	f.Add("registered-secret 192.0.2.1")
	f.Fuzz(func(t *testing.T, input string) {
		if got := filter.Filter(input); contains(got, "registered-secret") {
			t.Fatalf("secret survived: %q", got)
		}
	})
}
