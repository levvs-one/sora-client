package secret

import "github.com/levvs-one/sora-client/core/errs"

// On-disk format of the vault. The layout is fixed and small:
//
//	"  magic, eight bytes, so a wrong file is refused instead of decrypted
//	|  nonce, twelve random bytes, fresh for every write
//	|  ciphertext of the JSON reference map, with the GCM tag
//
// The magic carries the version, so a future format fails loudly on an older
// core instead of producing garbage. The store identifier lives in its own file
// and is bound into the AEAD as additional data: a vault that meets a key from
// a different store, or an id from a different store, fails to open instead of
// quietly decrypting to nothing. Copying the whole directory is a legitimate
// backup and does open, which is the point of keeping the id beside the key.
var vaultHeader = []byte("SORAVLT\x01")

const (
	// storeIDLen is the length of the store identifier.
	storeIDLen = 16
	// nonceLen is the GCM nonce length the store writes.
	nonceLen = 12
	// aeadOverhead is the GCM tag length, so a truncated file is detected
	// before the cipher is even called.
	aeadOverhead = 16
	// masterHeader marks the wrapped master key file and carries its version.
	masterHeader = "SORAMST\x01"
	// keyLen is the length of the master key: AES-256.
	keyLen = 32
)

// headerLen is the plaintext part of a vault file: the magic and the nonce.
var headerLen = len(vaultHeader) + nonceLen

// ValidateReference reports whether a reference is one the store is willing to
// hold. References travel through the control plane, so the rules are strict:
// a short opaque alphabet, no separators, no path characters, nothing a log
// line or a file name could be confused by.
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
