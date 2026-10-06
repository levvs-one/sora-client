package clashapi

import (
	"context"
	"sync"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/supervise"
)

// Engine is a supervised engine controlled over the Clash API: the lifecycle
// comes from the supervisor, groups, selection, latency and counters from the
// controller of the running process.
type Engine struct {
	*supervise.Supervisor

	mu       sync.Mutex
	counters engine.Counters
}

// NewEngine wraps a supervisor whose driver configures a Clash API controller
// on Runtime.ControlAddr with Runtime.Secret.
func NewEngine(sup *supervise.Supervisor) *Engine { return &Engine{Supervisor: sup} }

// For returns the controller client of one engine run.
func For(rt supervise.Runtime) *Client {
	return NewClient(rt.ControlAddr, rt.Secret, 5*time.Second)
}

func (e *Engine) api() (*Client, error) {
	rt, err := e.Running()
	if err != nil {
		return nil, err
	}
	return For(rt), nil
}

// Groups returns the selectable groups with their live state.
func (e *Engine) Groups(ctx context.Context) ([]engine.GroupStatus, error) {
	c, err := e.api()
	if err != nil {
		return nil, err
	}
	groups, err := c.Groups(ctx)
	return groups, e.Redactor().Err(err)
}

// Select pins one member of a group.
func (e *Engine) Select(ctx context.Context, group, target string) error {
	c, err := e.api()
	if err != nil {
		return err
	}
	if err := c.Select(ctx, group, target); err != nil {
		return e.Redactor().Err(err)
	}
	e.Events().Publish(engine.Event{Kind: engine.EventGroup, Group: &engine.GroupStatus{Name: group, Selected: target}})
	return nil
}

// Delay measures one proxy through the engine.
func (e *Engine) Delay(ctx context.Context, name, testURL string, timeout time.Duration) (time.Duration, error) {
	c, err := e.api()
	if err != nil {
		return 0, err
	}
	if testURL == "" {
		testURL = e.ProbeURL()
	}
	if timeout <= 0 {
		timeout = 5 * time.Second
	}
	d, err := c.Delay(ctx, name, testURL, timeout)
	return d, e.Redactor().Err(err)
}

// Counters returns the traffic counters of the running session. When the
// controller is briefly unreachable the last known value is returned together
// with the error, so the interface keeps its chart instead of dropping to zero.
func (e *Engine) Counters(ctx context.Context) (engine.Counters, error) {
	c, err := e.api()
	if err != nil {
		return engine.Counters{}, err
	}
	counters, cerr := c.Counters(ctx)
	e.mu.Lock()
	defer e.mu.Unlock()
	if cerr != nil {
		return e.counters, e.Redactor().Err(cerr)
	}
	e.counters = counters
	return counters, nil
}
