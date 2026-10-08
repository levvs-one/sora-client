package secret

import "github.com/levvs-one/sora-client/core/errs"

// Vault layout: versioned eight-byte magic, fresh 12-byte nonce, then JSON-map
// ciphertext and GCM tag. Separate store ID is AEAD data; mismatched IDs or
// keys fail. Copying the whole directory preserves valid backups.
var vaultHeader = []byte("SORAVLT\x01")

const (
	// storeIDLen is the length of the store identifier.
	storeIDLen = 16
	// nonceLen is the GCM nonce length the store writes.
	nonceLen = 12
	// aeadOverhead is the GCM tag size, checked before decrypting truncated
	// files.
	aeadOverhead = 16
	// masterHeader marks the wrapped master key file and carries its
	// version.
	masterHeader = "SORAMST\x01"
	// keyLen is the length of the master key: AES-256.
	keyLen = 32
)

// headerLen is the plaintext part of a vault file: the magic and the nonce.
var headerLen = len(vaultHeader) + nonceLen

// ValidateReference accepts bounded opaque references without separators, path
// characters, or log-unsafe text.
func ValidateReference(reference string) error {
	switch {
	case reference == "":
		return errs.Newf(errs.CodeInvalidArgument, errs.KeySecretReferenceInvalid,
			"secret store: the reference is empty")
	case len(reference) > MaxReferenceLen:
		return errs.Newf(errs.CodeInvalidArgument, errs.KeySecretReferenceInvalid,
			"secret store: the reference is longer than %d bytes", MaxReferenceLen)
	}
	for i := range len(reference) {
		c := reference[i]
		switch {
		case c >= 'a' && c <= 'z',
			c >= 'A' && c <= 'Z',
			c >= '0' && c <= '9',
			c == '-', c == '_':
		default:
			return errs.Newf(errs.CodeInvalidArgument, errs.KeySecretReferenceInvalid,
				"secret store: the reference has an unsupported character at %d", i)
		}
	}
	return nil
}
