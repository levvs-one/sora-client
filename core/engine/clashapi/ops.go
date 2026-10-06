package clashapi

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net"
	"net/http"
	"net/url"
	"strings"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
)

// Connections is the answer of GET /connections, the plain HTTP source of the
// traffic counters. The websocket stream stays a later optimization: polling
// this endpoint is cheap and needs no extra dependency.
type Connections struct {
	DownloadTotal uint64 `json:"downloadTotal"`
	UploadTotal   uint64 `json:"uploadTotal"`
	Memory        uint64 `json:"memory"`
	Connections   []struct {
		ID       string `json:"id"`
		Download uint64 `json:"download"`
		Upload   uint64 `json:"upload"`
	} `json:"connections"`
}

// ReloadConfig points a running engine at a config file inside its home
// directory. force=true is what makes mihomo replace the live configuration.
func (c *Client) ReloadConfig(ctx context.Context, path string) error {
	return c.call(ctx, http.MethodPut, "/configs?force=true", map[string]string{"path": path}, nil)
}

// ReloadPayload applies a configuration given inline, so Sora does not have to
// keep a file with credentials on disk.
func (c *Client) ReloadPayload(ctx context.Context, yamlText string) error {
	return c.call(ctx, http.MethodPut, "/configs?force=true", map[string]string{"payload": yamlText}, nil)
}

// Counters reads traffic counters and the number of live connections.
func (c *Client) Counters(ctx context.Context) (engine.Counters, error) {
	var raw Connections
	if err := c.call(ctx, http.MethodGet, "/connections", nil, &raw); err != nil {
		return engine.Counters{}, err
	}
	return engine.Counters{
		BytesUp:           raw.UploadTotal,
		BytesDown:         raw.DownloadTotal,
		ActiveConnections: len(raw.Connections),
		MemoryBytes:       raw.Memory,
		At:                time.Now(),
	}, nil
}

// CloseConnections drops every live connection, for example right after a
// server switch so that no stale flow keeps using the old outbound.
func (c *Client) CloseConnections(ctx context.Context) error {
	return c.call(ctx, http.MethodDelete, "/connections", nil, nil)
}

// FlushDNS clears the resolver cache, including the fake-ip table.
func (c *Client) FlushDNS(ctx context.Context) error {
	if err := c.call(ctx, http.MethodPost, "/cache/dns/flush", nil, nil); err != nil {
		return err
	}
	return c.call(ctx, http.MethodPost, "/cache/fakeip/flush", nil, nil)
}

// UpdateProvider makes the engine re-download one subscription provider.
func (c *Client) UpdateProvider(ctx context.Context, name string) error {
	return c.call(ctx, http.MethodPut, "/providers/proxies/"+url.PathEscape(name), nil, nil)
}

// call performs one controller request. body is nil, a map or a struct that is
// marshalled as JSON; out is nil or a pointer to unmarshal into.
//
// The secret never appears in an error: the URL is rebuilt without query
// credentials and the response body is capped before it is read.
func (c *Client) call(ctx context.Context, method, path string, body any, out any) error {
	var reader io.Reader
	if body != nil {
		raw, err := json.Marshal(body)
		if err != nil {
			return fmt.Errorf("clashapi: encode request: %w", err)
		}
		reader = bytes.NewReader(raw)
	}
	endpoint := "http://" + c.addr + path
	req, err := http.NewRequestWithContext(ctx, method, endpoint, reader)
	if err != nil {
		return fmt.Errorf("clashapi: build request: %w", err)
	}
	req.Header.Set("Authorization", "Bearer "+c.secret)
	req.Header.Set("Accept", "application/json")
	if body != nil {
		req.Header.Set("Content-Type", "application/json")
	}

	resp, err := c.http.Do(req)
	if err != nil {
		if errors.Is(err, context.DeadlineExceeded) || errors.Is(err, context.Canceled) {
			return err
		}
		var netErr net.Error
		if errors.As(err, &netErr) || isRefused(err) {
			return fmt.Errorf("%w: %s: %w", ErrUnreachable, redactURL(endpoint), err)
		}
		return fmt.Errorf("clashapi: controller request: %w", err)
	}
	defer func() {
		_, _ = io.Copy(io.Discard, io.LimitReader(resp.Body, 4<<10))
		_ = resp.Body.Close()
	}()

	payload, err := io.ReadAll(io.LimitReader(resp.Body, MaxResponse))
	if err != nil {
		return fmt.Errorf("clashapi: read controller response: %w", err)
	}
	switch {
	case resp.StatusCode == http.StatusNoContent || resp.StatusCode == http.StatusOK && out == nil:
		return nil
	case resp.StatusCode == http.StatusUnauthorized || resp.StatusCode == http.StatusForbidden:
		return fmt.Errorf("%w: %s %s", ErrUnauthorized, method, redactURL(endpoint))
	case resp.StatusCode == http.StatusNotFound:
		return fmt.Errorf("%w: %s %s", ErrNotFound, method, redactURL(endpoint))
	case resp.StatusCode >= 400:
		return fmt.Errorf("clashapi: %s %s answered %d: %s", method, redactURL(endpoint), resp.StatusCode, snippet(payload))
	}
	if out == nil {
		return nil
	}
	if err := json.Unmarshal(payload, out); err != nil {
		return fmt.Errorf("clashapi: decode controller response: %w", err)
	}
	return nil
}

func isRefused(err error) bool {
	var syscallErr *net.OpError
	return errors.As(err, &syscallErr)
}

// snippet keeps at most one line of engine output, so a message that carries a
// credential cannot be spread over a log line.
func snippet(b []byte) string {
	s := string(b)
	if i := strings.IndexAny(s, "\r\n"); i >= 0 {
		s = s[:i]
	}
	if len(s) > 240 {
		s = s[:240]
	}
	return s
}

// redactURL removes any user info from a URL before it reaches an error.
func redactURL(raw string) string {
	u, err := url.Parse(raw)
	if err != nil {
		return "<unparsable url>"
	}
	u.User = nil
	return u.String()
}
