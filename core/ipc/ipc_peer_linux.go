//go:build linux

package ipc

import (
	"net"
	"strconv"

	"golang.org/x/sys/unix"
)

// socketMode permits connections from polkit users outside the service group.
// Accept enforces kernel-verified peer identity before admitting them.
const socketMode = 0o666

// peerOf obtains UID and PID from Linux SO_PEERCRED, never client-supplied
// values.
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
