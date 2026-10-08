//go:build windows

package mihomo

import (
	"crypto/rand"
	"encoding/hex"

	"github.com/levvs-one/sora-client/core/engine/supervise"
)

// ControlAddress uses an unguessable named pipe to avoid discoverable
// controller ports. The secret still authenticates requests.
func (driver) ControlAddress(supervise.Runtime, bool) (string, error) {
	buf := make([]byte, 16)
	if _, err := rand.Read(buf); err != nil {
		return "", err
	}
	return `pipe:\\.\pipe\sora-mihomo-` + hex.EncodeToString(buf), nil
}
