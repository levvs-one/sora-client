//go:build !windows

package mihomo

import (
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/levvs-one/sora-client/core/engine/supervise"
)

func TestControlSocketFallsBackToAPrivateShortDirectory(t *testing.T) {
	long := filepath.Join(t.TempDir(), strings.Repeat("deep-", 20))
	addr, err := driver{}.ControlAddress(supervise.Runtime{HomeDir: long})
	if err != nil {
		t.Fatal(err)
	}
	path := strings.TrimPrefix(addr, "unix:")
	if len(path) > maxSocketPath {
		t.Fatalf("socket path %q is too long", path)
	}
	info, err := os.Stat(filepath.Dir(path))
	if err != nil || info.Mode().Perm() != 0o700 {
		t.Fatalf("socket directory must be owner-only: %v %v", info, err)
	}

	// A directory someone else prepared, here with the wrong mode, is refused.
	if err := os.Chmod(filepath.Dir(path), 0o755); err != nil {
		t.Fatal(err)
	}
	defer func() { _ = os.Remove(filepath.Dir(path)) }()
	if _, err := (driver{}).ControlAddress(supervise.Runtime{HomeDir: long}); err == nil {
		t.Fatal("a socket directory that is not owner-only must be refused")
	}
}
