//go:build !windows

package main

import (
	"runtime"

	"github.com/levvs-one/sora-client/core/secret"
)

// platformProtector wraps the master key of the store with a key file that only
// the owner may read, in a directory that only the owner may enter.
//
// There is no machine key store here that matches the Windows one, and a
// keychain call would make the core depend on a session the service does not
// have. Owner-only files are the honest equivalent: the value is at rest only as
// good as the account the core runs as, which is a property of the installation
// rather than of this file.
func platformProtector() secret.Protector { return secret.FileProtector{} }

// platformName names the platform in a report.
func platformName() string { return runtime.GOOS }
