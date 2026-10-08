//go:build windows

package ipc

import (
	"context"
	"net"
	"strconv"
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
// the machine. Everyone else (services, network logons, other sessions' batch
// jobs) is refused by the kernel before a single byte of the protocol is read.
//
// The interactive users are what lets the interface in at all: the core runs as
// LocalSystem, and the person's token under UAC carries the administrators group
// as deny-only, so without them nobody at the machine could connect. They get
// read, write and attributes (0x0012018B) and not GENERIC_WRITE: for a pipe
// that would include FILE_CREATE_PIPE_INSTANCE, and anyone signed in could
// then serve instances of this pipe to the app. Which of them may talk to the
// core is decided per connection, see peerOf.
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
	return "D:P(A;;GA;;;SY)(A;;GA;;;BA)(A;;GA;;;" + entry.User.Sid.String() + ")(A;;0x0012018B;;;IU)", nil
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

// peerOf asks the kernel which process opened the pipe and whether it belongs
// to the person at the machine: a process in the active session, or one with
// administrator rights. A second person signed in on the same computer, in a
// session that is not the active one, is not let in, as on Linux.
func peerOf(connection net.Conn) Peer {
	pipe, ok := connection.(interface{ Fd() uintptr })
	if !ok {
		return Peer{Detail: "not a named pipe"}
	}
	var pid uint32
	if err := windows.GetNamedPipeClientProcessId(windows.Handle(pipe.Fd()), &pid); err != nil {
		return Peer{Detail: "the client process is unknown"}
	}
	process, err := windows.OpenProcess(windows.PROCESS_QUERY_LIMITED_INFORMATION, false, pid)
	if err != nil {
		return Peer{PID: int(pid), Detail: "the client process cannot be inspected"}
	}
	defer func() { _ = windows.CloseHandle(process) }()
	var token windows.Token
	if err := windows.OpenProcessToken(process, windows.TOKEN_QUERY, &token); err != nil {
		return Peer{PID: int(pid), Detail: "the client token cannot be read"}
	}
	defer func() { _ = token.Close() }()

	var session, elevated, returned uint32
	if err := windows.GetTokenInformation(token, windows.TokenSessionId, (*byte)(unsafe.Pointer(&session)), 4, &returned); err != nil {
		return Peer{PID: int(pid), Detail: "the client session is unknown"}
	}
	_ = windows.GetTokenInformation(token, windows.TokenElevation, (*byte)(unsafe.Pointer(&elevated)), 4, &returned)
	system := false
	if user, err := token.GetTokenUser(); err == nil {
		system = user.User.Sid.IsWellKnown(windows.WinLocalSystemSid)
	}
	present := system || elevated != 0 || sessionActive(session)
	return Peer{PID: int(pid), Verified: true, Present: present, Detail: "pid " + strconv.Itoa(int(pid))}
}

// sessionActive reports whether the session is the one a person is using now.
func sessionActive(id uint32) bool {
	var sessions *windows.WTS_SESSION_INFO
	var count uint32
	if err := windows.WTSEnumerateSessions(0, 0, 1, &sessions, &count); err != nil {
		return false
	}
	defer windows.WTSFreeMemory(uintptr(unsafe.Pointer(sessions)))
	for _, s := range unsafe.Slice(sessions, count) {
		if s.SessionID == id {
			return s.State == windows.WTSActive
		}
	}
	return false
}

// defaultAllow lets in the person at the machine, see peerOf.
func defaultAllow(Options) func(Peer) bool {
	return func(p Peer) bool { return p.Verified && p.Present }
}
