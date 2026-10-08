//go:build !windows

package secret

import (
	"os"

	"github.com/levvs-one/sora-client/core/errs"
)

// platformProtector uses an owner-only key file under the service account.
// Desktop keyrings require a session and do not provide stronger same-user
// isolation.
func platformProtector() Protector { return FileProtector{} }

// hardenFile explicitly limits access to the owner because service-manager
// umasks may be permissive.
func hardenFile(file *os.File, mode os.FileMode) error {
	if err := file.Chmod(mode); err != nil {
		return errs.Wrap(err, errs.CodeInternal, errs.KeySecretStoreUnavailable)
	}
	return nil
}

// syncDir flushes rename metadata for power-loss durability. Unsupported
// filesystem sync is tolerated without affecting atomic replacement.
func syncDir(dir string) error {
	handle, err := os.Open(dir) //nolint:gosec // dir is the vault's own directory
	if err != nil {
		return nil //nolint:nilerr // best effort, as documented above
	}
	defer func() { _ = handle.Close() }()
	_ = handle.Sync()
	return nil
}
