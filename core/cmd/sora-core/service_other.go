//go:build !windows

package main

import "errors"

// runService reports that no service manager started the core; on Linux the
// core is a plain process under systemd.
func runService([]string) (bool, error) { return false, nil }

var errNotWindows = errors.New("a service is registered on Windows only; on Linux the package installs a systemd unit")

func installService([]string) error { return errNotWindows }

func uninstallService() error { return errNotWindows }
