// Package singbox runs sing-box as a supervised child process and implements
// engine.Engine on top of its HTTP REST API (compatible with Clash API).
package singbox

import (
	"context"
	"fmt"
	"os"
	"os/exec"
	"sync"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
)

type process struct {
	cmd     *exec.Cmd
	mu      sync.Mutex
	state_  engine.State
	err     error
	homeDir string
	binary  Binary
	rt      Runtime
	config  string
}

func newProcess(b Binary, homeDir string, rt Runtime, config string) *process {
	return &process{
		binary:  b,
		homeDir: homeDir,
		rt:      rt,
		config:  config,
		state_:  engine.StateIdle,
	}
}

func (p *process) start(ctx context.Context) error {
	p.mu.Lock()
	defer p.mu.Unlock()

	configPath := p.homeDir + "/config.json"
	if err := os.WriteFile(configPath, []byte(p.config), 0o600); err != nil {
		return err
	}

	args := []string{"run", "-c", configPath, "-D", p.homeDir}
	p.cmd = exec.CommandContext(ctx, p.binary.Path, args...)
	p.cmd.Dir = p.homeDir
	p.cmd.Stdout = os.Stdout
	p.cmd.Stderr = os.Stderr

	p.state_ = engine.StateStarting
	if err := p.cmd.Start(); err != nil {
		p.state_ = engine.StateFailed
		return err
	}
	p.state_ = engine.StateRunning
	return nil
}

func (p *process) stop(ctx context.Context, grace time.Duration) error {
	p.mu.Lock()
	defer p.mu.Unlock()
	if p.cmd == nil || p.cmd.Process == nil {
		return nil
	}
	if err := p.cmd.Process.Signal(os.Interrupt); err != nil {
		_ = p.cmd.Process.Kill()
	}
	done := make(chan error, 1)
	go func() { done <- p.cmd.Wait() }()
	select {
	case <-ctx.Done():
		_ = p.cmd.Process.Kill()
		return ctx.Err()
	case err := <-done:
		p.state_ = engine.StateStopped
		return err
	case <-time.After(grace):
		_ = p.cmd.Process.Kill()
		<-done
		p.state_ = engine.StateStopped
		return fmt.Errorf("sing-box did not stop within %s", grace)
	}
}

func (p *process) running() bool {
	p.mu.Lock()
	defer p.mu.Unlock()
	return p.state_ == engine.StateRunning
}

func (p *process) state() engine.State {
	p.mu.Lock()
	defer p.mu.Unlock()
	return p.state_
}
