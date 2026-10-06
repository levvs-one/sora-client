package mihomo

import (
	"context"
	"regexp"
	"sync"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/clashapi"
	"github.com/levvs-one/sora-client/core/engine/supervise"
)

// Prober recognizes a mihomo build. "mihomo -v" prints, for example,
// "Mihomo Meta v1.19.32 linux amd64 with go1.26.8 Wed Sep 30 16:55:16 UTC 2026".
var Prober = supervise.Prober{
	Kind:    engine.KindMihomo,
	Name:    "mihomo",
	EnvVar:  "SORA_MIHOMO_BIN",
	Args:    []string{"-v"},
	Pattern: regexp.MustCompile(`(?i)^Mihomo(?:\s+Meta)?\s+v?(\d+\.\d+\.\d+[0-9A-Za-z.\-]*)\s+(\w+)\s+(\w+)`),
}

// Engine runs mihomo as a supervised child process and implements
// engine.Engine on top of its external controller.
type Engine struct {
	*supervise.Supervisor

	mu       sync.Mutex
	counters engine.Counters
}

// New builds an engine instance. Nothing is started: Apply does the work.
func New(cfg supervise.Config) (*Engine, error) {
	sup, err := supervise.New(cfg, driver{})
	if err != nil {
		return nil, err
	}
	return &Engine{Supervisor: sup}, nil
}

// driver is the mihomo grammar and command line. The configuration goes in on
// stdin: mihomo reads "-f -" as "read the configuration from standard input".
type driver struct{}

func (driver) Kind() engine.Kind { return engine.KindMihomo }

func (driver) Render(p *engine.Plan, rt supervise.Runtime) ([]byte, error) {
	text, err := Render(p, Runtime{
		HomeDir: rt.HomeDir, ControllerAddr: rt.ControlAddr, Secret: rt.Secret,
		MixedPort: rt.LocalPort, TestURL: rt.ProbeURL,
	})
	return []byte(text), err
}

func (driver) RunArgs(rt supervise.Runtime) []string {
	return []string{"-d", rt.HomeDir, "-f", "-", "-ext-ctl", rt.ControlAddr}
}

func (driver) CheckArgs(rt supervise.Runtime) []string {
	return []string{"-d", rt.HomeDir, "-f", "-", "-t"}
}

func (driver) Handshake(ctx context.Context, rt supervise.Runtime) (string, error) {
	info, err := client(rt).Version(ctx)
	return info.Version, err
}

// Reload replaces the live configuration through the controller, so the tunnel
// and the listeners are not torn down.
func (driver) Reload(ctx context.Context, rt supervise.Runtime, cfg []byte) error {
	return client(rt).ReloadPayload(ctx, string(cfg))
}

func client(rt supervise.Runtime) *clashapi.Client {
	return clashapi.NewClient(rt.ControlAddr, rt.Secret, 5*time.Second)
}

func (e *Engine) api() (*clashapi.Client, error) {
	rt, err := e.Running()
	if err != nil {
		return nil, err
	}
	return client(rt), nil
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
