//go:build !windows

package main

import (
	"os"
	"path/filepath"
	"testing"

	"github.com/levvs-one/sora-client/core/ipc"
)

func TestInstanceLockSurvivesUntilClose(t *testing.T) {
	dir := t.TempDir()
	address := filepath.Join(dir, "core.sock")
	first, err := lockInstance(address, dir)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = first.Close() })
	if second, err := lockInstance(address, dir); err == nil {
		_ = second.Close()
		t.Fatal("a second instance acquired the startup lock")
	}
	if err := first.Close(); err != nil {
		t.Fatal(err)
	}
	next, err := lockInstance(address, dir)
	if err != nil {
		t.Fatal(err)
	}
	_ = next.Close()
}

func TestFailedConstructionReleasesEndpointAndLock(t *testing.T) {
	// Keep the socket path below sockaddr_un's limit even with a long TMPDIR.
	dir, err := os.MkdirTemp("", "sora-")
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() {
		if err := os.RemoveAll(dir); err != nil {
			t.Error(err)
		}
	})
	address := filepath.Join(dir, "core.sock")
	if _, err := New(t.Context(), Options{DataDir: dir, Socket: address, LocalPort: -1}); err == nil {
		t.Fatal("invalid port accepted")
	}
	lock, err := lockInstance(address, dir)
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = lock.Close() }()
	listener, err := ipc.Listen(t.Context(), ipc.Options{Address: address})
	if err != nil {
		t.Fatal(err)
	}
	_ = listener.Close()
}
