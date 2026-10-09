package supervise

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net"
	"net/http"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/logs"
)

// The test executable runs as "<test binary> -sora-fake-engine run|check" with
// configuration on stdin, covering supervision without installed engines.
const fakeFlag = "-sora-fake-engine"

type fakeConfig struct {
	Addr string `json:"addr"`
	// CrashAfter makes the fake exit with an error once it has served for
	// this long.
	CrashAfter   time.Duration `json:"crash_after"`
	CleanExit    bool          `json:"clean_exit"`
	CrashMessage string        `json:"crash_message"`
	Reject       bool          `json:"reject"`
}

func TestMain(m *testing.M) {
	if len(os.Args) > 2 && os.Args[1] == fakeFlag {
		os.Exit(fakeEngine(os.Args[2]))
	}
	os.Exit(m.Run())
}

func fakeEngine(mode string) int {
	raw, err := io.ReadAll(os.Stdin)
	if err != nil {
		return 3
	}
	var cfg fakeConfig
	if err := json.Unmarshal(raw, &cfg); err != nil {
		_, _ = os.Stderr.WriteString("fake: config is not JSON\n")
		return 2
	}
	if cfg.Reject {
		_, _ = os.Stderr.WriteString("fake: rejected key\n")
		return 1
	}
	if mode == "check" {
		return 0
	}
	var lc net.ListenConfig
	listener, err := lc.Listen(context.Background(), "tcp", cfg.Addr)
	if err != nil {
		return 4
	}
	go func() {
		_ = http.Serve(listener, http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
			_, _ = w.Write([]byte("9.8.7"))
		}))
	}()
	if cfg.CrashAfter > 0 {
		time.Sleep(cfg.CrashAfter)
		message := cfg.CrashMessage
		if message == "" {
			message = "fake: crashed"
		}
		_, _ = os.Stderr.WriteString(message)
		if cfg.CleanExit {
			return 0
		}
		return 1
	}
	select {}
}

type fakeDriver struct{ cfg fakeConfig }

func (fakeDriver) Kind() engine.Kind { return engine.KindMihomo }

func (d fakeDriver) Render(_ *engine.Plan, rt Runtime) ([]byte, error) {
	cfg := d.cfg
	cfg.Addr = rt.ControlAddr
	return json.Marshal(cfg)
}

func (fakeDriver) RunArgs(Runtime) []string   { return []string{fakeFlag, "run"} }
func (fakeDriver) CheckArgs(Runtime) []string { return []string{fakeFlag, "check"} }

func (fakeDriver) Handshake(ctx context.Context, rt Runtime) (string, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, "http://"+rt.ControlAddr+"/", nil)
	if err != nil {
		return "", err
	}
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return "", err
	}
	defer func() { _ = resp.Body.Close() }()
	body, err := io.ReadAll(resp.Body)
	return string(body), err
}

func (fakeDriver) Reload(context.Context, Runtime, []byte) error { return ErrReloadUnsupported }

func plan() *engine.Plan {
	return &engine.Plan{
		SessionID: "fake",
		Outbounds: []engine.Outbound{{ID: "out", Protocol: engine.ProtocolDirect}},
		Rules:     []engine.Rule{{Type: engine.RuleMatchAll, Target: "out"}},
	}
}

func newFake(t *testing.T, cfg fakeConfig, budget int) *Supervisor {
	t.Helper()
	sup, err := New(Config{
		Binary:        Binary{Kind: engine.KindMihomo, Path: os.Args[0]},
		HomeDir:       t.TempDir(),
		StartTimeout:  5 * time.Second,
		StopGrace:     time.Second,
		RestartBudget: budget,
		RestartWindow: time.Minute,
	}, fakeDriver{cfg: cfg})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = sup.Close() })
	return sup
}

func waitState(t *testing.T, sup *Supervisor, want engine.State, within time.Duration) {
	t.Helper()
	deadline := time.Now().Add(within)
	for time.Now().Before(deadline) {
		if sup.State() == want {
			return
		}
		time.Sleep(20 * time.Millisecond)
	}
	t.Fatalf("state = %s, want %s", sup.State(), want)
}

func TestApplyStartsAndAdoptsTheReportedVersion(t *testing.T) {
	sup := newFake(t, fakeConfig{}, 1)
	if err := sup.Apply(context.Background(), plan()); err != nil {
		t.Fatalf("Apply: %v", err)
	}
	if sup.State() != engine.StateRunning || sup.Version().String() != "9.8.7" {
		t.Fatalf("state %s, version %q", sup.State(), sup.Version())
	}
	if _, err := sup.Running(); err != nil {
		t.Fatal(err)
	}
	// A second plan restarts an engine that cannot reload and keeps
	// running.
	if err := sup.Apply(context.Background(), plan()); err != nil {
		t.Fatalf("second Apply: %v", err)
	}
	if err := sup.Stop(context.Background()); err != nil {
		t.Fatal(err)
	}
	if _, err := sup.Running(); !errors.Is(err, ErrNotRunning) {
		t.Fatalf("Running after Stop = %v", err)
	}
}

func TestRejectedConfigurationNeverStartsTheEngine(t *testing.T) {
	sup := newFake(t, fakeConfig{Reject: true}, 1)
	err := sup.Apply(context.Background(), plan())
	if err == nil || !strings.Contains(err.Error(), "rejected key") {
		t.Fatalf("Apply = %v, want the validator's own explanation", err)
	}
	if sup.State() != engine.StateFailed {
		t.Fatalf("state = %s", sup.State())
	}
}

func TestCrashRestartsInsideTheBudgetThenFails(t *testing.T) {
	sup := newFake(t, fakeConfig{CrashAfter: 300 * time.Millisecond}, 1)
	events, unsubscribe := sup.Events().Subscribe()
	defer unsubscribe()
	if err := sup.Apply(context.Background(), plan()); err != nil {
		t.Fatalf("Apply: %v", err)
	}
	// One restart is allowed; the second crash exhausts the budget.
	waitState(t, sup, engine.StateFailed, 10*time.Second)
	var restarted, fatal bool
	for !fatal {
		select {
		case ev := <-events:
			restarted = restarted || ev.Kind == engine.EventRestart
			fatal = ev.Kind == engine.EventFatal
		case <-time.After(time.Second):
			t.Fatalf("no fatal event (restarted=%v)", restarted)
		}
	}
	if !restarted {
		t.Fatal("the engine must be restarted once before the budget runs out")
	}
}

func TestStopAfterCloseIsSafe(t *testing.T) {
	sup := newFake(t, fakeConfig{}, 1)
	if err := sup.Apply(context.Background(), plan()); err != nil {
		t.Fatal(err)
	}
	if err := sup.Close(); err != nil {
		t.Fatal(err)
	}
	if err := sup.Stop(context.Background()); err != nil {
		t.Fatal(err)
	}
}

func TestUnexpectedExitsReachLogCenter(t *testing.T) {
	for _, clean := range []bool{false, true} {
		t.Run(fmt.Sprint(clean), func(t *testing.T) {
			sup := newFake(t, fakeConfig{CrashAfter: 300 * time.Millisecond, CleanExit: clean, CrashMessage: "failure with secret-value"}, 1)
			sup.cfg.Logs = logs.New(logs.Settings{CaptureLevel: logs.LevelWarning, RecordDestinations: true})
			sup.redactor.Add("secret-value")
			if err := sup.Apply(context.Background(), plan()); err != nil {
				t.Fatal(err)
			}
			waitState(t, sup, engine.StateFailed, 10*time.Second)
			entries := sup.cfg.Logs.Query(logs.Filter{}, 0, 0).Entries
			var status, tail bool
			for _, entry := range entries {
				if strings.Contains(entry.Message, "secret-value") {
					t.Fatal("secret reached the log store")
				}
				if entry.Level != logs.LevelError || entry.Source != "mihomo" {
					t.Fatalf("entry = %+v", entry)
				}
				status = status || strings.Contains(entry.Message, "engine exited unexpectedly:")
				tail = tail || strings.Contains(entry.Message, "failure with [masked]")
			}
			if !status || !tail {
				t.Fatalf("missing status or output: %+v", entries)
			}
		})
	}
}

func TestRequestedStopDoesNotLogAnUnexpectedExit(t *testing.T) {
	sup := newFake(t, fakeConfig{}, 1)
	sup.cfg.Logs = logs.New(logs.DefaultSettings())
	if err := sup.Apply(context.Background(), plan()); err != nil {
		t.Fatal(err)
	}
	if err := sup.Stop(context.Background()); err != nil {
		t.Fatal(err)
	}
	if entries := sup.cfg.Logs.Query(logs.Filter{MinLevel: logs.LevelWarning}, 0, 0).Entries; len(entries) != 0 {
		t.Fatalf("requested stop logged errors: %+v", entries)
	}
}

type routingDriver struct {
	fakeDriver
	routes, removals int
}

func (d *routingDriver) Route(context.Context, *engine.Plan) error { d.routes++; return nil }
func (d *routingDriver) Unroute(context.Context) error             { d.removals++; return nil }

func TestOnlyTunOwnerRemovesRouting(t *testing.T) {
	for _, tun := range []bool{false, true} {
		t.Run(fmt.Sprint(tun), func(t *testing.T) {
			sup := newFake(t, fakeConfig{}, 1)
			driver := &routingDriver{}
			sup.driver = driver
			p := plan()
			p.Tun.Enabled = tun
			if err := sup.Apply(context.Background(), p); err != nil {
				t.Fatal(err)
			}
			if err := sup.Stop(context.Background()); err != nil {
				t.Fatal(err)
			}
			want := 0
			if tun {
				want = 1
			}
			if driver.routes != want || driver.removals != want {
				t.Fatalf("routes=%d removals=%d, want %d", driver.routes, driver.removals, want)
			}
			if err := sup.Stop(context.Background()); err != nil {
				t.Fatal(err)
			}
			if driver.removals != want {
				t.Fatal("routing removed twice")
			}
		})
	}
}
