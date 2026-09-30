package mihomo

import (
	"context"
	"errors"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
)

// Stop shuts the engine down and forgets the plan.
func (e *Engine) Stop(ctx context.Context) error {
	e.mu.Lock()
	e.stopping = true
	proc := e.proc
	e.proc, e.client, e.plan = nil, nil, nil
	e.mu.Unlock()

	var err error
	if proc != nil {
		err = proc.Stop(ctx, e.cfg.StopGrace)
	}
	e.setState(engine.StateStopped)
	return e.redactor.Err(err)
}

// Close stops the engine and releases the supervision context.
func (e *Engine) Close() error {
	err := e.Stop(context.Background())
	e.cancel()
	return err
}

// apiGroupTypes maps the group type names the controller reports onto the
// names the Sora contract uses. The API answers in CamelCase while the YAML
// config is written in lowercase, and both appear in the same conversation.
var apiGroupTypes = map[string]engine.GroupType{
	"Selector":     engine.GroupSelect,
	"URLTest":      engine.GroupURLTest,
	"Fallback":     engine.GroupFallback,
	"LoadBalance":  engine.GroupLoadBalance,
	"Relay":        "relay",
	"select":       engine.GroupSelect,
	"url-test":     engine.GroupURLTest,
	"fallback":     engine.GroupFallback,
	"load-balance": engine.GroupLoadBalance,
}

// Groups returns the selectable groups with their live state.
func (e *Engine) Groups(ctx context.Context) ([]engine.GroupStatus, error) {
	client, err := e.api()
	if err != nil {
		return nil, err
	}
	proxies, err := client.Proxies(ctx)
	if err != nil {
		return nil, e.redactor.Err(err)
	}
	out := make([]engine.GroupStatus, 0, len(proxies))
	for name, px := range proxies {
		kind, isGroup := apiGroupTypes[px.Type]
		if !isGroup || name == "GLOBAL" {
			continue
		}
		status := engine.GroupStatus{
			Name: name, Type: kind, Selected: px.Now, All: px.All,
			Hidden: px.Hidden, Icon: px.Icon, TestURL: px.TestURL, Provider: px.ProviderName,
			LatencyMS: map[string]int{},
		}
		for _, h := range px.History {
			status.LatencyMS[h.Name] = h.Delay
		}
		out = append(out, status)
	}
	return out, nil
}

// Select pins one member of a group.
func (e *Engine) Select(ctx context.Context, group, target string) error {
	client, err := e.api()
	if err != nil {
		return err
	}
	if err := client.Select(ctx, group, target); err != nil {
		return e.redactor.Err(err)
	}
	e.bus.Publish(engine.Event{Kind: engine.EventGroup,
		Group: &engine.GroupStatus{Name: group, Selected: target}})
	return nil
}

// Delay measures one proxy through the engine.
func (e *Engine) Delay(ctx context.Context, name, testURL string, timeout time.Duration) (time.Duration, error) {
	client, err := e.api()
	if err != nil {
		return 0, err
	}
	if testURL == "" {
		testURL = e.cfg.ProbeURL
	}
	if timeout <= 0 {
		timeout = 5 * time.Second
	}
	duration, derr := client.Delay(ctx, name, testURL, timeout)
	return duration, e.redactor.Err(derr)
}

// Counters returns the traffic counters of the running session. When the
// controller is briefly unreachable the last known value is returned together
// with the error, so the interface can keep its chart instead of dropping to
// zero.
func (e *Engine) Counters(ctx context.Context) (engine.Counters, error) {
	client, err := e.api()
	if err != nil {
		return engine.Counters{}, err
	}
	counters, cerr := client.Counters(ctx)
	e.mu.Lock()
	if cerr == nil {
		e.counters = counters
	}
	cached := e.counters
	e.mu.Unlock()
	if cerr != nil {
		return cached, e.redactor.Err(cerr)
	}
	return counters, nil
}

// api returns the client of the running engine.
func (e *Engine) api() (*Client, error) {
	e.mu.Lock()
	defer e.mu.Unlock()
	if e.client == nil || e.proc == nil || e.proc.Exited() {
		return nil, errors.New("mihomo: engine is not running")
	}
	return e.client, nil
}

// setState records and announces a lifecycle change.
func (e *Engine) setState(state engine.State) {
	e.mu.Lock()
	changed := e.state != state
	e.state = state
	e.mu.Unlock()
	if changed {
		e.bus.Publish(engine.Event{Kind: engine.EventState, State: state})
	}
}
