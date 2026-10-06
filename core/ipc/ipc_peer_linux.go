//go:build linux

package ipc

import (
	"net"
	"strconv"

	"golang.org/x/sys/unix"
)

// socketMode opens the socket to every account, because the identity below is
// the boundary: connecting needs write permission on the socket file, and the
// person polkit admits is not in the service group. A connection is refused on
// accept unless the kernel's identity passes the allow rule.
const socketMode = 0o666

// peerOf reads the identity of the other end from the kernel. Linux answers
// SO_PEERCRED on a unix socket, so the uid and the pid here are the kernel's word
// and not a value the client sent.
func peerOf(connection net.Conn) Peer {
	unixConn, ok := connection.(*net.UnixConn)
	if !ok {
		return Peer{Detail: "not a unix connection"}
	}
	raw, err := unixConn.SyscallConn()
	if err != nil {
		return Peer{Detail: "the connection carries no kernel handle"}
	}
	var (
		credentials *unix.Ucred
		innerErr    error
	)
	if err := raw.Control(func(fd uintptr) {
		credentials, innerErr = unix.GetsockoptUcred(int(fd), unix.SOL_SOCKET, unix.SO_PEERCRED)
	}); err != nil {
		return Peer{Detail: "the connection cannot be inspected"}
	}
	if innerErr != nil || credentials == nil {
		return Peer{Detail: "the peer credentials are not available"}
	}
	return Peer{
		UID:      int(credentials.Uid),
		PID:      int(credentials.Pid),
		Verified: true,
		Detail:   "uid " + strconv.Itoa(int(credentials.Uid)) + " pid " + strconv.Itoa(int(credentials.Pid)),
	}
}
