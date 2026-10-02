// Package probe measures whether a server answers, without a tunnel and without
// exchanging a payload.
//
// A measurement here answers one question: is there something listening on that
// address, and how far away is it. It is what the interface shows next to a server
// before anyone connects through it, and it is what tells a user which of two
// identical subscriptions is the slow one.
//
// The measurement is deliberately shallow. It opens a TCP connection, optionally
// completes a TLS handshake to check that the peer presents a certificate, and
// closes everything. No credential is sent, no payload is exchanged, and no
// result is cached: a cached answer is a wrong answer the moment a provider moves
// a server.
package probe

import (
	"context"
	"crypto/tls"
	"math"
	"net"
	"strconv"
	"sync"
	"time"

	"github.com/levvs-one/sora-client/core/errs"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
)

// Defaults of a measurement. The timeouts are short on purpose: a user watching a
// list fill in is better served by a fast "no answer" than by a slow "maybe".
const (
	// DefaultTimeout bounds one endpoint.
	DefaultTimeout = 5 * time.Second
	// DefaultConcurrency bounds how many endpoints are measured at once. A
	// subscription can hold thousands of servers, and a thousand sockets at once is
	// a self-inflicted denial of service on the user's own machine.
	DefaultConcurrency = 8
	// MaxEndpoints bounds one request.
	MaxEndpoints = 256
)

// Config configures a prober.
type Config struct {
	// Timeout bounds one endpoint.
	Timeout time.Duration
	// Concurrency bounds how many endpoints are measured at once.
	Concurrency int
	// TLS turns the measurement into a handshake, which proves that the peer
	// presents a certificate and not only a socket.
	TLS bool
	// ServerName is the name a TLS handshake verifies the certificate against. An
	// empty value means the host of the endpoint, which is what a real connection
	// would use.
	ServerName string
}

// Prober measures endpoints and streams the results.
type Prober struct {
	timeout     time.Duration
	concurrency int
	tls         bool
	serverName  string
}

// New returns a prober with the defaults filled in.
func New(cfg Config) *Prober {
	if cfg.Timeout <= 0 {
		cfg.Timeout = DefaultTimeout
	}
	if cfg.Concurrency <= 0 {
		cfg.Concurrency = DefaultConcurrency
	}
	return &Prober{
		timeout:     cfg.Timeout,
		concurrency: cfg.Concurrency,
		tls:         cfg.TLS,
		serverName:  cfg.ServerName,
	}
}

// Probe measures every endpoint and streams one result per endpoint. The channel
// is closed when the last result has been sent. Results arrive in completion
// order, because a slow endpoint must not hold a list the user is watching.
//
// serverIDs names the endpoints for the caller; a shorter list leaves the rest
// unnamed, and the result then carries an empty id rather than an index that
// means nothing to a client.
func (p *Prober) Probe(ctx context.Context, endpoints []*corev1.Endpoint, serverIDs []string) (<-chan *corev1.ProbeResult, error) {
	if len(endpoints) == 0 {
		return nil, errs.Newf(errs.CodeInvalidArgument, errs.KeyProbeNoEndpoints,
			"probe: the request carries no endpoints")
	}
	if len(endpoints) > MaxEndpoints {
		return nil, errs.Newf(errs.CodeResourceExhausted, errs.KeyProbeTooMany,
			"probe: the request carries %d endpoints, the limit is %d", len(endpoints), MaxEndpoints)
	}
	results := make(chan *corev1.ProbeResult, len(endpoints))
	go func() {
		defer close(results)
		semaphore := make(chan struct{}, p.concurrency)
		var wg sync.WaitGroup
		for index, endpoint := range endpoints {
			wg.Add(1)
			go func(index int, endpoint *corev1.Endpoint) {
				defer wg.Done()
				select {
				case semaphore <- struct{}{}:
					defer func() { <-semaphore }()
				case <-ctx.Done():
					return
				}
				result := p.measure(ctx, index, endpoint, serverIDs)
				select {
				case results <- result:
				case <-ctx.Done():
				}
			}(index, endpoint)
		}
		wg.Wait()
	}()
	return results, nil
}

// measure performs one measurement and always returns a result, because a caller
// showing a list needs an entry for every server it asked about.
func (p *Prober) measure(ctx context.Context, index int, endpoint *corev1.Endpoint, serverIDs []string) *corev1.ProbeResult {
	result := &corev1.ProbeResult{}
	if index < len(serverIDs) {
		result.ServerId = serverIDs[index]
	}
	host, port, err := addressOf(endpoint)
	if err != nil {
		result.Error = toWire(err, "")
		return result
	}
	latency, err := p.dial(ctx, host, port)
	if err != nil {
		result.Error = toWire(err, host)
		return result
	}
	result.Reachable = true
	result.LatencyMs = counter(latency.Milliseconds())
	return result
}

// dial opens the connection, optionally completes a handshake, and reports how
// long the whole thing took.
func (p *Prober) dial(ctx context.Context, host string, port uint32) (time.Duration, error) {
	address := net.JoinHostPort(host, strconv.FormatUint(uint64(port), 10))
	timeout := p.timeout
	if deadline, ok := ctx.Deadline(); ok {
		if remaining := time.Until(deadline); remaining > 0 && remaining < timeout {
			timeout = remaining
		}
	}
	if timeout <= 0 {
		return 0, errs.Newf(errs.CodeDeadlineExceeded, errs.KeyProbeInvalidEndpoint,
			"probe: the request has no time left")
	}
	start := time.Now()
	if !p.tls {
		connection, err := (&net.Dialer{Timeout: timeout}).DialContext(ctx, "tcp", address)
		if err != nil {
			return 0, errs.From(err)
		}
		_ = connection.Close()
		return time.Since(start), nil
	}
	// The handshake is the measurement: a socket that opens and a certificate that
	// never arrives are different failures, and only the second one explains why a
	// server that "works" does not. The dialer carries the context so a cancelled
	// request stops the handshake instead of waiting for a timeout.
	dialer := &tls.Dialer{
		NetDialer: &net.Dialer{Timeout: timeout},
		Config:    p.tlsConfig(host),
	}
	connection, err := dialer.DialContext(ctx, "tcp", address)
	if err != nil {
		return 0, errs.From(err)
	}
	_ = connection.Close()
	return time.Since(start), nil
}

// EndpointProber is the shape the control plane depends on. It is declared here so
// that a change to the prober that no longer fits the service fails to compile
// here, next to the code that changed, and not in a package three layers up.
type EndpointProber interface {
	Probe(ctx context.Context, endpoints []*corev1.Endpoint, serverIDs []string) (<-chan *corev1.ProbeResult, error)
}

// Prober is an EndpointProber.
var _ EndpointProber = (*Prober)(nil)

// tlsConfig builds the handshake configuration. Verification is on: a measurement
// that accepted an untrusted certificate would report a hijacked server as
// healthy, which is the opposite of what a user needs to know.
func (p *Prober) tlsConfig(host string) *tls.Config {
	name := p.serverName
	if name == "" {
		name = host
	}
	return &tls.Config{
		ServerName: name,
		MinVersion: tls.VersionTLS12,
	}
}

// addressOf reads and checks one endpoint.
func addressOf(endpoint *corev1.Endpoint) (string, uint32, error) {
	if endpoint == nil {
		return "", 0, errs.Newf(errs.CodeInvalidArgument, errs.KeyProbeInvalidEndpoint,
			"probe: the endpoint is missing")
	}
	host := endpoint.GetHost()
	if host == "" {
		return "", 0, errs.Newf(errs.CodeInvalidArgument, errs.KeyProbeInvalidEndpoint,
			"probe: the endpoint has no host")
	}
	port := endpoint.GetPort()
	if port == 0 || port > 0xffff {
		return "", 0, errs.Newf(errs.CodeInvalidArgument, errs.KeyProbeInvalidEndpoint,
			"probe: the port is not a port")
	}
	return host, port, nil
}

// toWire renders a failure for the probe result. The address is deliberately not
// part of it: a probe answer reaches a list in the interface, and a list that
// shows addresses is a list that leaks a provider account.
func toWire(err error, host string) *corev1.SoraError {
	classified := errs.From(err)
	detail := classified.Detail()
	if host == "" && detail == "" {
		detail = "the endpoint is not a host and a port"
	}
	return &corev1.SoraError{
		Code:           probeCode(classified.Code()),
		UserMessageKey: string(classified.Key()),
		DetailRedacted: detail,
		Retryable:      classified.Retryable(),
	}
}

// probeCode maps a catalog class onto the contract. A probe is the one place
// where a refused connection is an answer rather than a failure, so a network
// condition becomes "unavailable" and only a malformed endpoint stays invalid.
func probeCode(code errs.Code) corev1.SoraErrorCode {
	switch code {
	case errs.CodeInvalidArgument:
		return corev1.SoraErrorCode_SORA_ERROR_CODE_INVALID_ARGUMENT
	case errs.CodePermissionDenied:
		return corev1.SoraErrorCode_SORA_ERROR_CODE_PERMISSION_DENIED
	case errs.CodeTimeout, errs.CodeDeadlineExceeded:
		return corev1.SoraErrorCode_SORA_ERROR_CODE_DEADLINE_EXCEEDED
	default:
		return corev1.SoraErrorCode_SORA_ERROR_CODE_UNAVAILABLE
	}
}

// counter narrows a millisecond count for the contract field, which cannot hold a
// negative value.
func counter(value int64) uint32 {
	if value <= 0 {
		return 0
	}
	if value > math.MaxUint32 {
		return math.MaxUint32
	}
	return uint32(value) //nolint:gosec // bounded by the check above
}
