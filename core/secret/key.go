package secret

import (
	"crypto/rand"
	"encoding/hex"
	"errors"
	"io/fs"
	"os"
	"path/filepath"

	"github.com/levvs-one/sora-client/core/errs"
)

// Protector wraps and unwraps the master key. Windows binds the key to the
// user account through DPAPI; every other platform keeps it in a file only the
// owner may read. The interface exists so a host can supply its own mechanism
// and so tests can run without touching the platform.
type Protector interface {
	// Protect wraps a master key for storage.
	Protect(key []byte) ([]byte, error)
	// Unprotect recovers a master key from its stored form.
	Unprotect(wrapped []byte) ([]byte, error)
	// Name identifies the mechanism in diagnostics, for example "dpapi" or
	// "file". It never contains a path or an account name.
	Name() string
}

// FileProtector keeps the wrapped key in a file whose permissions only the owner
// can read. It is the mechanism on platforms with no user key store that the
// core can rely on without a desktop session.
type FileProtector struct{}

// Protect stores the key with owner-only permissions.
func (FileProtector) Protect(key []byte) ([]byte, error) { return append([]byte(nil), key...), nil }

// Unprotect reads the key back. Permissions are checked by the store, which owns
// the file; this protector only copies.
func (FileProtector) Unprotect(wrapped []byte) ([]byte, error) {
	return append([]byte(nil), wrapped...), nil
}

// Name identifies the mechanism in diagnostics.
func (FileProtector) Name() string { return "file" }

// DefaultProtector returns the protector the current platform uses.
func DefaultProtector() Protector { return platformProtector() }

// loadOrCreateKey returns the master key and the store id, creating either of
// them on first start. The id is not secret: it binds a vault to this store, so
// a key and a vault that belong to different stores cannot be combined.
func loadOrCreateKey(dir string, prot Protector) (key, id []byte, err error) {
	id, err = loadOrCreateID(filepath.Join(dir, idFile))
	if err != nil {
		return nil, nil, err
	}
	wrapped, err := readMasterFile(filepath.Join(dir, masterFile))
	switch {
	case err == nil:
		key, err = prot.Unprotect(wrapped)
		if err != nil {
			return nil, nil, err
		}
		if len(key) != keyLen {
			wipe(key)
			return nil, nil, errs.Newf(errs.CodeInternal, errs.KeySecretStoreCorrupt,
				"secret store: the master key is %d bytes, expected %d", len(key), keyLen)
		}
		return key, id, nil
	case !errors.Is(err, fs.ErrNotExist):
		return nil, nil, err
	}
	key = make([]byte, keyLen)
	if _, err := rand.Read(key); err != nil {
		return nil, nil, errs.Wrap(err, errs.CodeInternal, errs.KeySecretStoreUnavailable)
	}
	protected, err := prot.Protect(key)
	if err != nil {
		wipe(key)
		return nil, nil, err
	}
	payload := append([]byte(masterHeader), protected...)
	wipe(protected)
	if err := writeFileAtomic(filepath.Join(dir, masterFile), payload, fileMode); err != nil {
		wipe(key)
		return nil, nil, err
	}
	return key, id, nil
}

// loadOrCreateID reads the store identifier, creating it when the store is new.
func loadOrCreateID(path string) ([]byte, error) {
	//nolint:gosec // the path is the data directory of the core joined with a fixed file name
	raw, err := os.ReadFile(path)
	switch {
	case err == nil:
		if len(raw) != storeIDLen {
			return nil, errs.Newf(errs.CodeInternal, errs.KeySecretStoreCorrupt,
				"secret store: the store id is %d bytes, expected %d", len(raw), storeIDLen)
		}
		return raw, nil
	case !errors.Is(err, fs.ErrNotExist):
		return nil, errs.Wrap(err, errs.CodeInternal, errs.KeySecretStoreUnavailable)
	}
	id := make([]byte, storeIDLen)
	if _, err := rand.Read(id); err != nil {
		return nil, errs.Wrap(err, errs.CodeInternal, errs.KeySecretStoreUnavailable)
	}
	if err := writeFileAtomic(path, id, fileMode); err != nil {
		return nil, err
	}
	return id, nil
}

// readMasterFile reads the wrapped master key and strips the header.
func readMasterFile(path string) ([]byte, error) {
	//nolint:gosec // the path is the data directory of the core joined with a fixed file name
	raw, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}
	if len(raw) < len(masterHeader) || string(raw[:len(masterHeader)]) != masterHeader {
		return nil, errs.Newf(errs.CodeInternal, errs.KeySecretStoreCorrupt,
			"secret store: the master key file has an unknown format")
	}
	return raw[len(masterHeader):], nil
}

// NewReference returns a fresh opaque reference for material the core imported
// on its own, for example the servers of a fetched subscription. The caller of
// the control plane never chooses a reference for imported material, so a
// reference can never address another store or smuggle a path into the vault.
func NewReference() (string, error) {
	var buf [16]byte
	if _, err := rand.Read(buf[:]); err != nil {
		return "", errs.Wrap(err, errs.CodeInternal, errs.KeySecretStoreUnavailable)
	}
	return "s1_" + hex.EncodeToString(buf[:]), nil
}
