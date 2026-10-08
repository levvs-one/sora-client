//go:build linux

package ipc

import (
	"context"
	"time"

	"github.com/godbus/dbus/v5"
)

// PolkitAction is what a person must hold to drive the core. Its policy
// (service/linux/sora.policy) grants it to the active local session without a
// password, the way desktop network managers work, and names the sora user as
// the action owner: polkit lets only root or an action owner ask about another
// identity's process, and the core does not run as root.
const PolkitAction = "io.github.levvs-one.sora.control"

// polkitTimeout bounds the question, so a hung polkit cannot hold a connection
// open; the answer is then "no".
const polkitTimeout = 3 * time.Second

// polkitSubject is the (sa{sv}) subject polkit checks: the client process as the
// kernel reported it. A start time of zero lets polkit look it up itself, which
// is what stops a pid that was reused from inheriting the authorization.
type polkitSubject struct {
	Kind    string
	Details map[string]dbus.Variant
}

type polkitResult struct {
	Authorized bool
	Challenge  bool
	Details    map[string]string
}

// polkitAllows asks polkit whether the peer process holds action. Any failure
// (no system bus, no polkit, an unregistered action) is a refusal.
func polkitAllows(peer Peer, action string) bool {
	if !peer.Verified || peer.PID <= 0 {
		return false
	}
	conn, err := dbus.ConnectSystemBus()
	if err != nil {
		return false
	}
	defer func() { _ = conn.Close() }()
	subject := polkitSubject{Kind: "unix-process", Details: map[string]dbus.Variant{
		"pid":        dbus.MakeVariant(uint32(peer.PID)), //nolint:gosec // a kernel pid, positive and below 2^22
		"start-time": dbus.MakeVariant(uint64(0)),
		"uid":        dbus.MakeVariant(int32(peer.UID)), //nolint:gosec // a kernel uid
	}}
	ctx, cancel := context.WithTimeout(context.Background(), polkitTimeout)
	defer cancel()
	// Flags 0: no interaction. A connection is never held open for a password
	// prompt; a session that needs one is not the active local session.
	call := conn.Object("org.freedesktop.PolicyKit1", "/org/freedesktop/PolicyKit1/Authority").CallWithContext(ctx,
		"org.freedesktop.PolicyKit1.Authority.CheckAuthorization", 0,
		subject, action, map[string]string{}, uint32(0), "")
	if call.Err != nil {
		return false
	}
	var result polkitResult
	if err := call.Store(&result); err != nil {
		return false
	}
	return result.Authorized
}
