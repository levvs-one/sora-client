//go:build !windows

package supervise

import (
	"os"
	"os/exec"
	"syscall"
)

// HideWindow keeps the engine in the process group of the core service. Off
// Windows there is no window to hide, and the child must stay in the same
// process group so that a shutdown signal reaches it too.
func HideWindow(*exec.Cmd) {}

// interrupt asks the engine to shut down cleanly; all three engines close their
// listeners and the tun device on SIGTERM.
func interrupt(p *os.Process) error { return p.Signal(syscall.SIGTERM) }
