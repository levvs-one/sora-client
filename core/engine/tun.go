package engine

import (
	"fmt"
	"net"
	"net/netip"
	"slices"
)

// Adapter subnets and fake addresses have separate reservations. Neither uses
// private/link-local space, which the kill switch keeps reachable.
var tunPools4 = []string{"192.0.2.1/30", "192.0.2.5/30", "192.0.2.9/30"}
var tunPools6 = []string{"2001:db8:5340::1/126", "2001:db8:5341::1/126", "2001:db8:5342::1/126"}

// PrepareTun chooses session addresses before the guard and engines use them.
// Restarts retain the choice so network watchers and firewall permits agree.
func PrepareTun(p *Plan) error {
	if p == nil {
		return fmt.Errorf("tun: nil plan")
	}
	if !p.Tun.Enabled {
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
	// The benchmark range is reserved for synthesized addresses. Reject
	// custom LAN pools rather than allowing cached fake addresses onto LAN.
	fake := p.DNS.FakeIPRange
	if fake == "" {
		fake = "198.18.0.0/16"
	}
	fakePrefix, err := netip.ParsePrefix(fake)
	benchmark := netip.MustParsePrefix("198.18.0.0/15")
	if err != nil || !fakePrefix.Addr().Is4() || fakePrefix.Bits() < benchmark.Bits() || !benchmark.Contains(fakePrefix.Addr()) {
		return fmt.Errorf("tun: fake-IP pool must be within %s", benchmark)
	}
	// Keep the selected pool across restarts, including when both adapter
	// addresses were supplied by the caller.
	if slices.ContainsFunc(used, fakePrefix.Overlaps) {
		return fmt.Errorf("tun: fake-IP pool overlaps an existing interface")
	}
	used = append(used, fakePrefix)
	if !p.Tun.IPv4.IsValid() {
		p.Tun.IPv4, err = chooseTunPrefix(tunPools4, used)
		if err != nil {
			return err
		}
	}
	if !p.Tun.IPv6.IsValid() {
		p.Tun.IPv6, err = chooseTunPrefix(tunPools6, used)
		if err != nil {
			return err
		}
	}
	if p.Tun.IPv4.Overlaps(fakePrefix) || !p.Tun.IPv4.Addr().Is4() || !p.Tun.IPv6.Addr().Is6() || p.Tun.IPv4.Bits() != 30 || p.Tun.IPv6.Bits() != 126 {
		return fmt.Errorf("tun: adapters must use separate IPv4 /30 and IPv6 /126 subnets")
	}
	for _, address := range []netip.Addr{p.Tun.IPv4.Addr(), p.Tun.IPv6.Addr()} {
		if !address.IsGlobalUnicast() || address.IsPrivate() {
			return fmt.Errorf("tun: adapter subnets must be outside private and link-local networks")
		}
	}
	if p.Tun.DeviceName == "" {
		p.Tun.DeviceName = TunDevice
	}
	p.DNS.FakeIPRange = fakePrefix.Masked().String()
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
		a4 = netip.MustParsePrefix(tunPools4[0])
	}
	if !a6.IsValid() {
		a6 = netip.MustParsePrefix(tunPools6[0])
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
