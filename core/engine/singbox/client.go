// Package singbox runs sing-box as a supervised child process and implements
// engine.Engine on top of its HTTP REST API (compatible with Clash API).
package singbox

import (
	"context"
	"encoding/json"
	"io"
	"net"
	"net/http"
	"net/url"
	"strconv"
	"strings"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/errs"
)

// Client talks to the sing-box REST API (Clash-compatible).
type Client struct {
	baseURL    *url.URL
	httpClient *http.Client
	secret     string
}

// NewClient builds a controller client. timeout bounds one request.
func NewClient(controllerAddr, secret string, timeout time.Duration) (*Client, error) {
	u, err := url.Parse("http://" + controllerAddr)
	if err != nil {
		return nil, errs.Wrap(err, errs.CodeInternal, errs.KeyEngineStartFailed)
	}
	return &Client{
		baseURL: u,
		secret:  secret,
		httpClient: &http.Client{
			Timeout: timeout,
			Transport: &http.Transport{
				DialContext: (&net.Dialer{Timeout: timeout}).DialContext,
			},
		},
	}, nil
}

func (c *Client) do(ctx context.Context, method, path string, body any) ([]byte, error) {
	var r io.Reader
	if body != nil {
		data, err := json.Marshal(body)
		if err != nil {
			return nil, errs.Wrap(err, errs.CodeInternal, errs.KeyEngineStartFailed)
		}
		r = strings.NewReader(string(data))
	}
	req, err := http.NewRequestWithContext(ctx, method, c.baseURL.ResolveReference(&url.URL{Path: path}).String(), r)
	if err != nil {
		return nil, errs.Wrap(err, errs.CodeInternal, errs.KeyEngineStartFailed)
	}
	req.Header.Set("Content-Type", "application/json")
	if c.secret != "" {
		req.Header.Set("Authorization", "Bearer "+c.secret)
	}
	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, errs.Wrap(err, errs.CodeUnavailable, errs.KeyEngineStartFailed)
	}
	defer resp.Body.Close()
	data, _ := io.ReadAll(resp.Body)
	if resp.StatusCode >= 400 {
		return nil, errs.Newf(errs.CodeInternal, errs.KeyEngineStartFailed,
			"sing-box API %s %s: %d %s", method, path, resp.StatusCode, string(data))
	}
	return data, nil
}

// GetProxies returns the list of proxies and their state.
func (c *Client) GetProxies(ctx context.Context) (map[string]interface{}, error) {
	data, err := c.do(ctx, "GET", "/proxies", nil)
	if err != nil {
		return nil, err
	}
	var result map[string]interface{}
	if err := json.Unmarshal(data, &result); err != nil {
		return nil, errs.Wrap(err, errs.CodeInternal, errs.KeyEngineStartFailed)
	}
	return result, nil
}

// SelectProxy selects a proxy in a selector/urltest group.
func (c *Client) SelectProxy(ctx context.Context, group, proxy string) error {
	_, err := c.do(ctx, "PUT", "/proxies/"+url.PathEscape(group), map[string]string{"name": proxy})
	return err
}

// Delay tests a proxy's latency to a URL.
func (c *Client) Delay(ctx context.Context, proxy, testURL string, timeout time.Duration) (time.Duration, error) {
	ctx, cancel := context.WithTimeout(ctx, timeout)
	defer cancel()
	data, err := c.do(ctx, "GET", "/proxies/"+url.PathEscape(proxy)+"/delay?url="+url.QueryEscape(testURL)+"&timeout="+strconv.Itoa(int(timeout.Milliseconds())), nil)
	if err != nil {
		return 0, err
	}
	var result struct {
		Delay int `json:"delay"`
	}
	if err := json.Unmarshal(data, &result); err != nil {
		return 0, errs.Wrap(err, errs.CodeInternal, errs.KeyEngineStartFailed)
	}
	return time.Duration(result.Delay) * time.Millisecond, nil
}

// ReloadPayload hot-reloads the configuration.
func (c *Client) ReloadPayload(ctx context.Context, jsonConfig string) error {
	_, err := c.do(ctx, "PUT", "/configs", map[string]string{"payload": jsonConfig})
	return err
}

// GetConfigs returns the current configuration.
func (c *Client) GetConfigs(ctx context.Context) (string, error) {
	data, err := c.do(ctx, "GET", "/configs", nil)
	if err != nil {
		return "", err
	}
	var result struct {
		Payload string `json:"payload"`
	}
	if err := json.Unmarshal(data, &result); err != nil {
		return "", errs.Wrap(err, errs.CodeInternal, errs.KeyEngineStartFailed)
	}
	return result.Payload, nil
}

// GetVersion returns the sing-box version.
func (c *Client) GetVersion(ctx context.Context) (string, error) {
	data, err := c.do(ctx, "GET", "/version", nil)
	if err != nil {
		return "", err
	}
	var result struct {
		Version string `json:"version"`
	}
	if err := json.Unmarshal(data, &result); err != nil {
		return "", err
	}
	return result.Version, nil
}

// GetConnections returns active connections.
func (c *Client) GetConnections(ctx context.Context) ([]map[string]interface{}, error) {
	data, err := c.do(ctx, "GET", "/connections", nil)
	if err != nil {
		return nil, err
	}
	var result []map[string]interface{}
	if err := json.Unmarshal(data, &result); err != nil {
		return nil, errs.Wrap(err, errs.CodeInternal, errs.KeyEngineStartFailed)
	}
	return result, nil
}

// GetTraffic returns traffic statistics.
func (c *Client) GetTraffic(ctx context.Context) (map[string]engine.Counters, error) {
	data, err := c.do(ctx, "GET", "/traffic", nil)
	if err != nil {
		return nil, err
	}
	var raw map[string]map[string]interface{}
	if err := json.Unmarshal(data, &raw); err != nil {
		return nil, errs.Wrap(err, errs.CodeInternal, errs.KeyEngineStartFailed)
	}
	result := make(map[string]engine.Counters, len(raw))
	for tag, t := range raw {
		result[tag] = engine.Counters{
			BytesUp:   uint64(t["up"].(float64)),
			BytesDown: uint64(t["down"].(float64)),
		}
	}
	return result, nil
}
