package probe_test

import (
	"context"
	"net"
	"strconv"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/errs"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
	"github.com/levvs-one/sora-client/core/probe"
)

// listener opens a socket that accepts and closes, which is what a reachable
// endpoint looks like to a measurement.
func listener(t *testing.T) (string, uint32) {
	t.Helper()
	server, err := (&net.ListenConfig{}).Listen(context.Background(), "tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatalf("listen: %v", err)
	}
	t.Cleanup(func() { _ = server.Close() })
	go func() {
		for {
			connection, err := server.Accept()
			if err != nil {
				return
			}
			_ = connection.Close()
		}
	}()
	host, portText, err := net.SplitHostPort(server.Addr().String())
	if err != nil {
		t.Fatalf("splitting %q: %v", server.Addr(), err)
	}
	port, err := strconv.ParseUint(portText, 10, 32)
	if err != nil {
		t.Fatalf("parsing port %q: %v", portText, err)
	}
	return host, uint32(port)
}

// closedPort returns a port that was just released, so nothing listens on it.
func closedPort(t *testing.T) uint32 {
	t.Helper()
	server, err := (&net.ListenConfig{}).Listen(context.Background(), "tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatalf("listen: %v", err)
	}
	_, portText, err := net.SplitHostPort(server.Addr().String())
	if err != nil {
		t.Fatalf("splitting %q: %v", server.Addr(), err)
	}
	if err := server.Close(); err != nil {
		t.Fatalf("close: %v", err)
	}
	number, err := strconv.ParseUint(portText, 10, 32)
	if err != nil {
		t.Fatalf("parsing port %q: %v", portText, err)
	}
	return uint32(number)
}

func TestProbeFindsAListeningPort(t *testing.T) {
	host, port := listener(t)
	prober := probe.New(probe.Config{Timeout: 2 * time.Second})
	results, err := prober.Probe(context.Background(), []*corev1.Endpoint{
		{Host: host, Port: port},
	}, []string{"berlin"})
	if err != nil {
		t.Fatalf("Probe() error = %v", err)
	}
	count := 0
	for result := range results {
		count++
		if !result.GetReachable() {
			t.Fatalf("the listener was not reached: %v", result.GetError())
		}
		if result.GetServerId() != "berlin" {
			t.Errorf("server id = %q, want berlin", result.GetServerId())
		}
	}
	if count != 1 {
		t.Errorf("the stream carried %d results, want 1", count)
	}
}

func TestProbeReportsAClosedPortWithoutLeakingTheAddress(t *testing.T) {
	prober := probe.New(probe.Config{Timeout: time.Second})
	results, err := prober.Probe(context.Background(), []*corev1.Endpoint{
		{Host: "127.0.0.1", Port: closedPort(t)},
	}, nil)
	if err != nil {
		t.Fatalf("Probe() error = %v", err)
	}
	for result := range results {
		if result.GetReachable() {
			t.Fatal("a closed port was reported as reachable")
		}
		if result.GetError() == nil {
			t.Fatal("a closed port produced no explanation")
		}
		if result.GetError().GetCode() != corev1.SoraErrorCode_SORA_ERROR_CODE_UNAVAILABLE {
			t.Errorf("code = %s, want unavailable", result.GetError().GetCode())
		}
		if result.GetServerId() != "" {
			t.Errorf("server id = %q, want empty when the caller named nothing", result.GetServerId())
		}
	}
}

func TestProbeRefusesEndpointsItCannotUse(t *testing.T) {
	prober := probe.New(probe.Config{})
	if _, err := prober.Probe(context.Background(), nil, nil); errs.KeyOf(err) != errs.KeyProbeNoEndpoints {
		t.Errorf("an empty request = %v, key = %q", err, errs.KeyOf(err))
	}
	many := make([]*corev1.Endpoint, probe.MaxEndpoints+1)
	if _, err := prober.Probe(context.Background(), many, nil); errs.KeyOf(err) != errs.KeyProbeTooMany {
		t.Errorf("an oversized request = %v, key = %q", err, errs.KeyOf(err))
	}
	results, err := prober.Probe(context.Background(), []*corev1.Endpoint{
		{Host: "", Port: 443},
		{Host: "de1.example.com", Port: 0},
		nil,
	}, nil)
	if err != nil {
		t.Fatalf("Probe() error = %v", err)
	}
	seen := 0
	for result := range results {
		seen++
		if result.GetError().GetCode() != corev1.SoraErrorCode_SORA_ERROR_CODE_INVALID_ARGUMENT {
			t.Errorf("a malformed endpoint gave %s", result.GetError().GetCode())
		}
	}
	if seen != 3 {
		t.Errorf("the stream carried %d results, want one per endpoint", seen)
	}
}

func TestProbeStopsWhenTheCallerCancels(t *testing.T) {
	host, port := listener(t)
	prober := probe.New(probe.Config{Timeout: time.Second})
	ctx, cancel := context.WithCancel(context.Background())
	results, err := prober.Probe(ctx, []*corev1.Endpoint{{Host: host, Port: port}}, nil)
	if err != nil {
		t.Fatalf("Probe() error = %v", err)
	}
	cancel()
	deadline := time.After(2 * time.Second)
	for done := false; !done; {
		select {
		case _, ok := <-results:
			if !ok {
				done = true
			}
		case <-deadline:
			t.Fatal("the stream did not close after the caller cancelled")
		}
	}
}

func TestProbeKeepsConcurrencyBounded(t *testing.T) {
	host, port := listener(t)
	prober := probe.New(probe.Config{Timeout: time.Second, Concurrency: 2})
	endpoints := make([]*corev1.Endpoint, 16)
	ids := make([]string, len(endpoints))
	for i := range endpoints {
		endpoints[i] = &corev1.Endpoint{Host: host, Port: port}
		ids[i] = "server-" + strconv.Itoa(i)
	}
	results, err := prober.Probe(context.Background(), endpoints, ids)
	if err != nil {
		t.Fatalf("Probe() error = %v", err)
	}
	reachable := 0
	for result := range results {
		if result.GetReachable() {
			reachable++
		}
	}
	if reachable != len(endpoints) {
		t.Errorf("%d of %d endpoints were reachable", reachable, len(endpoints))
	}
}
