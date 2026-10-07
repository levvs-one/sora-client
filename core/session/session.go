// Package session owns one tunnel session at a time: the state machine, the
// engine that carries the traffic, the system settings the session owns, and
// the event stream the control plane serves to the interface.
//
// The core is a privileged, long-lived process and the interface is a window.
// Everything in this package therefore assumes the interface may disappear at
// any moment: a session stops on its own context, the system guard is restored
// on every exit path, and every state change is written to a journal that a
// new subscriber can replay. Nothing here waits for a caller to be polite.
package session

import (
	"time"

	"github.com/levvs-one/sora-client/core/errs"
)

// State is the lifecycle state of a session. The set matches the states of the
// sora.core.v1 contract one for one, so the control plane only translates names
// and never invents a state of its own.
type State int

// Session states.
const (
	// StateDisconnected is the resting state and the state a fresh core
	// reports. Traffic is not redirected and no system setting is owned.
	StateDisconnected State = iota
	// StateConnecting is the first attempt to bring the plan up.
	StateConnecting
	// StateConnected means the engine is running and the guard is armed.
	StateConnected
	// StateReconnecting means a running session was lost and the core is
	// retrying inside its restart budget.
	StateReconnecting
	// StateFailed means the core gave up. Traffic stays blocked by the guard
	// when the kill switch is on, which is the whole point of a kill switch.
	StateFailed
)

// String renders the state for logs and diagnostics.
func (s State) String() string {
	switch s {
	case StateDisconnected:
		return "disconnected"
	case StateConnecting:
		return "connecting"
	case StateConnected:
		return "connected"
	case StateReconnecting:
		return "reconnecting"
	case StateFailed:
		return "failed"
	default:
		return "unknown"
	}
}

// allowedTransitions is the state machine, written out instead of scattered
// comparisons. A transition that is not listed is a bug in the caller, and a
// bug in the caller must not be able to invent a state.
var allowedTransitions = map[State][]State{
	StateDisconnected: {StateConnecting},
	StateConnecting:   {StateConnected, StateReconnecting, StateFailed, StateDisconnected},
	StateConnected:    {StateReconnecting, StateDisconnected, StateFailed},
	StateReconnecting: {StateConnected, StateFailed, StateDisconnected},
	StateFailed:       {StateConnecting, StateDisconnected},
}

// canTransition reports whether from to is a legal move.
func canTransition(from, to State) bool {
	for _, candidate := range allowedTransitions[from] {
		if candidate == to {
			return true
		}
	}
	return false
}

// terminal reports whether no further progress happens without a new command.
func (s State) terminal() bool { return s == StateFailed || s == StateDisconnected }

// KeySelectionChanged is the journal key of a group selection. It is defined
// here rather than in the error catalog because it is an event, not a failure.
const KeySelectionChanged errs.Key = "core.session.selection_changed"

// Status is the snapshot a client reads instead of watching events. It is a
// value, never a pointer to internal state, so a caller can keep it. The guard
// fields travel with it because the state of the system belongs to the state of
// the session: a client that reconnects must learn both.
// fields travel with it because the state of the system belongs to the state of
// the session: a client that reconnects must learn both.
type Status struct {
	State      State
	SessionID  string
	Reason     errs.Code
	Key        errs.Key
	Detail     string
	ChangedAt  time.Time
	RetryAfter time.Duration

	// KillSwitch reports whether traffic is blocked while the engine is down.
	KillSwitch bool
	// Bypass lists the destinations that skip the tunnel.
	Bypass []string
	// TunnelMode is the tunnel the session asked for.
	TunnelMode string
}
