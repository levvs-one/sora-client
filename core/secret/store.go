// Package secret stores a reference-to-credential JSON map encrypted with
// AES-256-GCM and a fresh nonce per write. Windows DPAPI or owner-only files
// protect the master key. Clients receive references, not stored values.
// Flushed, atomic replacement preserves either old or new state after crashes.
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

// Store limits bound file size and allocations from untrusted requests.
const (
	// MaxSecretBytes is the largest single secret the store accepts.
	MaxSecretBytes = 64 << 10
	// MaxSecrets is the largest number of references one store holds.
	MaxSecrets = 4096
	// MaxVaultBytes is the largest encrypted file the store writes.
	MaxVaultBytes = 8 << 20
	// MaxReferenceLen bounds key size as well as stored material.
	MaxReferenceLen = 64
)

// Fixed data filenames prevent callers from redirecting the store to arbitrary
// files.
const (
	vaultFile  = "secrets.vault"
	masterFile = "master.key"
	idFile     = "store.id"
	dirMode    = 0o700
	fileMode   = 0o600
)

// aadPrefix binds ciphertext to the format version so older cores reject future
// formats even with matching keys.
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
	// writeFile permits failure injection to verify memory/disk
	// consistency. Production uses writeFileAtomic.
	writeFile func(path string, data []byte, mode os.FileMode) error
}

// Options configures store opening. Protector is required because the platform
// must explicitly choose master-key protection.
type Options struct {
	// Protector wraps the master key before it touches the disk.
	Protector Protector
	// Now supplies file-header timestamps. Nil uses time.Now; tests can
	// override it.
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

// Put replaces material under a reference, copying the caller's slice. The
// store wipes its copy on replacement or deletion.
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
		// Failed writes must preserve memory/disk consistency across
		// restarts.
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

// Delete removes a reference and wipes its material. Missing references succeed
// for repeatable cleanup.
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

// Apply atomically stores puts and removes deletes in one vault write. Failed
// writes apply none of the changes, avoiding partial updates and per-secret
// writes.
func (s *Store) Apply(puts map[string][]byte, deletes []string) error {
	for reference, material := range puts {
		if err := ValidateReference(reference); err != nil {
			return err
		}
		if len(material) == 0 {
			return errs.Newf(errs.CodeInvalidArgument, errs.KeySecretReferenceInvalid,
				"secret store: reference %q has empty material", reference)
		}
		if len(material) > MaxSecretBytes {
			return errs.Newf(errs.CodeResourceExhausted, errs.KeySecretTooLarge,
				"secret store: reference %q holds %d bytes, the limit is %d", reference, len(material), MaxSecretBytes)
		}
	}
	for _, reference := range deletes {
		if err := ValidateReference(reference); err != nil {
			return err
		}
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.closed {
		return errs.Newf(errs.CodeInternal, errs.KeySecretStoreUnavailable, "secret store: closed")
	}
	next := make(map[string][]byte, len(s.items))
	for reference, material := range s.items {
		next[reference] = material
	}
	for _, reference := range deletes {
		delete(next, reference)
	}
	for reference, material := range puts {
		next[reference] = append([]byte(nil), material...)
	}
	if len(next) > MaxSecrets {
		for reference := range puts {
			wipe(next[reference])
		}
		return errs.Newf(errs.CodeResourceExhausted, errs.KeySecretStoreUnavailable,
			"secret store: the change would hold %d secrets, the limit is %d", len(next), MaxSecrets)
	}
	previous := s.items
	s.items = next
	if err := s.writeLocked(); err != nil {
		s.items = previous
		for reference := range puts {
			wipe(next[reference])
		}
		return err
	}
	// Wipe replaced and removed values; unchanged values are shared by both
	// maps.
	for reference, material := range previous {
		if kept, ok := next[reference]; !ok || &kept[0] != &material[0] {
			wipe(material)
		}
	}
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

// Refs returns sorted references for plan/store comparisons in diagnostics and
// tests. The client never receives this list.
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

// Close wipes in-memory keys and retains the encrypted file for the next start.
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

// read loads the vault, treating a missing file as an empty store.
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

// aad binds encryption to the format version and store ID, preventing another
// store from opening ciphertext even with the same master key.
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
