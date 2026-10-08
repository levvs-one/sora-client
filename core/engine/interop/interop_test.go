// Package interop_test checks real traffic through all engines using a local
// Xray server and HTTP target. Validators alone miss ignored keys, including in
// mihomo. SORA_ENGINES_DIR must contain sing-box, xray, and mihomo.
package interop_test

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net"
	"net/http"
	"net/http/httptest"
	"net/url"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/registry"
	"github.com/levvs-one/sora-client/core/engine/supervise"
	"github.com/levvs-one/sora-client/core/engine/xray"
	"github.com/levvs-one/sora-client/core/logs"
)

const (
	uuid     = "b831381d-6324-4d53-ad4f-8cda48b30811"
	password = "interop-test-password"
	reply    = "sora-interop-ok"
)

type service struct {
	name     string
	inbound  map[string]any
	outbound engine.Outbound
}

func port(t *testing.T) int {
	t.Helper()
	p, err := supervise.FreePort()
	if err != nil {
		t.Fatal(err)
	}
	return p
}

// services lists the server side of each case and the plan outbound that
// should reach it.
func services(t *testing.T) []service {
	vless := func(stream map[string]any) map[string]any {
		return map[string]any{"protocol": "vless", "settings": map[string]any{
			"clients": []any{map[string]any{"id": uuid}}, "decryption": "none"},
			"streamSettings": stream}
	}
	var out []service
	add := func(name string, inbound map[string]any, o engine.Outbound) {
		p := port(t)
		inbound["listen"], inbound["port"], inbound["tag"] = "127.0.0.1", p, name
		o.ID, o.Name, o.Server, o.Port = name, name, "127.0.0.1", uint16(p)
		out = append(out, service{name: name, inbound: inbound, outbound: o})
	}
	add("vless-tcp", vless(map[string]any{"network": "raw"}),
		engine.Outbound{Protocol: engine.ProtocolVLESS, UUID: uuid})
	add("vless-ws", vless(map[string]any{"network": "ws", "wsSettings": map[string]any{"path": "/ws"}}),
		engine.Outbound{Protocol: engine.ProtocolVLESS, UUID: uuid, Transport: engine.Transport{Type: "ws", Path: "/ws", Host: "cdn.example.com"}})
	add("vless-grpc", vless(map[string]any{"network": "grpc", "grpcSettings": map[string]any{"serviceName": "tun"}}),
		engine.Outbound{Protocol: engine.ProtocolVLESS, UUID: uuid, Transport: engine.Transport{Type: "grpc", Service: "tun"}})
	add("vless-httpupgrade", vless(map[string]any{"network": "httpupgrade", "httpupgradeSettings": map[string]any{"path": "/up"}}),
		engine.Outbound{Protocol: engine.ProtocolVLESS, UUID: uuid, Transport: engine.Transport{Type: "httpupgrade", Path: "/up"}})
	add("vless-xhttp", vless(map[string]any{"network": "xhttp", "xhttpSettings": map[string]any{"path": "/x", "mode": "packet-up"}}),
		engine.Outbound{Protocol: engine.ProtocolVLESS, UUID: uuid, Transport: engine.Transport{Type: "xhttp", Path: "/x", Mode: "packet-up"}})
	add("vmess-ws", map[string]any{"protocol": "vmess", "settings": map[string]any{"clients": []any{map[string]any{"id": uuid}}},
		"streamSettings": map[string]any{"network": "ws", "wsSettings": map[string]any{"path": "/vm"}}},
		engine.Outbound{Protocol: engine.ProtocolVMess, UUID: uuid, Transport: engine.Transport{Type: "ws", Path: "/vm"}})
	add("shadowsocks", map[string]any{"protocol": "shadowsocks", "settings": map[string]any{"method": "aes-256-gcm", "password": password, "network": "tcp,udp"}},
		engine.Outbound{Protocol: engine.ProtocolShadowsocks, Cipher: "aes-256-gcm", Password: password})
	return out
}

func startServer(t *testing.T, b supervise.Binary, svcs []service) {
	t.Helper()
	inbounds := make([]any, 0, len(svcs))
	for _, s := range svcs {
		inbounds = append(inbounds, s.inbound)
	}
	cfg, err := json.Marshal(map[string]any{
		"log":       map[string]any{"loglevel": "warning"},
		"inbounds":  inbounds,
		"outbounds": []any{map[string]any{"protocol": "freedom"}},
	})
	if err != nil {
		t.Fatal(err)
	}
	ctx, cancel := context.WithCancel(context.Background())
	proc, err := supervise.Start(ctx, supervise.Spec{Name: "xray-server", Path: b.Path, Args: []string{"run", "-c", "stdin:"}, Dir: t.TempDir(), Config: cfg})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() {
		cancel()
		_ = proc.Stop(context.Background(), 0)
	})
	time.Sleep(300 * time.Millisecond)
	if err := proc.Err(); err != nil {
		t.Fatalf("xray server: %v", err)
	}
}

func TestEveryEngineCarriesTrafficThroughEveryTransport(t *testing.T) {
	dir := os.Getenv("SORA_ENGINES_DIR")
	if dir == "" {
		t.Skip("set SORA_ENGINES_DIR to a directory with sing-box, xray and mihomo")
	}
	target := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) { _, _ = io.WriteString(w, reply) }))
	defer target.Close()

	server, err := xray.Prober.Discover(context.Background(), dir)
	if err != nil {
		t.Fatal(err)
	}
	svcs := services(t)
	startServer(t, server, svcs)

	// Wrong credentials must fail to rule out traffic bypassing the proxy.
	wrong := svcs[0]
	wrong.outbound.UUID = "00000000-0000-4000-8000-000000000000"
	wrong.name = "wrong-uuid"
	wrong.outbound.ID = wrong.name

	for _, kind := range []engine.Kind{engine.KindSingBox, engine.KindXray, engine.KindMihomo} {
		for _, svc := range append(svcs, wrong) {
			plan := &engine.Plan{
				SessionID:  "interop",
				LocalProxy: engine.LocalProxy{Enabled: true},
				Outbounds:  []engine.Outbound{svc.outbound},
				Rules:      []engine.Rule{{Type: engine.RuleMatchAll, Target: svc.name}},
				Options:    engine.Options{LogLevel: "warning", TestURL: engine.TestURLProduction},
			}
			if missing := engine.Catalog[kind].Missing(plan); len(missing) > 0 {
				continue
			}
			t.Run(string(kind)+"/"+svc.name, func(t *testing.T) {
				local := port(t)
				center := logs.New(logs.Settings{CaptureLevel: logs.LevelDebug, RecordDestinations: true})
				reg := registry.Discover(context.Background(), dir, supervise.Config{HomeDir: t.TempDir(), LocalPort: local, StartTimeout: 10 * time.Second, Logs: center})
				plan.Engines = []engine.Kind{kind}
				plan.Options.LogLevel = "debug"
				ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
				defer cancel()
				eng, err := reg.Factory()(ctx, plan)
				if err != nil {
					t.Fatal(err)
				}
				defer func() { _ = eng.Close() }()
				if err := eng.Apply(ctx, plan); err != nil {
					t.Fatalf("Apply: %v", err)
				}
				body, err := fetch(ctx, local, target.URL)
				if svc.name == wrong.name {
					if err == nil {
						t.Fatalf("a wrong uuid reached the target through %s: the request bypassed the proxy", kind)
					}
					return
				}
				if err != nil {
					t.Fatalf("request through %s: %v", kind, err)
				}
				if body != reply {
					t.Fatalf("got %q", body)
				}
				// Engine logs must reach the center without
				// credentials.
				page := center.Query(logs.Filter{Sources: []string{string(kind)}}, 0, 0)
				if len(page.Entries) == 0 {
					t.Fatalf("%s wrote nothing to the log center", kind)
				}
				for _, e := range center.Matching(logs.Filter{}) {
					if strings.Contains(e.Message, uuid) || strings.Contains(e.Message, password) {
						t.Fatalf("a credential reached the log center: %q", e.Message)
					}
				}
			})
		}
	}
}

// fetch requests target through the engine's mixed listener, retrying while
// the engine finishes its first connection.
func fetch(ctx context.Context, local int, target string) (string, error) {
	proxy, _ := url.Parse("http://127.0.0.1:" + strconv.Itoa(local))
	client := &http.Client{Timeout: 5 * time.Second, Transport: &http.Transport{Proxy: http.ProxyURL(proxy), DisableKeepAlives: true}}
	var last error
	for attempt := 0; attempt < 5; attempt++ {
		req, err := http.NewRequestWithContext(ctx, http.MethodGet, target, nil)
		if err != nil {
			return "", err
		}
		resp, err := client.Do(req)
		if err == nil {
			body, rerr := io.ReadAll(resp.Body)
			_ = resp.Body.Close()
			if rerr == nil && resp.StatusCode == http.StatusOK {
				return string(body), nil
			}
			last = fmt.Errorf("status %d: %w", resp.StatusCode, rerr)
		} else {
			last = err
		}
		time.Sleep(300 * time.Millisecond)
	}
	return "", last
}

// TestLocalProxyIsClosedOrLockedOnEveryEngine checks that absent proxies do not
// listen and authenticated proxies reject requests without login.
func TestLocalProxyIsClosedOrLockedOnEveryEngine(t *testing.T) {
	dir := os.Getenv("SORA_ENGINES_DIR")
	if dir == "" {
		t.Skip("set SORA_ENGINES_DIR to a directory with sing-box, xray and mihomo")
	}
	target := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) { _, _ = io.WriteString(w, reply) }))
	defer target.Close()
	for _, kind := range []engine.Kind{engine.KindSingBox, engine.KindXray, engine.KindMihomo} {
		t.Run(string(kind), func(t *testing.T) {
			ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
			defer cancel()
			run := func(lp engine.LocalProxy) (int, func()) {
				local := port(t)
				reg := registry.Discover(ctx, dir, supervise.Config{HomeDir: t.TempDir(), LocalPort: local, StartTimeout: 10 * time.Second})
				plan := &engine.Plan{
					SessionID:  "isolation",
					Engines:    []engine.Kind{kind},
					LocalProxy: lp,
					Outbounds:  []engine.Outbound{{ID: "out", Protocol: engine.ProtocolDirect}},
					Rules:      []engine.Rule{{Type: engine.RuleMatchAll, Target: "out"}},
					Options:    engine.Options{LogLevel: "warning", TestURL: engine.TestURLProduction},
				}
				eng, err := reg.Factory()(ctx, plan)
				if err != nil {
					t.Fatal(err)
				}
				if err := eng.Apply(ctx, plan); err != nil {
					t.Fatalf("Apply: %v", err)
				}
				return local, func() { _ = eng.Close() }
			}

			local, stop := run(engine.LocalProxy{})
			var dialer net.Dialer
			if conn, err := dialer.DialContext(ctx, "tcp", "127.0.0.1:"+strconv.Itoa(local)); err == nil {
				_ = conn.Close()
				t.Error("a plan without a local proxy must not listen on the port")
			}
			stop()

			local, stop = run(engine.LocalProxy{Enabled: true, Username: "sora", Password: "interop-login-password"})
			defer stop()
			if _, err := fetch(ctx, local, target.URL); err == nil {
				t.Error("a locked local proxy must refuse a request without the login")
			}
			if body, err := fetchAs(ctx, local, "sora", "interop-login-password", target.URL); err != nil || body != reply {
				t.Errorf("the login must open the local proxy: %q, %v", body, err)
			}
		})
	}
}

// fetchAs is fetch with a proxy login.
func fetchAs(ctx context.Context, local int, user, password, target string) (string, error) {
	proxy := &url.URL{Scheme: "http", Host: "127.0.0.1:" + strconv.Itoa(local), User: url.UserPassword(user, password)}
	client := &http.Client{Timeout: 5 * time.Second, Transport: &http.Transport{Proxy: http.ProxyURL(proxy), DisableKeepAlives: true}}
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, target, nil)
	if err != nil {
		return "", err
	}
	resp, err := client.Do(req)
	if err != nil {
		return "", err
	}
	defer func() { _ = resp.Body.Close() }()
	body, err := io.ReadAll(resp.Body)
	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("status %d", resp.StatusCode)
	}
	return string(body), err
}

// TestBypassCarriesTrafficThroughZapret checks real tpws traffic on every
// engine. It requires network access because tpws rejects private and loopback
// destinations. SORA_TPWS_BIN selects third_party/zapret's binary.
func TestBypassCarriesTrafficThroughZapret(t *testing.T) {
	dir, tpws := os.Getenv("SORA_ENGINES_DIR"), os.Getenv("SORA_TPWS_BIN")
	if dir == "" || tpws == "" {
		t.Skip("set SORA_ENGINES_DIR and SORA_TPWS_BIN")
	}
	engines := t.TempDir()
	for _, name := range []string{"sing-box", "xray", "mihomo", "geoip.dat", "geosite.dat"} {
		if err := os.Symlink(filepath.Join(dir, name), filepath.Join(engines, name)); err != nil {
			t.Fatal(err)
		}
	}
	if err := os.Symlink(tpws, filepath.Join(engines, "tpws")); err != nil {
		t.Fatal(err)
	}
	center := logs.New(logs.Settings{CaptureLevel: logs.LevelDebug})

	for _, kind := range []engine.Kind{engine.KindSingBox, engine.KindXray, engine.KindMihomo} {
		t.Run(string(kind), func(t *testing.T) {
			ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
			defer cancel()
			local := port(t)
			reg := registry.Discover(ctx, engines, supervise.Config{HomeDir: t.TempDir(), LocalPort: local, StartTimeout: 10 * time.Second, Logs: center})
			plan := &engine.Plan{
				SessionID: "bypass", Engines: []engine.Kind{kind}, LocalProxy: engine.LocalProxy{Enabled: true},
				Outbounds: []engine.Outbound{{ID: "zapret", Protocol: engine.ProtocolBypass,
					Bypass: &engine.BypassStrategy{SplitPos: []string{"1", "midsld"}, Disorder: true, HostCase: true}}},
				Rules:   []engine.Rule{{Type: engine.RuleMatchAll, Target: "zapret"}},
				Options: engine.Options{LogLevel: "warning", TestURL: engine.TestURLProduction},
			}
			eng, err := reg.Factory()(ctx, plan)
			if err != nil {
				t.Fatal(err)
			}
			defer func() { _ = eng.Close() }()
			if err := eng.Apply(ctx, plan); err != nil {
				t.Fatalf("Apply: %v", err)
			}
			proxy, _ := url.Parse("http://127.0.0.1:" + strconv.Itoa(local))
			client := &http.Client{Timeout: 10 * time.Second, Transport: &http.Transport{Proxy: http.ProxyURL(proxy)}}
			req, _ := http.NewRequestWithContext(ctx, http.MethodGet, engine.TestURLProduction, nil)
			resp, err := client.Do(req)
			if err != nil {
				t.Fatalf("request through %s and tpws: %v", kind, err)
			}
			_ = resp.Body.Close()
			if resp.StatusCode != http.StatusNoContent {
				t.Fatalf("request through %s and tpws answered %d", kind, resp.StatusCode)
			}
			if len(center.Query(logs.Filter{Sources: []string{"zapret"}}, 0, 0).Entries) == 0 {
				t.Error("tpws wrote nothing to the log center")
			}
		})
	}
}
