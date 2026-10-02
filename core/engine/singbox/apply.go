// Package singbox runs sing-box as a supervised child process and implements
// engine.Engine on top of its HTTP REST API (compatible with Clash API).
package singbox

import (
	"context"
	"encoding/hex"
	"fmt"
	"math/rand"
	"net"
	"strconv"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/errs"
)

func (e *Engine) Groups(ctx context.Context) ([]engine.GroupStatus, error) {
	if e.client == nil {
		return nil, nil
	}
	proxies, err := e.client.GetProxies(ctx)
	if err != nil {
		return nil, err
	}
	var groups []engine.GroupStatus
	for name, info := range proxies {
		if m, ok := info.(map[string]interface{}); ok {
			if m["type"] == "Selector" || m["type"] == "URLTest" {
				now := ""
				if v, ok := m["now"].(string); ok {
					now = v
				}
				var options []string
				if opts, ok := m["all"].([]interface{}); ok {
					for _, o := range opts {
						options = append(options, fmt.Sprintf("%v", o))
					}
				}
				groups = append(groups, engine.GroupStatus{
					Name:     name,
					Selected: now,
					All:      options,
				})
			}
		}
	}
	return groups, nil
}

func (e *Engine) Select(ctx context.Context, group, target string) error {
	if e.client == nil {
		return errs.Newf(errs.CodeFailedPrecondition, errs.KeyEngineStartFailed,
			"singbox: no controller client")
	}
	return e.client.SelectProxy(ctx, group, target)
}

func (e *Engine) Delay(ctx context.Context, name, url string, timeout time.Duration) (time.Duration, error) {
	if e.client == nil {
		return 0, errs.Newf(errs.CodeFailedPrecondition, errs.KeyEngineStartFailed,
			"singbox: no controller client")
	}
	return e.client.Delay(ctx, name, url, timeout)
}

func (e *Engine) Counters(ctx context.Context) (engine.Counters, error) {
	if e.client == nil {
		return engine.Counters{}, nil
	}
	traffic, err := e.client.GetTraffic(ctx)
	if err != nil {
		return engine.Counters{}, err
	}
	var total engine.Counters
	for _, t := range traffic {
		total.BytesUp += t.BytesUp
		total.BytesDown += t.BytesDown
	}
	return total, nil
}

func (e *Engine) start(ctx context.Context, p *engine.Plan) error {
	rt := Runtime{
		HomeDir:        e.cfg.HomeDir,
		ControllerAddr: "127.0.0.1:" + strconv.Itoa(e.reservePort()),
		Secret:         randomSecret(),
		MixedPort:      e.cfg.MixedPort,
		ProbeURL:       e.cfg.ProbeURL,
		Secrets:        make(map[string][]byte),
	}
	jsonConfig, err := Render(p, rt)
	if err != nil {
		return err
	}
	if err := TestConfig(ctx, e.cfg.Binary, e.cfg.HomeDir, jsonConfig); err != nil {
		return err
	}
	e.proc = newProcess(e.cfg.Binary, e.cfg.HomeDir, rt, jsonConfig)
	if err := e.proc.start(ctx); err != nil {
		return err
	}
	client, err := NewClient(rt.ControllerAddr, rt.Secret, 5*time.Second)
	if err != nil {
		return err
	}
	if err := waitReady(ctx, client, 30*time.Second); err != nil {
		_ = e.proc.stop(context.Background(), 5*time.Second)
		return err
	}
	e.client = client
	e.bus.Publish(engine.Event{Kind: engine.EventState, State: engine.StateRunning, Message: "sing-box started"})
	return nil
}

func (e *Engine) hotApply(ctx context.Context, p *engine.Plan) error {
	rt := Runtime{
		HomeDir:        e.cfg.HomeDir,
		ControllerAddr: e.client.baseURL.Host,
		Secret:         e.client.secret,
		MixedPort:      e.cfg.MixedPort,
		ProbeURL:       e.cfg.ProbeURL,
		Secrets:        make(map[string][]byte),
	}
	jsonConfig, err := Render(p, rt)
	if err != nil {
		return err
	}
	return e.client.ReloadPayload(ctx, jsonConfig)
}

func (e *Engine) reservePort() int {
	ln, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		return 9090
	}
	port := ln.Addr().(*net.TCPAddr).Port
	_ = ln.Close()
	return port
}

func randomSecret() string {
	b := make([]byte, 16)
	if _, err := rand.Read(b); err != nil {
		return "singbox-secret"
	}
	return hex.EncodeToString(b)
}

func waitReady(ctx context.Context, client *Client, timeout time.Duration) error {
	deadline := time.Now().Add(timeout)
	for time.Now().Before(deadline) {
		if _, err := client.GetVersion(ctx); err == nil {
			return nil
		}
		time.Sleep(200 * time.Millisecond)
	}
	return fmt.Errorf("sing-box controller not ready after %s", timeout)
}
