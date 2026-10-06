package control_test

import (
	"context"
	"testing"
	"time"

	"google.golang.org/grpc"

	"github.com/levvs-one/sora-client/core/control"
	"github.com/levvs-one/sora-client/core/engine"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
	"github.com/levvs-one/sora-client/core/session"
)

// fakeMeasurer measures "a" in 42 ms through sing-box and has no engine for
// anything else.
type fakeMeasurer struct{ opts engine.MeasureOptions }

func (f *fakeMeasurer) Measure(_ context.Context, outbounds []engine.Outbound, opts engine.MeasureOptions) (<-chan engine.Measurement, error) {
	f.opts = opts
	out := make(chan engine.Measurement, len(outbounds))
	for _, o := range outbounds {
		if o.ID == "a" {
			out <- engine.Measurement{OutboundID: o.ID, Engine: engine.KindSingBox, Latency: 42 * time.Millisecond}
		} else {
			out <- engine.Measurement{OutboundID: o.ID, Err: engine.ErrNoEngine}
		}
	}
	close(out)
	return out, nil
}

// fakeProber answers every endpoint as reachable in 7 ms.
type fakeProber struct{ asked []string }

func (f *fakeProber) Probe(_ context.Context, endpoints []*corev1.Endpoint, ids []string) (<-chan *corev1.ProbeResult, error) {
	f.asked = append(f.asked, ids...)
	out := make(chan *corev1.ProbeResult, len(endpoints))
	for i := range endpoints {
		id := ""
		if i < len(ids) {
			id = ids[i]
		}
		out <- &corev1.ProbeResult{ServerId: id, Reachable: true, LatencyMs: 7}
	}
	close(out)
	return out, nil
}

type probeStream struct {
	grpc.ServerStream
	ctx  context.Context
	sent []*corev1.ProbeResult
}

func (s *probeStream) Context() context.Context         { return s.ctx }
func (s *probeStream) Send(r *corev1.ProbeResult) error { s.sent = append(s.sent, r); return nil }

func probeServer(t *testing.T, m control.Measurer, p control.Prober) *control.Server {
	t.Helper()
	auth, err := control.NewAuthenticator(testToken)
	if err != nil {
		t.Fatal(err)
	}
	server, err := control.New(control.Config{
		Version: control.Version{Major: 1, Minor: 3, MinSupportedMinor: 1}, Authenticator: auth,
		Measurer: m, Prober: p,
		Sessions: session.NewManager(session.ManagerConfig{
			Factory: func(context.Context, *engine.Plan) (engine.Engine, error) { return newStubEngine(), nil },
		}),
	})
	if err != nil {
		t.Fatal(err)
	}
	return server
}

func probeRequest(method corev1.ProbeMethod) *corev1.ProbeServersRequest {
	spec := func(id string) *corev1.OutboundSpec {
		return &corev1.OutboundSpec{Id: id, Protocol: "shadowsocks", Endpoint: &corev1.Endpoint{Host: "203.0.113.9", Port: 8388}}
	}
	return &corev1.ProbeServersRequest{
		ApiVersion: &corev1.ApiVersion{Major: 1, Minor: 3, MinSupportedMinor: 1},
		Outbounds:  []*corev1.OutboundSpec{spec("a"), spec("b")},
		Options:    &corev1.ProbeOptions{Method: method, TimeoutMs: 1500, Concurrency: 3, Engines: []string{"xray"}},
	}
}

func TestProbeAutoFallsBackToAConnectionWhereNoEngineCarriesTheServer(t *testing.T) {
	m, p := &fakeMeasurer{}, &fakeProber{}
	stream := &probeStream{ctx: context.Background()}
	if err := probeServer(t, m, p).ProbeServers(probeRequest(corev1.ProbeMethod_PROBE_METHOD_UNSPECIFIED), stream); err != nil {
		t.Fatal(err)
	}
	byID := map[string]*corev1.ProbeResult{}
	for _, r := range stream.sent {
		byID[r.GetServerId()] = r
	}
	if a := byID["a"]; a.GetMethod() != "engine" || a.GetEngine() != "sing-box" || a.GetLatencyMs() != 42 {
		t.Errorf("a = %v", a)
	}
	if b := byID["b"]; b.GetMethod() != "connect" || b.GetLatencyMs() != 7 {
		t.Errorf("b must fall back to a connection check: %v", b)
	}
	if m.opts.Timeout != 1500*time.Millisecond || m.opts.Concurrency != 3 || len(m.opts.Engines) != 1 {
		t.Errorf("options did not reach the engines: %+v", m.opts)
	}
}

func TestProbeEngineOnlyReportsServersWithoutAnEngine(t *testing.T) {
	stream := &probeStream{ctx: context.Background()}
	if err := probeServer(t, &fakeMeasurer{}, &fakeProber{}).ProbeServers(probeRequest(corev1.ProbeMethod_PROBE_METHOD_ENGINE), stream); err != nil {
		t.Fatal(err)
	}
	for _, r := range stream.sent {
		if r.GetServerId() == "b" && (r.GetError() == nil || r.GetMethod() != "engine") {
			t.Errorf("without an engine, b must fail rather than fall back: %v", r)
		}
	}
}

func TestProbeConnectNeverStartsAnEngine(t *testing.T) {
	m, p := &fakeMeasurer{}, &fakeProber{}
	stream := &probeStream{ctx: context.Background()}
	if err := probeServer(t, m, p).ProbeServers(probeRequest(corev1.ProbeMethod_PROBE_METHOD_CONNECT), stream); err != nil {
		t.Fatal(err)
	}
	if m.opts.Timeout != 0 || len(p.asked) != 2 || len(stream.sent) != 2 {
		t.Errorf("connect must use the connection check only: measurer %+v, prober %v, sent %d", m.opts, p.asked, len(stream.sent))
	}
}
