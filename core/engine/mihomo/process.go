package mihomo

import (
	"context"
	"errors"
	"fmt"
	"io"
	"os"
	"os/exec"
	"strings"
	"sync"
	"time"
)

// KillWait bounds how long Stop waits for the operating system to reap a killed
// engine before it reports that the child process is stuck.
const KillWait = 5 * time.Second

// Process is one running engine child process.
type Process struct {
	cmd    *exec.Cmd
	stderr *Tail
	done   chan struct{}
	mu     sync.Mutex
	exited bool
	err    error
	pid    int
}

// Start launches the engine. The configuration is written to the child over
// stdin: mihomo reads "-f -" as "read the configuration from standard input",
// which keeps credentials out of both the process arguments and the disk.
func Start(ctx context.Context, b Binary, rt Runtime, yamlText string) (*Process, error) {
	if rt.HomeDir == "" || rt.ControllerAddr == "" || rt.Secret == "" {
		return nil, errors.New("mihomo: home directory, controller address and secret are required")
	}
	if err := os.MkdirAll(rt.HomeDir, 0o700); err != nil {
		return nil, fmt.Errorf("mihomo: create engine home: %w", err)
	}
	if rt.WriteConfigTo != "" {
		if err := os.WriteFile(rt.WriteConfigTo, []byte(yamlText), 0o600); err != nil {
			return nil, fmt.Errorf("mihomo: write debug config: %w", err)
		}
	}

	//nolint:gosec,noctx // b.Path is a probed engine binary; the supervisor goroutine and Stop own shutdown, so the start ctx must not gain kill rights over the process
	cmd := exec.Command(b.Path, "-d", rt.HomeDir, "-f", "-", "-ext-ctl", rt.ControllerAddr)
	hideWindow(cmd)
	cmd.Dir = rt.HomeDir
	cmd.Env = safeEnv()
	tail := NewTail(80)
	cmd.Stderr = tail

	stdin, err := cmd.StdinPipe()
	if err != nil {
		return nil, fmt.Errorf("mihomo: stdin pipe: %w", err)
	}
	if err := cmd.Start(); err != nil {
		return nil, fmt.Errorf("mihomo: start engine: %w", err)
	}
	go func() {
		_, _ = io.Copy(stdin, strings.NewReader(yamlText))
		_ = stdin.Close()
	}()

	p := &Process{cmd: cmd, stderr: tail, done: make(chan struct{}), pid: cmd.Process.Pid}
	go func() {
		err := cmd.Wait()
		p.mu.Lock()
		p.exited = true
		p.err = err
		p.mu.Unlock()
		close(p.done)
	}()
	go func() {
		select {
		case <-ctx.Done():
		case <-p.done:
			// The engine stopped by itself; there is nothing left to shut down.
			return
		}
		// The context that started the engine is gone, so nothing is left to own
		// the child. Shut it down on a context that cannot be cancelled, or the
		// engine would outlive both the caller and the supervisor watching it.
		_ = p.Stop(context.WithoutCancel(ctx), 2*time.Second)
	}()
	return p, nil
}

// PID is the operating system process id.
func (p *Process) PID() int { return p.pid }

// Stderr returns the tail of the engine output.
func (p *Process) Stderr() *Tail { return p.stderr }

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
	select {
	case <-p.done:
		return p.exitError()
	default:
		return nil
	}
}

// exitError wraps the recorded wait error with the engine output.
func (p *Process) exitError() error {
	p.mu.Lock()
	err := p.err
	p.mu.Unlock()
	if err == nil {
		return nil
	}
	return fmt.Errorf("mihomo: engine stopped: %w: %s", err, p.stderr.String())
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

// Stop terminates the engine. mihomo exposes no shutdown endpoint, so Sora
// gives it a short grace period and then ends the process. The engine keeps no
// state worth preserving: the configuration is rebuilt from the plan on every
// start, and Sora stores the group selection itself. A cancelled ctx ends the
// wait, not the shutdown: the engine is killed either way.
func (p *Process) Stop(ctx context.Context, grace time.Duration) error {
	if p.Exited() {
		return nil
	}
	if grace > 0 {
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
		return fmt.Errorf("mihomo: stop engine: %w", err)
	}
	timer := time.NewTimer(KillWait)
	defer timer.Stop()
	select {
	case <-p.done:
		return nil
	case <-ctx.Done():
		return ctx.Err()
	case <-timer.C:
		return errors.New("mihomo: engine did not exit after kill")
	}
}
