package engine

import (
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
