//go:build !windows

package supervise

import (
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"syscall"
)

// maxSocketPath is the shortest sun_path limit among the supported systems.
const maxSocketPath = 103

// ControlSocket returns "unix:<path>" in an owner-only directory, avoiding
// network discovery. It uses the engine home if short enough, otherwise a
// home-derived directory in the system temporary directory.
func ControlSocket(rt Runtime, name string) (string, error) {
	dir := rt.HomeDir
	if len(filepath.Join(dir, name)) > maxSocketPath {
		sum := sha256.Sum256([]byte(rt.HomeDir))
		dir = filepath.Join(os.TempDir(), "sora-"+hex.EncodeToString(sum[:6]))
		if err := privateDir(dir); err != nil {
			return "", err
		}
	}
	path := filepath.Join(dir, name)
	if len(path) > maxSocketPath {
		return "", fmt.Errorf("supervise: controller socket path is longer than %d bytes", maxSocketPath)
	}
	// A socket left by a crashed engine would make the bind fail.
	if err := os.Remove(path); err != nil && !errors.Is(err, os.ErrNotExist) {
		return "", err
	}
	return "unix:" + path, nil
}

// privateDir creates an owner-only directory. Existing entries must be real
// directories owned by this user with mode 0700 to prevent temporary-directory
// pre-creation attacks.
func privateDir(dir string) error {
	err := os.Mkdir(dir, 0o700)
	if err != nil && !errors.Is(err, os.ErrExist) {
		return err
	}
	info, err := os.Lstat(dir)
	if err != nil {
		return err
	}
	stat, ok := info.Sys().(*syscall.Stat_t)
	if !info.IsDir() || !ok || int(stat.Uid) != os.Getuid() || info.Mode().Perm() != 0o700 {
		return fmt.Errorf("supervise: %s is not a private directory of this user", dir)
	}
	return nil
}
