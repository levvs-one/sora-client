//go:build windows

package secret

import (
	"unsafe"

	"golang.org/x/sys/windows"

	"github.com/levvs-one/sora-client/core/errs"
)

// DPAPIProtector binds the master key to the core account, not machine-wide
// scope; CRYPTPROTECT_LOCAL_MACHINE is unset. Other accounts or machines cannot
// unwrap it, and the UI needs only references.
type DPAPIProtector struct{}

// Name identifies the mechanism in diagnostics.
func (DPAPIProtector) Name() string { return "dpapi" }

// entropy is public application-binding data required to unwrap the blob. It
// prevents unwrapping a copied file without the same value.
var entropy = []byte("sora.secret.v1")

// Protect wraps the key with user-scope DPAPI. UI_FORBIDDEN prevents dialogs in
// the service context.
func (DPAPIProtector) Protect(key []byte) ([]byte, error) {
	if len(key) == 0 {
		return nil, errs.Newf(errs.CodeInternal, errs.KeySecretStoreUnavailable,
			"secret store: refusing to protect an empty key")
	}
	var out windows.DataBlob
	if err := windows.CryptProtectData(blob(key), nil, blob(entropy), 0, nil,
		windows.CRYPTPROTECT_UI_FORBIDDEN, &out); err != nil {
		return nil, errs.Newf(errs.CodeInternal, errs.KeySecretStoreUnavailable,
			"secret store: the operating system refused to protect the key: %v", err)
	}
	return takeBlob(&out), nil
}

// Unprotect recovers a master key from its DPAPI form.
func (DPAPIProtector) Unprotect(wrapped []byte) ([]byte, error) {
	if len(wrapped) == 0 {
		return nil, errs.Newf(errs.CodeInternal, errs.KeySecretStoreCorrupt,
			"secret store: the protected key is empty")
	}
	var out windows.DataBlob
	if err := windows.CryptUnprotectData(blob(wrapped), nil, blob(entropy), 0, nil,
		windows.CRYPTPROTECT_UI_FORBIDDEN, &out); err != nil {
		// Use one failure for wrong account, machine, or entropy to
		// avoid exposing which protection check failed.
		return nil, errs.Newf(errs.CodeInternal, errs.KeySecretStoreCorrupt,
			"secret store: the protected key could not be unwrapped by this account")
	}
	return takeBlob(&out), nil
}

// blob references the caller's buffer; DPAPI reads it without retaining it.
func blob(b []byte) *windows.DataBlob {
	return &windows.DataBlob{Size: uint32(len(b)), Data: &b[0]} //nolint:gosec // a key or its wrapped form is far below 4 GiB
}

// takeBlob copies OS-allocated data, wipes the original key material, and frees
// the allocation.
func takeBlob(b *windows.DataBlob) []byte {
	if b.Size == 0 || b.Data == nil {
		return nil
	}
	system := unsafe.Slice(b.Data, int(b.Size))
	out := append([]byte(nil), system...)
	clear(system)
	_, _ = windows.LocalFree(windows.Handle(unsafe.Pointer(b.Data)))
	b.Data, b.Size = nil, 0
	return out
}
