package supervise

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

// Binary is one engine build on disk that has been probed successfully.
type Binary struct {
	Kind    engine.Kind
	Path    string
	Version engine.Version
	Goos    string
	Goarch  string
}

// Prober describes how to recognize one engine binary.
type Prober struct {
	Kind engine.Kind
	// Name is the executable name without extension, for example "sing-box".
	Name string
	// EnvVar lets a developer or a package manager point Sora at one build. It
	// is read at discovery only, and the value is still probed.
	EnvVar string
	// Args make the binary print its version, for example ["version"].
	Args []string
	// Pattern matches the first line of the version output. Group 1 is the
	// version; optional groups 2 and 3 are GOOS and GOARCH.
	Pattern *regexp.Regexp
}

// Probe runs the binary with the version arguments and parses the answer, so
// Sora never starts a file that is not the engine it expects.
func (pr Prober) Probe(ctx context.Context, path string) (Binary, error) {
	ctx, cancel := context.WithTimeout(ctx, 10*time.Second)
	defer cancel()
	cmd := exec.CommandContext(ctx, path, pr.Args...) //nolint:gosec // path is a discovery candidate and the arguments are literals
	HideWindow(cmd)
	var out bytes.Buffer
	cmd.Stdout = &out
	cmd.Stderr = &out
	if err := cmd.Run(); err != nil {
		return Binary{}, fmt.Errorf("%s: probe failed: %w: %s", pr.Kind, err, strings.TrimSpace(out.String()))
	}
	first, _, _ := strings.Cut(strings.TrimSpace(out.String()), "\n")
	match := pr.Pattern.FindStringSubmatch(strings.TrimSpace(first))
	if match == nil {
		return Binary{}, fmt.Errorf("%s: unexpected version output %q", pr.Kind, first)
	}
	version, err := engine.ParseVersion(match[1])
	if err != nil {
		return Binary{}, err
	}
	b := Binary{Kind: pr.Kind, Path: path, Version: version, Goos: runtime.GOOS, Goarch: runtime.GOARCH}
	if len(match) > 3 && match[2] != "" && match[3] != "" {
		b.Goos, b.Goarch = match[2], match[3]
	}
	return b, nil
}

// Discover finds an engine binary. The search order is short and explicit: the
// environment override, then the Sora engines directory, then PATH. Nothing is
// downloaded here: shipping and updating engines belongs to the updater and is
// covered by checksums there.
func (pr Prober) Discover(ctx context.Context, enginesDir string) (Binary, error) {
	var candidates []string
	if fromEnv := os.Getenv(pr.EnvVar); pr.EnvVar != "" && fromEnv != "" {
		candidates = append(candidates, fromEnv)
	}
	file := pr.Name
	if runtime.GOOS == "windows" {
		file += ".exe"
	}
	if enginesDir != "" {
		candidates = append(candidates, filepath.Join(enginesDir, file))
	}
	if found, err := exec.LookPath(pr.Name); err == nil {
		candidates = append(candidates, found)
	}
	lastErr := errors.New("no candidate")
	for _, candidate := range candidates {
		info, err := os.Stat(candidate)
		if err != nil || info.IsDir() {
			lastErr = fmt.Errorf("%s is not a file", candidate)
			continue
		}
		probed, err := pr.Probe(ctx, candidate)
		if err != nil {
			lastErr = err
			continue
		}
		return probed, nil
	}
	return Binary{}, fmt.Errorf("%s: no usable engine binary (%w); set %s or install it into %q", pr.Kind, lastErr, pr.EnvVar, enginesDir)
}

// VerifyDigest compares the binary against the checksum the updater recorded.
func (b Binary) VerifyDigest(expected string) error {
	if expected == "" {
		return fmt.Errorf("%s: no expected digest", b.Kind)
	}
	raw, err := os.ReadFile(b.Path)
	if err != nil {
		return fmt.Errorf("%s: read binary: %w", b.Kind, err)
	}
	sum := sha256.Sum256(raw)
	got := hex.EncodeToString(sum[:])
	if subtle.ConstantTimeCompare([]byte(got), []byte(strings.ToLower(strings.TrimSpace(expected)))) != 1 {
		return fmt.Errorf("%s: digest mismatch: got %s", b.Kind, got)
	}
	return nil
}
