//go:build windows

package guard

// PlatformFirewall returns the kill switch this platform has. Windows has no
// user id to match the engine by — os.Getuid reports -1 there — so the
// argument is not read.
func PlatformFirewall(int, []string) (Firewall, error) { return NoopFirewall{}, nil }
