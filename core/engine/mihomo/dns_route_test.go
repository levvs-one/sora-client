package mihomo

import (
	"strings"
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
)

func TestDNSUsesTheRequestedTransportAndOutbound(t *testing.T) {
	d := engine.DNS{Enabled: true, Servers: []engine.DNSServer{{Tag: "remote", Address: "1.1.1.1",
		Transport: engine.DNSTCP, Dialer: "private-link", ProxyOnly: true}}}
	cfg, err := buildDNS(d, engine.Options{}, map[string]string{"private-link": "private_link"})
	if err != nil {
		t.Fatal(err)
	}
	if len(cfg.Nameserver) != 1 || cfg.Nameserver[0] != "tcp://1.1.1.1#private_link" {
		t.Fatalf("remote-only DNS lost its TCP transport or dialer: %+v", cfg.Nameserver)
	}
	for _, server := range cfg.DefaultNameserver {
		if strings.Contains(server, "#") {
			t.Fatal("bootstrap DNS must not depend on the proxy it resolves")
		}
	}
	if _, err := buildDNS(d, engine.Options{}, nil); err == nil {
		t.Fatal("unknown DNS outbound silently became direct")
	}
}
