//go:build !windows

package main

// runService reports that no service manager started the core; on Linux the
// core is a plain process under systemd.
func runService([]string) (bool, error) { return false, nil }
