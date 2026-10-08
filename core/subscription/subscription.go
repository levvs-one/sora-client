// Package subscription fetches bearer-token references over HTTPS only. Every
// redirect is validated and counted; bodies are size-limited. Responses contain
// credentials and are never cached on disk.
package subscription

import (
	"context"
	"io"
	"net"
	"net/http"
	"net/netip"
	"net/url"
	"strings"
	"syscall"
	"time"

	"github.com/levvs-one/sora-client/core/errs"
)

// Default retrieval limits allow distant providers while bounding total fetch
// time to half a minute.
const (
	// DefaultTimeout bounds one retrieval, redirects included.
	DefaultTimeout = 30 * time.Second
	// MaxRedirects limits validated redirect hops carrying the bearer
	// reference.
	MaxRedirects = 5
	// MaxBodyBytes matches the import size limit, allowing accepted bodies
	// to reach parsing.
	MaxBodyBytes = 16 << 20
	// UserAgent identifies Sora when no override is set, allowing
	// provider-specific handling without browser impersonation.
	UserAgent = "sora-core/1 (+https://github.com/levvs-one/sora-client)"
	// MaxUserAgent bounds the User-Agent a subscription may set.
	MaxUserAgent = 256
)

// FetchOptions configures one subscription retrieval.
type FetchOptions struct {
	// UserAgent overrides the default because panels may choose
	// client-specific subscription formats.
	UserAgent string
}

// Result is one retrieved subscription.
type Result struct {
	Body []byte
	// Info contains provider response headers and leading body metadata.
	Info Info
}

// Options configures a fetcher.
type Options struct {
	// Timeout bounds one retrieval.
	Timeout time.Duration
	// MaxRedirects limits redirect hops carrying the bearer reference.
	MaxRedirects int
	// MaxBodyBytes is the largest body accepted.
	MaxBodyBytes int
	// HTTPClient performs requests. Nil verifies certificates and leaves
	// redirects to this package. Only tests may inject a client trusting a
	// local test server.
	HTTPClient *http.Client
}

// Fetcher retrieves subscription bodies.
type Fetcher struct {
	client       *http.Client
	timeout      time.Duration
	maxRedirects int
	maxBody      int
}

// New returns a fetcher with the defaults filled in.
func New(opts Options) *Fetcher {
	if opts.Timeout <= 0 {
		opts.Timeout = DefaultTimeout
	}
	if opts.MaxRedirects <= 0 {
		opts.MaxRedirects = MaxRedirects
	}
	if opts.MaxBodyBytes <= 0 {
		opts.MaxBodyBytes = MaxBodyBytes
	}
	client := opts.HTTPClient
	if client == nil {
		client = &http.Client{
			// Handle redirects here so every hop is validated and
			// counted.
			CheckRedirect: func(*http.Request, []*http.Request) error {
				return http.ErrUseLastResponse
			},
			Transport: &http.Transport{
				Proxy:                 http.ProxyFromEnvironment,
				DialContext:           dialChecked,
				ForceAttemptHTTP2:     true,
				MaxIdleConns:          8,
				IdleConnTimeout:       30 * time.Second,
				TLSHandshakeTimeout:   10 * time.Second,
				ExpectContinueTimeout: time.Second,
				ResponseHeaderTimeout: 20 * time.Second,
			},
		}
	}
	return &Fetcher{
		client:       client,
		timeout:      opts.Timeout,
		maxRedirects: opts.MaxRedirects,
		maxBody:      opts.MaxBodyBytes,
	}
}

// Fetch validates HTTPS and redirect limits on every hop and bounds the body.
// Failures stop retrieval without including the bearer reference in error
// details.
func (f *Fetcher) Fetch(ctx context.Context, reference string, opts FetchOptions) (Result, error) {
	agent, err := UserAgentFor(opts.UserAgent)
	if err != nil {
		return Result{}, err
	}
	target, err := ValidateReference(reference)
	if err != nil {
		return Result{}, err
	}
	ctx, cancel := context.WithTimeout(ctx, f.timeout)
	defer cancel()
	ctx = context.WithValue(ctx, privateKey{}, isPrivateHost(ctx, target.Hostname()))

	for hop := 0; ; hop++ {
		if hop > f.maxRedirects {
			return Result{}, errs.Newf(errs.CodeInvalidArgument, errs.KeySubscriptionRedirect,
				"subscription: the provider led the request more than %d times", f.maxRedirects)
		}
		body, header, location, err := f.hop(ctx, target, agent)
		if err != nil {
			return Result{}, err
		}
		if location == "" {
			return Result{Body: body, Info: parseInfo(header, body)}, nil
		}
		// Resolve relative redirects against the response URL, as
		// allowed by HTTP standards.
		moved, err := url.Parse(location)
		if err != nil {
			return Result{}, errs.Newf(errs.CodeInvalidArgument, errs.KeySubscriptionRedirect,
				"subscription: the provider sent a redirect that is not a location")
		}
		target, err = ValidateReference(target.ResolveReference(moved).String())
		if err != nil {
			return Result{}, err
		}
	}
}

// hop returns one response's body and headers or its redirect target.
func (f *Fetcher) hop(ctx context.Context, target *url.URL, agent string) ([]byte, http.Header, string, error) {
	request, err := http.NewRequestWithContext(ctx, http.MethodGet, target.String(), nil)
	if err != nil {
		// HTTP errors include bearer URLs; rebuild details using only
		// the cause.
		return nil, nil, "", errs.Newf(errs.CodeInvalidArgument, errs.KeySubscriptionScheme,
			"subscription: the reference is not a url this client can request")
	}
	request.Header.Set("User-Agent", agent)
	request.Header.Set("Accept", "text/plain, application/octet-stream, */*")
	// Bound decompressed size so compressed responses cannot exceed the
	// body limit.
	request.Header.Set("Accept-Encoding", "identity")

	response, err := f.client.Do(request)
	if err != nil {
		return nil, nil, "", errs.From(err)
	}
	defer func() {
		// Drain and close for connection reuse, but bound draining so
		// rejected responses cannot retain sockets indefinitely.
		_, _ = io.Copy(io.Discard, io.LimitReader(response.Body, drainLimit))
		_ = response.Body.Close()
	}()

	if location := redirectTarget(response); location != "" {
		return nil, nil, location, nil
	}
	if response.StatusCode != http.StatusOK {
		failure := errs.Newf(errs.CodeUnavailable, errs.KeySubscriptionStatus,
			"subscription: the provider answered %d", response.StatusCode)
		// Retry transient provider failures; rejected tokens need user
		// action and must not be retried.
		if response.StatusCode >= http.StatusInternalServerError ||
			response.StatusCode == http.StatusTooManyRequests {
			return nil, nil, "", failure.WithRetry(0)
		}
		return nil, nil, "", failure
	}
	if response.ContentLength > int64(f.maxBody) {
		return nil, nil, "", errs.Newf(errs.CodeResourceExhausted, errs.KeySubscriptionTooLarge,
			"subscription: the provider announced %d bytes, the limit is %d",
			response.ContentLength, f.maxBody)
	}
	body, err := io.ReadAll(io.LimitReader(response.Body, int64(f.maxBody)+1))
	if err != nil {
		return nil, nil, "", errs.From(err)
	}
	if len(body) > f.maxBody {
		return nil, nil, "", errs.Newf(errs.CodeResourceExhausted, errs.KeySubscriptionTooLarge,
			"subscription: the body is larger than the limit of %d bytes", f.maxBody)
	}
	if len(body) == 0 {
		return nil, nil, "", errs.Newf(errs.CodeInvalidArgument, errs.KeySubscriptionEmpty,
			"subscription: the provider answered with an empty body")
	}
	return body, response.Header, "", nil
}

// drainLimit bounds unwanted body reads for connection reuse. Larger bodies
// discard the connection instead of wasting reads.
const drainLimit = 4 << 10

// redirectTarget returns the next URL or empty for a final response.
func redirectTarget(response *http.Response) string {
	switch response.StatusCode {
	case http.StatusMovedPermanently, http.StatusFound, http.StatusSeeOther,
		http.StatusTemporaryRedirect, http.StatusPermanentRedirect:
	default:
		return ""
	}
	return response.Header.Get("Location")
}

// ValidateReference parses HTTPS references and rejects HTTP to avoid sending
// bearer tokens in cleartext.
func ValidateReference(reference string) (*url.URL, error) {
	trimmed := strings.TrimSpace(reference)
	if trimmed == "" {
		return nil, errs.Newf(errs.CodeInvalidArgument, errs.KeySubscriptionScheme,
			"subscription: the reference is empty")
	}
	parsed, err := url.Parse(trimmed)
	if err != nil {
		return nil, errs.Newf(errs.CodeInvalidArgument, errs.KeySubscriptionScheme,
			"subscription: the reference is not a url")
	}
	if parsed.User != nil {
		// Reject URL user info to avoid additional credentials in
		// reference strings and logs.
		return nil, errs.Newf(errs.CodeInvalidArgument, errs.KeySubscriptionScheme,
			"subscription: the reference carries credentials of its own")
	}
	switch strings.ToLower(parsed.Scheme) {
	case "https":
	case "http":
		return nil, errs.Newf(errs.CodeUnsupported, errs.KeySubscriptionScheme,
			"subscription: the reference uses http, which would send the token in clear")
	default:
		return nil, errs.Newf(errs.CodeUnsupported, errs.KeySubscriptionScheme,
			"subscription: the reference is not an http or https url")
	}
	if parsed.Host == "" {
		return nil, errs.Newf(errs.CodeInvalidArgument, errs.KeySubscriptionScheme,
			"subscription: the reference has no host")
	}
	return parsed, nil
}

// UserAgentFor validates an override or returns the default. Line breaks are
// rejected to prevent header injection.
func UserAgentFor(asked string) (string, error) {
	trimmed := strings.TrimSpace(asked)
	if trimmed == "" {
		return UserAgent, nil
	}
	if len(trimmed) > MaxUserAgent {
		return "", errs.Newf(errs.CodeInvalidArgument, errs.KeySubscriptionScheme,
			"subscription: the User-Agent is longer than %d bytes", MaxUserAgent)
	}
	for _, r := range trimmed {
		if r < 0x20 || r > 0x7e {
			return "", errs.Newf(errs.CodeInvalidArgument, errs.KeySubscriptionScheme,
				"subscription: the User-Agent may hold printable ASCII only")
		}
	}
	return trimmed, nil
}

// privateKey permits private destinations only for initially local
// subscriptions. Internet providers cannot redirect the service into local
// networks.
type privateKey struct{}

// isPrivateHost reports whether host is, or resolves to, an address that is
// not on the internet.
func isPrivateHost(ctx context.Context, host string) bool {
	if addr, err := netip.ParseAddr(host); err == nil {
		return !publicAddr(addr)
	}
	addrs, err := net.DefaultResolver.LookupNetIP(ctx, "ip", host)
	if err != nil {
		return false
	}
	for _, addr := range addrs {
		if !publicAddr(addr) {
			return true
		}
	}
	return false
}

func publicAddr(addr netip.Addr) bool {
	addr = addr.Unmap()
	return addr.IsGlobalUnicast() && !addr.IsPrivate()
}

// dialChecked rejects private resolved addresses unless the subscription is
// local. Checking the actual dial target after DNS prevents rebinding bypasses.
func dialChecked(ctx context.Context, network, address string) (net.Conn, error) {
	allowPrivate, _ := ctx.Value(privateKey{}).(bool)
	dialer := &net.Dialer{
		Timeout: 30 * time.Second,
		Control: func(_, address string, _ syscall.RawConn) error {
			return checkDial(allowPrivate, address)
		},
	}
	return dialer.DialContext(ctx, network, address)
}

// checkDial validates one resolved address using dialChecked's policy.
func checkDial(allowPrivate bool, address string) error {
	host, _, err := net.SplitHostPort(address)
	if err != nil {
		return err
	}
	addr, err := netip.ParseAddr(host)
	if err != nil {
		return err
	}
	if allowPrivate || publicAddr(addr) {
		return nil
	}
	return errs.Newf(errs.CodePermissionDenied, errs.KeySubscriptionRedirect,
		"subscription: the request was led to an address outside the internet")
}
