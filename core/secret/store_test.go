package secret

import (
	"bytes"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"testing"

	"github.com/levvs-one/sora-client/core/errs"
)

// testProtector keeps the wrapped key in memory so a test never depends on the
// platform key store. The file layout, the atomic write and the AEAD are the
// same code paths the real store uses.
type testProtector struct {
	mu    sync.Mutex
	blobs map[string][]byte
	calls int
}

func newTestProtector() *testProtector {
	return &testProtector{blobs: make(map[string][]byte)}
}

func (p *testProtector) Name() string { return "test" }

func (p *testProtector) Protect(key []byte) ([]byte, error) {
	p.mu.Lock()
	defer p.mu.Unlock()
	p.calls++
	wrapped := append([]byte("wrapped:"), key...)
	p.blobs[string(wrapped)] = append([]byte(nil), key...)
	return wrapped, nil
}

func (p *testProtector) Unprotect(wrapped []byte) ([]byte, error) {
	p.mu.Lock()
	defer p.mu.Unlock()
	key, ok := p.blobs[string(wrapped)]
	if !ok {
		return nil, errs.Newf(errs.CodeInternal, errs.KeySecretStoreCorrupt, "test protector has no such blob")
	}
	return append([]byte(nil), key...), nil
}

// failingWrite makes every file replacement fail, so a test can check what the
// store does when the disk stops cooperating.
func failingWrite(string, []byte, os.FileMode) error {
	return errs.Newf(errs.CodeInternal, errs.KeySecretStoreUnavailable, "test: the disk is full")
}

func openTestStore(t *testing.T) (*Store, *testProtector, string) {
	t.Helper()
	dir := t.TempDir()
	prot := newTestProtector()
	store, err := Open(dir, Options{Protector: prot})
	if err != nil {
		t.Fatalf("Open() error = %v", err)
	}
	t.Cleanup(func() { _ = store.Close() })
	return store, prot, dir
}

func TestPutGetDeleteRoundTrip(t *testing.T) {
	store, _, _ := openTestStore(t)

	if err := store.Put("s1_abc", []byte("password-value")); err != nil {
		t.Fatalf("Put() error = %v", err)
	}
	got, err := store.Get("s1_abc")
	if err != nil {
		t.Fatalf("Get() error = %v", err)
	}
	if string(got) != "password-value" {
		t.Errorf("Get() = %q, want %q", got, "password-value")
	}
	got[0] = 'X'
	again, err := store.Get("s1_abc")
	if err != nil {
		t.Fatalf("Get() after mutation error = %v", err)
	}
	if string(again) != "password-value" {
		t.Error("Get handed out the stored slice instead of a copy")
	}

	if err := store.Put("s1_abc", []byte("second-value")); err != nil {
		t.Fatalf("Put() replace error = %v", err)
	}
	replaced, err := store.Get("s1_abc")
	if err != nil {
		t.Fatalf("Get() after replace error = %v", err)
	}
	if string(replaced) != "second-value" {
		t.Errorf("after replace Get() = %q", replaced)
	}
	if store.Len() != 1 || !store.Has("s1_abc") {
		t.Errorf("store holds %d secrets, Has = %v", store.Len(), store.Has("s1_abc"))
	}

	if err := store.Delete("s1_abc"); err != nil {
		t.Fatalf("Delete() error = %v", err)
	}
	if _, err := store.Get("s1_abc"); errs.CodeOf(err) != errs.CodeNotFound {
		t.Errorf("Get after Delete error = %v, code = %q", err, errs.CodeOf(err))
	}
	if err := store.Delete("s1_abc"); err != nil {
		t.Errorf("deleting twice must succeed, got %v", err)
	}
}

func TestSecretsSurviveReopen(t *testing.T) {
	dir := t.TempDir()
	prot := newTestProtector()

	first, err := Open(dir, Options{Protector: prot})
	if err != nil {
		t.Fatalf("Open() error = %v", err)
	}
	for i, reference := range []string{"s1_one", "s1_two", "s1_three"} {
		if err := first.Put(reference, []byte{byte('a' + i), byte('0' + i)}); err != nil {
			t.Fatalf("Put(%q) error = %v", reference, err)
		}
	}
	if err := first.Close(); err != nil {
		t.Fatalf("Close() error = %v", err)
	}

	second, err := Open(dir, Options{Protector: prot})
	if err != nil {
		t.Fatalf("reopen error = %v", err)
	}
	defer func() { _ = second.Close() }()
	refs := second.Refs()
	if len(refs) != 3 || refs[0] != "s1_one" || refs[1] != "s1_three" || refs[2] != "s1_two" {
		t.Fatalf("Refs() = %v, want sorted s1_one s1_three s1_two", refs)
	}
	for i, reference := range []string{"s1_one", "s1_two", "s1_three"} {
		got, err := second.Get(reference)
		if err != nil {
			t.Fatalf("Get(%q) after reopen error = %v", reference, err)
		}
		if !bytes.Equal(got, []byte{byte('a' + i), byte('0' + i)}) {
			t.Errorf("Get(%q) = %q after reopen", reference, got)
		}
	}
}

func TestReferenceValidation(t *testing.T) {
	valid := []string{"a", "s1_0123456789abcdef", "A-Z_0-9", strings.Repeat("r", MaxReferenceLen)}
	for _, reference := range valid {
		if err := ValidateReference(reference); err != nil {
			t.Errorf("ValidateReference(%q) = %v, want nil", reference, err)
		}
	}
	invalid := []string{
		"",
		strings.Repeat("r", MaxReferenceLen+1),
		"s1 has space",
		"../escape",
		"s1/slash",
		"s1.dot",
		"s1:colon",
		"s1\nnewline",
		"s1\x00nul",
		"s1юникод",
	}
	for _, reference := range invalid {
		err := ValidateReference(reference)
		if errs.CodeOf(err) != errs.CodeInvalidArgument {
			t.Errorf("ValidateReference(%q) = %v, want an invalid argument error", reference, err)
		}
		if errs.KeyOf(err) != errs.KeySecretReferenceInvalid {
			t.Errorf("ValidateReference(%q) key = %q", reference, errs.KeyOf(err))
		}
	}
}

func TestStoreRejectsBadInput(t *testing.T) {
	store, _, _ := openTestStore(t)

	if err := store.Put("bad reference", []byte("x")); errs.CodeOf(err) != errs.CodeInvalidArgument {
		t.Errorf("Put with a bad reference = %v", err)
	}
	if err := store.Put("s1_empty", nil); errs.CodeOf(err) != errs.CodeInvalidArgument {
		t.Errorf("Put with no material = %v", err)
	}
	oversized := bytes.Repeat([]byte("x"), MaxSecretBytes+1)
	if err := store.Put("s1_big", oversized); errs.KeyOf(err) != errs.KeySecretTooLarge {
		t.Errorf("Put oversized = %v", err)
	}
	if store.Has("bad reference") {
		t.Error("Has accepted a reference the store would reject")
	}
	if _, err := store.Get("bad reference"); errs.CodeOf(err) != errs.CodeInvalidArgument {
		t.Errorf("Get with a bad reference = %v", err)
	}
	if err := store.Delete("bad reference"); errs.CodeOf(err) != errs.CodeInvalidArgument {
		t.Errorf("Delete with a bad reference = %v", err)
	}
	if store.Len() != 0 {
		t.Errorf("a rejected Put changed the store: %d entries", store.Len())
	}
}

func TestStoreKeepsFileAndMemoryInStep(t *testing.T) {
	dir := t.TempDir()
	prot := newTestProtector()
	store, err := Open(dir, Options{Protector: prot})
	if err != nil {
		t.Fatalf("Open() error = %v", err)
	}
	defer func() { _ = store.Close() }()
	if err := store.Put("s1_keep", []byte("kept")); err != nil {
		t.Fatalf("Put() error = %v", err)
	}
	store.writeFile = failingWrite
	if err := store.Put("s1_drop", []byte("dropped")); errs.KeyOf(err) != errs.KeySecretStoreUnavailable {
		t.Fatalf("Put with a failing disk = %v, want a store error", err)
	}
	if store.Has("s1_drop") {
		t.Error("a failed write left the new secret in memory")
	}
	if err := store.Delete("s1_keep"); errs.KeyOf(err) != errs.KeySecretStoreUnavailable {
		t.Fatalf("Delete with a failing disk = %v, want a store error", err)
	}
	if !store.Has("s1_keep") {
		t.Error("a failed delete dropped the secret from memory")
	}
	store.writeFile = writeFileAtomic
	if err := store.Close(); err != nil {
		t.Fatalf("Close() error = %v", err)
	}
	reopened, err := Open(dir, Options{Protector: prot})
	if err != nil {
		t.Fatalf("reopen error = %v", err)
	}
	defer func() { _ = reopened.Close() }()
	if got := reopened.Refs(); len(got) != 1 || got[0] != "s1_keep" {
		t.Errorf("after a failed write and delete the vault holds %v, want [s1_keep]", got)
	}
	material, err := reopened.Get("s1_keep")
	if err != nil {
		t.Fatalf("Get after reopen error = %v", err)
	}
	if string(material) != "kept" {
		t.Errorf("material after reopen = %q, want %q", material, "kept")
	}
}

func TestCorruptVaultIsRefused(t *testing.T) {
	dir := t.TempDir()
	prot := newTestProtector()
	store, err := Open(dir, Options{Protector: prot})
	if err != nil {
		t.Fatalf("Open() error = %v", err)
	}
	if err := store.Put("s1_value", []byte("material")); err != nil {
		t.Fatalf("Put() error = %v", err)
	}
	if err := store.Close(); err != nil {
		t.Fatalf("Close() error = %v", err)
	}
	path := filepath.Join(dir, vaultFile)

	raw, err := os.ReadFile(path)
	if err != nil {
		t.Fatalf("reading the vault: %v", err)
	}
	flipped := append([]byte(nil), raw...)
	flipped[len(flipped)-1] ^= 0xff
	if err := os.WriteFile(path, flipped, fileMode); err != nil {
		t.Fatalf("writing the vault: %v", err)
	}
	if _, err := Open(dir, Options{Protector: prot}); errs.KeyOf(err) != errs.KeySecretStoreCorrupt {
		t.Errorf("a flipped bit gives %v, key = %q", err, errs.KeyOf(err))
	}

	if err := os.WriteFile(path, []byte("not a vault at all"), fileMode); err != nil {
		t.Fatalf("writing the vault: %v", err)
	}
	if _, err := Open(dir, Options{Protector: prot}); errs.KeyOf(err) != errs.KeySecretStoreCorrupt {
		t.Errorf("a short file gives %v, key = %q", err, errs.KeyOf(err))
	}

	if err := os.WriteFile(path, append([]byte("SORAVLT\x02"), raw[8:]...), fileMode); err != nil {
		t.Fatalf("writing the vault: %v", err)
	}
	if _, err := Open(dir, Options{Protector: prot}); errs.KeyOf(err) != errs.KeySecretStoreCorrupt {
		t.Errorf("an unknown format version gives %v, key = %q", err, errs.KeyOf(err))
	}
}

func TestVaultCannotBeCombinedWithAForeignKeyOrID(t *testing.T) {
	firstDir, secondDir := t.TempDir(), t.TempDir()
	prot := newTestProtector()

	first, err := Open(firstDir, Options{Protector: prot})
	if err != nil {
		t.Fatalf("Open() error = %v", err)
	}
	if err := first.Put("s1_value", []byte("material")); err != nil {
		t.Fatalf("Put() error = %v", err)
	}
	if err := first.Close(); err != nil {
		t.Fatalf("Close() error = %v", err)
	}
	second, err := Open(secondDir, Options{Protector: prot})
	if err != nil {
		t.Fatalf("Open() error = %v", err)
	}
	if err := second.Put("s1_other", []byte("other material")); err != nil {
		t.Fatalf("Put() error = %v", err)
	}
	if err := second.Close(); err != nil {
		t.Fatalf("Close() error = %v", err)
	}

	// The second vault was sealed with the second key and the second identifier.
	// Bringing the first store key and identifier next to it must fail: the
	// identifier is bound into the ciphertext as additional data.
	copyStoreFiles(t, secondDir, firstDir, masterFile, idFile)
	if _, err := Open(secondDir, Options{Protector: prot}); errs.KeyOf(err) != errs.KeySecretStoreCorrupt {
		t.Errorf("a vault with a foreign key and identifier gives %v, key = %q", err, errs.KeyOf(err))
	}

	// Moving a whole store is a backup, not an attack: key, identifier and vault
	// travel together and the store must open.
	moved := t.TempDir()
	copyStoreFiles(t, moved, firstDir, masterFile, idFile, vaultFile)
	reopened, err := Open(moved, Options{Protector: prot})
	if err != nil {
		t.Fatalf("a complete directory must open, got %v", err)
	}
	defer func() { _ = reopened.Close() }()
	if got, err := reopened.Get("s1_value"); err != nil || string(got) != "material" {
		t.Errorf("after moving the whole store Get() = %q, err = %v", got, err)
	}
}

// copyStoreFiles copies the named files of one store directory into another.
func copyStoreFiles(t *testing.T, to, from string, names ...string) {
	t.Helper()
	for _, name := range names {
		raw, err := os.ReadFile(filepath.Join(from, name))
		if err != nil {
			t.Fatalf("reading %s: %v", name, err)
		}
		if err := os.WriteFile(filepath.Join(to, name), raw, fileMode); err != nil {
			t.Fatalf("writing %s: %v", name, err)
		}
	}
}

func TestClosedStoreRefusesWork(t *testing.T) {
	store, _, _ := openTestStore(t)
	if err := store.Put("s1_value", []byte("material")); err != nil {
		t.Fatalf("Put() error = %v", err)
	}
	if err := store.Close(); err != nil {
		t.Fatalf("Close() error = %v", err)
	}
	if err := store.Put("s1_other", []byte("material")); errs.KeyOf(err) != errs.KeySecretStoreUnavailable {
		t.Errorf("Put after Close = %v", err)
	}
	if _, err := store.Get("s1_value"); errs.KeyOf(err) != errs.KeySecretStoreUnavailable {
		t.Errorf("Get after Close = %v", err)
	}
	if err := store.Delete("s1_value"); errs.KeyOf(err) != errs.KeySecretStoreUnavailable {
		t.Errorf("Delete after Close = %v", err)
	}
	if err := store.Close(); err != nil {
		t.Errorf("closing twice = %v", err)
	}
	if refs := store.Refs(); len(refs) != 0 {
		t.Errorf("Refs after Close = %v, want empty", refs)
	}
}

func TestOpenRejectsUnusableOptions(t *testing.T) {
	if _, err := Open("  ", Options{Protector: newTestProtector()}); errs.CodeOf(err) != errs.CodeInvalidArgument {
		t.Errorf("Open with an empty directory = %v", err)
	}
	if _, err := Open(t.TempDir(), Options{}); errs.KeyOf(err) != errs.KeySecretStoreUnavailable {
		t.Errorf("Open without a protector = %v", err)
	}
}

func TestNewReferenceIsUniqueAndValid(t *testing.T) {
	seen := make(map[string]struct{}, 128)
	for i := 0; i < 128; i++ {
		reference, err := NewReference()
		if err != nil {
			t.Fatalf("NewReference() error = %v", err)
		}
		if err := ValidateReference(reference); err != nil {
			t.Fatalf("NewReference() produced %q, which fails validation: %v", reference, err)
		}
		if !strings.HasPrefix(reference, "s1_") {
			t.Errorf("reference %q has no version prefix", reference)
		}
		if _, dup := seen[reference]; dup {
			t.Fatalf("NewReference() repeated %q", reference)
		}
		seen[reference] = struct{}{}
	}
}

func TestConcurrentUseKeepsTheVaultConsistent(t *testing.T) {
	dir := t.TempDir()
	prot := newTestProtector()
	store, err := Open(dir, Options{Protector: prot})
	if err != nil {
		t.Fatalf("Open() error = %v", err)
	}
	const writers = 8
	results := make(chan error, writers)
	start := make(chan struct{})
	for i := 0; i < writers; i++ {
		go func(i int) {
			<-start
			results <- store.Put("s1_"+strings.Repeat("a", i+1), bytes.Repeat([]byte{byte('a' + i%26)}, 32))
		}(i)
	}
	close(start)
	for i := 0; i < writers; i++ {
		if err := <-results; err != nil {
			t.Fatalf("concurrent Put error = %v", err)
		}
	}
	if err := store.Close(); err != nil {
		t.Fatalf("Close() error = %v", err)
	}
	reopened, err := Open(dir, Options{Protector: prot})
	if err != nil {
		t.Fatalf("reopen error = %v", err)
	}
	defer func() { _ = reopened.Close() }()
	if got := reopened.Refs(); len(got) != writers {
		t.Errorf("after %d concurrent writes the vault holds %d secrets", writers, len(got))
	}
}

func TestVaultIsEncryptedOnDisk(t *testing.T) {
	store, _, dir := openTestStore(t)
	const material = "very-recognisable-secret-value"
	if err := store.Put("s1_plain", []byte(material)); err != nil {
		t.Fatalf("Put() error = %v", err)
	}
	raw, err := os.ReadFile(filepath.Join(dir, vaultFile))
	if err != nil {
		t.Fatalf("reading the vault: %v", err)
	}
	if bytes.Contains(raw, []byte(material)) {
		t.Error("the vault file contains the secret in the clear")
	}
	if !bytes.HasPrefix(raw, vaultHeader) {
		t.Error("the vault file does not start with the format header")
	}
	if bytes.Contains(raw, []byte("s1_plain")) {
		t.Error("the vault file leaks reference names in the clear")
	}
}

func TestApplyIsAllOrNothing(t *testing.T) {
	store, err := Open(t.TempDir(), Options{Protector: FileProtector{}})
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = store.Close() }()
	if err := store.Put("keep", []byte("kept")); err != nil {
		t.Fatal(err)
	}
	if err := store.Put("old", []byte("old")); err != nil {
		t.Fatal(err)
	}
	if err := store.Apply(map[string][]byte{"new_a": []byte("a"), "new_b": []byte("b")}, []string{"old"}); err != nil {
		t.Fatal(err)
	}
	if store.Has("old") || !store.Has("new_a") || !store.Has("new_b") || !store.Has("keep") {
		t.Fatalf("refs = %v", store.Refs())
	}
	if got, _ := store.Get("keep"); string(got) != "kept" {
		t.Fatalf("an untouched value was damaged: %q", got)
	}
	// A change that breaks a limit leaves everything as it was.
	err = store.Apply(map[string][]byte{"fine": []byte("x"), "bad ref!": []byte("y")}, []string{"keep"})
	if err == nil || store.Has("fine") || !store.Has("keep") {
		t.Fatalf("a refused change must not apply in part: %v, refs %v", err, store.Refs())
	}
	reopened, err := Open(store.dir, Options{Protector: FileProtector{}})
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = reopened.Close() }()
	if got, _ := reopened.Get("new_b"); string(got) != "b" || reopened.Has("old") {
		t.Fatalf("the change did not reach the disk: refs %v", reopened.Refs())
	}
}
