//go:build windows

package main

import (
	"context"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"time"

	"golang.org/x/sys/windows"
	"golang.org/x/sys/windows/svc"
	"golang.org/x/sys/windows/svc/mgr"
)

// serviceName is the name the installer registers the core under.
const serviceName = "SoraCore"

// runService runs the core under the service control manager when Windows
// started it as a service: a stop or a shutdown cancels the context, and the
// core restores the machine on the way out as it does on a signal.
func runService(arguments []string) (bool, error) {
	isService, err := svc.IsWindowsService()
	if err != nil || !isService {
		return false, err
	}
	h := &handler{arguments: arguments}
	if err := svc.Run(serviceName, h); err != nil {
		return true, err
	}
	return true, h.err
}

type handler struct {
	arguments []string
	err       error
}

func (h *handler) Execute(_ []string, requests <-chan svc.ChangeRequest, status chan<- svc.Status) (bool, uint32) {
	status <- svc.Status{State: svc.StartPending}
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	done := make(chan error, 1)
	go func() { done <- run(ctx, h.arguments) }()
	status <- svc.Status{State: svc.Running, Accepts: svc.AcceptStop | svc.AcceptShutdown}
	for {
		select {
		case change := <-requests:
			switch change.Cmd {
			case svc.Interrogate:
				status <- change.CurrentStatus
			case svc.Stop, svc.Shutdown:
				status <- svc.Status{State: svc.StopPending}
				cancel()
				h.err = <-done
				return false, exitCode(h.err)
			}
		case h.err = <-done:
			// The core stopped by itself: report it, so the recovery actions
			// the installer set restart it.
			return false, exitCode(h.err)
		}
	}
}

func exitCode(err error) uint32 {
	if err != nil {
		return 1
	}
	return 0
}

// installService registers this executable as the automatic service the
// interface talks to, restarted after a failure. An earlier registration, as
// an upgrade leaves, is stopped and pointed at this executable and these
// arguments instead of refused.
func installService(arguments []string) error {
	exe, err := os.Executable()
	if err != nil {
		return err
	}
	if exe, err = filepath.Abs(exe); err != nil {
		return err
	}
	m, err := mgr.Connect()
	if err != nil {
		return fmt.Errorf("service manager: %w", err)
	}
	defer func() { _ = m.Disconnect() }()
	config := mgr.Config{
		DisplayName:  "Sora core",
		Description:  "Runs the Sora connection engines for the Sora application.",
		StartType:    mgr.StartAutomatic,
		ErrorControl: mgr.ErrorNormal,
	}
	s, err := m.OpenService(serviceName)
	if err == nil {
		if err := stopService(s); err != nil {
			_ = s.Close()
			return err
		}
		current, err := s.Config()
		if err != nil {
			_ = s.Close()
			return err
		}
		current.DisplayName, current.Description, current.StartType = config.DisplayName, config.Description, config.StartType
		current.BinaryPathName = windows.ComposeCommandLine(append([]string{exe}, arguments...))
		if err := s.UpdateConfig(current); err != nil {
			_ = s.Close()
			return err
		}
	} else if s, err = m.CreateService(serviceName, exe, config, arguments...); err != nil {
		return fmt.Errorf("create the service: %w", err)
	}
	defer func() { _ = s.Close() }()
	restart := mgr.RecoveryAction{Type: mgr.ServiceRestart, Delay: 2 * time.Second}
	if err := s.SetRecoveryActions([]mgr.RecoveryAction{restart, restart, restart}, uint32((24 * time.Hour).Seconds())); err != nil {
		return err
	}
	// The core exits with an error when it fails rather than crashing, so a
	// failure exit restarts it too.
	if err := s.SetRecoveryActionsOnNonCrashFailures(true); err != nil {
		return err
	}
	return s.Start()
}

// uninstallService stops and removes the service; with none registered it
// succeeds, so an uninstaller may run it twice.
func uninstallService() error {
	m, err := mgr.Connect()
	if err != nil {
		return fmt.Errorf("service manager: %w", err)
	}
	defer func() { _ = m.Disconnect() }()
	s, err := m.OpenService(serviceName)
	if err != nil {
		return nil //nolint:nilerr // nothing registered is the state asked for
	}
	defer func() { _ = s.Close() }()
	if err := stopService(s); err != nil {
		return err
	}
	return s.Delete()
}

// stopService asks the service to stop and waits until it has, for as long as
// the core may take to restore the machine.
func stopService(s *mgr.Service) error {
	status, err := s.Query()
	if err != nil {
		return err
	}
	if status.State == svc.Stopped {
		return nil
	}
	if _, err := s.Control(svc.Stop); err != nil && !errors.Is(err, windows.ERROR_SERVICE_NOT_ACTIVE) {
		return err
	}
	for deadline := time.Now().Add(30 * time.Second); time.Now().Before(deadline); time.Sleep(200 * time.Millisecond) {
		if status, err = s.Query(); err != nil || status.State == svc.Stopped {
			return err
		}
	}
	return errors.New("the service did not stop within 30 seconds")
}
