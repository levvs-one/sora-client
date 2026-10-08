package clashapi

import (
	"context"
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"
)

// recorded stores the fake controller's last request for wire-level assertions.
type recorded struct {
	method, path, escapedPath, query, body, auth string
}

// newTestServer returns a client wired to a fake controller.
func newTestServer(t *testing.T, handler http.HandlerFunc) (*Client, *recorded) {
	t.Helper()
	rec := &recorded{}
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		body, _ := io.ReadAll(r.Body)
		rec.method, rec.path, rec.escapedPath, rec.query, rec.body, rec.auth =
			r.Method, r.URL.Path, r.URL.EscapedPath(), r.URL.RawQuery, string(body), r.Header.Get("Authorization")
		handler(w, r)
	}))
	t.Cleanup(server.Close)
	return NewClient(strings.TrimPrefix(server.URL, "http://"), "s3cret", 2*time.Second), rec
}

func jsonReply(w http.ResponseWriter, status int, payload any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(payload)
}

func TestVersionHandshake(t *testing.T) {
	client, rec := newTestServer(t, func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/version" {
			t.Errorf("unexpected path %s", r.URL.Path)
		}
		jsonReply(w, http.StatusOK, map[string]any{"meta": true, "version": "v1.19.32"})
	})
	info, err := client.Version(context.Background())
	if err != nil {
		t.Fatalf("Version: %v", err)
	}
	if info.Version != "v1.19.32" {
		t.Errorf("version = %s", info.Version)
	}
	if rec.auth != "Bearer s3cret" {
		t.Errorf("the secret must travel as a bearer token, got %q", rec.auth)
	}
}

func TestVersionRejectsClashForks(t *testing.T) {
	client, _ := newTestServer(t, func(w http.ResponseWriter, _ *http.Request) {
		jsonReply(w, http.StatusOK, map[string]any{"meta": false, "version": "0.20.1"})
	})
	if _, err := client.Version(context.Background()); !errors.Is(err, ErrNotMeta) {
		t.Fatalf("a non Meta core must be refused, got %v", err)
	}
}

func TestSelectSendsTheDocumentedRequest(t *testing.T) {
	client, rec := newTestServer(t, func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusNoContent)
	})
	if err := client.Select(context.Background(), "Group A/1", "tokyo-01"); err != nil {
		t.Fatalf("Select: %v", err)
	}
	if rec.method != http.MethodPut {
		t.Errorf("method = %s, want PUT", rec.method)
	}
	if rec.escapedPath != "/proxies/Group%20A%2F1" {
		t.Errorf("path = %s, want the group name percent-escaped", rec.escapedPath)
	}
	if !strings.Contains(rec.body, `"name":"tokyo-01"`) {
		t.Errorf("body = %s", rec.body)
	}
}

func TestDelaySendsMillisecondsAndMapsFailures(t *testing.T) {
	delayReply := 137
	client, rec := newTestServer(t, func(w http.ResponseWriter, _ *http.Request) {
		jsonReply(w, http.StatusOK, map[string]int{"delay": delayReply})
	})
	got, err := client.Delay(context.Background(), "tokyo-01", "https://www.gstatic.com/generate_204", 5*time.Second)
	if err != nil {
		t.Fatalf("Delay: %v", err)
	}
	if got != 137*time.Millisecond {
		t.Errorf("delay = %s, want 137ms", got)
	}
	if !strings.Contains(rec.query, "timeout=5000") || !strings.Contains(rec.query, "url=https") {
		t.Errorf("query = %s, want url and timeout in milliseconds", rec.query)
	}

	delayReply = -1
	if _, err := client.Delay(context.Background(), "tokyo-01", "", time.Second); !errors.Is(err, ErrDelayFailed) {
		t.Errorf("an unreachable proxy must surface as ErrDelayFailed, got %v", err)
	}
}

func TestCountersComeFromConnections(t *testing.T) {
	client, _ := newTestServer(t, func(w http.ResponseWriter, _ *http.Request) {
		jsonReply(w, http.StatusOK, map[string]any{
			"downloadTotal": 2048, "uploadTotal": 1024, "memory": 4096,
			"connections": []map[string]any{{"id": "1"}, {"id": "2"}},
		})
	})
	counters, err := client.Counters(context.Background())
	if err != nil {
		t.Fatalf("Counters: %v", err)
	}
	if counters.BytesUp != 1024 || counters.BytesDown != 2048 || counters.ActiveConnections != 2 || counters.MemoryBytes != 4096 {
		t.Errorf("unexpected counters: %+v", counters)
	}
}

func TestReloadPayloadUsesForceAndPayload(t *testing.T) {
	client, rec := newTestServer(t, func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusNoContent)
	})
	if err := client.ReloadPayload(context.Background(), "mixed-port: 7890\n"); err != nil {
		t.Fatalf("ReloadPayload: %v", err)
	}
	if rec.method != http.MethodPut || rec.path != "/configs" || rec.query != "force=true" {
		t.Errorf("request = %s %s?%s", rec.method, rec.path, rec.query)
	}
	if !strings.Contains(rec.body, "mixed-port") {
		t.Errorf("body = %s", rec.body)
	}
}

// TestListConnectionsReadsBothEngines checks real mihomo 1.19.32 and sing-box
// 1.14.2 responses.
func TestListConnectionsReadsBothEngines(t *testing.T) {
	for name, body := range map[string]string{
		"mihomo":   `{"downloadTotal":206756,"uploadTotal":1785,"connections":[{"id":"d86b2537","metadata":{"network":"tcp","type":"Socks5","sourceIP":"127.0.0.1","destinationIP":"","sourcePort":"47524","destinationPort":"443","host":"speed.cloudflare.com","process":"","processPath":"/usr/bin/curl","sniffHost":""},"upload":1785,"download":206756,"start":"2026-10-06T15:16:05.577928007+03:00","chains":["Tokyo","Proxy"],"rule":"Match","rulePayload":""}]}`,
		"sing-box": `{"downloadTotal":206739,"uploadTotal":1785,"connections":[{"chains":["Tokyo","Proxy"],"download":206739,"id":"d86b2537","metadata":{"destinationIP":"","destinationPort":"443","host":"speed.cloudflare.com","network":"tcp","processPath":"/usr/bin/curl","sourceIP":"127.0.0.1","sourcePort":"59950","type":"mixed/0"},"rule":"final","rulePayload":"","start":"2026-10-06T15:16:05.448171201+03:00","upload":1785}]}`,
	} {
		t.Run(name, func(t *testing.T) {
			client, rec := newTestServer(t, func(w http.ResponseWriter, _ *http.Request) { _, _ = io.WriteString(w, body) })
			list, err := client.ListConnections(context.Background())
			if err != nil || len(list) != 1 {
				t.Fatalf("ListConnections = %v, %v", list, err)
			}
			c := list[0]
			if c.Host != "speed.cloudflare.com" || c.Port != 443 || c.Process != "curl" || c.Download < 200000 ||
				c.Start.Year() != 2026 || len(c.Chain) != 2 || c.Chain[0] != "Proxy" {
				t.Fatalf("connection = %+v", c)
			}
			if err := client.CloseConnection(context.Background(), "d86b2537"); err != nil || rec.method != http.MethodDelete || rec.path != "/connections/d86b2537" {
				t.Fatalf("close = %v %s %s", err, rec.method, rec.path)
			}
		})
	}
}
