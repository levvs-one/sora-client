package registry

import (
	"context"
	"os"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/enginetest"
	"github.com/levvs-one/sora-client/core/engine/supervise"
	"github.com/levvs-one/sora-client/core/errs"
)

// TestFactoryPicksTheEngineThatCarriesThePlan needs all three engines in one
// directory, as a Sora installation ships them.
func TestFactoryPicksTheEngineThatCarriesThePlan(t *testing.T) {
	dir := os.Getenv("SORA_ENGINES_DIR")
	if dir == "" {
		t.Skip("set SORA_ENGINES_DIR to a directory with sing-box, xray and mihomo")
	}
	r := Discover(context.Background(), dir, supervise.Config{HomeDir: t.TempDir()})
	if len(r.Binaries()) != 3 {
		t.Fatalf("want three engines, found %v", r.Availability())
	}
	factory := r.Factory()

	xhttp := enginetest.Plan(engine.ProtocolVLESS)
	xhttp.Outbounds[0].Transport.Type = "xhttp"
	private := enginetest.Plan(engine.ProtocolVLESS)
	private.PrivateControl = true
	fallback := enginetest.Plan(engine.ProtocolTrojan)
	fallback.Groups[0].Type = engine.GroupFallback
	for name, tc := range map[string]struct {
		plan *engine.Plan
		want engine.Kind
	}{
		"plain plan goes to the preferred engine":  {enginetest.Plan(engine.ProtocolVLESS, engine.ProtocolAnyTLS), engine.KindSingBox},
		"xhttp needs xray":                         {xhttp, engine.KindXray},
		"fallback groups need mihomo":              {fallback, engine.KindMihomo},
		"private control needs a socket or a pipe": {private, engine.KindMihomo},
	} {
		t.Run(name, func(t *testing.T) {
			e, err := factory(context.Background(), tc.plan)
			if err != nil {
				t.Fatal(err)
			}
			defer func() { _ = e.Close() }()
			if e.Kind() != tc.want {
				t.Fatalf("picked %s, want %s (passed over: %v)", e.Kind(), tc.want, r.LastSelection().Rejected)
			}
		})
	}

	pinned := enginetest.Plan(engine.ProtocolVLESS)
	pinned.Engines = []engine.Kind{engine.KindMihomo}
	if e, err := factory(context.Background(), pinned); err != nil || e.Kind() != engine.KindMihomo {
		t.Errorf("a plan that pins mihomo must run on mihomo: %v", err)
	} else {
		_ = e.Close()
	}
	pinned.Engines = []engine.Kind{"v2ray"}
	if _, err := factory(context.Background(), pinned); err == nil {
		t.Error("an unknown engine in the plan must be refused")
	}
	if err := r.Pin("v2ray"); err == nil {
		t.Error("an unknown pinned engine must be refused")
	}
}

// TestMeasureRoutesEachServerToAnEngine measures a live direct outbound and a
// dead server on every engine, plus an outbound only Xray carries.
func TestMeasureRoutesEachServerToAnEngine(t *testing.T) {
	dir := os.Getenv("SORA_ENGINES_DIR")
	if dir == "" {
		t.Skip("set SORA_ENGINES_DIR to a directory with sing-box, xray and mihomo")
	}
	r := Discover(context.Background(), dir, supervise.Config{HomeDir: t.TempDir()})
	dead := engine.Outbound{ID: "dead", Protocol: engine.ProtocolShadowsocks, Server: "127.0.0.1", Port: 9, Cipher: "aes-256-gcm", Password: "dead-test-password"}
	xhttp := enginetest.Outbound(engine.ProtocolVLESS)
	xhttp.ID, xhttp.Flow, xhttp.Server = "xhttp", "", "127.0.0.1"
	xhttp.Transport = engine.Transport{Type: "xhttp", Path: "/x"}
	for _, kind := range []engine.Kind{engine.KindSingBox, engine.KindXray, engine.KindMihomo} {
		t.Run(string(kind), func(t *testing.T) {
			live := engine.Outbound{ID: "live", Protocol: engine.ProtocolDirect}
			results, err := r.Measure(context.Background(), []engine.Outbound{live, dead, xhttp},
				engine.MeasureOptions{Timeout: 8 * time.Second, Engines: []engine.Kind{kind, engine.KindXray}})
			if err != nil {
				t.Fatal(err)
			}
			got := map[string]engine.Measurement{}
			for m := range results {
				got[m.OutboundID] = m
			}
			if m := got["live"]; m.Err != nil || m.Latency <= 0 || m.Engine != kind {
				t.Errorf("live = %+v", m)
			}
			if m := got["dead"]; m.Err == nil {
				t.Errorf("a dead server must not report a latency: %+v", m)
			}
			want := engine.KindXray
			if engine.Catalog[kind].Supports(engine.FeatureXHTTP) {
				want = kind
			}
			if m := got["xhttp"]; m.Engine != want {
				t.Errorf("xhttp must be measured by the first engine that carries it, %s: %+v", want, m)
			}
		})
	}
}

func TestAPlanNoInstalledEngineCarriesSaysSo(t *testing.T) {
	r := &Registry{}
	_, err := r.Factory()(context.Background(), &engine.Plan{Outbounds: []engine.Outbound{
		{ID: "z", Protocol: engine.ProtocolBypass, Bypass: &engine.BypassStrategy{SplitPos: []string{"1"}}},
	}})
	if errs.KeyOf(err) != errs.KeyEngineBinaryMissing {
		t.Fatalf("err = %v, key %q: a missing tpws is a missing engine", err, errs.KeyOf(err))
	}
	_, err = r.Factory()(context.Background(), &engine.Plan{Outbounds: []engine.Outbound{
		{ID: "a", Protocol: engine.ProtocolVLESS, Server: "example.com", Port: 443},
	}})
	if errs.KeyOf(err) != errs.KeyEngineBinaryMissing {
		t.Fatalf("err = %v, key %q: no installed engine is a missing engine", err, errs.KeyOf(err))
	}
}
