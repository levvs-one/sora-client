//go:build windows

package main

import (
	"io"
	"os"
	"path/filepath"
	"time"

	"golang.org/x/sys/windows"
	"golang.org/x/sys/windows/svc"

	"github.com/levvs-one/sora-client/core/secret"
)

// platformProtector binds the master key to the core's machine and account via
// DPAPI. Only the core decrypts credentials; a user UI can use a LocalSystem
// core through references.
func platformProtector() secret.Protector { return secret.DPAPIProtector{} }

// platformName returns the platform name for reports.
func platformName() string { return "windows" }

// secureDataDir gives LocalSystem ownership and limits service access to SYSTEM
// and administrators. It replaces pre-created directories with unsafe access;
// manual runs keep their permissions.
func secureDataDir(dir string) error {
	service, err := svc.IsWindowsService()
	if err != nil {
		return err
	}
	if !service {
		return nil
	}
	if sd, err := windows.GetNamedSecurityInfo(dir, windows.SE_FILE_OBJECT, windows.OWNER_SECURITY_INFORMATION); err == nil {
		owner, _, err := sd.Owner()
		if err == nil && !owner.IsWellKnown(windows.WinLocalSystemSid) && !owner.IsWellKnown(windows.WinBuiltinAdministratorsSid) {
			aside := dir + ".untrusted-" + time.Now().Format("20060102150405")
			if err := os.Rename(dir, aside); err != nil {
				return err
			}
			if err := os.MkdirAll(dir, 0o700); err != nil {
				return err
			}
		}
	}
	system, err := windows.CreateWellKnownSid(windows.WinLocalSystemSid)
	if err != nil {
		return err
	}
	sd, err := windows.SecurityDescriptorFromString("D:P(A;OICI;FA;;;SY)(A;OICI;FA;;;BA)")
	if err != nil {
		return err
	}
	dacl, _, err := sd.DACL()
	if err != nil {
		return err
	}
	return windows.SetNamedSecurityInfo(dir, windows.SE_FILE_OBJECT,
		windows.OWNER_SECURITY_INFORMATION|windows.DACL_SECURITY_INFORMATION|windows.PROTECTED_DACL_SECURITY_INFORMATION,
		system, nil, dacl, nil)
}

func lockInstance(_ string, dataDir string) (io.Closer, error) {
	name, err := windows.UTF16PtrFromString(filepath.Join(dataDir, "core.lock"))
	if err != nil {
		return nil, err
	}
	handle, err := windows.CreateFile(name, windows.GENERIC_READ|windows.GENERIC_WRITE, 0, nil, windows.OPEN_ALWAYS, windows.FILE_ATTRIBUTE_NORMAL, 0)
	if err != nil {
		return nil, err
	}
	return os.NewFile(uintptr(handle), "core.lock"), nil
}
