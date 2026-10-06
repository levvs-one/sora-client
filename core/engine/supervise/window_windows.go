//go:build windows

package supervise

import (
	"errors"
	"os"
	"os/exec"
	"syscall"
)

// HideWindow stops the engine from flashing a console window when Sora is
// started from the desktop. Sora Legacy is a Windows 7 target, so the flag is
// set through the documented field instead of a raw constant.
func HideWindow(cmd *exec.Cmd) {
	if cmd.SysProcAttr == nil {
		cmd.SysProcAttr = &syscall.SysProcAttr{}
	}
	cmd.SysProcAttr.HideWindow = true
}

// interrupt has no console signal to send to a hidden child on Windows, so the
// engine is killed after the grace period instead.
func interrupt(*os.Process) error { return errors.ErrUnsupported }
