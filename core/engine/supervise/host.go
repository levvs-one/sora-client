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

// Tail keeps the last lines of the engine output, bounded but readable. It is
// safe for concurrent use and never fails, so it can be wired straight to
// exec.Cmd.Stdout and Stderr.
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

// FreePort asks the kernel for a free loopback port. The port is released and
// then handed to the engine, so a race is possible on a busy machine: the
// restart budget covers an engine that fails to bind.
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

// RandomSecret builds a controller secret. Every engine accepts an empty one,
// which would let any local process control the tunnel, so Sora always sets it.
func RandomSecret() (string, error) {
	buf := make([]byte, SecretBytes)
	if _, err := rand.Read(buf); err != nil {
		return "", fmt.Errorf("supervise: generate controller secret: %w", err)
	}
	return hex.EncodeToString(buf), nil
}

// SafeEnv gives the child only what it needs. Inheriting the parent environment
// would pass proxy variables and service secrets into a process whose only job
// is to own the network path.
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
