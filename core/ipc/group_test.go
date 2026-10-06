//go:build !windows

package ipc

import (
	"os"
	"os/user"
	"testing"
)

func TestGroupMembersMayConnect(t *testing.T) {
	me, err := user.Current()
	if err != nil {
		t.Skip(err)
	}
	primary, err := user.LookupGroupId(me.Gid)
	if err != nil {
		t.Skip(err)
	}
	stranger := os.Getuid() + 4242
	allow := defaultAllow(Options{Group: primary.Name})
	if !allow(Peer{UID: os.Getuid(), Verified: true}) {
		t.Error("the user of the core must be let in")
	}
	if !inGroup(os.Getuid(), primary.Name) {
		t.Errorf("a member of %s must be recognised", primary.Name)
	}
	if allow(Peer{UID: stranger, Verified: true}) {
		t.Error("an account outside the group must be refused")
	}
	if inGroup(os.Getuid(), "sora-group-that-does-not-exist") {
		t.Error("a missing group has no members")
	}
}
