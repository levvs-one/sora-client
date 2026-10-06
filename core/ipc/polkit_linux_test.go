//go:build linux

package ipc

import (
	"os"
	"testing"
)

func TestPolkitRefusesWhatItCannotConfirm(t *testing.T) {
	me := Peer{UID: os.Getuid(), PID: os.Getpid(), Verified: true}
	if polkitAllows(me, "io.github.levvs-one.sora.action-that-is-not-registered") {
		t.Fatal("an action polkit does not know must be refused")
	}
	if polkitAllows(Peer{UID: os.Getuid(), PID: os.Getpid()}, PolkitAction) {
		t.Fatal("a peer the kernel did not identify must not reach polkit")
	}
}

// TestPolkitGrantsTheActiveSession needs a desktop session and an action whose
// policy says allow_active=yes, for example org.freedesktop.login1.power-off.
func TestPolkitGrantsTheActiveSession(t *testing.T) {
	action := os.Getenv("SORA_POLKIT_ACTIVE_ACTION")
	if action == "" {
		t.Skip("set SORA_POLKIT_ACTIVE_ACTION to an allow_active=yes action to ask the running polkit")
	}
	if !polkitAllows(Peer{UID: os.Getuid(), PID: os.Getpid(), Verified: true}, action) {
		t.Fatalf("polkit refused %s to this active session", action)
	}
}
