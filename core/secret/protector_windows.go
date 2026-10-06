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
type DPAPIProtector struct{}

// Name identifies the mechanism in diagnostics.
func (DPAPIProtector) Name() string { return "dpapi" }

// cryptProtectUIForbidden keeps the call from ever showing a dialog. A
// privileged service has no desktop, and a prompt would hang the service.
const cryptProtectUIForbidden = 0x1

// entropy binds a protected blob to this application. The value is public by
// design: it stops another program on the machine from unwrapping the key even
// though it obtained a copy of the file, and it costs nothing to keep.
const entropy = "sora.secret.v1"

// dataBlob is the DATA_BLOB structure of the Windows cryptography API.
type dataBlob struct {
	size uint32
	data *byte
}

var (
	crypt32                = windows.NewLazySystemDLL("crypt32.dll")
	kernel32               = windows.NewLazySystemDLL("kernel32.dll")
	procCryptProtectData   = crypt32.NewProc("CryptProtectData")
	procCryptUnprotectData = crypt32.NewProc("CryptUnprotectData")
	procRtlZeroMemory      = kernel32.NewProc("RtlZeroMemory")
	procLocalFree          = kernel32.NewProc("LocalFree")
	// cryptProtectUserScope binds the blob to the calling account rather than
	// to the machine, so copying the file to another account is not enough.
	cryptProtectUserScope = 0x1
)

// Protect wraps the master key with DPAPI in user scope.
func (DPAPIProtector) Protect(key []byte) ([]byte, error) {
	if len(key) == 0 {
		return nil, errs.Newf(errs.CodeInternal, errs.KeySecretStoreUnavailable,
			"secret store: refusing to protect an empty key")
	}
	entropyPtr, err := windows.UTF16PtrFromString(entropy)
	if err != nil {
		return nil, errs.Wrap(err, errs.CodeInternal, errs.KeySecretStoreUnavailable)
	}
	in := dataBlob{size: uint32(len(key)), data: &key[0]} //nolint:gosec // the API takes a pointer to the caller's buffer and does not keep it
	var out dataBlob
	status, _, _ := procCryptProtectData.Call(
		uintptr(unsafe.Pointer(&in)),
		0,
		uintptr(unsafe.Pointer(entropyPtr)),
		0, 0,
		uintptr(cryptProtectUIForbidden|cryptProtectUserScope),
		uintptr(unsafe.Pointer(&out)),
	)
	if status == 0 {
		return nil, errs.Newf(errs.CodeInternal, errs.KeySecretStoreUnavailable,
			"secret store: the operating system refused to protect the key")
	}
	return takeBlob(&out), nil
}

// Unprotect recovers a master key from its DPAPI form.
func (DPAPIProtector) Unprotect(wrapped []byte) ([]byte, error) {
	if len(wrapped) == 0 {
		return nil, errs.Newf(errs.CodeInternal, errs.KeySecretStoreCorrupt,
			"secret store: the protected key is empty")
	}
	entropyPtr, err := windows.UTF16PtrFromString(entropy)
	if err != nil {
		return nil, errs.Wrap(err, errs.CodeInternal, errs.KeySecretStoreUnavailable)
	}
	in := dataBlob{size: uint32(len(wrapped)), data: &wrapped[0]} //nolint:gosec // the API reads the caller's buffer and does not keep it
	var out dataBlob
	status, _, _ := procCryptUnprotectData.Call(
		uintptr(unsafe.Pointer(&in)),
		0,
		uintptr(unsafe.Pointer(entropyPtr)),
		0, 0,
		uintptr(cryptProtectUIForbidden),
		uintptr(unsafe.Pointer(&out)),
	)
	if status == 0 {
		// A blob protected by another account, another machine or an older
		// entropy value lands here. There is nothing to recover and nothing
		// useful to say: naming the cause would tell a caller which of those
		// it was, which is exactly the information a probe wants.
		return nil, errs.Newf(errs.CodeInternal, errs.KeySecretStoreCorrupt,
			"secret store: the protected key could not be unwrapped by this account")
	}
	return takeBlob(&out), nil
}

// takeBlob copies a blob the operating system allocated, wipes the original and
// frees it. Leaving a copy of the master key in a buffer the process no longer
// owns is exactly the kind of leak this package exists to prevent.
func takeBlob(blob *dataBlob) []byte {
	if blob.size == 0 || blob.data == nil {
		return nil
	}
	out := make([]byte, int(blob.size))
	copy(out, unsafe.Slice(blob.data, int(blob.size)))
	_, _, _ = procRtlZeroMemory.Call(
		uintptr(unsafe.Pointer(blob.data)),
		uintptr(blob.size),
	)
	_, _, _ = procLocalFree.Call(uintptr(unsafe.Pointer(blob.data)))
	blob.data = nil
	blob.size = 0
	return out
}
