//go:build !linux && !windows

package ipc

// PolkitAction names the polkit action on Linux; other systems have no polkit.
const PolkitAction = "io.github.levvs-one.sora.control"

// polkitAllows refuses: without polkit the socket group is the boundary.
func polkitAllows(Peer, string) bool { return false }
