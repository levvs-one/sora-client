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
	"path/filepath"
	"slices"
	"strconv"
	"strings"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
)

// Connections models GET /connections, the polled HTTP source for traffic
// counters.
type Connections struct {
	DownloadTotal uint64       `json:"downloadTotal"`
	UploadTotal   uint64       `json:"uploadTotal"`
	Memory        uint64       `json:"memory"`
	Connections   []connection `json:"connections"`
}

// connection is one entry of GET /connections, in the shape both mihomo and
// sing-box answer with.
type connection struct {
	ID       string    `json:"id"`
	Download uint64    `json:"download"`
	Upload   uint64    `json:"upload"`
	Start    time.Time `json:"start"`
	Chains   []string  `json:"chains"`
	Rule     string    `json:"rule"`
	Payload  string    `json:"rulePayload"`
	Metadata struct {
		Network         string `json:"network"`
		Host            string `json:"host"`
		SniffHost       string `json:"sniffHost"`
		DestinationIP   string `json:"destinationIP"`
		DestinationPort string `json:"destinationPort"`
		Process         string `json:"process"`
		ProcessPath     string `json:"processPath"`
	} `json:"metadata"`
}

// ListConnections reads the live connections.
func (c *Client) ListConnections(ctx context.Context) ([]engine.Connection, error) {
	var raw Connections
	if err := c.call(ctx, http.MethodGet, "/connections", nil, &raw); err != nil {
		return nil, err
	}
	out := make([]engine.Connection, 0, len(raw.Connections))
	for _, in := range raw.Connections {
		m := in.Metadata
		host := firstOf(m.Host, m.SniffHost, m.DestinationIP)
		port, _ := strconv.ParseUint(m.DestinationPort, 10, 16)
		rule := in.Rule
		if in.Payload != "" {
			rule += " " + in.Payload
		}
		// Reverse the engine's outbound-to-group chain into the
		// client-facing group-to-outbound order.
		chain := slices.Clone(in.Chains)
		slices.Reverse(chain)
		out = append(out, engine.Connection{
			ID: in.ID, Network: m.Network, Host: host, Port: uint16(port),
			Process: firstOf(m.Process, filepath.Base(m.ProcessPath)), Rule: rule, Chain: chain,
			Upload: in.Upload, Download: in.Download, Start: in.Start,
		})
	}
	return out, nil
}

// CloseConnection drops one live connection.
func (c *Client) CloseConnection(ctx context.Context, id string) error {
	return c.call(ctx, http.MethodDelete, "/connections/"+url.PathEscape(id), nil, nil)
}

func firstOf(values ...string) string {
	for _, v := range values {
		if v != "" && v != "." {
			return v
		}
	}
	return ""
}

// ReloadConfig loads a config file inside the engine home. force=true replaces
// mihomo's live configuration.
func (c *Client) ReloadConfig(ctx context.Context, path string) error {
	return c.call(ctx, http.MethodPut, "/configs?force=true", map[string]string{"path": path}, nil)
}

// ReloadPayload applies inline configuration without keeping credentials on
// disk.
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

// CloseConnections drops all flows, preventing old connections from retaining a
// previous outbound after a switch.
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

// call performs a controller request with an optional JSON body and response
// destination. It excludes the secret from errors, strips URL credentials, and
// bounds response bodies.
func (c *Client) call(ctx context.Context, method, path string, body any, out any) error {
	var reader io.Reader
	if body != nil {
		raw, err := json.Marshal(body)
		if err != nil {
			return fmt.Errorf("clashapi: encode request: %w", err)
		}
		reader = bytes.NewReader(raw)
	}
	endpoint := "http://" + c.host + path
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

// snippet limits engine output to one line to prevent credentials from spanning
// log lines.
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
