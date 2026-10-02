//go:build !windows

package ipc

import (
	"context"
	"net"
	"os"
	"os/user"
	"path/filepath"
	"strconv"

	"github.com/levvs-one/sora-client/core/errs"
)

// defaultSocketGroup is the group that may open the socket when a caller does not
// name one. It matches the group the service account runs in, which is what the
// installation creates.
const defaultSocketGroup = "sora"

// ListenAddress is where the core listens on this platform.
func ListenAddress() string { return "/run/sora/core.sock" }

// listenLocal opens a unix socket, removes a leftover from a crashed core and
// restricts it to the group that may talk to the service.
func listenLocal(address string, opts Options) (net.Listener, error) {
	if err := os.MkdirAll(filepath.Dir(address), 0o755); err != nil {
		return nil, errs.Wrap(err, errs.CodeInternal, errs.KeyInternal)
	}
	// A socket left by a crashed core would make the service unable to start
	// until a person deletes a file, which is not a thing a service may depend on.
	if err := removeLeftover(address); err != nil {
		return nil, err
	}
	listener, err := net.Listen("unix", address)
	if err != nil {
		return nil, errs.Wrap(err, errs.CodeInternal, errs.KeyInternal)
	}
	// The socket carries the identity of the peer through the kernel, so the
	// permission on it is the real boundary: 0660 with the service group means the
	// interface account may connect and nothing else on the machine may.
	if err := os.Chmod(address, 0o660); err != nil {
		_ = listener.Close()
		return nil, errs.Wrap(err, errs.CodeInternal, errs.KeyInternal)
	}
	if err := chownToGroup(address, opts.Group); err != nil {
		_ = listener.Close()
		return nil, err
	}
	return listener, nil
}

// dialLocal opens a client connection to a unix socket.
func dialLocal(ctx context.Context, address string) (net.Conn, error) {
	dialer := &net.Dialer{}
	connection, err := dialer.DialContext(ctx, "unix", address)
	if err != nil {
		return nil, errs.From(err)
	}
	return connection, nil
}

// defaultAllow lets the owner of the core and nobody else. A different uid means
// another account on the machine, and an interface running as that account has no
// business driving a privileged service of this one.
func defaultAllow(peer Peer) bool {
	if !peer.Verified {
		// The peer could not be identified, so the permission on the socket is the
		// only boundary left. Refusing here would make the core unusable on a kernel
		// that does not answer, which is worse than the permission.
		return true
	}
	return peer.UID == os.Getuid()
}

// removeLeftover deletes a socket that nobody is listening on.
func removeLeftover(address string) error {
	if _, err := os.Stat(address); err != nil {
		return nil
	}
	if connection, err := net.DialTimeout("unix", address, dialTimeout); err == nil {
		_ = connection.Close()
		return nil
	}
	if err := os.Remove(address); err != nil {
		return errs.Wrap(err, errs.CodeInternal, errs.KeyInternal)
	}
	return nil
}

// chownToGroup gives the socket to the group that may connect. A service that
// cannot change the group still works: the permission alone decides, and a group
// is a convenience for an installation that wants one.
func chownToGroup(address, group string) error {
	if group == "" {
		group = defaultSocketGroup
	}
	// The group is looked up through the standard library rather than through the
	// system call package, because that lookup is not available on every platform
	// this file is compiled for.
	found, err := user.LookupGroup(group)
	if err != nil || found == nil {
		return nil
	}
	id, err := strconv.Atoi(found.Gid)
	if err != nil {
		return nil
	}
	// A failure here is not fatal: the mode 0660 already restricts the socket, and
	// the owner is the service account.
	_ = os.Chown(address, -1, id)
	return nil
}
