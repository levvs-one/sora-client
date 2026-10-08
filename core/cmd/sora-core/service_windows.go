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
	"golang.org/x/sys/windows/svc/eventlog"
	"golang.org/x/sys/windows/svc/mgr"

	"github.com/levvs-one/sora-client/core/errs"
)

// serviceName is the installed Windows service name.
const serviceName = "SoraCore"

// runService handles SCM startup. Stop and shutdown requests cancel the context
// so the core restores system settings.
func runService(arguments []string) (bool, error) {
	isService, err := svc.IsWindowsService()
	if err != nil || !isService {
		return false, err
	}
	h := &handler{arguments: arguments}
	err = svc.Run(serviceName, h)
	if err == nil {
		err = h.err
	}
	if err != nil {
		// Services have no console, so startup failures go to the
		// Windows event log.
		if log, lerr := eventlog.Open(serviceName); lerr == nil {
			_ = log.Error(1, "Sora core stopped: "+string(errs.KeyOf(err))+": "+errs.Detail(err))
			_ = log.Close()
		}
	}
	return true, err
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
			// Report unexpected termination so SCM applies the
			// configured recovery actions.
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

// installService registers an automatic service with failure recovery. Existing
// registrations are stopped and updated to this executable and its arguments.
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
	// The event source may exist from an earlier installation.
	_ = eventlog.InstallAsEventCreate(serviceName, eventlog.Error|eventlog.Warning|eventlog.Info)
	restart := mgr.RecoveryAction{Type: mgr.ServiceRestart, Delay: 2 * time.Second}
	if err := s.SetRecoveryActions([]mgr.RecoveryAction{restart, restart, restart}, uint32((24 * time.Hour).Seconds())); err != nil {
		return err
	}
	// Enable recovery for error exits as well as crashes.
	if err := s.SetRecoveryActionsOnNonCrashFailures(true); err != nil {
		return err
	}
	return s.Start()
}

// uninstallService stops and removes the service. It succeeds if no service is
// registered.
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
	_ = eventlog.Remove(serviceName)
	return s.Delete()
}

// stopService requests a stop and waits within the core's system-restoration
// budget.
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
