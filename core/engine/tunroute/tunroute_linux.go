//go:build linux

package tunroute

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net"
	"net/netip"
	"os"
	"os/exec"
	"slices"
	"strconv"
	"strings"

	"github.com/levvs-one/sora-client/core/engine"
)

// table holds the TUN default route. Rules precede main-table priority 32766
// while leaving higher priorities to system rules.
const (
	table             = "5340"
	priorityBound     = "5337"
	priorityForeign   = "5337"
	priorityReturn    = "5333"
	priorityEngine    = "5334"
	priorityDNS       = "5335"
	priorityDNSBypass = "5336"
	priorityMain      = "5338"
	priorityTunnel    = "5339"
	protocol          = "242"
)

func route(ctx context.Context, tun engine.Tun, uid int) error {
	if err := cleanup(ctx, tun); err != nil {
		return err
	}
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
			family+" rule add iif lo ipproto tcp dport 53 lookup "+table+" priority "+priorityDNS,
			// If the TUN lookup fails, DNS still must skip foreign bypasses.
			family+" rule add iif lo ipproto udp dport 53 goto "+priorityMain+" priority "+priorityDNSBypass,
			family+" rule add iif lo ipproto tcp dport 53 goto "+priorityMain+" priority "+priorityDNSBypass,
			family+" rule add iif lo lookup main suppress_prefixlength 1 priority "+priorityMain,
			family+" rule add iif lo lookup "+table+" priority "+priorityTunnel,
		)
	}
	return steps
}

func bypass(ctx context.Context, device string, uid int) error {
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
		// DNS skips these rules via priorityDNSBypass; other protocols retain
		// the foreign VPN's bound sockets and point-to-point source addresses.
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
		out, err := exec.CommandContext(ctx, "ip", family, "-d", "-j", "-N", "rule").Output() //nolint:gosec // family is the fixed -4/-6 set
		if err != nil {
			return fmt.Errorf("tunroute: read rules: %w", err)
		}
		var rules []map[string]json.RawMessage
		if err := json.Unmarshal(out, &rules); err != nil {
			return fmt.Errorf("tunroute: decode rules: %w", err)
		}
		var kept []map[string]json.RawMessage
		for _, rule := range rules {
			args := ownedRule(rule)
			// Zero-valued selectors (including protocol 0) are wildcards in
			// Linux rule_find. Never let deletion select an earlier foreign rule.
			if args == "" || slices.ContainsFunc(kept, func(older map[string]json.RawMessage) bool { return deleteMatches(rule, older) }) {
				kept = append(kept, rule)
				continue
			}
			if err := ip(ctx, family+" rule del "+args); err != nil {
				errs = append(errs, err)
				kept = append(kept, rule)
			}
		}
		// Reading first lets a proxy-only, unprivileged core start when there
		// is no stale state, without attempting privileged mutations.
		out, err = exec.CommandContext(ctx, "ip", family, "route", "show", "table", table).CombinedOutput() //nolint:gosec // fixed family and Sora table
		if err != nil && !strings.Contains(string(out), "FIB table does not exist") {
			errs = append(errs, fmt.Errorf("tunroute: read table: %w: %s", err, out))
		} else if err == nil && len(out) != 0 {
			errs = append(errs, ip(ctx, family+" route flush table "+table))
		}
	}
	return errors.Join(errs...)
}

// New rules carry an owner protocol. For pre-upgrade crashes, recognize only
// the exact legacy selectors and table at their original reserved priorities.
func ownedRule(rule map[string]json.RawMessage) string {
	value := func(key string) string { return strings.Trim(string(rule[key]), "\"") }
	priority, err := strconv.Atoi(value("priority"))
	if err != nil {
		return ""
	}
	args := ruleSelectors(rule)
	if args == "" {
		return ""
	}
	// mihomo's IPv6 bound-interface rules use dynamically chosen priorities.
	// Older builds used table 2022; never flush that shared engine table.
	_, detached := rule["oif_detached"]
	if priority > 0 && value("oif") == engine.TunDevice && value("src") == "all" && (value("table") == table || value("table") == "2022") && (value("protocol") == "" || value("protocol") == "0" || value("protocol") == "2") && (len(rule) == 4 || len(rule) == 5 && (detached || value("protocol") != "") || len(rule) == 6 && detached && value("protocol") != "") {
		return args
	}
	if priority < 5333 || priority > 5339 {
		return ""
	}
	if value("protocol") == protocol && value("goto") == priorityMain && value("table") == "" {
		return args
	}
	if value("protocol") == protocol && (value("table") == table || value("table") == "254") {
		return args
	}
	if value("protocol") != "" && value("protocol") != "0" && value("protocol") != "2" {
		return ""
	}
	// Extra selectors indicate a different owner's rule even at our priority.
	allowed := []string{"priority", "src", "table", "protocol"}

	switch {
	case priority == 5333 && value("table") == "254" && value("src") == "all" && value("oif") != "":
		allowed = append(allowed, "oif")

	case priority == 5334 && value("table") == "254" && value("src") != "all" && value("src") != "":

	case priority == 5335 && value("table") == table && value("src") != "all" && value("src") != "":

	case priority == 5336 && value("table") == "254" && value("src") == "all" && value("uid_start") == strconv.Itoa(os.Getuid()) && value("uid_end") == value("uid_start"):
		allowed = append(allowed, "uid_start", "uid_end")

	case priority == 5337 && (value("dport_mask") == "" || value("dport_mask") == "0xffff") && value("table") == table && value("src") == "all" && value("iif") == "lo" && value("ipproto") == "ipproto-17" && value("dport") == "53":
		allowed = append(allowed, "iif", "ipproto", "dport", "dport_mask")

	case priority == 5338 && value("table") == "254" && value("src") == "all" && value("iif") == "lo" && value("suppress_prefixlen") == "0":
		allowed = append(allowed, "iif", "suppress_prefixlen")

	case priority == 5339 && value("table") == table && value("src") == "all" && value("iif") == "lo":
		allowed = append(allowed, "iif")

	default:
		return ""
	}
	for key := range rule {
		if !slices.Contains(allowed, key) {
			return ""
		}
	}
	return args
}

// ruleSelectors serializes every selector Sora installs. Unknown attributes
// are left alone instead of being silently dropped from a delete command.
func ruleSelectors(rule map[string]json.RawMessage) string {
	value := func(key string) string { return strings.Trim(string(rule[key]), "\"") }
	known := []string{"priority", "src", "dst", "table", "protocol", "goto", "oif", "iif", "oif_detached", "iif_detached", "uid_start", "uid_end", "ipproto", "dport", "dport_mask", "suppress_prefixlen"}
	for key := range rule {
		if !slices.Contains(known, key) {
			return ""
		}
	}
	proto := value("protocol")
	if proto == "" {
		proto = "0"
	}
	args := "priority " + value("priority") + " protocol " + proto
	for _, pair := range [][2]string{{"src", "from"}, {"dst", "to"}, {"oif", "oif"}, {"iif", "iif"}, {"table", "table"}, {"goto", "goto"}, {"suppress_prefixlen", "suppress_prefixlength"}} {
		if v := value(pair[0]); v != "" {
			args += " " + pair[1] + " " + v
		}
	}
	if value("uid_start") != "" {
		args += " uidrange " + value("uid_start") + "-" + value("uid_end")
	}
	if v := value("ipproto"); v != "" {
		args += " ipproto " + strings.TrimPrefix(v, "ipproto-")
	}
	if v := value("dport"); v != "" {
		if mask := value("dport_mask"); mask != "" {
			v += "/" + mask
		}
		args += " dport " + v
	}
	return args
}

// Kernel rule_find only compares positive selectors; omitted and zero values
// cannot exclude a more selective rule. This deliberately errs on preservation.
func deleteMatches(want, older map[string]json.RawMessage) bool {
	value := func(rule map[string]json.RawMessage, key string) string { return strings.Trim(string(rule[key]), "\"") }
	for _, key := range []string{"priority", "table", "protocol", "src", "dst", "oif", "iif", "uid_start", "uid_end", "ipproto", "dport", "dport_mask", "suppress_prefixlen"} {
		v := value(want, key)
		if v == "" || v == "all" || v == "0" && key != "priority" && key != "uid_start" && key != "uid_end" && key != "suppress_prefixlen" {
			continue
		}
		if v != value(older, key) {
			return false
		}
	}
	return (value(want, "goto") == "") == (value(older, "goto") == "")
}

// cleanup only touches the reserved table/priorities and the named Sora
// adapter. Before installation, keep the current engine's selected addresses.
func cleanup(ctx context.Context, tun engine.Tun) error {
	if _, err := exec.LookPath("ip"); err != nil {
		if !tun.Enabled && errors.Is(err, exec.ErrNotFound) {
			return nil
		}
		return fmt.Errorf("tunroute: TUN routing requires iproute2 (ip): %w", err)
	}
	if err := unroute(ctx); err != nil {
		return err
	}
	interfaces, err := net.Interfaces()
	if err != nil {
		return err
	}
	for _, iface := range interfaces {
		if iface.Name != tun.DeviceName {
			continue
		}
		addresses, err := iface.Addrs()
		if err != nil {
			return err
		}
		for _, address := range addresses {
			if tun.Enabled && slices.Contains(tun.Addresses(), address.String()) {
				continue
			}
			prefix, err := netip.ParsePrefix(address.String())
			if err != nil {
				return err
			}
			// Preserve unrelated and kernel-generated addresses even on sora0.
			owned := []string{"192.0.2.1/30", "192.0.2.5/30", "192.0.2.9/30", "2001:db8:5340::1/126", "2001:db8:5341::1/126", "2001:db8:5342::1/126",
				"172.19.0.1/30", "172.20.0.1/30", "172.21.0.1/30", "172.22.0.1/30", "198.18.0.1/30", "198.19.0.1/30", "fdfe:dcba:9876::1/126", "fdfe:dcba:9877::1/126", "fdfe:dcba:9878::1/126"}
			if !slices.Contains(owned, prefix.String()) {
				continue
			}
			family := "-4"
			if prefix.Addr().Is6() {
				family = "-6"
			}
			if err := ip(ctx, family+" addr del "+address.String()+" dev "+tun.DeviceName); err != nil {
				return err
			}
		}
	}
	return nil
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
	if strings.Contains(args, " rule add ") {
		args += " protocol " + protocol
	}
	out, err := exec.CommandContext(ctx, "ip", strings.Fields(args)...).CombinedOutput() //nolint:gosec // fixed arguments built above
	if err != nil {
		return fmt.Errorf("tunroute: ip %s: %w: %s", args, err, strings.TrimSpace(string(out)))
	}
	return nil
}
