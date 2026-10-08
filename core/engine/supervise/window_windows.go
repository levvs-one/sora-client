//go:build windows

package supervise

import (
	"errors"
	"os"
	"os/exec"
	"syscall"
)

// HideWindow suppresses the engine console window using the documented field
// for Windows 7 compatibility.
func HideWindow(cmd *exec.Cmd) {
	if cmd.SysProcAttr == nil {
		cmd.SysProcAttr = &syscall.SysProcAttr{}
	}
	cmd.SysProcAttr.HideWindow = true
}

// interrupt cannot signal a hidden Windows console; shutdown kills it after the
// grace period.
func interrupt(*os.Process) error { return errors.ErrUnsupported }
