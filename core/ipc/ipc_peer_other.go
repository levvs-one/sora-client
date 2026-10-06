//go:build !windows && !linux

package ipc

import "net"

// socketMode keeps the socket to the service group: without a verified peer
// identity, the permission on the file is the boundary.
const socketMode = 0o660

// peerOf reports what a unix socket can say about the other end on this platform.
//
// macOS offers LOCAL_PEERCRED and LOCAL_PEERPID through the same socket options,
// and the access list of the socket file is the boundary in front of it. The
// reading is not implemented here because it has to be checked on hardware this
// project does not build on, and a peer identity that is guessed is worse than a
// peer identity that is honestly absent. Verified is false, and the permission on
// the socket plus the token of the caller are what actually decide.
func peerOf(net.Conn) Peer {
	return Peer{Verified: false, Detail: "the permission on the socket is the boundary"}
}
