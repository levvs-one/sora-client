package mihomo

import (
	"bytes"
	"context"
	"crypto/sha256"
	"crypto/subtle"
	"encoding/hex"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"runtime"
	"strings"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
)

// EnvBinary lets a developer or a package manager point Sora at one engine
// build. It is read at startup only, and the value is still probed.
const EnvBinary = "SORA_MIHOMO_BIN"

// versionLine matches the output of "mihomo -v", for example
// "Mihomo Meta v1.19.32 windows amd64 with go1.25.14 Wed Sep 30 16:55:17 UTC 2026".
var versionLine = regexp.MustCompile(`(?i)^Mihomo(?:\s+Meta)?\s+v?(\d+\.\d+\.\d+[0-9A-Za-z.\-]*)\s+(\w+)\s+(\w+)`)

// Binary is one engine build on disk that has been probed successfully.
type Binary struct {
	Path    string
	Version engine.Version
	Goos    string
	Goarch  string
}

// Discover finds an engine binary. The search order is short and explicit: the
// environment override, then the Sora engines directory, then PATH. Nothing is
// downloaded here: shipping and updating the engine belongs to the updater and
// is covered by checksums there.
func Discover(enginesDir string) (Binary, error) {
	var candidates []string
	if fromEnv := os.Getenv(EnvBinary); fromEnv != "" {
		candidates = append(candidates, fromEnv)
	}
	name := "mihomo"
	if runtime.GOOS == "windows" {
		name += ".exe"
	}
	if enginesDir != "" {
		candidates = append(candidates, filepath.Join(enginesDir, name))
	}
	if found, err := exec.LookPath("mihomo"); err == nil {
		candidates = append(candidates, found)
	}
	lastErr := errors.New("no candidate")
	for _, candidate := range candidates {
		info, err := os.Stat(candidate) //nolint:gosec // candidates are the Sora engines dir, PATH and an operator-set env var
		if err != nil || info.IsDir() {
			lastErr = fmt.Errorf("%s is not a file", candidate)
			continue
		}
		probed, err := Probe(context.Background(), candidate, 5*time.Second)
		if err != nil {
			lastErr = fmt.Errorf("%s: %w", candidate, err)
			continue
		}
		return probed, nil
	}
	return Binary{}, fmt.Errorf("mihomo: no usable engine binary (%w); set %s or install the engine into %q", lastErr, EnvBinary, enginesDir)
}

// Probe runs "mihomo -v" and parses the answer, so Sora never starts a binary
// that is not the engine it expects.
func Probe(ctx context.Context, path string, timeout time.Duration) (Binary, error) {
	if timeout <= 0 {
		timeout = 5 * time.Second
	}
	ctx, cancel := context.WithTimeout(ctx, timeout)
	defer cancel()
	cmd := exec.CommandContext(ctx, path, "-v") //nolint:gosec // path is a discovered engine binary and "-v" is a literal
	hideWindow(cmd)
	var out bytes.Buffer
	cmd.Stdout = &out
	cmd.Stderr = &out
	if err := cmd.Run(); err != nil {
		return Binary{}, fmt.Errorf("probe failed: %w: %s", err, strings.TrimSpace(out.String()))
	}
	first := strings.TrimSpace(out.String())
	if i := strings.IndexByte(first, '\n'); i >= 0 {
		first = first[:i]
	}
	match := versionLine.FindStringSubmatch(first)
	if match == nil {
		return Binary{}, fmt.Errorf("unexpected version output %q", first)
	}
	version, err := engine.ParseVersion(match[1])
	if err != nil {
		return Binary{}, err
	}
	return Binary{Path: path, Version: version, Goos: match[2], Goarch: match[3]}, nil
}

// VerifyDigest compares the binary against the checksum the updater recorded.
func (b Binary) VerifyDigest(expected string) error {
	if expected == "" {
		return errors.New("mihomo: no expected digest")
	}
	raw, err := os.ReadFile(b.Path)
	if err != nil {
		return fmt.Errorf("mihomo: read binary: %w", err)
	}
	sum := sha256.Sum256(raw)
	got := hex.EncodeToString(sum[:])
	if subtle.ConstantTimeCompare([]byte(got), []byte(strings.ToLower(strings.TrimSpace(expected)))) != 1 {
		return fmt.Errorf("mihomo: digest mismatch: got %s", got)
	}
	return nil
}

// TestConfig asks the engine to parse the configuration with -t. It is the only
// validator that knows the real grammar, and it runs before any listener is
// opened and before any privilege is used. The configuration goes in on stdin,
// so a file with credentials is never written.
func TestConfig(ctx context.Context, b Binary, homeDir, yamlText string) error {
	ctx, cancel := context.WithTimeout(ctx, 20*time.Second)
	defer cancel()
	cmd := exec.CommandContext(ctx, b.Path, "-d", homeDir, "-f", "-", "-t") //nolint:gosec // b.Path is a probed engine binary, the config arrives on stdin
	hideWindow(cmd)
	cmd.Stdin = strings.NewReader(yamlText)
	var out bytes.Buffer
	cmd.Stdout = &out
	cmd.Stderr = &out
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("mihomo: configuration rejected: %w: %s", err, tailOf(out.String(), 8))
	}
	return nil
}
