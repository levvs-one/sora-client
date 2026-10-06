// Package clashapi is the client of the Clash compatible controller API that
// both mihomo (external-controller) and sing-box (experimental.clash_api)
// serve on the loopback interface. One client belongs to one running engine:
// the address and the secret change with every start.
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

// MaxResponse bounds one controller response body. Answers are small by
// contract; the cap stops a hung or hostile engine from exhausting memory.
const MaxResponse = 8 << 20

// Controller errors the caller has to tell apart from transport noise.
var (
	ErrUnauthorized = errors.New("clashapi: controller rejected the secret")
	ErrNotFound     = errors.New("clashapi: controller has no such object")
	ErrNotMeta      = errors.New("clashapi: controller is not a Clash Meta compatible core")
	ErrUnreachable  = errors.New("clashapi: controller is not reachable")
	ErrDelayFailed  = errors.New("clashapi: latency test failed")
)

// Client talks to one engine controller.
type Client struct {
	// host is what request URLs carry. Over a socket or a pipe it is a fixed
	// name, because the dialer, not the URL, decides where the request goes.
	host   string
	secret string
	http   *http.Client
}

// Controller address schemes besides a plain host:port.
const (
	schemeUnix = "unix:"
	schemePipe = "pipe:"
)

// NewClient builds a controller client. addr is host:port, "unix:" followed by
// a socket path, or "pipe:" followed by a Windows named pipe. timeout bounds
// one request, not the lifetime of the client.
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

// Version performs the handshake. The Meta flag is what separates mihomo from
// the dead Clash it descends from, so a false value means Sora is pointed at
// the wrong binary and every later call would fail in confusing ways.
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
	History       []struct {
		Name  string `json:"name"`
		Alive bool   `json:"alive"`
		Delay int    `json:"delay"`
	} `json:"history"`
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

// groupTypes maps the group type names the controller reports onto the names
// the Sora contract uses. The API answers in CamelCase while configuration
// files are written in lowercase, and both appear in the same conversation.
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
		for _, h := range px.History {
			status.LatencyMS[h.Name] = h.Delay
		}
		out = append(out, status)
	}
	sort.Slice(out, func(i, j int) bool { return out[i].Name < out[j].Name })
	return out, nil
}
