//go:build !windows

package mihomo

import (
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"syscall"

	"github.com/levvs-one/sora-client/core/engine/supervise"
)

// maxSocketPath is the shortest sun_path limit among the supported systems.
const maxSocketPath = 103

// ControlAddress puts the controller on a unix socket in an owner-only
// directory: no other user can connect, and no application finds a port that
// answers. The engine home is used when the path fits the socket limit;
// otherwise a short directory named after the home is used in the system
// temporary directory.
func (driver) ControlAddress(rt supervise.Runtime) (string, error) {
	dir := rt.HomeDir
	if len(filepath.Join(dir, socketName)) > maxSocketPath {
		sum := sha256.Sum256([]byte(rt.HomeDir))
		dir = filepath.Join(os.TempDir(), "sora-"+hex.EncodeToString(sum[:6]))
		if err := privateDir(dir); err != nil {
			return "", err
		}
	}
	path := filepath.Join(dir, socketName)
	if len(path) > maxSocketPath {
		return "", fmt.Errorf("mihomo: controller socket path is longer than %d bytes", maxSocketPath)
	}
	// A socket left by a crashed engine would make the bind fail.
	if err := os.Remove(path); err != nil && !errors.Is(err, os.ErrNotExist) {
		return "", err
	}
	return "unix:" + path, nil
}

const socketName = "controller.sock"

// privateDir makes dir an owner-only directory. In a shared temporary
// directory another user could create the name first, so an existing entry is
// accepted only if it is a real directory, owned by this user, mode 0700.
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
		return fmt.Errorf("mihomo: %s is not a private directory of this user", dir)
	}
	return nil
}
