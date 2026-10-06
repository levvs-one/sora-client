//go:build !windows

package guard

// PlatformProxy returns the proxy this platform has. Linux and Android have no
// system-wide proxy setting that Sora may own: desktops are configured per
// application, and on Android the tunnel is owned by the system service. Returning
// the no-op proxy says exactly that, instead of pretending to change something.
func PlatformProxy() Proxy { return NoopProxy{} }
