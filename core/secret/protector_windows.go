//go:build windows

package secret

import (
	"unsafe"

	"golang.org/x/sys/windows"

	"github.com/levvs-one/sora-client/core/errs"
)

// DPAPIProtector binds the master key to the account that runs the core through
// the Windows Data Protection API. The key never exists in a form another
// account can unwrap, and a copy of master.key on another machine is worthless.
//
// The account that starts the core owns the vault. On Windows that is the
// service account, so the file is not readable by the interactive user by
// design: the interface never needs the key, it only asks the core to use it.
// Without CRYPTPROTECT_LOCAL_MACHINE the blob is bound to that account, not to
// the machine.
type DPAPIProtector struct{}

// Name identifies the mechanism in diagnostics.
func (DPAPIProtector) Name() string { return "dpapi" }

// entropy binds a protected blob to this application. The value is public by
// design: it stops another program on the machine from unwrapping the key even
// though it obtained a copy of the file, and it costs nothing to keep.
var entropy = []byte("sora.secret.v1")

// Protect wraps the master key with DPAPI in user scope. UI_FORBIDDEN keeps
// the call from ever showing a dialog: a service has no desktop to show it on.
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
		// A blob protected by another account, another machine or an older
		// entropy value lands here. There is nothing to recover and nothing
		// useful to say: naming the cause would tell a caller which of those
		// it was, which is exactly the information a probe wants.
		return nil, errs.Newf(errs.CodeInternal, errs.KeySecretStoreCorrupt,
			"secret store: the protected key could not be unwrapped by this account")
	}
	return takeBlob(&out), nil
}

// blob points a DATA_BLOB at the caller's buffer; the API reads it and does
// not keep it.
func blob(b []byte) *windows.DataBlob {
	return &windows.DataBlob{Size: uint32(len(b)), Data: &b[0]} //nolint:gosec // a key or its wrapped form is far below 4 GiB
}

// takeBlob copies a blob the operating system allocated, wipes the original and
// frees it. Leaving a copy of the master key in a buffer the process no longer
// owns is exactly the kind of leak this package exists to prevent.
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
