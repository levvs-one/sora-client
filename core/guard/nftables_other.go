//go:build !linux

package guard

import "github.com/levvs-one/sora-client/core/errs"

// PlatformFirewall returns the kill switch this platform has.
//
// On Linux it is a table of this package's own in nftables, and it is exact: the
// engine is matched by its user id and everything else is dropped.
//
// On Windows and macOS there is no mechanism here that is both correct and
// reversible, so the answer is honest rather than approximate. The Windows
// firewall gives a block rule precedence over every allow rule and cannot exclude
// a program, so a table of block rules that lets the engine through does not exist;
// what is needed is the filtering platform with per-program filters, which is a
// separate piece of work. Until it exists, the proxy keeps pointing at the local
// port of an engine that is not running, which stops every application that
// honours the system proxy, and the applications that ignore it are a documented
// gap rather than a pretended guarantee.
func PlatformFirewall(engineUID int, _ []string) (Firewall, error) {
	if engineUID < 0 {
		return nil, errs.Newf(errs.CodeInvalidArgument, errs.KeyGuardFirewallFail,
			"guard: the engine has no user id")
	}
	return NoopFirewall{}, nil
}
