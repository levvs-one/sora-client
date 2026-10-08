//go:build !linux && !windows

package guard

// PlatformFirewall returns NoopFirewall here. This package has no reversible
// macOS firewall implementation.
func PlatformFirewall(FirewallOptions) (Firewall, error) { return NoopFirewall{}, nil }
