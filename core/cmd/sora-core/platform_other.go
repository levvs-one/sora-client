//go:build !windows

package main

import (
	"runtime"

	"github.com/levvs-one/sora-client/core/secret"
)

// platformProtector uses an owner-only key file and directory without a
// session-dependent keychain. Protection depends on the service account's
// security.
func platformProtector() secret.Protector { return secret.FileProtector{} }

// platformName returns the platform name for reports.
func platformName() string { return runtime.GOOS }

// secureDataDir needs no changes: creation uses owner-only permissions and the
// service unit assigns ownership.
func secureDataDir(string) error { return nil }
