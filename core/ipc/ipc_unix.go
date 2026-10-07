//go:build !windows

package ipc

import (
	"context"
	"errors"
	"io/fs"
	"net"
	"os"
	"os/user"
	"path/filepath"
	"slices"
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
	//nolint:gosec // the interface account must traverse the directory; the socket mode below is the boundary
	if err := os.MkdirAll(filepath.Dir(address), 0o755); err != nil {
		return nil, errs.Wrap(err, errs.CodeInternal, errs.KeyInternal)
	}
	// A socket left by a crashed core would make the service unable to start
	// until a person deletes a file, which is not a thing a service may depend on.
	if err := removeLeftover(address); err != nil {
		return nil, err
	}
	var lc net.ListenConfig
	listener, err := lc.Listen(context.Background(), "unix", address)
	if err != nil {
		return nil, errs.Wrap(err, errs.CodeInternal, errs.KeyInternal)
	}
	if err := os.Chmod(address, socketMode); err != nil { //nolint:gosec // see socketMode: the boundary is the platform's peer rule
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

// defaultAllow lets in the user the core runs as, the members of the socket
// group and, on Linux, the person in the active local session as polkit sees
// it. A system installation runs the core as its own user, so that the kill
// switch can tell the engine's traffic from everyone else's; the person at the
// machine needs neither a group nor a terminal, and any other account is
// refused.
func defaultAllow(opts Options) func(Peer) bool {
	group := opts.Group
	if group == "" {
		group = defaultSocketGroup
	}
	return func(peer Peer) bool {
		if !peer.Verified {
			// The permission on the socket is the only boundary left, and an open
			// socket is no boundary at all.
			return socketMode&0o007 == 0
		}
		return peer.UID == os.Getuid() || inGroup(peer.UID, group) || polkitAllows(peer, PolkitAction)
	}
}

// inGroup reports whether the account uid belongs to the named group, as its
// primary group or a supplementary one.
func inGroup(uid int, group string) bool {
	wanted, err := user.LookupGroup(group)
	if err != nil {
		return false
	}
	account, err := user.LookupId(strconv.Itoa(uid))
	if err != nil {
		return false
	}
	ids, err := account.GroupIds()
	if err != nil {
		return false
	}
	return slices.Contains(ids, wanted.Gid)
}

// removeLeftover deletes a socket that nobody is listening on.
func removeLeftover(address string) error {
	if _, err := os.Stat(address); errors.Is(err, fs.ErrNotExist) {
		return nil
	} else if err != nil {
		return errs.Wrap(err, errs.CodeInternal, errs.KeyInternal)
	}
	dialer := net.Dialer{Timeout: dialTimeout}
	if connection, err := dialer.DialContext(context.Background(), "unix", address); err == nil {
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
		return nil //nolint:nilerr // a missing group is not fatal, as documented above
	}
	id, err := strconv.Atoi(found.Gid)
	if err != nil {
		return nil //nolint:nilerr // a group id that is not a number is treated as a missing group
	}
	// A failure here is not fatal: the owner is the service account, and the
	// peer rule decides who is let in.
	_ = os.Chown(address, -1, id)
	return nil
}
