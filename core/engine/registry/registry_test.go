package registry

import (
	"context"
	"os"
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/enginetest"
	"github.com/levvs-one/sora-client/core/engine/supervise"
)

// TestFactoryPicksTheEngineThatCarriesThePlan needs all three engines in one
// directory, as a Sora installation ships them.
func TestFactoryPicksTheEngineThatCarriesThePlan(t *testing.T) {
	dir := os.Getenv("SORA_ENGINES_DIR")
	if dir == "" {
		t.Skip("set SORA_ENGINES_DIR to a directory with sing-box, xray and mihomo")
	}
	r := Discover(context.Background(), dir)
	if len(r.Binaries()) != 3 {
		t.Fatalf("want three engines, found %v", r.Availability())
	}
	factory, err := r.Factory(supervise.Config{HomeDir: t.TempDir()}, "")
	if err != nil {
		t.Fatal(err)
	}

	xhttp := enginetest.Plan(engine.ProtocolVLESS)
	xhttp.Outbounds[0].Transport.Type = "xhttp"
	fallback := enginetest.Plan(engine.ProtocolTrojan)
	fallback.Groups[0].Type = engine.GroupFallback
	for name, tc := range map[string]struct {
		plan *engine.Plan
		want engine.Kind
	}{
		"plain plan goes to the preferred engine": {enginetest.Plan(engine.ProtocolVLESS, engine.ProtocolAnyTLS), engine.KindSingBox},
		"xhttp needs xray":                        {xhttp, engine.KindXray},
		"fallback groups need mihomo":             {fallback, engine.KindMihomo},
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

	if _, err := r.Factory(supervise.Config{}, "v2ray"); err == nil {
		t.Error("an unknown pinned engine must be refused")
	}
}
