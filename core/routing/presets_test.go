package routing

import (
	"context"
	"os"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/registry"
	"github.com/levvs-one/sora-client/core/engine/supervise"
)

func TestUserRulesComeFirstAndTheRestGoesToTheProxy(t *testing.T) {
	user := []engine.Rule{{Type: engine.RuleDomainSuffix, Value: "example.ru", Target: "Proxy"}}
	rules, err := Apply(user, Options{Preset: "ru", ProxyTarget: "Proxy", BlockAds: true})
	if err != nil {
		t.Fatal(err)
	}
	if rules[0] != user[0] {
		t.Fatalf("a user rule must come first, got %+v", rules[0])
	}
	if rules[1].Target != "reject" || rules[1].Value != "category-ads-all" {
		t.Fatalf("the ad block comes right after the user's rules, got %+v", rules[1])
	}
	last := rules[len(rules)-1]
	if last.Type != engine.RuleMatchAll || last.Target != "Proxy" {
		t.Fatalf("everything else goes to the proxy, got %+v", last)
	}
	for _, r := range rules {
		if r.Type == engine.RuleGeoIP && !r.NoResolve {
			t.Fatalf("a geoip rule must not resolve names: %+v", r)
		}
	}
}

func TestAUserCatchAllWinsAndPresetsNeedATarget(t *testing.T) {
	user := []engine.Rule{{Type: engine.RuleMatchAll, Target: "direct"}}
	if rules, err := Apply(user, Options{Preset: "ru", ProxyTarget: "Proxy"}); err != nil || len(rules) != 1 {
		t.Fatalf("after a user catch-all nothing can match: %v, %v", rules, err)
	}
	if _, err := Apply(nil, Options{Preset: "ru"}); err == nil {
		t.Fatal("a preset without a proxy target must be refused")
	}
	if _, err := Apply(nil, Options{Preset: "mars", ProxyTarget: "Proxy"}); err == nil {
		t.Fatal("an unknown preset must be refused")
	}
	if rules, err := Apply(nil, Options{}); err != nil || len(rules) != 0 {
		t.Fatalf("no preset leaves the user's rules alone: %v, %v", rules, err)
	}
}

// TestPresetsPassThePlanCheck runs every preset through the plan check, so a
// preset can never produce a plan the core refuses.
func TestPresetsPassThePlanCheck(t *testing.T) {
	for _, preset := range Presets() {
		rules, err := Apply(nil, Options{Preset: preset.ID, ProxyTarget: "out", BlockAds: true})
		if err != nil {
			t.Fatal(err)
		}
		plan := &engine.Plan{SessionID: "presets", Rules: rules,
			Outbounds: []engine.Outbound{{ID: "out", Protocol: engine.ProtocolDirect}}}
		if err := plan.Validate(); err != nil {
			t.Fatalf("preset %s: %v", preset.ID, err)
		}
	}
}

// TestEveryEngineAcceptsEveryPreset hands each preset to the validator of each
// engine, with the geo databases Sora ships, so a preset never names a geosite
// tag or a rule set an engine cannot load.
func TestEveryEngineAcceptsEveryPreset(t *testing.T) {
	dir := os.Getenv("SORA_ENGINES_DIR")
	if dir == "" {
		t.Skip("set SORA_ENGINES_DIR to a directory with sing-box, xray, mihomo and the geo databases")
	}
	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Minute)
	defer cancel()
	reg := registry.Discover(ctx, dir, supervise.Config{HomeDir: t.TempDir()})
	for _, preset := range Presets() {
		for _, kind := range []engine.Kind{engine.KindSingBox, engine.KindXray, engine.KindMihomo} {
			t.Run(preset.ID+"/"+string(kind), func(t *testing.T) {
				rules, err := Apply(nil, Options{Preset: preset.ID, ProxyTarget: "out", BlockAds: true})
				if err != nil {
					t.Fatal(err)
				}
				plan := &engine.Plan{SessionID: "presets", Engines: []engine.Kind{kind}, Rules: rules,
					LocalProxy: engine.LocalProxy{Enabled: true},
					Outbounds:  []engine.Outbound{{ID: "out", Protocol: engine.ProtocolShadowsocks, Server: "203.0.113.5", Port: 8388, Cipher: "aes-256-gcm", Password: "preset-test-password"}},
					Options:    engine.Options{LogLevel: "warning", TestURL: engine.TestURLProduction}}
				eng, err := reg.Factory()(ctx, plan)
				if err != nil {
					t.Fatal(err)
				}
				defer func() { _ = eng.Close() }()
				if err := eng.Validate(ctx, plan); err != nil {
					t.Fatal(err)
				}
			})
		}
	}
}

func TestATargetWithoutAPresetStillCarriesTheRest(t *testing.T) {
	rules, err := Apply(nil, Options{ProxyTarget: "proxy"})
	if err != nil {
		t.Fatal(err)
	}
	if len(rules) != 1 || rules[0].Type != engine.RuleMatchAll || rules[0].Target != "proxy" {
		t.Fatalf("rules = %+v: the rest must go to the target, not direct", rules)
	}
	if rules, _ := Apply(nil, Options{}); len(rules) != 0 {
		t.Fatalf("a plan without routing options gets no rules: %+v", rules)
	}
}
