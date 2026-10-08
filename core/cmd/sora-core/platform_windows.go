//go:build windows

package main

import (
	"os"
	"time"

	"golang.org/x/sys/windows"
	"golang.org/x/sys/windows/svc"

	"github.com/levvs-one/sora-client/core/secret"
)

// platformProtector wraps the master key of the store with the machine and the
// account that run the core.
//
// DPAPI is the right choice here and not a convenience: the material never leaves
// the core. A plan carries references, the interface hands over material it is
// told to forget, and only this process ever asks the store to decrypt. That is
// why a service running as LocalSystem and an interface running as the user can
// share a core without sharing a key.
func platformProtector() secret.Protector { return secret.DPAPIProtector{} }

// platformName names the platform in a report.
func platformName() string { return "windows" }

// secureDataDir makes the data directory of the service belong to the system:
// owned by LocalSystem, with a protected access list for LocalSystem and the
// administrators only. ProgramData lets any user create a folder, so one made
// in advance by someone else, with rights of their own, would otherwise be
// used as found. Such a folder is set aside and a new one made.
//
// A core started by hand keeps its directory as it is: it runs as the person,
// who must keep the access.
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
