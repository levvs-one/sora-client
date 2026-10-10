package registry

import (
	"context"
	"encoding/pem"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"runtime"
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
	xhttpEngine := engine.KindXray
	if b := r.binaries[engine.KindSingBox]; engine.BuildCapabilities(b.Kind, b.Version, b.BuildTags).Supports(engine.FeatureXHTTP) {
		xhttpEngine = engine.KindSingBox
	}
	private := enginetest.Plan(engine.ProtocolVLESS)
	private.PrivateControl = true
	fallback := enginetest.Plan(engine.ProtocolTrojan)
	fallback.Groups[0].Type = engine.GroupFallback
	for name, tc := range map[string]struct {
		plan *engine.Plan
		want engine.Kind
	}{
		"plain plan goes to the preferred engine":  {enginetest.Plan(engine.ProtocolVLESS, engine.ProtocolAnyTLS), engine.KindSingBox},
		"xhttp uses the first compatible build":    {xhttp, xhttpEngine},
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
	target := httptest.NewTLSServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		time.Sleep(5 * time.Millisecond)
		w.WriteHeader(http.StatusNoContent)
	}))
	t.Cleanup(target.Close)
	plain := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) { w.WriteHeader(http.StatusNoContent) }))
	t.Cleanup(plain.Close)
	certificate := filepath.Join(t.TempDir(), "cert.pem")
	if err := os.WriteFile(certificate, pem.EncodeToMemory(&pem.Block{Type: "CERTIFICATE", Bytes: target.TLS.Certificates[0].Certificate[0]}), 0600); err != nil {
		t.Fatal(err)
	}
	enginetest.TrustCertificate(t, certificate)
	r = Discover(context.Background(), dir, supervise.Config{HomeDir: t.TempDir()})
	xhttp := enginetest.Outbound(engine.ProtocolVLESS)
	xhttp.ID, xhttp.Flow, xhttp.Server = "xhttp", "", "127.0.0.1"
	xhttp.Transport = engine.Transport{Type: "xhttp", Path: "/x"}
	for _, kind := range []engine.Kind{engine.KindSingBox, engine.KindXray, engine.KindMihomo} {
		t.Run(string(kind), func(t *testing.T) {
			live := engine.Outbound{ID: "live", Protocol: engine.ProtocolDirect}
			probeURL := target.URL
			if kind == engine.KindXray {
				// Xray latency is timed by the Go client; its system trust is
				// independent of the test-local certificate used by engines.
				probeURL = plain.URL
			}
			results, err := r.Measure(context.Background(), []engine.Outbound{live, dead, xhttp},
				engine.MeasureOptions{URL: probeURL, Timeout: 8 * time.Second, Engines: []engine.Kind{kind, engine.KindXray}})
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
			if b := r.binaries[kind]; engine.BuildCapabilities(kind, b.Version, b.BuildTags).Supports(engine.FeatureXHTTP) {
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

func TestBypassAvailabilityRequiresPlatformReshaperAndEngine(t *testing.T) {
	for _, tc := range []struct {
		tpws    string
		engines bool
		want    bool
	}{
		{"", false, false}, {"/tpws", false, false}, {"", true, false}, {"/tpws", true, runtime.GOOS == "linux"},
	} {
		r := &Registry{tpws: tc.tpws, binaries: map[engine.Kind]supervise.Binary{}}
		if tc.engines {
			r.binaries[engine.KindXray] = supervise.Binary{}
		}
		if got := r.BypassAvailable(); got != tc.want {
			t.Errorf("tpws %q, engines %v: got %v, want %v", tc.tpws, tc.engines, got, tc.want)
		}
	}
}

func TestInstalledButIncompatibleEngineHasADifferentErrorFromMissing(t *testing.T) {
	r := &Registry{
		preference:   []engine.Kind{engine.KindSingBox},
		binaries:     map[engine.Kind]supervise.Binary{engine.KindSingBox: {}},
		availability: []engine.Availability{{Kind: engine.KindSingBox, Usable: true, Version: engine.Version{Major: 1, Minor: 14}}},
	}
	p := enginetest.Plan(engine.ProtocolVLESS)
	p.Outbounds[0].Transport.Type = "xhttp"
	if _, err := r.Factory()(t.Context(), p); errs.KeyOf(err) != errs.KeyPlanEngineUnsupported {
		t.Fatalf("incompatible installed engine: %v", err)
	}
}

func TestXrayBridgeRequiresTheInstalledPacketEngineBeforeConstruction(t *testing.T) {
	p := enginetest.Plan(engine.ProtocolVLESS)
	p.Engines = []engine.Kind{engine.KindXray}
	p.Tun = engine.Tun{Enabled: true, Stack: "mips"}
	r := &Registry{preference: engine.DefaultPreference, binaries: map[engine.Kind]supervise.Binary{}}
	if _, err := r.Factory()(t.Context(), p); errs.KeyOf(err) != errs.KeyEngineBinaryMissing {
		t.Fatalf("missing packet engine: %v", err)
	}
	r.binaries[engine.KindMihomo] = supervise.Binary{Version: engine.Version{Major: 1, Minor: 19, Patch: 0}}
	if _, err := r.Factory()(t.Context(), p); errs.KeyOf(err) != errs.KeyPlanEngineUnsupported {
		t.Fatalf("old packet engine: %v", err)
	}
	if p.Tun.Stack != "mips" {
		t.Fatal("factory mutated the caller's TUN stack")
	}
}
