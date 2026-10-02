package mihomo

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"fmt"
	"net"
	"os"
	"strings"
	"sync"
	"time"
)

// Tail keeps the last lines of the engine output. The engine reports parse
// errors on stderr, and that text is the only explanation a user can get, so
// it is kept bounded but readable. Tail is safe for concurrent use.
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

// Write appends complete lines. It never fails, so it can be wired straight to
// exec.Cmd.Stderr.
func (t *Tail) Write(p []byte) (int, error) {
	t.mu.Lock()
	defer t.mu.Unlock()
	for _, line := range strings.Split(strings.TrimRight(string(p), "\n"), "\n") {
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
func (t *Tail) String() string {
	t.mu.Lock()
	defer t.mu.Unlock()
	return strings.Join(t.lines, "\n")
}

func tailOf(s string, n int) string {
	t := NewTail(n)
	_, _ = t.Write([]byte(s))
	return t.String()
}

// FreePort asks the kernel for a free loopback port. The port is released and
// then handed to the engine, so a race is possible on a busy machine: the
// caller retries with a new port when the engine fails to bind.
func FreePort() (int, error) {
	var lc net.ListenConfig
	listener, err := lc.Listen(context.Background(), "tcp", "127.0.0.1:0")
	if err != nil {
		return 0, fmt.Errorf("mihomo: pick a free port: %w", err)
	}
	defer func() { _ = listener.Close() }()
	return listener.Addr().(*net.TCPAddr).Port, nil
}

// RandomSecret builds the controller secret. mihomo accepts an empty secret,
// which would let any local process control the tunnel, so Sora always sets one.
func RandomSecret() (string, error) {
	buf := make([]byte, SecretBytes)
	if _, err := rand.Read(buf); err != nil {
		return "", fmt.Errorf("mihomo: generate controller secret: %w", err)
	}
	return hex.EncodeToString(buf), nil
}

// WaitReady polls the controller until it answers, the deadline passes or the
// process dies. A dead child is reported with its own stderr, because "the API
// did not come up" tells a user nothing.
func WaitReady(ctx context.Context, client *Client, proc *Process, timeout time.Duration) (VersionInfo, error) {
	ctx, cancel := context.WithTimeout(ctx, timeout)
	defer cancel()
	ticker := time.NewTicker(100 * time.Millisecond)
	defer ticker.Stop()
	var lastErr error
	for {
		info, err := client.Version(ctx)
		if err == nil {
			return info, nil
		}
		lastErr = err
		if proc != nil {
			if reason := proc.Err(); reason != nil {
				return VersionInfo{}, reason
			}
		}
		select {
		case <-ctx.Done():
			return VersionInfo{}, fmt.Errorf("mihomo: engine API did not come up: %w", lastErr)
		case <-ticker.C:
		}
	}
}

// safeEnv gives the child only what it needs. Inheriting the parent environment
// would pass proxy variables and service secrets into a process whose only job
// is to own the network path.
func safeEnv() []string {
	keys := []string{"SYSTEMROOT", "WINDIR", "COMSPEC", "PATH", "HOME", "USERPROFILE", "TEMP", "TMP", "LANG", "LC_ALL", "TZ"}
	out := make([]string, 0, len(keys))
	for _, key := range keys {
		if v := os.Getenv(key); v != "" {
			out = append(out, key+"="+v)
		}
	}
	return out
}
