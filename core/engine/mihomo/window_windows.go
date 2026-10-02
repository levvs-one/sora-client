//go:build windows

package mihomo

import (
	"os/exec"
	"syscall"
)

// hideWindow stops the engine from flashing a console window when Sora is
// started from the desktop. Sora Legacy is a Windows 7 target, so the flag is
// set through the documented field instead of a raw constant.
func hideWindow(cmd *exec.Cmd) {
	if cmd.SysProcAttr == nil {
		cmd.SysProcAttr = &syscall.SysProcAttr{}
	}
	cmd.SysProcAttr.HideWindow = true
}
