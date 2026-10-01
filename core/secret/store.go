// Package secret stores the credential material of a session.
//
// The control plane never carries a secret. A plan holds a reference, the core
// resolves it here, and the interface never learns the value. That split is
// the reason this package exists: an unprivileged interface that can start a
// tunnel should not be able to read every password the user owns, and a
// diagnostic archive that quotes no secrets can still be attached to a bug
// report.
//
// The store is one encrypted file plus one wrapped master key. The file is
// AES-256-GCM with a fresh nonce per write, and the wrapped key is handed to
// the operating system on Windows and kept in a file only the owner may read
// elsewhere. The plaintext of the payload is a JSON map from reference to
// material, so the file stays inspectable in structure and opaque in content.
//
// Every write is atomic: the new file is written next to the old one, flushed,
// and renamed over it. A crash therefore leaves either the previous state or
// the new one, never a half-written vault.
package secret

import (
	"crypto/aes"
	"crypto/cipher"
	"crypto/rand"
	"crypto/subtle"
	"encoding/json"
	"errors"
	"io"
	"io/fs"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"sync"
	"time"

	"github.com/levvs-one/sora-client/core/errs"
)

// Limits of one store. They exist so a hostile or broken caller cannot turn
// the store into an unbounded file or an unbounded allocation.
const (
	// MaxSecretBytes is the largest single secret the store accepts.
	MaxSecretBytes = 64 << 10
	// MaxSecrets is the largest number of references one store holds.
	MaxSecrets = 4096
	// MaxVaultBytes is the largest encrypted file the store writes.
	MaxVaultBytes = 8 << 20
	// MaxReferenceLen bounds a reference so a caller cannot use it to make the
	// file large through its keys alone.
	MaxReferenceLen = 64
)

// File names inside the data directory. They are fixed: the core finds its
// state by convention, and a caller that could choose the names could point the
// store at something else.
const (
	vaultFile  = "secrets.vault"
	masterFile = "master.key"
	idFile     = "store.id"
	dirMode    = 0o700
	fileMode   = 0o600
)

// aadPrefix binds a ciphertext to this format version, so a file written by a
// future version cannot be decrypted by an older core even if the key matches.
const aadPrefix = "sora.secret.v1"

// Store is the encrypted credential store of one core process. It is safe for
// concurrent use; writes are serialized, reads take a read lock.
type Store struct {
	mu     sync.RWMutex
	dir    string
	prot   Protector
	key    []byte
	id     []byte
	items  map[string][]byte
	closed bool
	// writeFile replaces a file atomically. It is a field so a test can make a
	// write fail and check that memory and disk never drift apart; production
	// always uses writeFileAtomic.
	writeFile func(path string, data []byte, mode os.FileMode) error
}

// Options configures how a store is opened. The zero value is not useful:
// Protector is required, because how the master key is protected is a decision
// of the platform and not something a store may guess.
type Options struct {
	// Protector wraps the master key before it touches the disk.
	Protector Protector
	// Now supplies timestamps for the file header. Tests replace it; the zero
	// value means time.Now.
	Now func() time.Time
}

// Open loads the store in dir, creating the directory, the master key and an
// empty vault when they are not there yet.
func Open(dir string, opts Options) (*Store, error) {
	if strings.TrimSpace(dir) == "" {
		return nil, errs.Newf(errs.CodeInvalidArgument, errs.KeySecretStoreUnavailable,
			"secret store: empty directory")
	}
	if opts.Protector == nil {
		return nil, errs.Newf(errs.CodeInternal, errs.KeySecretStoreUnavailable,
			"secret store: no key protector")
	}
	if opts.Now == nil {
		opts.Now = time.Now
	}
	if err := os.MkdirAll(dir, dirMode); err != nil {
		return nil, errs.Wrap(err, errs.CodeInternal, errs.KeySecretStoreUnavailable)
	}
	key, id, err := loadOrCreateKey(dir, opts.Protector)
	if err != nil {
		return nil, err
	}
	s := &Store{
		dir:       dir,
		prot:      opts.Protector,
		key:       key,
		id:        id,
		items:     make(map[string][]byte),
		writeFile: writeFileAtomic,
	}
	if err := s.read(); err != nil {
		wipe(key)
		return nil, err
	}
	return s, nil
}

// Put stores material under a reference and replaces whatever was there. The
// caller keeps ownership of the slice it passes: the store copies it and wipes
// its own copy when the value is replaced or deleted.
func (s *Store) Put(reference string, material []byte) error {
	if err := ValidateReference(reference); err != nil {
		return err
	}
	if len(material) == 0 {
		return errs.Newf(errs.CodeInvalidArgument, errs.KeySecretReferenceInvalid,
			"secret store: reference %q has empty material", reference)
	}
	if len(material) > MaxSecretBytes {
		return errs.Newf(errs.CodeResourceExhausted, errs.KeySecretTooLarge,
			"secret store: reference %q holds %d bytes, the limit is %d",
			reference, len(material), MaxSecretBytes)
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.closed {
		return errs.Newf(errs.CodeInternal, errs.KeySecretStoreUnavailable, "secret store: closed")
	}
	if _, exists := s.items[reference]; !exists && len(s.items) >= MaxSecrets {
		return errs.Newf(errs.CodeResourceExhausted, errs.KeySecretStoreUnavailable,
			"secret store: already holds %d secrets", MaxSecrets)
	}
	stored := append([]byte(nil), material...)
	previous, had := s.items[reference]
	s.items[reference] = stored
	if err := s.writeLocked(); err != nil {
		// A failed write must not leave the in-memory state ahead of the file,
		// or the running session would use a secret the next start cannot read.
		if had {
			s.items[reference] = previous
		} else {
			delete(s.items, reference)
		}
		wipe(stored)
		return err
	}
	if had {
		wipe(previous)
	}
	return nil
}

// Get returns a copy of the material stored under a reference.
func (s *Store) Get(reference string) ([]byte, error) {
	if err := ValidateReference(reference); err != nil {
		return nil, err
	}
	s.mu.RLock()
	defer s.mu.RUnlock()
	if s.closed {
		return nil, errs.Newf(errs.CodeInternal, errs.KeySecretStoreUnavailable, "secret store: closed")
	}
	stored, ok := s.items[reference]
	if !ok {
		return nil, errs.Newf(errs.CodeNotFound, errs.KeySecretNotFound,
			"secret store: no secret under that reference")
	}
	return append([]byte(nil), stored...), nil
}

// Delete removes a reference and wipes the material it held. Deleting a
// reference that is not there succeeds, so a cleanup path can run twice.
func (s *Store) Delete(reference string) error {
	if err := ValidateReference(reference); err != nil {
		return err
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.closed {
		return errs.Newf(errs.CodeInternal, errs.KeySecretStoreUnavailable, "secret store: closed")
	}
	previous, had := s.items[reference]
	if !had {
		return nil
	}
	delete(s.items, reference)
	if err := s.writeLocked(); err != nil {
		s.items[reference] = previous
		return err
	}
	wipe(previous)
	return nil
}

// Has reports whether a reference is stored, without copying the material.
func (s *Store) Has(reference string) bool {
	if ValidateReference(reference) != nil {
		return false
	}
	s.mu.RLock()
	defer s.mu.RUnlock()
	_, ok := s.items[reference]
	return ok
}

// Refs returns every stored reference in sorted order. Diagnostics and tests
// use it to compare the store with the plan; nothing else needs the list, and
// the interface never receives it.
func (s *Store) Refs() []string {
	s.mu.RLock()
	defer s.mu.RUnlock()
	out := make([]string, 0, len(s.items))
	for reference := range s.items {
		out = append(out, reference)
	}
	sort.Strings(out)
	return out
}

// Len reports how many secrets the store holds.
func (s *Store) Len() int {
	s.mu.RLock()
	defer s.mu.RUnlock()
	return len(s.items)
}

// Close wipes the key material in memory. The file stays on disk: the next
// start of the core needs it, and it is encrypted at rest.
func (s *Store) Close() error {
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.closed {
		return nil
	}
	s.closed = true
	wipe(s.key)
	wipe(s.id)
	for reference, material := range s.items {
		wipe(material)
		delete(s.items, reference)
	}
	return nil
}

// readLocked loads the vault, treating a missing file as an empty store.
func (s *Store) read() error {
	s.mu.Lock()
	defer s.mu.Unlock()
	raw, err := os.ReadFile(filepath.Join(s.dir, vaultFile))
	if err != nil {
		if errors.Is(err, fs.ErrNotExist) {
			return nil
		}
		return errs.Wrap(err, errs.CodeInternal, errs.KeySecretStoreUnavailable)
	}
	items, err := s.unseal(raw)
	if err != nil {
		return err
	}
	s.items = items
	return nil
}

// writeLocked seals the current state and replaces the vault atomically.
func (s *Store) writeLocked() error {
	sealed, err := s.seal(s.items)
	if err != nil {
		return err
	}
	defer wipe(sealed)
	if len(sealed) > MaxVaultBytes {
		return errs.Newf(errs.CodeResourceExhausted, errs.KeySecretTooLarge,
			"secret store: the vault would be %d bytes, the limit is %d", len(sealed), MaxVaultBytes)
	}
	return s.writeFile(filepath.Join(s.dir, vaultFile), sealed, fileMode)
}

// seal encrypts the item map into the on-disk format.
func (s *Store) seal(items map[string][]byte) ([]byte, error) {
	payload, err := json.Marshal(items)
	if err != nil {
		return nil, errs.Wrap(err, errs.CodeInternal, errs.KeySecretStoreUnavailable)
	}
	aead, err := s.aead()
	if err != nil {
		return nil, err
	}
	nonce := make([]byte, aead.NonceSize())
	if _, err := io.ReadFull(rand.Reader, nonce); err != nil {
		return nil, errs.Wrap(err, errs.CodeInternal, errs.KeySecretStoreUnavailable)
	}
	header := s.header(nonce)
	return aead.Seal(header, nonce, payload, s.aad()), nil
}

// unseal decrypts a vault file and returns its items.
func (s *Store) unseal(raw []byte) (map[string][]byte, error) {
	if len(raw) < headerLen+aeadOverhead {
		return nil, errs.Newf(errs.CodeInternal, errs.KeySecretStoreCorrupt,
			"secret store: the vault is too short to hold a header")
	}
	if subtle.ConstantTimeCompare(raw[:len(vaultHeader)], vaultHeader) != 1 {
		return nil, errs.Newf(errs.CodeInternal, errs.KeySecretStoreCorrupt,
			"secret store: the vault has an unknown format")
	}
	nonce := raw[len(vaultHeader):headerLen]
	body := raw[headerLen:]
	aead, err := s.aead()
	if err != nil {
		return nil, err
	}
	plaintext, err := aead.Open(nil, nonce, body, s.aad())
	if err != nil {
		return nil, errs.Newf(errs.CodeInternal, errs.KeySecretStoreCorrupt,
			"secret store: the vault failed its integrity check")
	}
	defer wipe(plaintext)
	items := make(map[string][]byte)
	if err := json.Unmarshal(plaintext, &items); err != nil {
		return nil, errs.Newf(errs.CodeInternal, errs.KeySecretStoreCorrupt,
			"secret store: the vault payload is not a reference map")
	}
	for reference := range items {
		if ValidateReference(reference) != nil {
			return nil, errs.Newf(errs.CodeInternal, errs.KeySecretStoreCorrupt,
				"secret store: the vault holds an invalid reference")
		}
	}
	return items, nil
}

// header builds the plaintext part of a vault file: the magic and the nonce.
func (s *Store) header(nonce []byte) []byte {
	out := make([]byte, 0, headerLen)
	out = append(out, vaultHeader...)
	return append(out, nonce...)
}

// aad is the additional data every seal and open binds. It carries the format
// version and the store identifier, so a ciphertext cannot be opened under a
// different store even when both hold the same master key.
func (s *Store) aad() []byte {
	out := make([]byte, 0, len(aadPrefix)+len(s.id))
	out = append(out, aadPrefix...)
	return append(out, s.id...)
}

// aead builds the cipher for the master key.
func (s *Store) aead() (cipher.AEAD, error) {
	block, err := aes.NewCipher(s.key)
	if err != nil {
		return nil, errs.Wrap(err, errs.CodeInternal, errs.KeySecretStoreUnavailable)
	}
	aead, err := cipher.NewGCM(block)
	if err != nil {
		return nil, errs.Wrap(err, errs.CodeInternal, errs.KeySecretStoreUnavailable)
	}
	return aead, nil
}
