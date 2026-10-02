//go:build windows

package main

import "github.com/levvs-one/sora-client/core/secret"

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
