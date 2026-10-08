//go:build !windows

package supervise

import (
	"os"
	"os/exec"
	"syscall"
)

// HideWindow preserves the core's process group on non-Windows platforms so
// shutdown signals also reach the child.
func HideWindow(*exec.Cmd) {}

// interrupt sends SIGTERM so engines close listeners and the TUN device.
func interrupt(p *os.Process) error { return p.Signal(syscall.SIGTERM) }
