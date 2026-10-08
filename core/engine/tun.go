package engine

import (
	"fmt"
	"net"
	"net/netip"
	"slices"
)

// Reserve the whole IPv4 pool because mihomo derives its adapter address from
// dns.fake-ip-range, including in redir-host mode.
var tunPools4 = []string{"172.19.0.1/16", "172.20.0.1/16", "172.21.0.1/16", "172.22.0.1/16", "198.18.0.1/16", "198.19.0.1/16"}
var tunPools6 = []string{"fdfe:dcba:9876::1/126", "fdfe:dcba:9877::1/126", "fdfe:dcba:9878::1/126"}

// PrepareTun chooses session addresses before the guard and engines use them.
// Restarts retain the choice so network watchers and firewall permits agree.
func PrepareTun(p *Plan) error {
	if p == nil {
		return fmt.Errorf("tun: nil plan")
	}
	if !p.Tun.Enabled || p.Tun.IPv4.IsValid() && p.Tun.IPv6.IsValid() {
		return nil
	}
	addrs, err := net.InterfaceAddrs()
	if err != nil {
		return fmt.Errorf("tun: read interface addresses: %w", err)
	}
	used := make([]netip.Prefix, 0, len(addrs))
	for _, addr := range addrs {
		prefix, err := netip.ParsePrefix(addr.String())
		if err != nil {
			return fmt.Errorf("tun: read interface prefix: %w", err)
		}
		used = append(used, prefix)
	}
	pools4 := tunPools4
	if p.DNS.FakeIPRange != "" {
		pools4 = []string{p.DNS.FakeIPRange}
	}
	pool, err := chooseTunPrefix(pools4, used)
	if err != nil {
		return err
	}
	if !pool.Addr().Is4() || pool.Bits() > 30 {
		return fmt.Errorf("tun: IPv4 address pool must hold a /30 adapter subnet")
	}
	addr6, err := chooseTunPrefix(tunPools6, used)
	if err != nil {
		return err
	}
	// A network address is not an adapter address; custom fake-IP pools often
	// specify the network itself.
	addr4 := pool.Addr()
	if addr4 == pool.Masked().Addr() {
		addr4 = addr4.Next()
	}
	p.Tun.IPv4 = netip.PrefixFrom(addr4, 30)
	p.Tun.IPv6 = addr6
	if p.Tun.DeviceName == "" {
		p.Tun.DeviceName = TunDevice
	}
	p.DNS.FakeIPRange = netip.PrefixFrom(addr4, pool.Bits()).String()
	return nil
}

func chooseTunPrefix(candidates []string, used []netip.Prefix) (netip.Prefix, error) {
	for _, candidate := range candidates {
		prefix, err := netip.ParsePrefix(candidate)
		if err != nil {
			return netip.Prefix{}, fmt.Errorf("tun: invalid address pool: %w", err)
		}
		if !slices.ContainsFunc(used, prefix.Overlaps) {
			return prefix, nil
		}
	}
	return netip.Prefix{}, fmt.Errorf("tun: all address pools overlap existing interfaces")
}

// Addresses supplies the adapter addresses to renderers. Defaults also permit
// validation of plans before session preparation.
func (t Tun) Addresses() []string {
	a4, a6 := t.IPv4, t.IPv6
	if !a4.IsValid() {
		a4 = netip.MustParsePrefix("172.19.0.1/30")
	}
	if !a6.IsValid() {
		a6 = netip.MustParsePrefix("fdfe:dcba:9876::1/126")
	}
	return []string{a4.String(), a6.String()}
}

// Networks limits firewall permits to the running session's adapter subnets.
func (t Tun) Networks() []netip.Prefix {
	if !t.Enabled {
		return nil
	}
	addresses := t.Addresses()
	return []netip.Prefix{netip.MustParsePrefix(addresses[0]).Masked(), netip.MustParsePrefix(addresses[1]).Masked()}
}
