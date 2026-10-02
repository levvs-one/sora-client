package mihomo

import (
	"context"
	"errors"
	"fmt"
	"net"
	"net/http"
	"net/url"
	"strconv"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
)

// Controller errors the caller has to tell apart from transport noise.
var (
	ErrUnauthorized = errors.New("mihomo: controller rejected the secret")
	ErrNotFound     = errors.New("mihomo: controller has no such object")
	ErrNotMihomo    = errors.New("mihomo: controller is not a mihomo core")
	ErrUnreachable  = errors.New("mihomo: controller is not reachable")
	ErrDelayFailed  = errors.New("mihomo: latency test failed")
)

// Client talks to the mihomo external controller. One client belongs to one
// running engine: the address and the secret change with every start.
type Client struct {
	addr   string
	secret string
	http   *http.Client
}

// NewClient builds a controller client. timeout bounds one request, not the
// lifetime of the client.
func NewClient(addr, secret string, timeout time.Duration) *Client {
	if timeout <= 0 {
		timeout = 10 * time.Second
	}
	dialer := &net.Dialer{Timeout: 3 * time.Second, KeepAlive: 15 * time.Second}
	return &Client{
		addr:   addr,
		secret: secret,
		http: &http.Client{
			Timeout:   timeout,
			Transport: &http.Transport{DialContext: dialer.DialContext, MaxIdleConnsPerHost: 4},
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
		return out, ErrNotMihomo
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
