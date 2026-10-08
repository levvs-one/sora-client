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

// pipeName includes the API version to keep incompatible clients and cores
// separate during upgrades.
const pipeName = `\\.\pipe\sora-core-v1`

// ListenAddress is the platform's core endpoint address.
func ListenAddress() string { return pipeName }

// pipeSecurityDescriptor grants SYSTEM, admins, process SID, and interactive
// users access, including UAC deny-only admins. Mask 0x0012018B excludes
// pipe-instance creation; peerOf restricts sessions.
func pipeSecurityDescriptor() (string, error) {
	token := windows.Token(0) //nolint:gosec // the token of this process, opened for querying
	if err := windows.OpenProcessToken(windows.CurrentProcess(), windows.TOKEN_QUERY, &token); err != nil {
		return "", errs.Wrap(err, errs.CodeInternal, errs.KeyPermissionDenied)
	}
	defer func() { _ = token.Close() }()
	// TOKEN_USER has a variable-length SID. Use the actual SID: named-pipe
	// ACLs do not resolve creator-owner (CO), and an unprotected CO
	// descriptor is rejected by conversion.
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

// listenLocal opens a named pipe. Process-owned pipes disappear on exit, so no
// stale endpoint cleanup is needed.
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

// dialLocal opens a named-pipe connection within the context deadline.
func dialLocal(ctx context.Context, address string) (net.Conn, error) {
	connection, err := winio.DialPipeContext(ctx, address)
	if err != nil {
		return nil, errs.From(err)
	}
	return connection, nil
}

// peerOf obtains the client process from the kernel and admits active-session
// or administrator processes. Inactive user sessions are rejected, matching
// Linux policy.
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

// sessionActive reports whether a Windows session is active.
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

// defaultAllow admits active-session or administrator peers; see peerOf.
func defaultAllow(Options) func(Peer) bool {
	return func(p Peer) bool { return p.Verified && p.Present }
}
