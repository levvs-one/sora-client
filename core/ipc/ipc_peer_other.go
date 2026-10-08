//go:build !windows && !linux

package ipc

import "net"

// socketMode restricts access to the service group when peer identity cannot be
// verified.
const socketMode = 0o660

// peerOf leaves Verified false: macOS LOCAL_PEERCRED/LOCAL_PEERPID support is
// unimplemented without hardware validation. Socket permissions and the control
// token enforce access.
func peerOf(net.Conn) Peer {
	return Peer{Verified: false, Detail: "the permission on the socket is the boundary"}
}
