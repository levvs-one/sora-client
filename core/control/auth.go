package control

import (
	"crypto/rand"
	"crypto/subtle"
	"encoding/base64"
	"errors"
	"io/fs"
	"os"
	"path/filepath"
	"strings"
	"sync"

	"github.com/levvs-one/sora-client/core/errs"
)

// TokenLen is the control token length in bytes. Connect and Disconnect carry
// raw bytes; any other length is rejected.
const TokenLen = 32

// tokenFile stores the control token in the core data directory with owner-only
// read access for client authentication.
const tokenFile = "control.token"

// Authenticator checks tokens in constant time. The OS-generated token protects
// the local endpoint from unauthenticated same-account processes and stale
// clients.
type Authenticator struct {
	mu    sync.RWMutex
	token []byte
}

// NewAuthenticator returns an authenticator for an existing token. The token is
// copied, so the caller may wipe its own.
func NewAuthenticator(token []byte) (*Authenticator, error) {
	if len(token) != TokenLen {
		return nil, errs.Newf(errs.CodeInvalidArgument, errs.KeyUnauthenticated,
			"control: the authenticator must be %d bytes, got %d", TokenLen, len(token))
	}
	return &Authenticator{token: append([]byte(nil), token...)}, nil
}

// LoadOrCreateToken loads the data directory's token or creates it on first
// start. Invalid existing files are rejected to expose corruption and avoid
// disconnecting clients.
func LoadOrCreateToken(dir string) (*Authenticator, error) {
	if strings.TrimSpace(dir) == "" {
		return nil, errs.Newf(errs.CodeInvalidArgument, errs.KeyUnauthenticated,
			"control: no data directory for the authenticator")
	}
	path := filepath.Join(dir, tokenFile)
	raw, err := os.ReadFile(path) //nolint:gosec // a fixed file name inside the data directory of the core
	switch {
	case err == nil:
		token, decodeErr := base64.StdEncoding.DecodeString(strings.TrimSpace(string(raw)))
		if decodeErr != nil || len(token) != TokenLen {
			return nil, errs.Newf(errs.CodeInternal, errs.KeyUnauthenticated,
				"control: the stored authenticator is not readable")
		}
		return NewAuthenticator(token)
	case !errors.Is(err, fs.ErrNotExist):
		return nil, errs.Wrap(err, errs.CodeInternal, errs.KeyUnauthenticated)
	}
	token := make([]byte, TokenLen)
	if _, err := rand.Read(token); err != nil {
		return nil, errs.Wrap(err, errs.CodeInternal, errs.KeyUnauthenticated)
	}
	encoded := []byte(base64.StdEncoding.EncodeToString(token))
	if err := writeOwnerOnly(path, encoded); err != nil {
		return nil, err
	}
	return NewAuthenticator(token)
}

// Verify checks a token in constant time after rejecting an invalid length.
func (a *Authenticator) Verify(presented []byte) bool {
	if a == nil || len(presented) != TokenLen {
		return false
	}
	a.mu.RLock()
	expected := a.token
	a.mu.RUnlock()
	if len(expected) != TokenLen {
		return false
	}
	return subtle.ConstantTimeCompare(presented, expected) == 1
}

// Check returns the catalog error when token verification fails.
func (a *Authenticator) Check(presented []byte) error {
	if a.Verify(presented) {
		return nil
	}
	return errs.Newf(errs.CodeUnauthenticated, errs.KeyUnauthenticated,
		"control: the presented authenticator does not match")
}

// Token returns a copy of the token for Handshake clients admitted by the
// transport.
func (a *Authenticator) Token() []byte {
	a.mu.RLock()
	defer a.mu.RUnlock()
	return append([]byte(nil), a.token...)
}

// Rotate replaces and returns the token without restarting the core. All
// existing client tokens become invalid.
func (a *Authenticator) Rotate() ([]byte, error) {
	fresh := make([]byte, TokenLen)
	if _, err := rand.Read(fresh); err != nil {
		return nil, errs.Wrap(err, errs.CodeInternal, errs.KeyUnauthenticated)
	}
	a.mu.Lock()
	a.token = append([]byte(nil), fresh...)
	a.mu.Unlock()
	return fresh, nil
}

// writeOwnerOnly stores a file that only the owner may read.
func writeOwnerOnly(path string, data []byte) error {
	if err := os.WriteFile(path, data, 0o600); err != nil {
		return errs.Wrap(err, errs.CodeInternal, errs.KeyUnauthenticated)
	}
	return nil
}
