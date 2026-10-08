package secret

import (
	"os"
	"path/filepath"

	"github.com/levvs-one/sora-client/core/errs"
)

// writeFileAtomic replaces content atomically so readers see the old or new
// file. It creates the temporary file beside the destination to keep rename on
// one filesystem.
func writeFileAtomic(path string, data []byte, mode os.FileMode) error {
	dir := filepath.Dir(path)
	tmp, err := os.CreateTemp(dir, filepath.Base(path)+".tmp-*")
	if err != nil {
		return errs.Wrap(err, errs.CodeInternal, errs.KeySecretStoreUnavailable)
	}
	tmpName := tmp.Name()
	defer func() {
		// Remove failed temporary writes so encrypted store data is not
		// left beside the vault.
		_ = os.Remove(tmpName)
	}()
	if err := hardenFile(tmp, mode); err != nil {
		_ = tmp.Close()
		return err
	}
	if _, err := tmp.Write(data); err != nil {
		_ = tmp.Close()
		return errs.Wrap(err, errs.CodeInternal, errs.KeySecretStoreUnavailable)
	}
	if err := tmp.Sync(); err != nil {
		_ = tmp.Close()
		return errs.Wrap(err, errs.CodeInternal, errs.KeySecretStoreUnavailable)
	}
	if err := tmp.Close(); err != nil {
		return errs.Wrap(err, errs.CodeInternal, errs.KeySecretStoreUnavailable)
	}
	if err := os.Rename(tmpName, path); err != nil {
		return errs.Wrap(err, errs.CodeInternal, errs.KeySecretStoreUnavailable)
	}
	return syncDir(dir)
}

// wipe zeroes a buffer as best-effort key cleanup. Go does not guarantee
// erasure or eliminate other memory copies.
func wipe(buf []byte) {
	for i := range buf {
		buf[i] = 0
	}
}
