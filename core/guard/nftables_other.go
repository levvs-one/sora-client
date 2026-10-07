//go:build !linux && !windows

package guard

// PlatformFirewall returns the kill switch this platform has: none here. On
// macOS there is no mechanism in this package that is both correct and
// reversible, so the answer is honest rather than approximate.
func PlatformFirewall(int, []string) (Firewall, error) { return NoopFirewall{}, nil }
