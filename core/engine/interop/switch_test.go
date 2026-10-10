package interop_test

import (
	"context"
	"fmt"
	"io"
	"net"
	"net/http"
	"net/http/httptest"
	"os"
	"strconv"
	"testing"
	"time"

	"github.com/txthinking/socks5"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/registry"
	"github.com/levvs-one/sora-client/core/engine/supervise"
	"github.com/levvs-one/sora-client/core/engine/xray"
	"github.com/levvs-one/sora-client/core/session"
)

func TestRealEngineSwitchesKeepTCPAndUDPAndReleaseTun(t *testing.T) {
	dir := os.Getenv("SORA_ENGINES_DIR")
	if dir == "" {
		t.Skip("set SORA_ENGINES_DIR to installed engines")
	}
	tun := os.Getenv("SORA_TUN_INTEGRATION") == "1"
	if tun {
		current, err := os.Readlink("/proc/self/ns/net")
		parent := os.Getenv("SORA_PARENT_NETNS")
		if err != nil || parent == "" || parent == current {
			t.Fatal("TUN switch tests require an isolated network namespace")
		}
	}
	target := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) { _, _ = io.WriteString(w, reply) }))
	t.Cleanup(target.Close)
	udp, err := (&net.ListenConfig{}).ListenPacket(t.Context(), "udp", "127.0.0.1:0")
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
	server, err := xray.Prober.Discover(t.Context(), dir)
	if err != nil {
		t.Fatal(err)
	}
	svcs := services(t)
	startServer(t, server, svcs)
	var ss service
	for _, s := range svcs {
		if s.name == "shadowsocks" {
			ss = s
		}
	}
	local := port(t)
	reg := registry.Discover(t.Context(), dir, supervise.Config{HomeDir: t.TempDir(), LocalPort: local, StartTimeout: 10 * time.Second})
	manager := session.NewManager(session.ManagerConfig{Factory: reg.Factory()})
	t.Cleanup(func() { _ = manager.Disconnect(context.Background()) })
	var previous *session.Session
	for i := 0; i < 30; i++ {
		kind := []engine.Kind{engine.KindXray, engine.KindSingBox, engine.KindMihomo}[i%3]
		p := &engine.Plan{
			SessionID: fmt.Sprintf("switch-%d", i), Engines: []engine.Kind{kind},
			PrivateControl: engine.Catalog[kind].Supports(engine.FeaturePrivateControl),
			LocalProxy:     engine.LocalProxy{Enabled: true}, Outbounds: []engine.Outbound{ss.outbound},
			Rules: []engine.Rule{{Type: engine.RuleMatchAll, Target: ss.name}},
			Tun:   engine.Tun{Enabled: tun, DeviceName: engine.TunDevice},
			DNS:   engine.DNS{Enabled: tun, Servers: []engine.DNSServer{{Tag: "resolver", Address: "1.1.1.1", Transport: engine.DNSPlain}}},
		}
		if kind == engine.KindMihomo || (kind == engine.KindXray && tun) {
			p.Tun.Stack = []string{"mixed", "system", "gvisor", "mips"}[(i/3)%4]
		}
		ctx, cancel := context.WithTimeout(t.Context(), 20*time.Second)
		current, err := manager.Connect(ctx, p, session.Settings{})
		cancel()
		if err != nil {
			t.Fatalf("switch %d to %s: %v", i, kind, err)
		}
		if previous != nil && previous.State() != session.StateDisconnected {
			t.Fatal("old session remained connected")
		}
		previous = current
		if tun {
			if _, err := net.InterfaceByName(engine.TunDevice); err != nil {
				t.Fatal(err)
			}
		}
		if body, err := fetch(t.Context(), local, target.URL); err != nil || body != reply {
			t.Fatalf("TCP switch %d (%s): %q %v", i, kind, body, err)
		}
		client, err := socks5.NewClient(net.JoinHostPort("127.0.0.1", strconv.Itoa(local)), "", "", 5, 5)
		if err != nil {
			t.Fatal(err)
		}
		var sockets []net.Conn
		client.DialTCP = func(network, _, address string) (net.Conn, error) {
			conn, err := (&net.Dialer{Timeout: 5 * time.Second}).DialContext(t.Context(), network, address)
			if err == nil {
				sockets = append(sockets, conn)
			}
			return conn, err
		}
		conn, err := client.Dial("udp", udp.LocalAddr().String())
		if err != nil {
			for _, socket := range sockets {
				_ = socket.Close()
			}
			t.Fatalf("UDP association %d (%s): %v", i, kind, err)
		}
		payload := fmt.Sprintf("sora-udp-%d-%s", i, kind)
		_, err = conn.Write([]byte(payload))
		buffer := make([]byte, 4096)
		var n int
		if err == nil {
			n, err = conn.Read(buffer)
		}
		_ = conn.Close()
		if err != nil || string(buffer[:n]) != payload {
			t.Fatalf("UDP switch %d (%s): %q %v", i, kind, buffer[:n], err)
		}
		// Provider Xray profiles are refused before touching the working tunnel.
		bad := *p
		bad.SessionID, bad.Engines, bad.PrivateControl = "unsupported", []engine.Kind{engine.KindSingBox}, false
		bad.Outbounds = []engine.Outbound{{ID: "provider", Protocol: engine.ProtocolXrayProfile, Profile: []byte(`{"outbounds":[{"protocol":"freedom"}]}`)}}
		bad.Rules = []engine.Rule{{Type: engine.RuleMatchAll, Target: "provider"}}
		if _, err := manager.Connect(t.Context(), &bad, session.Settings{}); err == nil {
			t.Fatal("unsupported provider profile was accepted")
		}
		if manager.Current() != current || current.State() != session.StateConnected {
			t.Fatal("rejected switch lost the live session")
		}
		if i%3 == 2 {
			if err := manager.Disconnect(t.Context()); err != nil {
				t.Fatal(err)
			}
			if manager.Current() != nil {
				t.Fatal("disconnect retained a session")
			}
			if tun {
				if _, err := net.InterfaceByName(engine.TunDevice); err == nil {
					t.Fatal("disconnect left a TUN adapter")
				}
			}
			previous = nil
		}
	}
	if err := manager.Disconnect(t.Context()); err != nil {
		t.Fatal(err)
	}
}
