//go:build linux

package tunroute

import (
	"context"
	"errors"
	"fmt"
	"net"
	"net/netip"
	"os"
	"os/exec"
	"strconv"
	"strings"

	"github.com/levvs-one/sora-client/core/engine"
)

// table holds the TUN default route. Rules precede main-table priority 32766
// while leaving higher priorities to system rules.
const (
	table           = "5340"
	priorityBound   = "5333"
	priorityForeign = "5334"
	priorityReturn  = "5335"
	priorityEngine  = "5336"
	priorityDNS     = "5337"
	priorityMain    = "5338"
	priorityTunnel  = "5339"
)

func route(ctx context.Context, tun engine.Tun, uid int) error {
	if err := bypass(ctx, tun.DeviceName, uid); err != nil {
		return err
	}
	for _, step := range routeSteps(tun, families()) {
		if err := ip(ctx, step); err != nil {
			_ = unroute(ctx)
			return err
		}
	}
	return nil
}

func routeSteps(tun engine.Tun, families []string) []string {
	steps := []string{}
	addresses := tun.Addresses()
	for _, family := range families {
		address := addresses[0]
		if family == "-6" {
			address = addresses[1]
		}
		prefix := netip.MustParsePrefix(address)
		source := prefix.Addr().String()
		steps = append(steps,
			family+" addr replace "+address+" dev "+tun.DeviceName,
			family+" route replace default dev "+tun.DeviceName+" src "+source+" table "+table,
			// The return rule serves reverse-path validation of TUN replies, which
			// the kernel looks up with root's UID rather than the engine's.
			family+" rule add from "+source+" lookup "+table+" priority "+priorityReturn,
			family+" rule add iif lo ipproto udp dport 53 lookup "+table+" priority "+priorityDNS,
			family+" rule add iif lo lookup main suppress_prefixlength 0 priority "+priorityMain,
			family+" rule add iif lo lookup "+table+" priority "+priorityTunnel,
		)
	}
	return steps
}

func bypass(ctx context.Context, device string, uid int) error {
	_ = unroute(ctx)
	interfaces, err := net.Interfaces()
	if err != nil {
		return fmt.Errorf("tunroute: list interfaces: %w", err)
	}
	for _, iface := range interfaces {
		if iface.Name == device || iface.Flags&net.FlagLoopback != 0 {
			continue
		}
		var addresses []netip.Prefix
		if iface.Flags&net.FlagPointToPoint != 0 {
			addrs, err := iface.Addrs()
			if err != nil {
				_ = unroute(ctx)
				return fmt.Errorf("tunroute: interface addresses: %w", err)
			}
			for _, addr := range addrs {
				prefix, err := netip.ParsePrefix(addr.String())
				if err != nil {
					_ = unroute(ctx)
					return err
				}
				addresses = append(addresses, prefix)
			}
		}
		for _, step := range bypassSteps(iface.Name, addresses, families()) {
			if err := ip(ctx, step); err != nil {
				_ = unroute(ctx)
				return err
			}
		}
	}
	for _, family := range families() {
		owner := strconv.Itoa(uid)
		if err := ip(ctx, family+" rule add uidrange "+owner+"-"+owner+" lookup main priority "+priorityEngine); err != nil {
			_ = unroute(ctx)
			return err
		}
	}
	return nil
}

func bypassSteps(device string, addresses []netip.Prefix, families []string) []string {
	var steps []string
	for _, family := range families {
		// A bound socket belongs to its chosen interface, including another
		// VPN's physical uplink. Sending it to Sora would create a loop.
		steps = append(steps, family+" rule add oif "+device+" lookup main priority "+priorityBound)
		for _, prefix := range addresses {
			if prefix.Addr().Is4() != (family == "-4") {
				continue
			}
			steps = append(steps, family+" rule add from "+prefix.Addr().String()+" lookup main priority "+priorityForeign)
		}
	}
	return steps
}

func unroute(ctx context.Context) error {
	var errs []error
	for _, family := range families() {
		for _, priority := range []string{priorityBound, priorityForeign, priorityReturn, priorityEngine, priorityDNS, priorityMain, priorityTunnel} {
			// Delete all stacked rule matches left by crashes;
			// bound retries to avoid an infinite loop.
			for range 256 {
				if ip(ctx, family+" rule del priority "+priority) != nil {
					break
				}
			}
		}
		if err := ip(ctx, family+" route flush table "+table); err != nil && !strings.Contains(err.Error(), "FIB table does not exist") {
			errs = append(errs, err)
		}
	}
	return errors.Join(errs...)
}

// families returns supported address families, excluding IPv6 when the kernel
// rejects IPv6 routes.
func families() []string {
	if _, err := os.Stat("/proc/net/if_inet6"); err != nil {
		return []string{"-4"}
	}
	return []string{"-4", "-6"}
}

func ip(ctx context.Context, args string) error {
	out, err := exec.CommandContext(ctx, "ip", strings.Fields(args)...).CombinedOutput() //nolint:gosec // fixed arguments built above
	if err != nil {
		return fmt.Errorf("tunroute: ip %s: %w: %s", args, err, strings.TrimSpace(string(out)))
	}
	return nil
}
