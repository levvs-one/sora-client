// Package control is the control plane of the Sora core: it implements the
// sora.core.v1 service, translates the contract into the core types and enforces
// the limits a client may not exceed.
//
// Everything that crosses this boundary is untrusted. A request is checked for
// contract version, authenticator, limits and shape before any work is done, and
// every answer is masked through the plan redactor. The package holds no state of
// its own beyond the authenticator: sessions live in the session manager, secrets
// in the secret store, so a control plane can be rebuilt without touching either.
package control

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"errors"
	"math"
	"strings"
	"sync"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/protobuf/proto"
	"google.golang.org/protobuf/types/known/durationpb"
	"google.golang.org/protobuf/types/known/timestamppb"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/errs"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
	"github.com/levvs-one/sora-client/core/logs"
	"github.com/levvs-one/sora-client/core/parser"
	"github.com/levvs-one/sora-client/core/secret"
	"github.com/levvs-one/sora-client/core/session"
	"github.com/levvs-one/sora-client/core/subscription"
)

// sessionSettings reads the system settings a session owns from the request.
//
// The core decides what the machine needs; the client only says what it asked
// for. A tunnel mode means the interface wants the system route, and bypass rules
// mean private destinations must skip the tunnel: everything else is the guard's
// business, and the guard is the only thing that may change the system.
func sessionSettings(in *corev1.SessionPlan) session.Settings {
	settings := session.Settings{
		SystemProxy: in.GetTunnelMode() != corev1.TunnelMode_TUNNEL_MODE_APPLICATION,
		TunnelMode:  "system",
	}
	if in.GetTunnelMode() == corev1.TunnelMode_TUNNEL_MODE_APPLICATION {
		settings.SystemProxy = true
		settings.TunnelMode = "application"
	}
	settings.Bypass = append([]string(nil), in.GetBypassSettings().GetRules()...)
	return settings
}

// SessionIDLen is the length of a session identifier minted by the core. The
// client may bring its own, and then it is checked against the same length.
const SessionIDLen = 16

// maxSessionIDLen bounds a client supplied identifier, because it is used in a
// log line, in an event stream and in a file name of the engine home directory.
const maxSessionIDLen = 64

// Version is the contract version the core serves.
type Version struct {
	Major             uint32
	Minor             uint32
	MinSupportedMinor uint32
}

// String renders the version for a log line.
func (v Version) String() string {
	return strings.Join([]string{itoa(v.Major), itoa(v.Minor)}, ".")
}

// itoa renders a small unsigned number without pulling in fmt for one call.
func itoa(v uint32) string {
	if v == 0 {
		return "0"
	}
	var buf [10]byte
	i := len(buf)
	for v > 0 {
		i--
		buf[i] = byte('0' + v%10)
		v /= 10
	}
	return string(buf[i:])
}

// Capabilities lists what this core can do. The interface shows them in its
// settings and uses them to hide what an older core cannot do.
func Capabilities() []string {
	return []string{
		"import-parse",
		"secret-store",
		"event-stream",
		"kill-switch",
		"stats",
		"engine-selection",
		"tls-fragment",
		"log-center",
		"connection-center",
	}
}

// Measurer times a real request through each outbound with the engine that
// carries it. An outbound no engine carries gets engine.ErrNoEngine.
type Measurer interface {
	Measure(ctx context.Context, outbounds []engine.Outbound, opts engine.MeasureOptions) (<-chan engine.Measurement, error)
}

// Prober measures whether an endpoint answers. It is an interface so the control
// plane does not depend on how a probe is performed: a direct dial on the desktop
// and a probe through the tunnel on Android are different implementations of the
// same question.
type Prober interface {
	Probe(ctx context.Context, endpoints []*corev1.Endpoint, serverIDs []string) (<-chan *corev1.ProbeResult, error)
}

// Diagnostics collects the report and the archive the interface can send to
// support. Both operations are redacted by the core before they return.
type Diagnostics interface {
	Run(ctx context.Context, status session.Status) ([]string, error)
	Export(ctx context.Context, status session.Status) ([]byte, error)
}

// Fetcher retrieves subscriptions by reference.
//
// The reference is a bearer token, so the retrieval is deliberately narrow: only
// https, a bounded number of redirects, a bounded body, and no cache. The
// interface is declared here because the control plane only needs the one method,
// and because the retrieval belongs behind it rather than inside the transport.
type Fetcher interface {
	Fetch(ctx context.Context, reference string, opts subscription.FetchOptions) (subscription.Result, error)
}

// Server implements the control-plane service.
type Server struct {
	corev1.UnimplementedCoreControlServer

	version     Version
	auth        *Authenticator
	sessions    *session.Manager
	secrets     SecretStore
	parser      parser.LinkParser
	redactors   *redactorCache
	prober      Prober
	measurer    Measurer
	logs        *logs.Center
	diagnostics Diagnostics
	fetcher     Fetcher
}

// SecretStore is what the control plane needs from the credential store. The
// interface is smaller than the store itself on purpose: the control plane may
// resolve, write and delete material, and nothing else.
type SecretStore interface {
	Get(reference string) ([]byte, error)
	Put(reference string, material []byte) error
	Delete(reference string) error
}

// redactorCache holds one redactor per session, because a redactor is seeded with
// the secrets of the plan it masks. Dropping the plan and keeping the redactor
// would leak; keeping the plan and dropping the redactor would leak too.
type redactorCache struct {
	mu    sync.Mutex
	byRef map[string]*engine.Redactor
}

// Config configures a control plane. Only the sessions manager is required: a
// core that cannot tunnel is still a core that answers a handshake and refuses
// everything else with a proper error.
type Config struct {
	// Version is the contract version the core serves.
	Version Version
	// Authenticator checks the token on Connect and Disconnect.
	Authenticator *Authenticator
	// Sessions owns the tunnel lifecycle.
	Sessions *session.Manager
	// Secrets stores credential material. A nil store disables the import and
	// the secret methods, which then answer with a proper failure instead of
	// failing on a nil pointer.
	Secrets SecretStore
	// MaxImportItems bounds one import.
	MaxImportItems int
	// Prober measures endpoints; nil answers that probing is unavailable.
	Prober Prober
	// Measurer times real requests through engines; nil leaves only the
	// connection check.
	Measurer Measurer
	// Logs is the log center; nil answers that the core keeps no record.
	Logs *logs.Center
	// Diagnostics collects reports and archives; nil answers that the feature is
	// unavailable.
	Diagnostics Diagnostics
	// Fetcher retrieves subscriptions; nil answers that fetching is unavailable.
	Fetcher Fetcher
}

// New builds a control plane. The version is filled in when a caller left it
// empty, because a core with an unset version could not negotiate with anyone.
func New(cfg Config) (*Server, error) {
	if cfg.Sessions == nil {
		return nil, errs.Newf(errs.CodeFailedPrecondition, errs.KeySessionRequired,
			"control: no session manager")
	}
	if cfg.Authenticator == nil {
		return nil, errs.Newf(errs.CodeFailedPrecondition, errs.KeyUnauthenticated,
			"control: no authenticator")
	}
	if cfg.Version.Major == 0 {
		cfg.Version = Version{Major: 1, Minor: 0, MinSupportedMinor: 0}
	}
	return &Server{
		version:     cfg.Version,
		auth:        cfg.Authenticator,
		sessions:    cfg.Sessions,
		secrets:     cfg.Secrets,
		parser:      parser.LinkParser{MaxItems: cfg.MaxImportItems},
		redactors:   &redactorCache{byRef: make(map[string]*engine.Redactor)},
		prober:      cfg.Prober,
		measurer:    cfg.Measurer,
		logs:        cfg.Logs,
		diagnostics: cfg.Diagnostics,
		fetcher:     cfg.Fetcher,
	}, nil
}

// SetDiagnostics attaches the collector after the plane was built. A collector
// needs the session manager and the engine build, both of which exist before the
// control plane does, so the composition root hands it over here instead of
// threading it through a constructor argument it cannot fill yet.
//
// It is a construction step, not a runtime one: calling it while the plane serves
// requests is a race, and a composition root that does it late has a design
// problem that a lock would only hide.
func (s *Server) SetDiagnostics(collector Diagnostics) {
	s.diagnostics = collector
}

// apiVersion renders the version the core serves.
func (s *Server) apiVersion() *corev1.ApiVersion {
	return &corev1.ApiVersion{
		Major:             s.version.Major,
		Minor:             s.version.Minor,
		MinSupportedMinor: s.version.MinSupportedMinor,
		Capabilities:      Capabilities(),
	}
}

// checkVersion refuses a client that cannot be served, and names both versions so
// a mismatched client can report something better than "failed".
func (s *Server) checkVersion(client *corev1.ApiVersion) (uint32, error) {
	if client == nil {
		return 0, errs.Newf(errs.CodeVersionMismatch, errs.KeyAPIVersionMismatch,
			"control: the request carries no api version")
	}
	negotiated, err := Negotiate(client, s.apiVersion())
	if err != nil {
		return 0, errs.Newf(errs.CodeVersionMismatch, errs.KeyAPIVersionMismatch,
			"control: the client speaks %d.%d, the core speaks %s",
			client.GetMajor(), client.GetMinor(), s.version)
	}
	return negotiated, nil
}

// requestID returns the identifier the client sent, or mints one so an answer
// always carries something a log can be searched by.
func requestID(sent string) string {
	if trimmed := strings.TrimSpace(sent); trimmed != "" {
		return trimmed
	}
	var buf [8]byte
	if _, err := rand.Read(buf[:]); err != nil {
		return ""
	}
	return "req_" + hex.EncodeToString(buf[:])
}

// newSessionID mints a session identifier. The client may bring its own, and then
// it must look like one: the identifier reaches a log line, an event stream and a
// file name, so it is limited to a short opaque alphabet.
func newSessionID(proposed string) (string, error) {
	trimmed := strings.TrimSpace(proposed)
	if trimmed == "" {
		var buf [SessionIDLen]byte
		if _, err := rand.Read(buf[:]); err != nil {
			return "", errs.Wrap(err, errs.CodeInternal, errs.KeyInternal)
		}
		return "s_" + hex.EncodeToString(buf[:]), nil
	}
	if len(trimmed) > maxSessionIDLen {
		return "", errs.Newf(errs.CodeInvalidArgument, errs.KeyInvalidRequest,
			"control: the session id is longer than %d bytes", maxSessionIDLen)
	}
	for i := range len(trimmed) {
		c := trimmed[i]
		switch {
		case c >= 'a' && c <= 'z', c >= 'A' && c <= 'Z', c >= '0' && c <= '9', c == '-', c == '_':
		default:
			return "", errs.Newf(errs.CodeInvalidArgument, errs.KeyInvalidRequest,
				"control: the session id has an unsupported character at %d", i)
		}
	}
	return trimmed, nil
}

// mask returns a masking function for a plan, or nil when there is no plan. Every
// answer built from a plan goes through it.
//
// The redactor is seeded with credentials and with identifiers: a plan that names
// the server de1.example.com would otherwise let that name leave the core inside
// an error detail or an event, which is a report about one user.
func (s *Server) mask(plan *engine.Plan) func(string) string {
	if plan == nil {
		return nil
	}
	values := append(plan.Secrets(), plan.Identifiers()...)
	redactor := engine.NewRedactor(values...)
	s.redactors.put(plan.SessionID, redactor)
	return redactor.String
}

// put records the redactor of a session, so a later answer can mask with the same
// values after the plan object itself is gone.
func (c *redactorCache) put(sessionID string, redactor *engine.Redactor) {
	if sessionID == "" {
		return
	}
	c.mu.Lock()
	defer c.mu.Unlock()
	if len(c.byRef) >= maxCachedRedactors {
		// A core that has seen this many sessions is cycling, not failing. The map
		// is emptied rather than ordered by age: the oldest entry is the one most
		// likely to belong to a session that has ended.
		clear(c.byRef)
	}
	c.byRef[sessionID] = redactor
}

// get returns the redactor of a session, or nil.
func (c *redactorCache) get(sessionID string) *engine.Redactor {
	c.mu.Lock()
	defer c.mu.Unlock()
	return c.byRef[sessionID]
}

// drop forgets the redactor of a session that has ended.
func (c *redactorCache) drop(sessionID string) {
	c.mu.Lock()
	defer c.mu.Unlock()
	delete(c.byRef, sessionID)
}

// maxCachedRedactors bounds the redactor cache. Eight sessions in flight is far
// more than a machine ever runs, and a bounded cache cannot grow without limit in
// a process that runs for weeks.
const maxCachedRedactors = 8

// wireStateValue renders a session state onto the contract. The mapping is one to
// one, so an unknown state can only be a bug in this package and is reported as
// disconnected rather than as a value the interface does not know.
func wireStateValue(state session.State) corev1.ConnectionStateValue {
	switch state {
	case session.StateDisconnected:
		return corev1.ConnectionStateValue_CONNECTION_STATE_VALUE_DISCONNECTED
	case session.StateConnecting:
		return corev1.ConnectionStateValue_CONNECTION_STATE_VALUE_CONNECTING
	case session.StateConnected:
		return corev1.ConnectionStateValue_CONNECTION_STATE_VALUE_CONNECTED
	case session.StateReconnecting:
		return corev1.ConnectionStateValue_CONNECTION_STATE_VALUE_RECONNECTING
	case session.StateFailed:
		return corev1.ConnectionStateValue_CONNECTION_STATE_VALUE_FAILED
	default:
		return corev1.ConnectionStateValue_CONNECTION_STATE_VALUE_DISCONNECTED
	}
}

// wireStatus renders a session status onto the contract.
func wireStatus(status session.Status) *corev1.ConnectionState {
	out := &corev1.ConnectionState{
		Value:      wireStateValue(status.State),
		SessionId:  status.SessionID,
		ChangedAt:  timestampOrNil(status.ChangedAt),
		RetryAfter: durationOrNil(status.RetryAfter),
	}
	if code, ok := wireCodes[status.Reason]; ok {
		out.Reason = code
	}
	return out
}

// requestDeadline returns the deadline of a request, or a default one when the
// client sent none. A control plane that waits forever for a client is a control
// plane that keeps a session alive after the user has left.
func requestDeadline(ctx context.Context, fallback time.Duration) (context.Context, context.CancelFunc) {
	if _, ok := ctx.Deadline(); ok {
		return ctx, func() {}
	}
	return context.WithTimeout(ctx, fallback)
}

// Deadlines of the methods, used when the client sends none. They are generous
// enough for a slow machine and short enough that a forgotten caller cannot hold a
// system change open: the engine answers on the loopback interface, so a connect
// that takes longer than this is already broken.
const (
	connectTimeout    = 30 * time.Second
	disconnectTimeout = 15 * time.Second
	guardTimeout      = 10 * time.Second
	statsTimeout      = 5 * time.Second
	importTimeout     = 60 * time.Second
)

// Limits of the transport. A service that sets them once, in one place, is a
// service whose client and server cannot drift apart: the numbers the core checks
// in a plan are the numbers the transport refuses a message over.
const (
	// MaxRecvMsgBytes is the largest message the core accepts from a client. It is
	// the plan limit plus the envelope around it, so a client cannot send a plan
	// that is over the limit and still be believed.
	MaxRecvMsgBytes = MaxPlanBytes + (1 << 20)
	// MaxSendMsgBytes is the largest message the core answers with. The largest
	// answer the contract defines is a diagnostic archive, which the collector
	// bounds, and the room left here is what a client needs to read it.
	MaxSendMsgBytes = 16 << 20
)

// Handshake answers with the contract version the core serves. It is the only
// method that does not require an authenticator, because a client must learn the
// version before it can ask for anything else.
//
// It also negotiates, and it is the method where the negotiation matters: a
// client that is too old finds out here, and the answer carries the version the
// core speaks even when it refuses, because a client that cannot be served still
// has to learn what it should update to.
func (s *Server) Handshake(_ context.Context, req *corev1.HandshakeRequest) (*corev1.HandshakeResponse, error) {
	negotiated, err := s.checkVersion(req.GetClientVersion())
	if err != nil {
		return &corev1.HandshakeResponse{
			NegotiatedVersion: s.apiVersion(),
			Error:             toWire(err, nil, ""),
		}, nil
	}
	answer := s.apiVersion()
	answer.Minor = negotiated
	return &corev1.HandshakeResponse{NegotiatedVersion: answer}, nil
}

// Connect starts a session for the plan of the request.
//
// The order of the checks is the design: version, then authenticator, then limits,
// then the plan itself. A caller that fails any of them has not touched the
// system, so a mistyped plan cannot cost a user their current connection.
func (s *Server) Connect(ctx context.Context, req *corev1.ConnectRequest) (*corev1.ConnectResponse, error) {
	id := requestID(req.GetRequestId())
	if _, err := s.checkVersion(req.GetApiVersion()); err != nil {
		return nil, transportStatus(err)
	}
	if err := s.auth.Check(req.GetControlAuthenticator()); err != nil {
		return nil, transportStatus(err)
	}
	if size := proto.Size(req.GetSessionPlan()); size > MaxPlanBytes {
		err := errs.Newf(errs.CodeResourceExhausted, errs.KeyPlanTooLarge,
			"control: the plan is %d bytes, the limit is %d", size, MaxPlanBytes)
		return &corev1.ConnectResponse{Error: toWire(err, nil, id)}, nil
	}
	sessionID, err := newSessionID(req.GetSessionId())
	if err != nil {
		return &corev1.ConnectResponse{Error: toWire(err, nil, id)}, nil
	}
	plan, err := planFromProto(req.GetSessionPlan(), sessionID, s.secrets)
	if err != nil {
		return &corev1.ConnectResponse{Error: toWire(err, nil, id)}, nil
	}
	mask := s.mask(plan)

	ctx, cancel := requestDeadline(ctx, connectTimeout)
	defer cancel()
	started, err := s.sessions.Connect(ctx, plan, sessionSettings(req.GetSessionPlan()))
	if err != nil {
		return &corev1.ConnectResponse{Error: toWire(err, mask, id)}, nil
	}
	return &corev1.ConnectResponse{
		Status: &corev1.SessionStatus{
			Connection:        wireStatus(started.Status()),
			NegotiatedVersion: s.apiVersion(),
		},
	}, nil
}

// Disconnect stops the session. A client that names a session which is not the
// running one is refused rather than silently stopping whatever is running: two
// interfaces on one machine must not be able to cut each other's tunnel.
func (s *Server) Disconnect(ctx context.Context, req *corev1.DisconnectRequest) (*corev1.DisconnectResponse, error) {
	id := requestID(req.GetRequestId())
	if _, err := s.checkVersion(req.GetApiVersion()); err != nil {
		return nil, transportStatus(err)
	}
	if err := s.auth.Check(req.GetControlAuthenticator()); err != nil {
		return nil, transportStatus(err)
	}
	if wanted := strings.TrimSpace(req.GetSessionId()); wanted != "" {
		running := s.sessions.Current()
		if running == nil || running.ID() != wanted {
			err := errs.Newf(errs.CodeNotFound, errs.KeyUnknownSession,
				"control: the request names a session that is not running")
			return &corev1.DisconnectResponse{Error: toWire(err, nil, id)}, nil
		}
	}
	ctx, cancel := requestDeadline(ctx, disconnectTimeout)
	defer cancel()
	if err := s.sessions.Disconnect(ctx); err != nil {
		return &corev1.DisconnectResponse{
			Status: &corev1.SessionStatus{Connection: wireStatus(s.sessions.Status())},
			Error:  toWire(err, nil, id),
		}, nil
	}
	if finished := s.sessions.Status().SessionID; finished != "" {
		s.redactors.drop(finished)
	}
	return &corev1.DisconnectResponse{
		Status: &corev1.SessionStatus{Connection: wireStatus(s.sessions.Status())},
	}, nil
}

// GetStatus answers with the current state of the session and the contract version
// that applies to it. A client that names a session which is not the current one
// is told so instead of being handed the state of somebody else's tunnel.
func (s *Server) GetStatus(_ context.Context, req *corev1.GetStatusRequest) (*corev1.GetStatusResponse, error) {
	id := requestID("")
	if _, err := s.checkVersion(req.GetApiVersion()); err != nil {
		return nil, transportStatus(err)
	}
	if err := s.checkSession(req.GetSessionId()); err != nil {
		return &corev1.GetStatusResponse{
			Status: &corev1.SessionStatus{
				Connection:        wireStatus(session.Status{}),
				NegotiatedVersion: s.apiVersion(),
			},
			Error: toWire(err, nil, id),
		}, nil
	}
	status := s.sessions.Status()
	return &corev1.GetStatusResponse{Status: &corev1.SessionStatus{
		Connection:        wireStatus(status),
		NegotiatedVersion: s.apiVersion(),
	}}, nil
}

// checkSession refuses a request that names a session other than the running one.
// An empty name means the caller does not care, which the contract allows and a
// client that just opened does.
func (s *Server) checkSession(named string) error {
	wanted := strings.TrimSpace(named)
	if wanted == "" {
		return nil
	}
	running := s.sessions.Current()
	if running == nil || running.ID() != wanted {
		return errs.Newf(errs.CodeNotFound, errs.KeyUnknownSession,
			"control: the request names a session that is not running")
	}
	return nil
}

// SetKillSwitch arms or disarms the kill switch of the running session.
func (s *Server) SetKillSwitch(ctx context.Context, req *corev1.SetKillSwitchRequest) (*corev1.SetKillSwitchResponse, error) {
	id := requestID(req.GetRequestId())
	if _, err := s.checkVersion(req.GetApiVersion()); err != nil {
		return nil, transportStatus(err)
	}
	running := s.sessions.Current()
	if running == nil {
		err := errs.Newf(errs.CodeFailedPrecondition, errs.KeySessionRequired,
			"control: there is no session to arm")
		return &corev1.SetKillSwitchResponse{Error: toWire(err, nil, id)}, nil
	}
	if err := s.checkSession(req.GetSessionId()); err != nil {
		return &corev1.SetKillSwitchResponse{Error: toWire(err, nil, id)}, nil
	}
	ctx, cancel := requestDeadline(ctx, guardTimeout)
	defer cancel()
	if err := running.SetKillSwitch(ctx, req.GetEnabled()); err != nil {
		return &corev1.SetKillSwitchResponse{Enabled: req.GetEnabled(), Error: toWire(err, nil, id)}, nil
	}
	return &corev1.SetKillSwitchResponse{Enabled: req.GetEnabled()}, nil
}

// GetStats answers with the traffic counters of the running session. A core with
// no session answers with zeroes and no error: statistics of nothing are not a
// failure.
func (s *Server) GetStats(ctx context.Context, req *corev1.GetStatsRequest) (*corev1.GetStatsResponse, error) {
	if _, err := s.checkVersion(req.GetApiVersion()); err != nil {
		return nil, transportStatus(err)
	}
	if err := s.checkSession(req.GetSessionId()); err != nil {
		return &corev1.GetStatsResponse{
			Stats: &corev1.StatsTick{},
			Error: toWire(err, nil, ""),
		}, nil
	}
	running := s.sessions.Current()
	if running == nil {
		return &corev1.GetStatsResponse{Stats: &corev1.StatsTick{}}, nil
	}
	ctx, cancel := requestDeadline(ctx, statsTimeout)
	defer cancel()
	counters, err := running.Counters(ctx)
	if err != nil {
		var mask func(string) string
		if redactor := s.redactors.get(running.ID()); redactor != nil {
			mask = redactor.String
		}
		return &corev1.GetStatsResponse{
			Stats: &corev1.StatsTick{},
			Error: toWire(err, mask, ""),
		}, nil
	}
	return &corev1.GetStatsResponse{Stats: &corev1.StatsTick{
		BytesUp:           counters.BytesUp,
		BytesDown:         counters.BytesDown,
		ActiveConnections: counter(counters.ActiveConnections),
	}}, nil
}

// WatchEvents streams the events of the session and then keeps streaming.
//
// The order of the two halves is the whole point. The subscription is taken
// first and the journal head is remembered; the history is replayed up to that
// head, and the live channel then delivers everything that arrived after it. An
// event appended between the two halves is in both, and the sequence numbers drop
// the duplicate, so a client that reconnects with the sequence it last saw sees
// every event exactly once and never a hole.
func (s *Server) WatchEvents(req *corev1.WatchEventsRequest, stream grpc.ServerStreamingServer[corev1.CoreEvent]) error {
	if _, err := s.checkVersion(req.GetApiVersion()); err != nil {
		return transportStatus(err)
	}
	ctx := stream.Context()
	running := s.sessions.Current()
	if running == nil {
		// Without a session there is nothing to stream, and a stream that ends
		// immediately is how a client learns that.
		return errs.Newf(errs.CodeFailedPrecondition, errs.KeySessionRequired,
			"control: there is no session to watch")
	}
	if wanted := strings.TrimSpace(req.GetSessionId()); wanted != "" && wanted != running.ID() {
		return errs.Newf(errs.CodeNotFound, errs.KeyUnknownSession,
			"control: the request names a session that is not running")
	}
	feed := newEventFeed(running.Journal(), req.GetAfterSequence(), s.redactors.get(running.ID()))
	defer feed.close()

	for _, event := range feed.history() {
		if err := stream.Send(toWireEvent(event, feed.redactor)); err != nil {
			return err
		}
	}
	for {
		select {
		case <-ctx.Done():
			return nil
		case event, ok := <-feed.live:
			if !ok {
				return nil
			}
			if err := stream.Send(toWireEvent(event, feed.redactor)); err != nil {
				return err
			}
		}
	}
}

// eventFeed is the seam between the journal and the event stream. It exists so
// the rule "subscribe first, replay up to the head, drop the duplicates" is a
// thing a test can read and check instead of a comment nobody can verify.
type eventFeed struct {
	journal     *session.Journal
	redactor    *engine.Redactor
	live        <-chan session.Event
	unsubscribe func()
	after       uint64
	head        uint64
}

// newEventFeed subscribes to the journal and remembers where the history ends.
func newEventFeed(journal *session.Journal, after uint64, redactor *engine.Redactor) *eventFeed {
	live, unsubscribe := journal.Subscribe(streamBuffer)
	feed := &eventFeed{
		journal:     journal,
		redactor:    redactor,
		live:        live,
		unsubscribe: unsubscribe,
		after:       after,
	}
	// The head is read after the subscription is in place, which is what makes the
	// two halves cover the journal between them without a hole.
	feed.head = journal.Latest()
	return feed
}

// history returns the events a reconnecting client has not seen: the ones above
// the sequence it named and at or below the head that existed when it subscribed.
func (f *eventFeed) history() []session.Event {
	events := f.journal.Since(f.after, 0)
	out := make([]session.Event, 0, len(events))
	for _, event := range events {
		if event.Sequence > f.head {
			// Beyond the head the live channel already holds it, and sending it
			// twice would make a client count it twice.
			continue
		}
		out = append(out, event)
	}
	return out
}

// close releases the subscription.
func (f *eventFeed) close() {
	if f.unsubscribe != nil {
		f.unsubscribe()
	}
}

// streamBuffer is the queue of one event subscriber. It matches the batching
// limits of the contract: enough for a burst of counters and state changes, small
// enough that a client that stopped reading loses events instead of memory.
const streamBuffer = 128

// toWireEvent renders one journal event onto the contract.
func toWireEvent(event session.Event, redactor *engine.Redactor) *corev1.CoreEvent {
	var mask func(string) string
	if redactor != nil {
		mask = redactor.String
	}
	out := &corev1.CoreEvent{
		Sequence:  event.Sequence,
		SessionId: "",
		EmittedAt: timestampOrNil(event.At),
	}
	switch event.Kind {
	case session.EventState:
		out.Payload = &corev1.CoreEvent_StateChanged{StateChanged: &corev1.StateChanged{
			State: &corev1.ConnectionState{
				Value:      wireStateValue(event.State),
				Reason:     reasonCode(event.Reason),
				ChangedAt:  timestampOrNil(event.At),
				RetryAfter: durationOrNil(event.RetryAfter),
			},
		}}
	case session.EventCounters:
		out.Payload = &corev1.CoreEvent_StatsTick{StatsTick: &corev1.StatsTick{
			BytesUp:           event.Counters.BytesUp,
			BytesDown:         event.Counters.BytesDown,
			ActiveConnections: counter(event.Counters.ActiveConnections),
		}}
	case session.EventLog:
		out.Payload = &corev1.CoreEvent_LogBatch{LogBatch: &corev1.LogBatch{
			Lines: []string{maskText(mask, event.LogLine)},
		}}
	case session.EventProbe:
		probe := &corev1.ProbeResult{}
		if event.Probe != nil {
			probe.ServerId = event.Probe.ServerID
			probe.Reachable = event.Probe.Reachable
			probe.LatencyMs = latency(event.Probe.LatencyMS)
		}
		probe.Error = toWire(errOrNil(event), mask, "")
		out.Payload = &corev1.CoreEvent_ProbeResult{ProbeResult: probe}
	case session.EventError:
		out.Payload = &corev1.CoreEvent_Error{Error: toWire(errOrNil(event), mask, "")}
	default:
		out.Payload = &corev1.CoreEvent_LogBatch{LogBatch: &corev1.LogBatch{
			Lines: []string{maskText(mask, event.Detail)},
		}}
	}
	return out
}

// reasonCode renders a catalog class onto the contract, or nothing when the event
// carries no cause.
func reasonCode(reason errs.Code) corev1.SoraErrorCode {
	if code, ok := wireCodes[reason]; ok {
		return code
	}
	return corev1.SoraErrorCode_SORA_ERROR_CODE_UNSPECIFIED
}

// errOrNil rebuilds a catalog error from an event, so the masking and the key
// rules of toWire apply to a failure that travels on the stream as well.
func errOrNil(event session.Event) error {
	if event.Key == "" && event.Reason == "" {
		return nil
	}
	return errs.New(event.Reason, event.Key, nil).WithDetail(event.Detail)
}

// maskText applies a masking function when there is one.
func maskText(mask func(string) string, text string) string {
	if mask == nil {
		return text
	}
	return mask(text)
}

// ParseImport turns a subscription body into a plan the core can run and returns
// it with references instead of credentials.
//
// This is the moment a secret stops travelling in clear: the parsed credentials go
// straight into the vault, and the client receives only the references. A body
// that cannot be parsed leaves nothing behind in the store.
func (s *Server) ParseImport(_ context.Context, req *corev1.ParseImportRequest) (*corev1.ParseImportResponse, error) {
	id := requestID(req.GetRequestId())
	if _, err := s.checkVersion(req.GetApiVersion()); err != nil {
		return nil, transportStatus(err)
	}
	payload := req.GetPayload()
	if len(payload) == 0 {
		err := errs.Newf(errs.CodeInvalidArgument, errs.KeySubscriptionEmpty,
			"control: the import payload is empty")
		return &corev1.ParseImportResponse{Error: toWire(err, nil, id)}, nil
	}
	if len(payload) > MaxImportBytes {
		err := errs.Newf(errs.CodeResourceExhausted, errs.KeySubscriptionTooLarge,
			"control: the import payload is %d bytes, the limit is %d", len(payload), MaxImportBytes)
		return &corev1.ParseImportResponse{Error: toWire(err, nil, id)}, nil
	}
	if s.secrets == nil {
		err := errs.Newf(errs.CodeFailedPrecondition, errs.KeySecretStoreUnavailable,
			"control: this core cannot store credentials, so it cannot import")
		return &corev1.ParseImportResponse{Error: toWire(err, nil, id)}, nil
	}
	// Parsing a body is bounded by the payload limit and runs in this process, so
	// there is nothing here to cancel: the deadline that matters belongs to the
	// fetch that produced the body. What is bounded is the number of secrets one
	// body may create, and that is the parser's own limit.
	// The payload is detected before it is parsed. A parser that tries every
	// format in turn would accept anything and answer "no servers" for a file of
	// plain text; detecting first turns that into the honest answer, which is
	// that the core does not know what this is.
	if _, err := (parser.ImportDetector{MaxItems: s.parser.MaxItems}).Detect(payload); err != nil {
		return &corev1.ParseImportResponse{Error: toWire(importError(err), nil, id)}, nil
	}
	result, err := s.parser.Parse(payload)
	if err != nil {
		return &corev1.ParseImportResponse{Error: toWire(importError(err), nil, id)}, nil
	}
	if len(result.Servers) == 0 {
		err := errs.Newf(errs.CodeInvalidArgument, errs.KeySubscriptionNoServers,
			"control: the payload produced no usable server")
		return &corev1.ParseImportResponse{Error: toWire(err, nil, id)}, nil
	}

	plan := &corev1.SessionPlan{TunnelMode: corev1.TunnelMode_TUNNEL_MODE_SYSTEM}
	for _, server := range result.Servers {
		reference, err := referenceOf(server)
		if err != nil {
			return &corev1.ParseImportResponse{Error: toWire(err, nil, id)}, nil
		}
		document, err := credentialDocument(server)
		if err != nil {
			return &corev1.ParseImportResponse{Error: toWire(err, nil, id)}, nil
		}
		if err := s.secrets.Put(reference, document); err != nil {
			return &corev1.ParseImportResponse{Error: toWire(err, nil, id)}, nil
		}
		plan.Outbounds = append(plan.Outbounds, outboundToProto(server, reference))
	}
	// No routing rule is invented here. A rule names an outbound, and the only
	// outbounds in this plan are the imported servers; a client that wants a
	// particular split adds the rules it wants, with the targets it can name.
	return &corev1.ParseImportResponse{SessionPlan: plan}, nil
}

// importError maps a parser failure onto the catalog. The parser speaks in its own
// sentinel errors; the control plane is the only place that knows both vocabularies.
func importError(err error) error {
	switch {
	case errors.Is(err, parser.ErrEmptySource):
		return errs.Wrap(err, errs.CodeInvalidArgument, errs.KeySubscriptionEmpty)
	case errors.Is(err, parser.ErrInputTooLarge):
		return errs.Wrap(err, errs.CodeResourceExhausted, errs.KeySubscriptionTooLarge)
	case errors.Is(err, parser.ErrUnsupported):
		return errs.Wrap(err, errs.CodeUnsupported, errs.KeySubscriptionFormat)
	default:
		return errs.Wrap(err, errs.CodeInvalidArgument, errs.KeySubscriptionFormat)
	}
}

// PutSecret stores one piece of credential material under a reference.
func (s *Server) PutSecret(_ context.Context, req *corev1.PutSecretRequest) (*corev1.PutSecretResponse, error) {
	id := requestID(req.GetRequestId())
	if _, err := s.checkVersion(req.GetApiVersion()); err != nil {
		return nil, transportStatus(err)
	}
	reference := req.GetCredentials().GetReference()
	if err := secret.ValidateReference(reference); err != nil {
		return &corev1.PutSecretResponse{Error: toWire(err, nil, id)}, nil
	}
	if s.secrets == nil {
		err := errs.Newf(errs.CodeFailedPrecondition, errs.KeySecretStoreUnavailable,
			"control: this core has no secret store")
		return &corev1.PutSecretResponse{Error: toWire(err, nil, id)}, nil
	}
	if err := s.secrets.Put(reference, req.GetMaterial()); err != nil {
		return &corev1.PutSecretResponse{Error: toWire(err, nil, id)}, nil
	}
	return &corev1.PutSecretResponse{Credentials: req.GetCredentials()}, nil
}

// DeleteSecret removes stored material. Removing a reference that holds nothing
// succeeds, so a cleanup path may run twice.
func (s *Server) DeleteSecret(_ context.Context, req *corev1.DeleteSecretRequest) (*corev1.DeleteSecretResponse, error) {
	id := requestID(req.GetRequestId())
	if _, err := s.checkVersion(req.GetApiVersion()); err != nil {
		return nil, transportStatus(err)
	}
	if err := secret.ValidateReference(req.GetCredentials().GetReference()); err != nil {
		return &corev1.DeleteSecretResponse{Error: toWire(err, nil, id)}, nil
	}
	if s.secrets == nil {
		return &corev1.DeleteSecretResponse{}, nil
	}
	if err := s.secrets.Delete(req.GetCredentials().GetReference()); err != nil {
		return &corev1.DeleteSecretResponse{Error: toWire(err, nil, id)}, nil
	}
	return &corev1.DeleteSecretResponse{}, nil
}

// FetchSubscription retrieves a subscription by reference and returns its servers
// with credentials already in the store, exactly as ParseImport does. The
// reference itself is a bearer token, so it is never logged, never returned and
// never used to build a file name.
func (s *Server) FetchSubscription(ctx context.Context, req *corev1.FetchSubscriptionRequest) (*corev1.FetchSubscriptionResponse, error) {
	id := requestID(req.GetRequestId())
	if _, err := s.checkVersion(req.GetApiVersion()); err != nil {
		return nil, transportStatus(err)
	}
	if s.fetcher == nil {
		err := errs.Newf(errs.CodeUnsupported, errs.KeySubscriptionFetch,
			"control: this core cannot fetch subscriptions over the network")
		return &corev1.FetchSubscriptionResponse{Error: toWire(err, nil, id)}, nil
	}
	ctx, cancel := requestDeadline(ctx, importTimeout)
	defer cancel()
	fetched, err := s.fetcher.Fetch(ctx, req.GetReference(), subscription.FetchOptions{UserAgent: req.GetUserAgent()})
	if err != nil {
		return &corev1.FetchSubscriptionResponse{Error: toWire(err, nil, id)}, nil
	}
	// The import does the work and returns a plan; a fetch answers with the
	// servers of that plan, because a client that asked for a subscription wants
	// the list, not a session it never asked for.
	imported, importErr := s.ParseImport(ctx, &corev1.ParseImportRequest{
		ApiVersion: req.GetApiVersion(),
		RequestId:  req.GetRequestId(),
		Payload:    fetched.Body,
	})
	if importErr != nil {
		return nil, importErr
	}
	if imported.GetError() != nil {
		return &corev1.FetchSubscriptionResponse{Error: imported.GetError()}, nil
	}
	return &corev1.FetchSubscriptionResponse{
		Outbounds: imported.GetSessionPlan().GetOutbounds(),
		Info:      subscriptionInfoToWire(fetched.Info),
	}, nil
}

func subscriptionInfoToWire(info subscription.Info) *corev1.SubscriptionInfo {
	out := &corev1.SubscriptionInfo{
		Title: info.Title, HasUsage: info.HasUsage,
		UploadBytes: info.Upload, DownloadBytes: info.Download, TotalBytes: info.Total,
		WebPageUrl: info.WebPageURL, SupportUrl: info.SupportURL, Announce: info.Announce,
	}
	if info.UpdateInterval > 0 {
		out.UpdateInterval = durationpb.New(info.UpdateInterval)
	}
	if !info.Expire.IsZero() {
		out.Expire = timestamppb.New(info.Expire)
	}
	return out
}

// ProbeServers measures servers and streams the results as they arrive, so the
// interface fills a list in instead of waiting for all of it.
//
// Endpoints are measured with a TCP connection. Outbounds are measured as the
// options say: by default with a real request through the first engine that
// carries the server, and with a connection where no engine does; the result
// says which of the two it is.
//
// The method takes no context: a server streaming call receives it from the
// stream, and passing one separately would let a caller measure against a deadline
// that does not belong to the connection.
func (s *Server) ProbeServers(req *corev1.ProbeServersRequest, stream grpc.ServerStreamingServer[corev1.ProbeResult]) error {
	if _, err := s.checkVersion(req.GetApiVersion()); err != nil {
		return transportStatus(err)
	}
	ctx, cancel := context.WithCancel(stream.Context())
	defer cancel()
	id := requestID(req.GetRequestId())
	total := len(req.GetEndpoints()) + len(req.GetOutbounds())
	if total == 0 {
		return errs.Newf(errs.CodeInvalidArgument, errs.KeyProbeNoEndpoints,
			"control: the probe request carries no endpoints")
	}
	if total > MaxProbeEndpoints {
		return errs.Newf(errs.CodeResourceExhausted, errs.KeyProbeTooMany,
			"control: the probe request carries %d servers, the limit is %d", total, MaxProbeEndpoints)
	}

	results := make(chan *corev1.ProbeResult, total)
	var wg sync.WaitGroup
	connect := func(endpoints []*corev1.Endpoint, ids []string) error {
		if len(endpoints) == 0 {
			return nil
		}
		if s.prober == nil {
			return errs.Newf(errs.CodeUnsupported, errs.KeyProbeInvalidEndpoint,
				"control: this core cannot probe endpoints")
		}
		found, err := s.prober.Probe(ctx, endpoints, ids)
		if err != nil {
			return err
		}
		wg.Add(1)
		go func() {
			defer wg.Done()
			for r := range found {
				r.Method = probeConnect
				results <- r
			}
		}()
		return nil
	}

	if err := connect(req.GetEndpoints(), nil); err != nil {
		return transportStatus(err)
	}
	if len(req.GetOutbounds()) > 0 {
		if err := s.measureOutbounds(ctx, req, id, results, &wg, connect); err != nil {
			return transportStatus(err)
		}
	}
	go func() {
		wg.Wait()
		close(results)
	}()
	for result := range results {
		if err := stream.Send(result); err != nil {
			return err
		}
	}
	return nil
}

// Probe methods as the results name them.
const (
	probeEngine  = "engine"
	probeConnect = "connect"
)

// measureOutbounds resolves the outbounds of a probe request and measures them
// through engines, falling back to a connection check where the options allow.
func (s *Server) measureOutbounds(ctx context.Context, req *corev1.ProbeServersRequest, id string,
	results chan<- *corev1.ProbeResult, wg *sync.WaitGroup, connect func([]*corev1.Endpoint, []string) error) error {
	opts := req.GetOptions()
	specs := req.GetOutbounds()
	if opts.GetMethod() == corev1.ProbeMethod_PROBE_METHOD_CONNECT || s.measurer == nil {
		if opts.GetMethod() == corev1.ProbeMethod_PROBE_METHOD_ENGINE {
			return errs.Newf(errs.CodeUnsupported, errs.KeyProbeInvalidEndpoint,
				"control: this core cannot measure through an engine")
		}
		endpoints, ids := endpointsOf(specs)
		return connect(endpoints, ids)
	}

	// Engine errors may quote a server or a credential, so every value of the
	// measured outbounds is masked in the results.
	redactor := engine.NewRedactor()
	outbounds := make([]engine.Outbound, 0, len(specs))
	bySpec := make(map[string]*corev1.OutboundSpec, len(specs))
	for i, spec := range specs {
		o, err := outboundFromProto(i, spec, s.secrets)
		if err != nil {
			results <- &corev1.ProbeResult{ServerId: spec.GetId(), Method: probeEngine, Error: toWire(err, nil, id)}
			continue
		}
		redactor.Add(o.Secrets()...)
		redactor.Add(o.Identifiers()...)
		outbounds = append(outbounds, o)
		bySpec[o.ID] = spec
	}
	measured, err := s.measurer.Measure(ctx, outbounds, engine.MeasureOptions{
		URL:         opts.GetUrl(),
		Timeout:     time.Duration(opts.GetTimeoutMs()) * time.Millisecond,
		Concurrency: int(opts.GetConcurrency()),
		Engines:     kinds(opts.GetEngines()),
	})
	if err != nil {
		return err
	}
	auto := opts.GetMethod() == corev1.ProbeMethod_PROBE_METHOD_UNSPECIFIED
	// The results are forwarded as they come; this goroutine holds the wait
	// group, so the fallback below may still add to it.
	wg.Add(1)
	go func() {
		defer wg.Done()
		var orphans []*corev1.OutboundSpec
		for m := range measured {
			if auto && errors.Is(m.Err, engine.ErrNoEngine) {
				orphans = append(orphans, bySpec[m.OutboundID])
				continue
			}
			result := &corev1.ProbeResult{ServerId: m.OutboundID, Method: probeEngine, Engine: string(m.Engine)}
			if m.Err != nil {
				result.Error = toWire(m.Err, redactor.String, id)
			} else {
				result.Reachable = true
				result.LatencyMs = latencyMS(m.Latency)
			}
			results <- result
		}
		endpoints, ids := endpointsOf(orphans)
		if err := connect(endpoints, ids); err != nil {
			for _, spec := range orphans {
				results <- &corev1.ProbeResult{ServerId: spec.GetId(), Method: probeConnect, Error: toWire(err, nil, id)}
			}
		}
	}()
	return nil
}

// latencyMS converts a latency for the wire, saturating rather than wrapping.
func latencyMS(d time.Duration) uint32 {
	ms := d.Milliseconds()
	switch {
	case ms <= 0:
		return 0
	case ms >= math.MaxUint32:
		return math.MaxUint32
	}
	return uint32(ms)
}

func endpointsOf(specs []*corev1.OutboundSpec) ([]*corev1.Endpoint, []string) {
	endpoints := make([]*corev1.Endpoint, 0, len(specs))
	ids := make([]string, 0, len(specs))
	for _, spec := range specs {
		endpoints = append(endpoints, spec.GetEndpoint())
		ids = append(ids, spec.GetId())
	}
	return endpoints, ids
}

// RunDiagnostics answers with a redacted report of the running session.
func (s *Server) RunDiagnostics(ctx context.Context, req *corev1.RunDiagnosticsRequest) (*corev1.RunDiagnosticsResponse, error) {
	id := requestID(req.GetRequestId())
	if _, err := s.checkVersion(req.GetApiVersion()); err != nil {
		return nil, transportStatus(err)
	}
	if err := s.checkSession(req.GetSessionId()); err != nil {
		return &corev1.RunDiagnosticsResponse{Error: toWire(err, nil, id)}, nil
	}
	if s.diagnostics == nil {
		err := errs.Newf(errs.CodeUnsupported, errs.KeyDiagnosticsFailed,
			"control: this core cannot collect diagnostics")
		return &corev1.RunDiagnosticsResponse{Error: toWire(err, nil, id)}, nil
	}
	ctx, cancel := requestDeadline(ctx, importTimeout)
	defer cancel()
	lines, err := s.diagnostics.Run(ctx, s.sessions.Status())
	if err != nil {
		return &corev1.RunDiagnosticsResponse{Error: toWire(err, nil, id)}, nil
	}
	return &corev1.RunDiagnosticsResponse{Report: &corev1.DiagnosticReport{Lines: lines}}, nil
}

// ExportDiagnostics answers with a redacted archive that can be attached to a bug
// report. The archive is built inside the core from values that are already
// masked, so a client cannot widen what it contains.
func (s *Server) ExportDiagnostics(ctx context.Context, req *corev1.ExportDiagnosticsRequest) (*corev1.ExportDiagnosticsResponse, error) {
	id := requestID(req.GetRequestId())
	if _, err := s.checkVersion(req.GetApiVersion()); err != nil {
		return nil, transportStatus(err)
	}
	if err := s.checkSession(req.GetSessionId()); err != nil {
		return &corev1.ExportDiagnosticsResponse{Error: toWire(err, nil, id)}, nil
	}
	if s.diagnostics == nil {
		err := errs.Newf(errs.CodeUnsupported, errs.KeyDiagnosticsFailed,
			"control: this core cannot export diagnostics")
		return &corev1.ExportDiagnosticsResponse{Error: toWire(err, nil, id)}, nil
	}
	ctx, cancel := requestDeadline(ctx, importTimeout)
	defer cancel()
	archive, err := s.diagnostics.Export(ctx, s.sessions.Status())
	if err != nil {
		return &corev1.ExportDiagnosticsResponse{Error: toWire(err, nil, id)}, nil
	}
	return &corev1.ExportDiagnosticsResponse{Archive: archive}, nil
}
