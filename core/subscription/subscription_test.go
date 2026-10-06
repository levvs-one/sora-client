package subscription_test

import (
	"context"
	"crypto/tls"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/levvs-one/sora-client/core/errs"
	"github.com/levvs-one/sora-client/core/subscription"
)

// body is what a provider answers with in the tests: one share link, which is what
// the parser expects.
const body = "vless://11111111-1111-4111-8111-111111111111@de1.example.com:443?security=tls#Berlin"

// newServer starts a provider that answers over tls, together with a client that
// trusts it. The client is injected rather than the certificate, because the
// production client must never be told to skip verification.
func newServer(t *testing.T, handler http.HandlerFunc) (*subscription.Fetcher, string) {
	t.Helper()
	server := httptest.NewTLSServer(handler)
	t.Cleanup(server.Close)
	client := &http.Client{
		CheckRedirect: func(*http.Request, []*http.Request) error {
			return http.ErrUseLastResponse
		},
		Transport: &http.Transport{TLSClientConfig: &tls.Config{InsecureSkipVerify: true}}, //nolint:gosec // a test server with a self signed certificate
	}
	fetcher := subscription.New(subscription.Options{HTTPClient: client, Timeout: 2 * 1000000000})
	return fetcher, server.URL + "/sub?token=s3cr3t-token-value"
}

func TestFetchReturnsTheBody(t *testing.T) {
	fetcher, url := newServer(t, func(w http.ResponseWriter, r *http.Request) {
		if got := r.Header.Get("User-Agent"); !strings.HasPrefix(got, "sora-core/") {
			t.Errorf("user agent = %q, want one that identifies the client honestly", got)
		}
		if got := r.Header.Get("Accept-Encoding"); got != "identity" {
			t.Errorf("accept-encoding = %q, want identity so a body cannot be expanded past the limit", got)
		}
		_, _ = w.Write([]byte(body))
	})
	got, err := fetcher.Fetch(context.Background(), url)
	if err != nil {
		t.Fatalf("Fetch() error = %v", err)
	}
	if string(got) != body {
		t.Errorf("Fetch() = %q", got)
	}
}

func TestFetchRefusesAPlainHttpReference(t *testing.T) {
	fetcher := subscription.New(subscription.Options{})
	_, err := fetcher.Fetch(context.Background(), "http://provider.example/sub?token=abc")
	if errs.KeyOf(err) != errs.KeySubscriptionScheme {
		t.Fatalf("a plain http reference = %v, key = %q", err, errs.KeyOf(err))
	}
	if errs.Retryable(err) {
		t.Error("a refused scheme is not retryable, the user has to change the link")
	}
}

func TestFetchRefusesReferencesThatCarryTheirOwnCredentials(t *testing.T) {
	fetcher := subscription.New(subscription.Options{})
	_, err := fetcher.Fetch(context.Background(), "https://user:pass@provider.example/sub")
	if errs.KeyOf(err) != errs.KeySubscriptionScheme {
		t.Errorf("a reference with credentials = %v, key = %q", err, errs.KeyOf(err))
	}
	for _, reference := range []string{"", "   ", "ftp://provider.example/sub", "https:///sub"} {
		if _, err := fetcher.Fetch(context.Background(), reference); err == nil {
			t.Errorf("the fetcher accepted %q", reference)
		}
	}
}

func TestFetchFollowsARedirectToAnotherHttpsHost(t *testing.T) {
	final := httptest.NewTLSServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		_, _ = w.Write([]byte(body))
	}))
	defer final.Close()

	moves := 0
	fetcher, url := newServer(t, func(w http.ResponseWriter, r *http.Request) {
		moves++
		http.Redirect(w, r, final.URL+"/moved", http.StatusFound)
	})
	got, err := fetcher.Fetch(context.Background(), url)
	if err != nil {
		t.Fatalf("Fetch() error = %v", err)
	}
	if string(got) != body {
		t.Errorf("Fetch() = %q after one redirect", got)
	}
	if moves != 1 {
		t.Errorf("the provider was asked %d times, want once before the redirect", moves)
	}
}

func TestFetchStopsAtARedirectThatDowngradesToHttp(t *testing.T) {
	fetcher, url := newServer(t, func(w http.ResponseWriter, r *http.Request) {
		http.Redirect(w, r, "http://provider.example/sub", http.StatusFound)
	})
	_, err := fetcher.Fetch(context.Background(), url)
	if errs.KeyOf(err) != errs.KeySubscriptionScheme {
		t.Errorf("a redirect to http = %v, key = %q", err, errs.KeyOf(err))
	}
}

func TestFetchStopsAfterTooManyRedirects(t *testing.T) {
	fetcher, url := newServer(t, func(w http.ResponseWriter, r *http.Request) {
		http.Redirect(w, r, "/again", http.StatusFound)
	})
	_, err := fetcher.Fetch(context.Background(), url)
	if errs.KeyOf(err) != errs.KeySubscriptionRedirect {
		t.Errorf("an endless redirect = %v, key = %q", err, errs.KeyOf(err))
	}
}

// fetcherClient returns a client that trusts the certificate of a test server. It
// exists so the production client, which must verify certificates, is never the
// one a test relaxes.
func fetcherClient(t *testing.T) *http.Client {
	t.Helper()
	return &http.Client{
		CheckRedirect: func(*http.Request, []*http.Request) error {
			return http.ErrUseLastResponse
		},
		Transport: &http.Transport{TLSClientConfig: &tls.Config{InsecureSkipVerify: true}}, //nolint:gosec // a self signed test certificate
	}
}

func TestFetchRefusesABodyPastTheLimit(t *testing.T) {
	_, url := newServer(t, func(w http.ResponseWriter, _ *http.Request) {
		w.Header().Set("Content-Length", "2048")
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte(strings.Repeat("x", 2048)))
	})
	small := subscription.New(subscription.Options{MaxBodyBytes: 1024, HTTPClient: fetcherClient(t)})
	_, err := small.Fetch(context.Background(), url)
	if errs.KeyOf(err) != errs.KeySubscriptionTooLarge {
		t.Errorf("an oversized body = %v, key = %q", err, errs.KeyOf(err))
	}
}

func TestFetchReportsAProviderStatusWithoutQuotingTheToken(t *testing.T) {
	fetcher, url := newServer(t, func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusForbidden)
	})
	_, err := fetcher.Fetch(context.Background(), url)
	if errs.KeyOf(err) != errs.KeySubscriptionStatus {
		t.Fatalf("a 403 = %v, key = %q", err, errs.KeyOf(err))
	}
	if errs.Retryable(err) {
		t.Error("a provider that refused this token will refuse it again, so retrying only hides the reason")
	}
	for _, secret := range []string{"s3cr3t-token-value", "token"} {
		if strings.Contains(errs.Detail(err), secret) {
			t.Errorf("the detail %q leaks the token", errs.Detail(err))
		}
	}
}

func TestFetchAsksAgainWhenAProviderIsBroken(t *testing.T) {
	fetcher, url := newServer(t, func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusServiceUnavailable)
	})
	_, err := fetcher.Fetch(context.Background(), url)
	if errs.KeyOf(err) != errs.KeySubscriptionStatus {
		t.Fatalf("a 503 = %v, key = %q", err, errs.KeyOf(err))
	}
	if !errs.Retryable(err) {
		t.Error("a provider that is busy may answer differently in a moment")
	}
}

func TestFetchRefusesAnEmptyBody(t *testing.T) {
	fetcher, url := newServer(t, func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusOK)
	})
	_, err := fetcher.Fetch(context.Background(), url)
	if errs.KeyOf(err) != errs.KeySubscriptionEmpty {
		t.Errorf("an empty body = %v, key = %q", err, errs.KeyOf(err))
	}
}
