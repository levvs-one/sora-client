// Package supervise owns the life of an engine child process: probing the
// binary, handing it the configuration over stdin, waiting for its controller,
// restarting it inside a budget and stopping it on every exit path.
//
// Every engine Sora drives (mihomo, sing-box, Xray) is a separate GPL binary
// started as a child process. What differs between them is the configuration
// grammar and the control API; that part is a Driver. Everything else is the
// same code, so a fix to supervision reaches every engine at once.
package supervise

import (
	"bytes"
	"context"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"sync"
	"time"
)

// KillWait bounds how long Stop waits for the operating system to reap a killed
// engine before it reports that the child process is stuck.
const KillWait = 5 * time.Second

// Spec describes one engine process to start.
type Spec struct {
	// Name prefixes errors, for example "xray".
	Name string
	Path string
	Args []string
	Dir  string
	// Config is written to the child over stdin and closed. Every supported
	// engine reads its configuration from stdin, which keeps credentials out of
	// both the process arguments and the disk.
	Config []byte
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

// Start launches the engine. ctx owns the process: when it ends, the child is
// stopped on a context that cannot be cancelled, so the engine never outlives
// both the caller and the supervisor watching it.
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
	// Engines log to either stream depending on build and level; both feed the
	// same bounded tail, which is the only explanation a user gets for a crash.
	cmd.Stdout = tail
	cmd.Stderr = tail
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

// PID is the operating system process id.
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

// Stop terminates the engine: an interrupt where the platform has one, a grace
// period, then a kill. None of the engines keeps state worth preserving, since
// the configuration is rebuilt from the plan on every start. A cancelled ctx
// ends the wait, not the shutdown: the engine is killed either way.
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

// Check runs the engine's own validator on cfg. The engine is the only party
// that knows its grammar, so this is what catches a key Sora got wrong, before
// any listener is opened.
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
