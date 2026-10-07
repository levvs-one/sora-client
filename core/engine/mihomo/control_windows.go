//go:build windows

package mihomo

import (
	"crypto/rand"
	"encoding/hex"

	"github.com/levvs-one/sora-client/core/engine/supervise"
)

// ControlAddress puts the controller on a named pipe with an unguessable name,
// so no application finds a port that answers. The controller secret still
// guards every request.
func (driver) ControlAddress(supervise.Runtime, bool) (string, error) {
	buf := make([]byte, 16)
	if _, err := rand.Read(buf); err != nil {
		return "", err
	}
	return `pipe:\\.\pipe\sora-mihomo-` + hex.EncodeToString(buf), nil
}
