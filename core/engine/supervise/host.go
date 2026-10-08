package supervise

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"fmt"
	"net"
	"os"
	"strings"
	"sync"
)

// Tail concurrently stores bounded engine output lines. It never returns write
// errors and can receive exec.Cmd stdout and stderr directly.
type Tail struct {
	mu    sync.Mutex
	lines []string
	max   int
}

// NewTail returns a tail that keeps limit lines.
func NewTail(limit int) *Tail {
	if limit <= 0 {
		limit = 50
	}
	return &Tail{max: limit, lines: make([]string, 0, limit)}
}

func (t *Tail) Write(p []byte) (int, error) {
	t.mu.Lock()
	defer t.mu.Unlock()
	for _, line := range strings.Split(strings.TrimRight(string(p), "\n"), "\n") {
		line = strings.TrimRight(line, "\r")
		if line == "" {
			continue
		}
		t.lines = append(t.lines, line)
		if len(t.lines) > t.max {
			t.lines = t.lines[len(t.lines)-t.max:]
		}
	}
	return len(p), nil
}

// String returns the kept lines, oldest first.
func (t *Tail) String() string { return t.Last(t.max) }

// Last returns at most n of the newest lines.
func (t *Tail) Last(n int) string {
	t.mu.Lock()
	defer t.mu.Unlock()
	lines := t.lines
	if n >= 0 && len(lines) > n {
		lines = lines[len(lines)-n:]
	}
	return strings.Join(lines, "\n")
}

// FreePort reserves and releases a loopback port for the engine. Another
// process can claim it before binding; the restart budget covers this race.
func FreePort() (int, error) {
	var lc net.ListenConfig
	listener, err := lc.Listen(context.Background(), "tcp", "127.0.0.1:0")
	if err != nil {
		return 0, fmt.Errorf("supervise: pick a free port: %w", err)
	}
	defer func() { _ = listener.Close() }()
	return listener.Addr().(*net.TCPAddr).Port, nil
}

// SecretBytes is the length of a controller secret before hex encoding.
const SecretBytes = 32

// RandomSecret generates a required controller secret to prevent
// unauthenticated local control.
func RandomSecret() (string, error) {
	buf := make([]byte, SecretBytes)
	if _, err := rand.Read(buf); err != nil {
		return "", fmt.Errorf("supervise: generate controller secret: %w", err)
	}
	return hex.EncodeToString(buf), nil
}

// SafeEnv filters the child environment to exclude inherited proxy variables
// and service secrets.
func SafeEnv() []string {
	keys := []string{"SYSTEMROOT", "WINDIR", "COMSPEC", "PATH", "HOME", "USERPROFILE", "TEMP", "TMP", "LANG", "LC_ALL", "TZ"}
	out := make([]string, 0, len(keys))
	for _, key := range keys {
		if v := os.Getenv(key); v != "" {
			out = append(out, key+"="+v)
		}
	}
	return out
}
