package engine

import (
	"runtime"
	"strings"
	"testing"
)

func validPlan() *Plan {
	return &Plan{
		SessionID: "s-1",
		Outbounds: []Outbound{
			{ID: "a", Name: "A", Protocol: ProtocolVMess, Server: "a.example.com", Port: 443, UUID: "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"},
			{ID: "b", Name: "B", Protocol: ProtocolHysteria2, Server: "b.example.com", Port: 8443, Password: "secret-pass"},
		},
		Groups: []Group{{Name: "Proxy", Type: GroupSelect, Outbounds: []string{"a", "b"}}},
		Rules:  []Rule{{Type: RuleMatchAll, Target: "a"}},
	}
}

func TestPlanValidateAcceptsAGoodPlan(t *testing.T) {
	if err := validPlan().Validate(); err != nil {
		t.Fatalf("good plan rejected: %v", err)
	}
}

func TestPlanValidateReportsEveryProblem(t *testing.T) {
	plan := validPlan()
	plan.SessionID = ""
	plan.Outbounds[1].ID = plan.Outbounds[0].ID
	plan.Outbounds[1].Server = "https://wrong.example.com/"
	plan.Groups[0].Outbounds = append(plan.Groups[0].Outbounds, "missing")
	plan.Rules = append(plan.Rules, Rule{Type: RuleIPCIDR, Value: "not-a-cidr", Target: "nope"})

	err := plan.Validate()
	if err == nil {
		t.Fatal("a broken plan must not validate")
	}
	text := err.Error()
	for _, want := range []string{"empty session id", "duplicate outbound id", "bare host", "unknown outbound", "not a CIDR", "unknown target"} {
		if !strings.Contains(text, want) {
			t.Errorf("error does not report %q:\n%s", want, text)
		}
	}
}

func TestPlanRejectsUntrustedDisplayNames(t *testing.T) {
	for _, name := range []string{"with\nnewline", "with\ttab", " padded ", strings.Repeat("x", MaxNameBytes+1)} {
		plan := validPlan()
		plan.Outbounds[0].Name = name
		if err := plan.Validate(); err == nil {
			t.Errorf("display name %q must be rejected", name)
		}
	}
	good := validPlan()
	good.Outbounds[0].Name = "Токио 01 (JP)"
	if err := good.Validate(); err != nil {
		t.Errorf("an ordinary localized name must be accepted: %v", err)
	}
}

func TestPlanRequiresAProbeTargetForAutomaticGroups(t *testing.T) {
	plan := validPlan()
	plan.Groups[0] = Group{Name: "Auto", Type: GroupURLTest, Outbounds: []string{"a"}}
	if err := plan.Validate(); err == nil || !strings.Contains(err.Error(), "test url") {
		t.Fatalf("an auto group without any probe url must fail: %v", err)
	}
	plan.Options.TestURL = TestURLProduction
	if err := plan.Validate(); err != nil {
		t.Fatalf("the plan level probe must satisfy the group: %v", err)
	}
}

func TestSecretsAndWarnings(t *testing.T) {
	plan := validPlan()
	secrets := plan.Secrets()
	if len(secrets) != 2 {
		t.Fatalf("expected the uuid and the password, got %v", secrets)
	}
	plan.Outbounds[0].TLS = TLS{Enabled: true}
	if warnings := plan.Outbounds[0].Warnings(); len(warnings) != 1 || warnings[0] != "tls-server-name-missing" {
		t.Errorf("unexpected warnings: %v", warnings)
	}
}

func TestSelectEnginePicksByCapability(t *testing.T) {
	plan := validPlan()
	plan.Outbounds = append(plan.Outbounds, Outbound{
		ID: "c", Name: "C", Protocol: ProtocolTUIC, Server: "c.example.com", Port: 9443,
		UUID: "cccccccc-1111-2222-3333-444444444444", Password: "another-secret",
	})
	available := []Availability{
		{Kind: KindXray, Usable: true, Version: mustVersion(t, "26.3.27")},
		{Kind: KindMihomo, Usable: true, Version: mustVersion(t, "1.19.32")},
		{Kind: KindSingBox, Usable: false, Reason: "binary missing"},
	}

	sel, err := SelectEngine(plan, available, []Kind{KindXray, KindMihomo, KindSingBox})
	if err != nil {
		t.Fatalf("selection failed: %v", err)
	}
	if sel.Kind != KindMihomo {
		t.Errorf("only mihomo carries tuic, got %s (%s)", sel.Kind, sel.Reason)
	}
	if !strings.Contains(strings.Join(sel.Rejected, ";"), "protocol tuic") {
		t.Errorf("the rejection reason must name the missing protocol: %v", sel.Rejected)
	}
}

func TestSelectEngineRefusesWhenNothingCanCarryThePlan(t *testing.T) {
	plan := validPlan()
	plan.Tun = Tun{Enabled: true}
	_, err := SelectEngine(plan, []Availability{{Kind: KindXray, Usable: false, Reason: "not installed"}}, []Kind{KindXray})
	if err == nil || !strings.Contains(err.Error(), "not installed") {
		t.Fatalf("expected a readable reason, got %v", err)
	}
}

func TestSelectEngineRespectsMinimumVersion(t *testing.T) {
	_, err := SelectEngine(validPlan(), []Availability{
		{Kind: KindMihomo, Usable: true, Version: mustVersion(t, "1.18.0")},
	}, []Kind{KindMihomo})
	if err == nil || !strings.Contains(err.Error(), "older than") {
		t.Fatalf("an outdated engine must be rejected: %v", err)
	}
}

func TestSingBoxCapabilitiesFollowTheBuildRatherThanTheName(t *testing.T) {
	p := validPlan()
	p.Outbounds = p.Outbounds[:1]
	p.Outbounds[0].Transport.Type = "xhttp"
	for _, tc := range []struct {
		version string
		tags    []string
		want    bool
	}{
		{"1.14.3", []string{"with_xhttp"}, false},
		{"1.14.3-lx.14", nil, false},
		{"1.14.3-lx.14", []string{"with_xhttp", "with_awg"}, true},
		{"1.14.2-lx.14", []string{"with_xhttp"}, false},
	} {
		version := mustVersion(t, tc.version)
		_, err := SelectEngine(p, []Availability{{Kind: KindSingBox, Usable: true, Version: version, BuildTags: tc.tags}}, []Kind{KindSingBox})
		if (err == nil) != tc.want {
			t.Errorf("version %s, tags %v: %v", tc.version, tc.tags, err)
		}
	}
	if Catalog[KindSingBox].Supports(FeatureXHTTP) {
		t.Fatal("discovering a fork changed upstream capabilities")
	}
	p.Outbounds[0].Transport.Type = "tcp"
	p.Outbounds[0].Amnezia = &AmneziaWG{J1: "legacy"}
	caps := BuildCapabilities(KindSingBox, mustVersion(t, "1.14.3-lx.14"), []string{"with_awg"})
	if len(caps.Missing(p)) == 0 {
		t.Fatal("legacy AWG fields must not be silently discarded")
	}
}

func TestTLSVerificationSettingSelectsCompatibleEngine(t *testing.T) {
	p := validPlan()
	p.Outbounds = p.Outbounds[:1]
	p.Outbounds[0].TLS = TLS{Enabled: true, Insecure: true}
	available := []Availability{
		{Kind: KindXray, Usable: true, Version: mustVersion(t, "26.3.27")},
		{Kind: KindSingBox, Usable: true, Version: mustVersion(t, "1.14.3-lx.14"), BuildTags: []string{"with_xhttp"}},
	}
	if _, err := SelectEngine(p, available, []Kind{KindXray}); err == nil || !strings.Contains(err.Error(), "TLS verification") {
		t.Fatalf("manual Xray must reject an unsupported setting before switching: %v", err)
	}
	selection, err := SelectEngine(p, available, []Kind{KindXray, KindSingBox})
	if err != nil || selection.Kind != KindSingBox {
		t.Fatalf("automatic selection should preserve the setting: %+v, %v", selection, err)
	}
	for _, tls := range []TLS{{Insecure: true}, {Enabled: true, Reality: true, Insecure: true}} {
		p.Outbounds[0].TLS = tls
		if _, err := SelectEngine(p, available, []Kind{KindXray}); err != nil {
			t.Fatalf("an unused TLS flag rejected plaintext or REALITY: %v", err)
		}
	}
}

func TestTunStackNeverSilentlyChangesWithTheEngine(t *testing.T) {
	p := validPlan()
	p.Outbounds = p.Outbounds[:1]
	p.Tun.Enabled = true
	for _, stack := range []string{"system", "gvisor", "mixed", "mips"} {
		p.Tun.Stack = stack
		for _, kind := range []Kind{KindXray, KindSingBox, KindMihomo} {
			want := (kind != KindXray || (runtime.GOOS == "linux" && stack == "gvisor")) && (kind != KindSingBox || stack != "mips")
			if got := len(Catalog[kind].Missing(p)) == 0; got != want {
				t.Errorf("%s stack %s: supported %t, want %t", kind, stack, got, want)
			}
		}
	}
}
