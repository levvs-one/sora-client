// Package subscription retrieves a subscription body by reference.
//
// The reference is a bearer token: whoever holds the link holds the subscription.
// That single fact decides every rule in this package. The link is only ever sent
// over https, because a plain http request hands the token to every network on the
// way. Redirects are followed, but each hop is checked again and the number is
// bounded, because a redirect is the one way a provider can move a token somewhere
// it should not go. The body is capped, because a provider that answers with an
// endless stream must not be able to fill the disk of a laptop.
//
// Nothing is cached. A subscription body is a list of credentials, and a cache
// would be a second place where those credentials live, on a disk, with no
// benefit: a subscription is fetched when a user asks for it.
package subscription

import (
	"context"
	"io"
	"net/http"
	"net/url"
	"strings"
	"time"

	"github.com/levvs-one/sora-client/core/errs"
)

// Defaults of one retrieval. They are chosen for a provider on the other side of
// the world, on a connection the user already has, and they are still bounded: a
// fetch that has not answered in half a minute is a failure the user should see.
const (
	// DefaultTimeout bounds one retrieval, redirects included.
	DefaultTimeout = 30 * time.Second
	// MaxRedirects bounds how far a provider may lead the token.
	MaxRedirects = 5
	// MaxBodyBytes is the largest body accepted. It matches the import limit, so a
	// body that passes this check can always be parsed.
	MaxBodyBytes = 16 << 20
	// UserAgent identifies the client honestly. It does not imitate a browser,
	// because a provider that needs to treat Sora differently must be able to.
	UserAgent = "sora-core/1 (+https://github.com/levvs-one/sora-client)"
)

// Options configures a fetcher.
type Options struct {
	// Timeout bounds one retrieval.
	Timeout time.Duration
	// MaxRedirects bounds how far a provider may lead the token.
	MaxRedirects int
	// MaxBodyBytes is the largest body accepted.
	MaxBodyBytes int
	// HTTPClient retrieves the body. A nil client means one that verifies
	// certificates and never follows a redirect on its own. Tests inject a client
	// that trusts a local server; nothing else may.
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
			// Redirects are followed by this package, not by the client, because
			// each hop has to be checked and counted here.
			CheckRedirect: func(*http.Request, []*http.Request) error {
				return http.ErrUseLastResponse
			},
			Transport: &http.Transport{
				Proxy:                 http.ProxyFromEnvironment,
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

// Fetch retrieves the body behind a reference.
//
// The steps are the same on every hop: the scheme must be https, the hop count
// must be inside the budget, and the body must fit. A failure at any of them stops
// the retrieval, and the detail of a failure never quotes the reference, because
// the reference is the credential.
func (f *Fetcher) Fetch(ctx context.Context, reference string) ([]byte, error) {
	target, err := validateReference(reference)
	if err != nil {
		return nil, err
	}
	ctx, cancel := context.WithTimeout(ctx, f.timeout)
	defer cancel()

	for hop := 0; ; hop++ {
		if hop > f.maxRedirects {
			return nil, errs.Newf(errs.CodeInvalidArgument, errs.KeySubscriptionRedirect,
				"subscription: the provider led the request more than %d times", f.maxRedirects)
		}
		body, location, err := f.hop(ctx, target)
		if err != nil {
			return nil, err
		}
		if location == "" {
			return body, nil
		}
		// A redirect may be relative, which the standards allow and providers use.
		// It is resolved against the url it came from, so a hop that stays on the
		// same host does not have to spell the host out again.
		moved, err := url.Parse(location)
		if err != nil {
			return nil, errs.Newf(errs.CodeInvalidArgument, errs.KeySubscriptionRedirect,
				"subscription: the provider sent a redirect that is not a location")
		}
		target, err = validateReference(target.ResolveReference(moved).String())
		if err != nil {
			return nil, err
		}
	}
}

// hop performs one request and reports either the body or where the provider sent
// the token next.
func (f *Fetcher) hop(ctx context.Context, target *url.URL) ([]byte, string, error) {
	request, err := http.NewRequestWithContext(ctx, http.MethodGet, target.String(), nil)
	if err != nil {
		// The error of this call quotes the url, which is the token. It is replaced
		// by a line that names the reason and nothing else.
		return nil, "", errs.Newf(errs.CodeInvalidArgument, errs.KeySubscriptionScheme,
			"subscription: the reference is not a url this client can request")
	}
	request.Header.Set("User-Agent", UserAgent)
	request.Header.Set("Accept", "text/plain, application/octet-stream, */*")
	// A provider that answers with a compressed body must not be able to expand it
	// into something larger than the limit below.
	request.Header.Set("Accept-Encoding", "identity")

	response, err := f.client.Do(request)
	if err != nil {
		return nil, "", errs.From(err)
	}
	defer func() {
		// The body is drained and closed so the connection can be reused, and the
		// drain is bounded: a provider that keeps sending must not hold a goroutine
		// and a socket after the answer has already been refused.
		_, _ = io.Copy(io.Discard, io.LimitReader(response.Body, drainLimit))
		_ = response.Body.Close()
	}()

	if location := redirectTarget(response); location != "" {
		return nil, location, nil
	}
	if response.StatusCode != http.StatusOK {
		failure := errs.Newf(errs.CodeUnavailable, errs.KeySubscriptionStatus,
			"subscription: the provider answered %d", response.StatusCode)
		// A provider that is busy or broken may answer differently in a moment, so
		// the caller is told to try again. A provider that refused this token will
		// refuse it again, and a retry would only hide that from the user.
		if response.StatusCode >= http.StatusInternalServerError ||
			response.StatusCode == http.StatusTooManyRequests {
			return nil, "", failure.WithRetry(0)
		}
		return nil, "", failure
	}
	if response.ContentLength > int64(f.maxBody) {
		return nil, "", errs.Newf(errs.CodeResourceExhausted, errs.KeySubscriptionTooLarge,
			"subscription: the provider announced %d bytes, the limit is %d",
			response.ContentLength, f.maxBody)
	}
	body, err := io.ReadAll(io.LimitReader(response.Body, int64(f.maxBody)+1))
	if err != nil {
		return nil, "", errs.From(err)
	}
	if len(body) > f.maxBody {
		return nil, "", errs.Newf(errs.CodeResourceExhausted, errs.KeySubscriptionTooLarge,
			"subscription: the body is larger than the limit of %d bytes", f.maxBody)
	}
	if len(body) == 0 {
		return nil, "", errs.Newf(errs.CodeInvalidArgument, errs.KeySubscriptionEmpty,
			"subscription: the provider answered with an empty body")
	}
	return body, "", nil
}

// drainLimit is how much of an unwanted body is read so the connection can be
// returned to the pool. Anything larger is left on the socket, which is cheaper
// than reading a body nobody wants.
const drainLimit = 4 << 10

// redirectTarget reports where the provider wants the request to go, or an empty
// string when this is a final answer.
func redirectTarget(response *http.Response) string {
	switch response.StatusCode {
	case http.StatusMovedPermanently, http.StatusFound, http.StatusSeeOther,
		http.StatusTemporaryRedirect, http.StatusPermanentRedirect:
	default:
		return ""
	}
	return response.Header.Get("Location")
}

// validateReference checks a reference and returns it parsed. Plain http is
// refused: the reference is a credential, and a credential sent in clear is a
// credential that has to be rotated afterwards.
func validateReference(reference string) (*url.URL, error) {
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
		// Credentials inside the url are a second secret in the same string, and
		// they would follow it into every log line that mentions the reference.
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
