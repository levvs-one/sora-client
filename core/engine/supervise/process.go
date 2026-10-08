// Package supervise manages separate engine processes: discovery, stdin
// configuration, readiness, bounded restarts, and shutdown. Drivers supply
// engine-specific grammar, arguments, and control handshakes; supervision is
// shared across mihomo, sing-box, and Xray.
package supervise

import (
	"bytes"
	"context"
	"errors"
	"fmt"
	"io"
	"os"
	"os/exec"
	"sync"
	"time"
)

// KillWait bounds the wait for a killed child to be reaped before reporting it
// stuck.
const KillWait = 5 * time.Second

// Spec describes one engine process to start.
type Spec struct {
	// Name prefixes errors, for example "xray".
	Name string
	Path string
	Args []string
	Dir  string
	// Config is sent over stdin, then closed, keeping credentials off disk
	// and out of process arguments.
	Config []byte
	// Lines receives every complete output line of the engine, when set.
	Lines func(string)
}

// Process is one running engine child process.
type Process struct {
	name   string
	cmd    *exec.Cmd
	stderr *Tail
	done   chan struct{}
	mu     sync.Mutex
	err    error
}

// Start launches a context-owned engine. Cancellation stops it using an
// independent shutdown context so the child cannot outlive supervision.
func Start(ctx context.Context, spec Spec) (*Process, error) {
	if spec.Path == "" || spec.Dir == "" {
		return nil, fmt.Errorf("%s: binary and working directory are required", spec.Name)
	}
	if err := os.MkdirAll(spec.Dir, 0o700); err != nil {
		return nil, fmt.Errorf("%s: create engine home: %w", spec.Name, err)
	}
	//nolint:gosec,noctx // spec.Path is a probed engine binary; the goroutine below and Stop own shutdown, so ctx must not gain kill rights over the process
	cmd := exec.Command(spec.Path, spec.Args...)
	HideWindow(cmd)
	cmd.Dir = spec.Dir
	cmd.Env = SafeEnv()
	cmd.Stdin = bytes.NewReader(spec.Config)
	tail := NewTail(80)
	// Capture both streams because engine output varies by build and level;
	// retain a bounded tail for crash reports.
	var out io.Writer = tail
	if spec.Lines != nil {
		out = io.MultiWriter(tail, &lineWriter{emit: spec.Lines})
	}
	cmd.Stdout = out
	cmd.Stderr = out
	if err := cmd.Start(); err != nil {
		return nil, fmt.Errorf("%s: start engine: %w", spec.Name, err)
	}

	p := &Process{name: spec.Name, cmd: cmd, stderr: tail, done: make(chan struct{})}
	go func() {
		err := cmd.Wait()
		p.mu.Lock()
		p.err = err
		p.mu.Unlock()
		close(p.done)
	}()
	go func() {
		select {
		case <-ctx.Done():
			_ = p.Stop(context.WithoutCancel(ctx), 2*time.Second)
		case <-p.done:
		}
	}()
	return p, nil
}

// PID returns the operating system process ID.
func (p *Process) PID() int { return p.cmd.Process.Pid }

// Output returns the tail of the engine output.
func (p *Process) Output() *Tail { return p.stderr }

// Exited reports whether the process has already terminated.
func (p *Process) Exited() bool {
	select {
	case <-p.done:
		return true
	default:
		return false
	}
}

// Err reports why the process stopped, or nil while it is running.
func (p *Process) Err() error {
	if !p.Exited() {
		return nil
	}
	return p.exitError()
}

func (p *Process) exitError() error {
	p.mu.Lock()
	err := p.err
	p.mu.Unlock()
	if err == nil {
		return nil
	}
	return fmt.Errorf("%s: engine stopped: %w: %s", p.name, err, p.stderr.Last(8))
}

// Wait blocks until the process stops or ctx ends.
func (p *Process) Wait(ctx context.Context) error {
	select {
	case <-p.done:
		return p.exitError()
	case <-ctx.Done():
		return ctx.Err()
	}
}

// Stop sends an interrupt, waits a grace period, then kills the engine.
// Cancellation ends the wait but still kills the child; configuration is
// rebuilt on restart.
func (p *Process) Stop(ctx context.Context, grace time.Duration) error {
	if p.Exited() {
		return nil
	}
	if grace > 0 && interrupt(p.cmd.Process) == nil {
		timer := time.NewTimer(grace)
		defer timer.Stop()
		select {
		case <-p.done:
			return nil
		case <-ctx.Done():
		case <-timer.C:
		}
	}
	if err := p.cmd.Process.Kill(); err != nil && !p.Exited() {
		return fmt.Errorf("%s: stop engine: %w", p.name, err)
	}
	timer := time.NewTimer(KillWait)
	defer timer.Stop()
	select {
	case <-p.done:
		return nil
	case <-ctx.Done():
		return ctx.Err()
	case <-timer.C:
		return errors.New(p.name + ": engine did not exit after kill")
	}
}

// Check runs the engine's validator on cfg before opening listeners, catching
// grammar errors.
func Check(ctx context.Context, spec Spec) error {
	if err := os.MkdirAll(spec.Dir, 0o700); err != nil {
		return fmt.Errorf("%s: create engine home: %w", spec.Name, err)
	}
	ctx, cancel := context.WithTimeout(ctx, 20*time.Second)
	defer cancel()
	cmd := exec.CommandContext(ctx, spec.Path, spec.Args...) //nolint:gosec // spec.Path is a probed engine binary, the config arrives on stdin
	HideWindow(cmd)
	cmd.Dir = spec.Dir
	cmd.Env = SafeEnv()
	cmd.Stdin = bytes.NewReader(spec.Config)
	out := NewTail(40)
	cmd.Stdout = out
	cmd.Stderr = out
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("%s: configuration rejected: %w: %s", spec.Name, err, out.Last(8))
	}
	return nil
}

// maxLine limits unterminated engine output to prevent unbounded buffering.
const maxLine = 64 << 10

// lineWriter assembles complete lines and locks because stdout and stderr share
// it.
type lineWriter struct {
	mu   sync.Mutex
	buf  []byte
	emit func(string)
}

func (w *lineWriter) Write(p []byte) (int, error) {
	w.mu.Lock()
	defer w.mu.Unlock()
	w.buf = append(w.buf, p...)
	for {
		i := bytes.IndexByte(w.buf, '\n')
		if i < 0 {
			break
		}
		w.emit(string(bytes.TrimRight(w.buf[:i], "\r")))
		w.buf = w.buf[i+1:]
	}
	if len(w.buf) > maxLine {
		w.emit(string(w.buf))
		w.buf = nil
	}
	return len(p), nil
}
