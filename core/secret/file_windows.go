//go:build windows

package secret

import "os"

// platformProtector returns the mechanism this platform uses for the master key.
func platformProtector() Protector { return DPAPIProtector{} }

// hardenFile relies on the inherited access list of the data directory. The
// directory is created with a private DACL by the service installer, so a file
// inside it inherits an owner-only list and needs no further work here.
func hardenFile(*os.File) error { return nil }

// syncDir is a no-op on Windows, where a directory handle cannot be flushed. The
// rename is still atomic, so a crash leaves either the old file or the new one;
// only the directory entry itself may lag behind on a power loss.
func syncDir(string) error { return nil }
