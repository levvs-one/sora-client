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

// defaultSocketGroup matches the service account group created by the
// installer.
const defaultSocketGroup = "sora"

// ListenAddress is the platform's core endpoint address.
func ListenAddress() string { return "/run/sora/core.sock" }

// listenLocal creates a Unix socket, removes stale sockets, and applies
// platform permissions for authorized peers.
func listenLocal(address string, opts Options) (net.Listener, error) {
	//nolint:gosec // the interface account must traverse the directory; the socket mode below is the boundary
	if err := os.MkdirAll(filepath.Dir(address), 0o755); err != nil {
		return nil, errs.Wrap(err, errs.CodeInternal, errs.KeyInternal)
	}
	// Remove stale sockets so crashes do not require manual cleanup before
	// restarting.
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

// defaultAllow admits the core user, socket-group members, and Linux active
// local users authorized by polkit. The dedicated service UID separates engine
// traffic for the kill switch.
func defaultAllow(opts Options) func(Peer) bool {
	group := opts.Group
	if group == "" {
		group = defaultSocketGroup
	}
	return func(peer Peer) bool {
		if !peer.Verified {
			// Without verified identity, refuse sockets lacking
			// restrictive permissions.
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

// chownToGroup assigns the socket group when permitted. If unavailable,
// endpoint permissions and peer checks still enforce access.
func chownToGroup(address, group string) error {
	if group == "" {
		group = defaultSocketGroup
	}
	// Use standard-library group lookup because the syscall package lacks
	// it on some supported platforms.
	found, err := user.LookupGroup(group)
	if err != nil || found == nil {
		return nil //nolint:nilerr // a missing group is not fatal, as documented above
	}
	id, err := strconv.Atoi(found.Gid)
	if err != nil {
		return nil //nolint:nilerr // a group id that is not a number is treated as a missing group
	}
	// Ownership changes are optional; the service owns the socket and peer
	// checks enforce access.
	_ = os.Chown(address, -1, id)
	return nil
}
