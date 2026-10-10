package control

import (
	"strings"
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
)

func TestInternationalDomainRules(t *testing.T) {
	for _, tc := range []struct {
		input, value string
		kind         engine.RuleType
	}{
		{"domain:гоыыыыс.рф", "xn--c1awj3baaa.xn--p1ai", engine.RuleDomainSuffix},
		{"full:例子.中国", "xn--fsqu00a.xn--fiqs8s", engine.RuleDomain},
		{"domain:bücher.de", "xn--bcher-kva.de", engine.RuleDomainSuffix},
		{"process:Программа.exe", "Программа.exe", engine.RuleProcess},
	} {
		t.Run(tc.input, func(t *testing.T) {
			rule, err := ruleFromProto(&corev1.RoutingRule{Destination: tc.input, OutboundId: "direct"})
			if err != nil {
				t.Fatal(err)
			}
			if rule.Value != tc.value || rule.Type != tc.kind {
				t.Fatalf("got %#v, want %s %s", rule, tc.kind, tc.value)
			}
		})
	}
	for _, value := range []string{"domain:-bad.ru", "domain:bad-.ru", "domain:bad_host.ru", "domain:a..ru", "domain:" + strings.Repeat("a", 64) + ".ru"} {
		if _, err := ruleFromProto(&corev1.RoutingRule{Destination: value, OutboundId: "direct"}); err == nil {
			t.Errorf("accepted %q", value)
		}
	}
}
