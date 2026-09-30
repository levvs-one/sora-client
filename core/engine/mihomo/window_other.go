//go:build !windows

package mihomo

import "os/exec"

// hideWindow keeps the engine in the process group of the core service. Off
// Windows there is no window to hide, and the child must stay in the same
// process group so that a shutdown signal reaches it too.
func hideWindow(cmd *exec.Cmd) {}
