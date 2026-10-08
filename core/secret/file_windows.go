//go:build windows

package secret

import "os"

// platformProtector returns the mechanism this platform uses for the master
// key.
func platformProtector() Protector { return DPAPIProtector{} }

// hardenFile relies on the installer's private data-directory DACL inherited by
// files.
func hardenFile(*os.File, os.FileMode) error { return nil }

// syncDir does nothing on Windows because directory handles cannot be flushed.
// Rename stays atomic, but directory metadata may lag after power loss.
func syncDir(string) error { return nil }
