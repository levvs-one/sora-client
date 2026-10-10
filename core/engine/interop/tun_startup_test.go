//go:build linux

package interop_test

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net"
	"net/http"
	"net/http/httptest"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"syscall"
	"testing"
	"time"

	"golang.org/x/net/dns/dnsmessage"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/registry"
	"github.com/levvs-one/sora-client/core/engine/supervise"
	"github.com/levvs-one/sora-client/core/engine/xray"
	"github.com/levvs-one/sora-client/core/engine/xraytun"
)

func TestEveryEngineStartsTun(t *testing.T) {
	if os.Getenv("SORA_TUN_INTEGRATION") != "1" {
		t.Skip("set SORA_TUN_INTEGRATION=1 and SORA_ENGINES_DIR inside unshare -Urn, passing the parent namespace in SORA_PARENT_NETNS")
	}
	self, err := os.Readlink("/proc/self/ns/net")
	if err != nil {
		t.Fatal(err)
	}
	host := os.Getenv("SORA_PARENT_NETNS")
	if host == "" || self == host {
		t.Fatal("TUN integration requires an isolated network namespace")
	}
	target := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) { _, _ = io.WriteString(w, reply) }))
	t.Cleanup(target.Close)
	address := strings.TrimPrefix(target.URL, "http://")
	udp, err := (&net.ListenConfig{}).ListenPacket(t.Context(), "udp", address)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = udp.Close() })
	go func() {
		buffer := make([]byte, 4096)
		for {
			n, addr, err := udp.ReadFrom(buffer)
			if err != nil {
				return
			}
			_, _ = udp.WriteTo(buffer[:n], addr)
		}
	}()
	server, err := xray.Prober.Discover(t.Context(), os.Getenv("SORA_ENGINES_DIR"))
	if err != nil {
		t.Fatal(err)
	}
	serverPort := port(t)
	startServer(t, server, []service{{inbound: map[string]any{
		"listen": "127.0.0.1", "port": serverPort, "protocol": "shadowsocks",
		"settings": map[string]any{"method": "aes-256-gcm", "password": password, "network": "tcp,udp"},
	}}}, address)
	for _, tc := range []struct {
		kind    engine.Kind
		stack   string
		profile bool
	}{
		{engine.KindSingBox, "", false}, {engine.KindXray, "gvisor", false},
		{engine.KindXray, "system", false}, {engine.KindXray, "mixed", false}, {engine.KindXray, "mips", false},
		{engine.KindMihomo, "mixed", false}, {engine.KindMihomo, "system", false},
		{engine.KindMihomo, "gvisor", false}, {engine.KindMihomo, "mips", false},
		{engine.KindXray, "mips", true},
	} {
		name := string(tc.kind) + "/" + tc.stack
		if tc.profile {
			name += "/provider-json"
		}
		t.Run(name, func(t *testing.T) {
			kind := tc.kind
			home, err := os.MkdirTemp("", "sora-tun-")
			if err != nil {
				t.Fatal(err)
			}
			t.Cleanup(func() { _ = os.RemoveAll(home) })
			ctx, cancel := context.WithTimeout(t.Context(), 15*time.Second)
			defer cancel()
			reg := registry.Discover(ctx, os.Getenv("SORA_ENGINES_DIR"), supervise.Config{HomeDir: home})
			plan := &engine.Plan{
				SessionID: "tun-startup", PrivateControl: engine.Catalog[kind].Supports(engine.FeaturePrivateControl), Engines: []engine.Kind{kind},
				Outbounds: []engine.Outbound{{ID: "out", Protocol: engine.ProtocolShadowsocks,
					Server: "127.0.0.1", Port: uint16(serverPort), Cipher: "aes-256-gcm", Password: password}},
				Rules: []engine.Rule{{Type: engine.RuleMatchAll, Target: "out"}},
				Tun:   engine.Tun{Enabled: true, DeviceName: engine.TunDevice, Stack: tc.stack},
				DNS:   engine.DNS{Enabled: true, Servers: []engine.DNSServer{{Tag: "resolver", Address: "1.1.1.1", Transport: engine.DNSPlain}}},
			}
			if tc.profile {
				raw, err := json.Marshal(map[string]any{"outbounds": []any{map[string]any{
					"protocol": "shadowsocks", "tag": "provider-proxy", "settings": map[string]any{"servers": []any{map[string]any{
						"address": "127.0.0.1", "port": serverPort, "method": "aes-256-gcm", "password": password,
					}}},
				}}})
				if err != nil {
					t.Fatal(err)
				}
				plan.Outbounds = []engine.Outbound{{ID: "out", Protocol: engine.ProtocolXrayProfile, Profile: raw,
					Server: "127.0.0.1", Port: uint16(serverPort)}}
			}
			if kind == engine.KindXray && tc.stack != "gvisor" {
				plan.DNS.Mode = string(engine.DNSFakeIP)
			}
			eng, err := reg.Factory()(ctx, plan)
			if err != nil {
				t.Fatal(err)
			}
			t.Cleanup(func() { _ = eng.Close() })
			if err := eng.Apply(ctx, plan); err != nil {
				t.Fatal(err)
			}
			if eng.State() != engine.StateRunning {
				t.Fatal("engine did not reach running state")
			}
			if _, err := net.InterfaceByName(engine.TunDevice); err != nil {
				t.Fatal(err)
			}
			// A destination with no real interface proves packets entered TUN.
			if out, err := exec.CommandContext(ctx, "ip", "route", "replace", "203.0.113.10/32", "dev", engine.TunDevice).CombinedOutput(); err != nil {
				t.Fatalf("TUN route: %v %s", err, out)
			}
			_, targetPort, _ := net.SplitHostPort(address)
			destination := net.JoinHostPort("203.0.113.10", targetPort)
			client := &http.Client{Timeout: 5 * time.Second, Transport: &http.Transport{DisableKeepAlives: true}}
			request, err := http.NewRequestWithContext(ctx, http.MethodGet, "http://"+destination, nil)
			if err != nil {
				t.Fatal(err)
			}
			resp, err := client.Do(request)
			if err != nil {
				t.Fatalf("TCP through TUN: %v", err)
			}
			body, err := io.ReadAll(resp.Body)
			_ = resp.Body.Close()
			if err != nil || string(body) != reply {
				t.Fatalf("TCP through TUN: %q %v", body, err)
			}
			conn, err := (&net.Dialer{Timeout: 5 * time.Second}).DialContext(ctx, "udp", destination)
			if err != nil {
				t.Fatal(err)
			}
			_ = conn.SetDeadline(time.Now().Add(5 * time.Second))
			payload := fmt.Sprintf("TUN-%s-%s", kind, tc.stack)
			_, err = conn.Write([]byte(payload))
			buffer := make([]byte, 4096)
			var n int
			if err == nil {
				n, err = conn.Read(buffer)
			}
			_ = conn.Close()
			if err != nil || string(buffer[:n]) != payload {
				t.Fatalf("UDP through TUN: %q %v", buffer[:n], err)
			}
			if bridge, ok := eng.(*xraytun.Engine); ok {
				query := dnsmessage.Message{Header: dnsmessage.Header{ID: 42, RecursionDesired: true},
					Questions: []dnsmessage.Question{{Name: dnsmessage.MustNewName("bridge.example."), Type: dnsmessage.TypeA, Class: dnsmessage.ClassINET}}}
				raw, err := query.Pack()
				if err != nil {
					t.Fatal(err)
				}
				resolver, err := (&net.Dialer{Timeout: 3 * time.Second}).DialContext(ctx, "udp", "203.0.113.10:53")
				if err != nil {
					t.Fatal(err)
				}
				_ = resolver.SetDeadline(time.Now().Add(3 * time.Second))
				_, err = resolver.Write(raw)
				if err == nil {
					n, err = resolver.Read(buffer)
				}
				_ = resolver.Close()
				if err != nil {
					t.Fatalf("DNS hijack through bridge: %v", err)
				}
				var answer dnsmessage.Message
				if err := answer.Unpack(buffer[:n]); err != nil {
					t.Fatal(err)
				}
				fake := ""
				for _, answer := range answer.Answers {
					if address, ok := answer.Body.(*dnsmessage.AResource); ok {
						fake = net.IP(address.A[:]).String()
					}
				}
				if !strings.HasPrefix(fake, "198.18.") {
					t.Fatalf("DNS did not return Sora's fake-IP: %s", fake)
				}
				if out, err := exec.CommandContext(ctx, "ip", "route", "replace", "198.18.0.0/16", "dev", engine.TunDevice).CombinedOutput(); err != nil {
					t.Fatalf("fake-IP test route: %v %s", err, out)
				}
				request, err := http.NewRequestWithContext(ctx, http.MethodGet, "http://"+net.JoinHostPort(fake, targetPort), nil)
				if err != nil {
					t.Fatal(err)
				}
				response, err := client.Do(request)
				if err != nil {
					t.Fatalf("hostname recovered from fake-IP: %v", err)
				}
				body, err := io.ReadAll(response.Body)
				_ = response.Body.Close()
				if err != nil || string(body) != reply {
					t.Fatalf("fake-IP response: %q %v", body, err)
				}
				// The additional listener must reject unauthenticated apps.
				rt, err := bridge.Engine.(*xray.Engine).Running()
				if err != nil {
					t.Fatal(err)
				}
				if body, err := fetch(ctx, rt.LocalPort, target.URL); err == nil && body == reply {
					t.Fatal("private Xray bridge allowed an unauthenticated request")
				}
				for _, child := range []string{"xray", "xray-tun"} {
					events, unsub := eng.Events().Subscribe()
					children, err := exec.CommandContext(ctx, "pgrep", "-P", strconv.Itoa(os.Getpid())).Output()
					if err != nil {
						t.Fatal(err)
					}
					killed := 0
					for _, pid := range strings.Fields(string(children)) {
						cwd, err := os.Readlink("/proc/" + pid + "/cwd")
						if err != nil || cwd != filepath.Join(home, child) {
							continue
						}
						id, err := strconv.Atoi(pid)
						if err != nil {
							t.Fatal(err)
						}
						if err := syscall.Kill(id, syscall.SIGKILL); err != nil {
							t.Fatal(err)
						}
						killed++
					}
					if killed != 1 {
						t.Fatalf("%s: killed %d owned processes, expected one", child, killed)
					}
					down, recovered := false, false
					for !recovered {
						select {
						case ev := <-events:
							if ev.Kind == engine.EventEngineDown {
								down = true
							}
							if ev.Kind == engine.EventFatal {
								t.Fatalf("%s: fatal recovery failure %v", child, ev.Err)
							}
							if down && ev.Kind == engine.EventState && ev.State == engine.StateRunning {
								recovered = true
							}
						case <-ctx.Done():
							t.Fatalf("%s: did not recover: %v", child, ctx.Err())
						}
					}
					unsub()
					if _, err := net.InterfaceByName(engine.TunDevice); err != nil {
						t.Fatal(err)
					}
					if out, err := exec.CommandContext(ctx, "ip", "route", "replace", "203.0.113.10/32", "dev", engine.TunDevice).CombinedOutput(); err != nil {
						t.Fatalf("route after recovery: %v %s", err, out)
					}
					request, err := http.NewRequestWithContext(ctx, http.MethodGet, "http://"+destination, nil)
					if err != nil {
						t.Fatal(err)
					}
					response, err := client.Do(request)
					if err != nil {
						t.Fatalf("%s: TCP after recovery: %v", child, err)
					}
					body, err := io.ReadAll(response.Body)
					_ = response.Body.Close()
					if err != nil || string(body) != reply {
						t.Fatalf("%s: invalid recovery reply %q %v", child, body, err)
					}
					packet, err := (&net.Dialer{Timeout: 5 * time.Second}).DialContext(ctx, "udp", destination)
					if err != nil {
						t.Fatal(err)
					}
					_ = packet.SetDeadline(time.Now().Add(5 * time.Second))
					_, err = packet.Write([]byte(payload))
					if err == nil {
						n, err = packet.Read(buffer)
					}
					_ = packet.Close()
					if err != nil || string(buffer[:n]) != payload {
						t.Fatalf("%s: UDP after recovery: %q %v", child, buffer[:n], err)
					}
				}
				events, unsub := eng.Events().Subscribe()
				children, err := exec.CommandContext(ctx, "pgrep", "-P", strconv.Itoa(os.Getpid())).Output()
				if err != nil {
					t.Fatal(err)
				}
				for _, pid := range strings.Fields(string(children)) {
					cwd, err := os.Readlink("/proc/" + pid + "/cwd")
					if err != nil || cwd != filepath.Join(home, "xray-tun") {
						continue
					}
					id, err := strconv.Atoi(pid)
					if err != nil {
						t.Fatal(err)
					}
					if err := syscall.Kill(id, syscall.SIGKILL); err != nil {
						t.Fatal(err)
					}
				}
				down := false
				for !down {
					select {
					case ev := <-events:
						down = ev.Kind == engine.EventEngineDown
					case <-ctx.Done():
						t.Fatal("missing engine-down event before disconnect")
					}
				}
				unsub()
				if err := eng.Stop(ctx); err != nil {
					t.Fatal(err)
				}
				// Waiting longer than the second restart delay proves Stop
				// cancels a scheduled restart without relying on Close.
				time.Sleep(1500 * time.Millisecond)
				if eng.State() != engine.StateStopped {
					t.Fatalf("disconnect was undone by recovery: %s", eng.State())
				}
				if children, err := exec.CommandContext(ctx, "pgrep", "-P", strconv.Itoa(os.Getpid())).Output(); err == nil {
					for _, pid := range strings.Fields(string(children)) {
						cwd, _ := os.Readlink("/proc/" + pid + "/cwd")
						if strings.HasPrefix(cwd, home+string(os.PathSeparator)) {
							t.Fatal("disconnect left or restarted an owned engine process")
						}
					}
				}
			}
			if err := eng.Stop(ctx); err != nil {
				t.Fatal(err)
			}
			if _, err := net.InterfaceByName(engine.TunDevice); err == nil {
				t.Fatal("stopping the engine left the TUN adapter behind")
			}
		})
	}
}
