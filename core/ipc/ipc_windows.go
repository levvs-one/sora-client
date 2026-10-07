//go:build windows

package ipc

import (
	"context"
	"net"
	"unsafe"

	"github.com/Microsoft/go-winio"
	"golang.org/x/sys/windows"

	"github.com/levvs-one/sora-client/core/errs"
)

// pipeName is the name of the control endpoint. The version is part of the name so
// that an old interface and a new core cannot meet halfway through an upgrade and
// disagree about the contract.
const pipeName = `\\.\pipe\sora-core-v1`

// ListenAddress is where the core listens on this platform.
func ListenAddress() string { return pipeName }

// pipeSecurityDescriptor builds the access list of the pipe: the local system,
// the administrators, the account this core runs as, and the person signed in at
// the machine. Everyone else — services, network logons, other sessions' batch
// jobs — is refused by the kernel before a single byte of the protocol is read.
//
// The interactive users are what lets the interface in at all: the core runs as
// LocalSystem, and the person's token under UAC carries the administrators group
// as deny-only, so without them nobody at the machine could connect. They get
// read and write, not full control; this is the Windows counterpart of the
// active-session rule on Linux.
//
// The descriptor is assembled from the process token rather than written out as a
// constant. The string that circulates for named pipes and ends up in many
// projects is
//
//	D:P(A;;GA;;;SY)(A;;GA;;;BA)(A;;GA;;;CO)
//
// and it does not work: the creator owner of a named pipe is not resolved by the
// kernel in the access list, so the only account that may connect is nobody and
// every call is refused with "access is denied". The same string without the
// protected flag is rejected outright by the converter. Naming the real account of
// this process is the version that works, and it is measured rather than assumed.
func pipeSecurityDescriptor() (string, error) {
	token := windows.Token(0) //nolint:gosec // the token of this process, opened for querying
	if err := windows.OpenProcessToken(windows.CurrentProcess(), windows.TOKEN_QUERY, &token); err != nil {
		return "", errs.Wrap(err, errs.CodeInternal, errs.KeyPermissionDenied)
	}
	defer func() { _ = token.Close() }()
	// TOKEN_USER ends in a variable length security identifier, so the buffer is
	// sized generously and the structure is read back out of it.
	const capacity = 1024
	var returned uint32
	buffer := make([]byte, capacity)
	if err := windows.GetTokenInformation(token, windows.TokenUser, &buffer[0], capacity, &returned); err != nil {
		return "", errs.Wrap(err, errs.CodeInternal, errs.KeyPermissionDenied)
	}
	entry := (*windows.Tokenuser)(unsafe.Pointer(&buffer[0])) //nolint:gosec // the buffer was filled by the kernel
	if entry.User.Sid == nil {
		return "", errs.Newf(errs.CodeInternal, errs.KeyPermissionDenied,
			"ipc: the account of this process has no security identifier")
	}
	return "D:P(A;;GA;;;SY)(A;;GA;;;BA)(A;;GA;;;" + entry.User.Sid.String() + ")(A;;GRGW;;;IU)", nil
}

// listenLocal opens a named pipe. A pipe has no leftover to remove: it exists only
// while a process holds it, so a crashed core leaves nothing behind for a person to
// clean up.
func listenLocal(address string, _ Options) (net.Listener, error) {
	descriptor, err := pipeSecurityDescriptor()
	if err != nil {
		return nil, err
	}
	listener, err := winio.ListenPipe(address, &winio.PipeConfig{
		SecurityDescriptor: descriptor,
		MessageMode:        false,
		InputBufferSize:    64 << 10,
		OutputBufferSize:   64 << 10,
	})
	if err != nil {
		return nil, errs.Wrap(err, errs.CodeInternal, errs.KeyInternal)
	}
	return listener, nil
}

// dialLocal opens a client connection to a named pipe. The context carries the
// deadline, so a client that cannot reach a core that is not running fails in a
// few seconds instead of hanging on a pipe that will never answer.
func dialLocal(ctx context.Context, address string) (net.Conn, error) {
	connection, err := winio.DialPipeContext(ctx, address)
	if err != nil {
		return nil, errs.From(err)
	}
	return connection, nil
}

// peerOf reports what a named pipe can say about the other end.
//
// Windows decides who may connect with the access list of the pipe itself, and
// the pipe API this package uses does not report the identity of a client. So the
// boundary here is that list, and the identity of a client is established by the
// token it presents, which is checked by the control plane above. This is stated
// rather than papered over: Verified is false, and a caller that needs the
// identity of a client has to ask the kernel through a mechanism this package does
// not pretend to have.
func peerOf(net.Conn) Peer {
	return Peer{Verified: false, Detail: "the pipe access list is the boundary"}
}

// defaultAllow accepts every connection that got past the access list of the pipe.
// Anything else was refused by the kernel before it reached this point, and a
// second check with no information would only be theatre.
func defaultAllow(Options) func(Peer) bool { return func(Peer) bool { return true } }
