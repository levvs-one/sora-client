//go:build linux

package tunroute

import (
	"context"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"strconv"
	"strings"
)

// table holds the default route into the adapter. The rules sit just above
// the main table's 32766, below anything the system or another program is
// likely to own.
const (
	table          = "5340"
	priorityReturn = "5335"
	priorityEngine = "5336"
	priorityDNS    = "5337"
	priorityMain   = "5338"
	priorityTunnel = "5339"

	// The adapter's own addresses, the ones sing-box uses for its adapter.
	adapter4 = "172.19.0.1"
	adapter6 = "fdfe:dcba:9876::1"
)

func route(ctx context.Context, device string, uid int) error {
	_ = unroute(ctx)
	// "not" in a rule negates the whole selector, so "not this user and port
	// 53" would match the engine's own connections. The engine's traffic is
	// therefore sent to the main table first, positively, and the rules after
	// it see only everyone else's.
	engine := "uidrange " + strconv.Itoa(uid) + "-" + strconv.Itoa(uid)
	steps := []string{}
	for _, family := range families() {
		address, prefix := adapter4, "/30"
		if family == "-6" {
			address, prefix = adapter6, "/126"
		}
		steps = append(steps,
			// Traffic sent into the adapter takes the adapter's own address
			// as its source, so its answers can be recognised: a reverse path
			// check looks them up as if from loopback and as root, whatever
			// account the engine runs as, and only their destination tells
			// that they came through the tunnel.
			family+" addr replace "+address+prefix+" dev "+device,
			family+" route replace default dev "+device+" src "+address+" table "+table,
			family+" rule add from "+address+" lookup "+table+" priority "+priorityReturn,
			family+" rule add "+engine+" lookup main priority "+priorityEngine,
			family+" rule add ipproto udp dport 53 lookup "+table+" priority "+priorityDNS,
			family+" rule add lookup main suppress_prefixlength 0 priority "+priorityMain,
			family+" rule add lookup "+table+" priority "+priorityTunnel,
		)
	}
	for _, step := range steps {
		if err := ip(ctx, step); err != nil {
			_ = unroute(ctx)
			return err
		}
	}
	return nil
}

func unroute(ctx context.Context) error {
	var errs []error
	for _, family := range families() {
		for _, priority := range []string{priorityReturn, priorityEngine, priorityDNS, priorityMain, priorityTunnel} {
			// A rule is deleted one match at a time; a leftover from a crash may
			// have stacked several. The bound only guards against a loop.
			for range 16 {
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

// families are the address families the machine has; a kernel without IPv6
// refuses every IPv6 route, and there is no IPv6 traffic to route then.
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
