//go:build !windows

package secret

import (
	"os"

	"github.com/levvs-one/sora-client/core/errs"
)

// platformProtector returns the mechanism this platform uses for the master key.
// The service account owns its data directory, so owner-only permissions on the
// key file are the boundary. A desktop keyring would be friendlier to a person
// and weaker for a daemon: it needs a session, and it can be unlocked by
// anything running as the same user.
func platformProtector() Protector { return FileProtector{} }

// hardenFile restricts a file to its owner. The mode is set explicitly instead
// of relying on the process umask, because a core started by a service manager
// inherits a umask nobody checked.
func hardenFile(file *os.File) error {
	if err := file.Chmod(fileMode); err != nil {
		return errs.Wrap(err, errs.CodeInternal, errs.KeySecretStoreUnavailable)
	}
	return nil
}

// syncDir flushes the directory entry so a rename survives a power loss. The
// call is best effort: some filesystems refuse to open a directory for sync, and
// a vault that survives a crash on a filesystem that does not support it is
// still correct, only less durable.
func syncDir(dir string) error {
	handle, err := os.Open(dir)
	if err != nil {
		return nil
	}
	defer func() { _ = handle.Close() }()
	_ = handle.Sync()
	return nil
}
