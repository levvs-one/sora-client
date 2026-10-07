//go:build windows

package main

import (
	"context"

	"golang.org/x/sys/windows/svc"
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
