// Package session manages one tunnel's state, engine, system settings, and
// replayable events. Sessions use independent contexts and restore guards on
// exit so UI disconnections do not prevent supervision or cleanup.
package session

import (
	"time"

	"github.com/levvs-one/sora-client/core/errs"
)

// State matches the sora.core.v1 lifecycle states one-to-one for control-plane
// translation.
type State int

// Session states.
const (
	// StateDisconnected is the initial resting state, with no redirected
	// traffic or owned system settings.
	StateDisconnected State = iota
	// StateConnecting is the first attempt to bring the plan up.
	StateConnecting
	// StateConnected means the engine is running and the guard is armed.
	StateConnected
	// StateReconnecting means a running session was lost and the core is
	// retrying inside its restart budget.
	StateReconnecting
	// StateFailed indicates exhausted recovery. The guard keeps traffic
	// blocked when the kill switch is enabled.
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

// allowedTransitions defines legal state changes; unlisted transitions are
// rejected.
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

// KeySelectionChanged identifies group-selection events and belongs outside the
// error catalog because it is not a failure.
const KeySelectionChanged errs.Key = "core.session.selection_changed"

// Status is a value snapshot callers may retain. It includes guard settings so
// reconnecting clients can restore both session and system-state views.
type Status struct {
	State      State
	SessionID  string
	Reason     errs.Code
	Key        errs.Key
	Detail     string
	ChangedAt  time.Time
	RetryAfter time.Duration

	// KillSwitch reports whether traffic is blocked while the engine is
	// down.
	KillSwitch bool
	// Bypass lists the destinations that skip the tunnel.
	Bypass []string
	// TunnelMode is the tunnel the session asked for.
	TunnelMode string
}
