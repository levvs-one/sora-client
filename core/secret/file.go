package secret

import (
	"os"
	"path/filepath"

	"github.com/levvs-one/sora-client/core/errs"
)

// writeFileAtomic writes data to path so that a reader either sees the previous
// content or the new content. The temporary file is created in the destination
// directory, because a rename across directories is not atomic and would leave
// a window where the vault does not exist at all.
func writeFileAtomic(path string, data []byte, mode os.FileMode) error {
	dir := filepath.Dir(path)
	tmp, err := os.CreateTemp(dir, filepath.Base(path)+".tmp-*")
	if err != nil {
		return errs.Wrap(err, errs.CodeInternal, errs.KeySecretStoreUnavailable)
	}
	tmpName := tmp.Name()
	defer func() {
		// The rename below usually consumed the file; a failure here means the
		// temporary file is still there, and leaving it behind would put a copy
		// of a secret next to the vault.
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

// wipe overwrites a buffer with zeroes. Go gives no guarantee that the compiler
// keeps such a write, and the collector copies slices around, so this is a best
// effort that shortens the window rather than a promise. It exists because the
// alternative is leaving key material in freed memory of a process that runs
// for weeks.
func wipe(buf []byte) {
	for i := range buf {
		buf[i] = 0
	}
}
