//go:build !linux && !windows

package ipc

// PolkitAction names the polkit action on Linux; other systems have no polkit.
const PolkitAction = "io.github.levvs-one.sora.control"

// polkitAllows rejects authorization; socket-group permissions enforce access
// without polkit.
func polkitAllows(Peer, string) bool { return false }
