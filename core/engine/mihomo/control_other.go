//go:build !windows

package mihomo

import "github.com/levvs-one/sora-client/core/engine/supervise"

// ControlAddress puts the controller on a private unix socket; see
// supervise.ControlSocket.
func (driver) ControlAddress(rt supervise.Runtime, _ bool) (string, error) {
	return supervise.ControlSocket(rt, "controller.sock")
}
