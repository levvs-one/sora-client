//go:build windows

package guard_test

import (
	"net"
	"net/http"
	"os/exec"
	"strings"
	"testing"

	"github.com/levvs-one/sora-client/core/guard"
)

// fetch asks curl, a program the kill switch does not know, for a page and
// reports the HTTP status, or the empty string when no connection was made.
func fetch(t *testing.T, url string) string {
	t.Helper()
	out, _ := exec.CommandContext(t.Context(), "curl.exe", "-s", "-o", "NUL", "-m", "5", "-w", "%{http_code}", url).Output() //nolint:gosec // fixed test addresses
	code := strings.TrimSpace(string(out))
	if code == "000" {
		return ""
	}
	return code
}

func TestWFPBlocksWhatIsNotTheTunnel(t *testing.T) {
	const outside = "http://example.com/"
	if fetch(t, outside) == "" {
		t.Skip("this machine reaches nothing outside; nothing to block")
	}
	local, err := (&net.ListenConfig{}).Listen(t.Context(), "tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	server := &http.Server{Handler: http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) { w.WriteHeader(http.StatusNoContent) })} //nolint:gosec // a test server on loopback
	go func() { _ = server.Serve(local) }()
	t.Cleanup(func() { _ = server.Close() })

	firewall, err := guard.PlatformFirewall(guard.FirewallOptions{EnginesDir: t.TempDir()})
	if err != nil {
		t.Fatal(err)
	}
	ctx := t.Context()
	if err := firewall.Arm(ctx, nil); err != nil {
		t.Fatalf("Arm() = %v", err)
	}
	t.Cleanup(func() { _ = firewall.Disarm(ctx) })
	if armed, _ := firewall.Armed(ctx); !armed {
		t.Error("Armed() = false after Arm")
	}
	if code := fetch(t, outside); code != "" {
		t.Errorf("an unknown program reached %s through the kill switch: %s", outside, code)
	}
	if code := fetch(t, "http://"+local.Addr().String()+"/"); code != "204" {
		t.Errorf("loopback was blocked: %q", code)
	}
	if err := firewall.Arm(ctx, nil); err != nil {
		t.Errorf("a second Arm() = %v", err)
	}
	if err := firewall.Disarm(ctx); err != nil {
		t.Fatalf("Disarm() = %v", err)
	}
	if code := fetch(t, outside); code == "" {
		t.Error("the block outlived Disarm")
	}
}
