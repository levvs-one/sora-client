//go:build !windows

package main

import (
	"fmt"
	"io"
	"os"
	"path/filepath"
	"runtime"

	"golang.org/x/sys/unix"

	"github.com/levvs-one/sora-client/core/secret"
)

// platformProtector uses an owner-only key file and directory without a
// session-dependent keychain. Protection depends on the service account's
// security.
func platformProtector() secret.Protector { return secret.FileProtector{} }

// platformName returns the platform name for reports.
func platformName() string { return runtime.GOOS }

// secureDataDir needs no changes: creation uses owner-only permissions and the
// service unit assigns ownership.
func secureDataDir(string) error { return nil }

// Hold the inode through shutdown; unlinking it would let another process lock
// a different inode while this service is still restoring its routes.
func lockInstance(address, _ string) (io.Closer, error) {
	//nolint:gosec // IPC clients must traverse the socket directory; the lock itself is owner-only
	if err := os.MkdirAll(filepath.Dir(address), 0o755); err != nil {
		return nil, err
	}
	file, err := os.OpenFile(address+".lock", os.O_CREATE|os.O_RDWR, 0o600) //nolint:gosec // fixed suffix beside the operator-selected IPC endpoint
	if err != nil {
		return nil, err
	}
	if err := unix.Flock(int(file.Fd()), unix.LOCK_EX|unix.LOCK_NB); err != nil {
		_ = file.Close()
		return nil, fmt.Errorf("core: another instance owns %s: %w", address, err)
	}
	return file, nil
}
