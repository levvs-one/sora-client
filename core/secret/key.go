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

// Protector wraps master keys using account-bound Windows DPAPI or owner-only
// files elsewhere. Hosts and tests can supply an alternative mechanism.
type Protector interface {
	// Protect wraps a master key for storage.
	Protect(key []byte) ([]byte, error)
	// Unprotect recovers a master key from its stored form.
	Unprotect(wrapped []byte) ([]byte, error)
	// Name identifies the mechanism in diagnostics, for example "dpapi" or
	// "file". It never contains a path or an account name.
	Name() string
}

// FileProtector uses owner-only key storage without requiring a desktop
// session.
type FileProtector struct{}

// Protect stores the key with owner-only permissions.
func (FileProtector) Protect(key []byte) ([]byte, error) { return append([]byte(nil), key...), nil }

// Unprotect copies the key; the owning store checks file permissions.
func (FileProtector) Unprotect(wrapped []byte) ([]byte, error) {
	return append([]byte(nil), wrapped...), nil
}

// Name identifies the mechanism in diagnostics.
func (FileProtector) Name() string { return "file" }

// DefaultProtector returns the protector the current platform uses.
func DefaultProtector() Protector { return platformProtector() }

// loadOrCreateKey loads or creates the master key and public store ID. The ID
// binds the vault to its store and prevents mixing keys and vaults from
// different stores.
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

// NewReference generates opaque references for core-imported material. Clients
// cannot choose imported references or inject store paths.
func NewReference() (string, error) {
	var buf [16]byte
	if _, err := rand.Read(buf[:]); err != nil {
		return "", errs.Wrap(err, errs.CodeInternal, errs.KeySecretStoreUnavailable)
	}
	return "s1_" + hex.EncodeToString(buf[:]), nil
}
