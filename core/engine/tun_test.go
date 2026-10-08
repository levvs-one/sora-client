package engine

import (
	"net/netip"
	"slices"
	"testing"
)

func TestChooseTunPrefixAvoidsOverlappingNetworks(t *testing.T) {
	for _, occupied := range []string{"172.19.0.1/30", "172.19.0.3/32", "172.16.0.1/12", "172.19.200.1/24"} {
		used := []netip.Prefix{netip.MustParsePrefix(occupied)}
		got, err := chooseTunPrefix(tunPools4, used)
		if err != nil {
			t.Fatal(err)
		}
		if got.Overlaps(used[0]) {
			t.Errorf("chosen %s overlaps %s", got, used[0])
		}
	}
}

func TestChooseTunPrefixIPv6AndExhaustion(t *testing.T) {
	used := []netip.Prefix{netip.MustParsePrefix(tunPools6[0]), netip.MustParsePrefix("172.19.0.0/16")}
	got, err := chooseTunPrefix(tunPools6, used)
	if err != nil || got.String() != tunPools6[1] {
		t.Fatalf("choice = %s, %v", got, err)
	}
	for _, pools := range [][]string{tunPools4, tunPools6} {
		used = nil
		for _, pool := range pools {
			used = append(used, netip.MustParsePrefix(pool))
		}
		if _, err := chooseTunPrefix(pools, used); err == nil {
			t.Fatal("exhausted pools must fail")
		}
	}
	if _, err := chooseTunPrefix([]string{"invalid"}, nil); err == nil {
		t.Fatal("invalid pool accepted")
	}
}

func TestPreparedTunKeepsSessionAddresses(t *testing.T) {
	if err := PrepareTun(nil); err == nil {
		t.Fatal("nil plan accepted")
	}
	p := &Plan{Tun: Tun{Enabled: true}, DNS: DNS{Mode: string(DNSFakeIP)}}
	if err := PrepareTun(p); err != nil {
		t.Fatal(err)
	}
	before := p.Tun.Addresses()
	if p.Tun.IPv4.Bits() != 30 || p.Tun.IPv6.Bits() != 126 || p.DNS.FakeIPRange == "" {
		t.Fatalf("tun = %+v, dns = %+v", p.Tun, p.DNS)
	}
	if err := PrepareTun(p); err != nil {
		t.Fatal(err)
	}
	if !slices.Equal(before, p.Tun.Addresses()) {
		t.Fatal("a restart changed addresses")
	}
	want := []netip.Prefix{p.Tun.IPv4.Masked(), p.Tun.IPv6.Masked()}
	if !slices.Equal(want, p.Tun.Networks()) {
		t.Fatalf("networks = %v, want %v", p.Tun.Networks(), want)
	}
	p.Tun.Enabled = false
	if len(p.Tun.Networks()) != 0 {
		t.Fatal("proxy mode grants tunnel network permits")
	}
}
