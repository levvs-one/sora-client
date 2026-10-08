// Package clashapi implements the Clash-compatible API used by mihomo and
// sing-box. Each client belongs to one engine run, whose controller address and
// secret change at startup.
package clashapi

import (
	"context"
	"errors"
	"fmt"
	"net"
	"net/http"
	"net/url"
	"sort"
	"strconv"
	"strings"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
)

// MaxResponse limits controller bodies to prevent an unresponsive or hostile
// engine from exhausting memory.
const MaxResponse = 8 << 20

// Controller errors distinct from transport errors.
var (
	ErrUnauthorized = errors.New("clashapi: controller rejected the secret")
	ErrNotFound     = errors.New("clashapi: controller has no such object")
	ErrNotMeta      = errors.New("clashapi: controller is not a Clash Meta compatible core")
	ErrUnreachable  = errors.New("clashapi: controller is not reachable")
	ErrDelayFailed  = errors.New("clashapi: latency test failed")
)

// Client talks to one engine controller.
type Client struct {
	// host supplies request URL authority; socket and pipe dialers select
	// the actual destination.
	host   string
	secret string
	http   *http.Client
}

// Controller address schemes besides a plain host:port.
const (
	schemeUnix = "unix:"
	schemePipe = "pipe:"
)

// NewClient accepts host:port, unix:<path>, or pipe:<name>. timeout bounds each
// request, not the client lifetime.
func NewClient(addr, secret string, timeout time.Duration) *Client {
	if timeout <= 0 {
		timeout = 10 * time.Second
	}
	dialer := &net.Dialer{Timeout: 3 * time.Second, KeepAlive: 15 * time.Second}
	dial := dialer.DialContext
	host := addr
	switch {
	case strings.HasPrefix(addr, schemeUnix):
		path := strings.TrimPrefix(addr, schemeUnix)
		dial = func(ctx context.Context, _, _ string) (net.Conn, error) { return dialer.DialContext(ctx, "unix", path) }
		host = "controller"
	case strings.HasPrefix(addr, schemePipe):
		pipe := strings.TrimPrefix(addr, schemePipe)
		dial = func(ctx context.Context, _, _ string) (net.Conn, error) { return dialPipe(ctx, pipe) }
		host = "controller"
	}
	return &Client{
		host:   host,
		secret: secret,
		http: &http.Client{
			Timeout:   timeout,
			Transport: &http.Transport{DialContext: dial, MaxIdleConnsPerHost: 4},
		},
	}
}

// VersionInfo is the answer of GET /version.
type VersionInfo struct {
	Meta    bool   `json:"meta"`
	Version string `json:"version"`
}

// Version performs the controller handshake. A false Meta flag identifies
// legacy Clash rather than the required mihomo binary.
func (c *Client) Version(ctx context.Context) (VersionInfo, error) {
	var out VersionInfo
	if err := c.call(ctx, http.MethodGet, "/version", nil, &out); err != nil {
		return VersionInfo{}, err
	}
	if !out.Meta {
		return out, ErrNotMeta
	}
	return out, nil
}

// Proxy is one proxy or group as the controller reports it.
type Proxy struct {
	Name          string   `json:"name"`
	Type          string   `json:"type"`
	UDP           bool     `json:"udp"`
	Now           string   `json:"now"`
	All           []string `json:"all"`
	TestURL       string   `json:"testUrl"`
	Hidden        bool     `json:"hidden"`
	Icon          string   `json:"icon"`
	DialerProxy   string   `json:"dialer-proxy"`
	ProviderName  string   `json:"providerName"`
	EmptyFallback string   `json:"emptyFallback"`
	History       []Delay  `json:"history"`
	// Alive and Extra come from mihomo only. Extra holds the checks made
	// against other URLs, such as the test URL of a group.
	Alive *bool `json:"alive"`
	Extra map[string]struct {
		Alive   *bool   `json:"alive"`
		History []Delay `json:"history"`
	} `json:"extra"`
}

// Delay is one check of a proxy.
type Delay struct {
	Delay int `json:"delay"`
}

// lastDelay is the latest check against url, or against the default URL when
// url has none. Zero means the proxy did not answer or was never checked.
// mihomo also writes zero for an answer under a millisecond and tells the two
// apart by alive; such an answer counts as one millisecond here.
func (p Proxy) lastDelay(url string) int {
	alive, history := p.Alive, p.History
	if checked, ok := p.Extra[url]; ok {
		alive, history = checked.Alive, checked.History
	}
	if len(history) == 0 {
		return 0
	}
	delay := history[len(history)-1].Delay
	if alive == nil {
		return delay
	}
	if !*alive {
		return 0
	}
	return max(delay, 1)
}

// Proxies lists every proxy and every group.
func (c *Client) Proxies(ctx context.Context) (map[string]Proxy, error) {
	var raw struct {
		Proxies map[string]Proxy `json:"proxies"`
	}
	if err := c.call(ctx, http.MethodGet, "/proxies", nil, &raw); err != nil {
		return nil, err
	}
	return raw.Proxies, nil
}

// Select pins one member of a selectable group.
func (c *Client) Select(ctx context.Context, group, target string) error {
	body := map[string]string{"name": target}
	return c.call(ctx, http.MethodPut, "/proxies/"+url.PathEscape(group), body, nil)
}

// Delay measures one proxy. The engine expects the probe budget in
// milliseconds and answers -1 for an unreachable proxy.
func (c *Client) Delay(ctx context.Context, name, testURL string, timeout time.Duration) (time.Duration, error) {
	if testURL == "" {
		testURL = engine.TestURLProduction
	}
	q := url.Values{}
	q.Set("url", testURL)
	q.Set("timeout", strconv.Itoa(int(timeout/time.Millisecond)))
	var out struct {
		Delay int `json:"delay"`
	}
	path := "/proxies/" + url.PathEscape(name) + "/delay?" + q.Encode()
	if err := c.call(ctx, http.MethodGet, path, nil, &out); err != nil {
		return 0, err
	}
	if out.Delay <= 0 {
		return 0, fmt.Errorf("%w: %s is unreachable", ErrDelayFailed, name)
	}
	return time.Duration(out.Delay) * time.Millisecond, nil
}

// groupTypes maps controller CamelCase names to contract names; configuration
// files use lowercase variants.
var groupTypes = map[string]engine.GroupType{
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

// Groups returns the selectable groups with their live state. GLOBAL is the
// controller's own synthetic group and is not part of any Sora plan.
func (c *Client) Groups(ctx context.Context) ([]engine.GroupStatus, error) {
	proxies, err := c.Proxies(ctx)
	if err != nil {
		return nil, err
	}
	out := make([]engine.GroupStatus, 0, len(proxies))
	for name, px := range proxies {
		kind, isGroup := groupTypes[px.Type]
		if !isGroup || name == "GLOBAL" {
			continue
		}
		status := engine.GroupStatus{
			Name: name, Type: kind, Selected: px.Now, All: px.All,
			Hidden: px.Hidden, Icon: px.Icon, TestURL: px.TestURL, Provider: px.ProviderName,
			LatencyMS: map[string]int{},
		}
		// A group's own history is the delay through its current member;
		// each member keeps its own.
		for _, member := range px.All {
			status.LatencyMS[member] = proxies[member].lastDelay(px.TestURL)
		}
		out = append(out, status)
	}
	sort.Slice(out, func(i, j int) bool { return out[i].Name < out[j].Name })
	return out, nil
}
