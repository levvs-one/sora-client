package control_test

import (
	"context"
	"strings"
	"testing"
	"time"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"github.com/levvs-one/sora-client/core/control"
	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/errs"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
	"github.com/levvs-one/sora-client/core/secret"
	"github.com/levvs-one/sora-client/core/session"
	"github.com/levvs-one/sora-client/core/subscription"
)

// stubEngine is an engine that answers without touching the system, so the tests
// exercise the control plane and not the tunnel.
type stubEngine struct {
	bus     *engine.EventBus
	state   engine.State
	applied int
}

func newStubEngine() *stubEngine {
	return &stubEngine{bus: engine.NewEventBus(8), state: engine.StateIdle}
}

func (e *stubEngine) Kind() engine.Kind                            { return engine.KindMihomo }
func (e *stubEngine) Capabilities() engine.Capabilities            { return engine.Catalog[engine.KindMihomo] }
func (e *stubEngine) Events() *engine.EventBus                     { return e.bus }
func (e *stubEngine) Version() engine.Version                      { return engine.Version{Raw: "1.19.32"} }
func (e *stubEngine) State() engine.State                          { return e.state }
func (e *stubEngine) Validate(context.Context, *engine.Plan) error { return nil }

func (e *stubEngine) Apply(context.Context, *engine.Plan) error {
	e.applied++
	e.state = engine.StateRunning
	return nil
}

func (e *stubEngine) Stop(context.Context) error {
	e.state = engine.StateStopped
	return nil
}
func (e *stubEngine) Close() error                                         { return nil }
func (e *stubEngine) Groups(context.Context) ([]engine.GroupStatus, error) { return nil, nil }
func (e *stubEngine) Select(context.Context, string, string) error         { return nil }
func (e *stubEngine) Delay(context.Context, string, string, time.Duration) (time.Duration, error) {
	return 0, nil
}
func (e *stubEngine) Counters(context.Context) (engine.Counters, error) {
	return engine.Counters{BytesUp: 10, BytesDown: 20, ActiveConnections: 1}, nil
}

// newTestServer builds a control plane over a stub engine and a real store in a
// temporary directory. The token is fixed across tests so a failure reproduces.
func newTestServer(t *testing.T) (*control.Server, *secret.Store) {
	t.Helper()
	store, err := secret.Open(t.TempDir(), secret.Options{Protector: secret.FileProtector{}})
	if err != nil {
		t.Fatalf("opening the secret store: %v", err)
	}
	t.Cleanup(func() { _ = store.Close() })

	auth, err := control.NewAuthenticator(testToken)
	if err != nil {
		t.Fatalf("NewAuthenticator() error = %v", err)
	}
	manager := session.NewManager(session.ManagerConfig{
		Factory: func(context.Context, *engine.Plan) (engine.Engine, error) {
			return newStubEngine(), nil
		},
		Backoff: engine.Backoff{Initial: time.Millisecond, Max: time.Millisecond, Factor: 1},
		Budget:  func() *engine.RestartBudget { return engine.NewRestartBudget(2, time.Minute, nil) },
	})
	server, err := control.New(control.Config{
		Version:       control.Version{Major: 1, Minor: 2, MinSupportedMinor: 1},
		Authenticator: auth,
		Sessions:      manager,
		Secrets:       store,
	})
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}
	return server, store
}

// testToken is the token every test presents. It protects nothing but a temporary
// directory, and being fixed makes a failure reproducible.
var testToken = func() []byte {
	out := make([]byte, control.TokenLen)
	for i := range out {
		out[i] = byte(i + 1)
	}
	return out
}()

func clientVersion() *corev1.ApiVersion {
	return &corev1.ApiVersion{Major: 1, Minor: 2, MinSupportedMinor: 1}
}

// validPlan is a plan with one server and one reference that the store knows.
func validPlan(t *testing.T, store *secret.Store) *corev1.SessionPlan {
	t.Helper()
	reference, err := secret.NewReference()
	if err != nil {
		t.Fatalf("NewReference() error = %v", err)
	}
	if err := store.Put(reference, []byte(`{"uuid":"11111111-1111-4111-8111-111111111111","server_name":"de1.example.com"}`)); err != nil {
		t.Fatalf("seeding the store: %v", err)
	}
	return &corev1.SessionPlan{
		TunnelMode: corev1.TunnelMode_TUNNEL_MODE_SYSTEM,
		Outbounds: []*corev1.OutboundSpec{{
			Id:          "out-1",
			DisplayName: "Berlin",
			Protocol:    "vless",
			Transport:   "tcp",
			Security:    "tls",
			Endpoint:    &corev1.Endpoint{Host: "de1.example.com", Port: 443},
			Credentials: &corev1.CredentialsRef{Reference: reference},
		}},
	}
}

// Compile-time proof that the fetcher of the subscription package is what the
// control plane asks for. If the two ever drift, this fails next to the change
// rather than in a service.
var _ control.Fetcher = (*subscription.Fetcher)(nil)

func TestNewRequiresItsCollaborators(t *testing.T) {
	auth, err := control.NewAuthenticator(testToken)
	if err != nil {
		t.Fatalf("NewAuthenticator() error = %v", err)
	}
	if _, err := control.New(control.Config{Authenticator: auth}); errs.KeyOf(err) != errs.KeySessionRequired {
		t.Errorf("without sessions = %v, key = %q", err, errs.KeyOf(err))
	}
	manager := session.NewManager(session.ManagerConfig{
		Factory: func(context.Context, *engine.Plan) (engine.Engine, error) { return newStubEngine(), nil },
	})
	if _, err := control.New(control.Config{Sessions: manager}); errs.KeyOf(err) != errs.KeyUnauthenticated {
		t.Errorf("without an authenticator = %v, key = %q", err, errs.KeyOf(err))
	}
}

func TestHandshakeNeedsNoAuthenticator(t *testing.T) {
	server, _ := newTestServer(t)
	response, err := server.Handshake(context.Background(), &corev1.HandshakeRequest{})
	if err != nil {
		t.Fatalf("Handshake() error = %v", err)
	}
	version := response.GetNegotiatedVersion()
	if version.GetMajor() != 1 || version.GetMinor() != 2 {
		t.Errorf("version = %d.%d, want 1.2", version.GetMajor(), version.GetMinor())
	}
	if len(version.GetCapabilities()) == 0 {
		t.Error("the core advertised no capabilities, so an interface cannot decide what to show")
	}
}

func TestConnectRefusesABadTokenBeforeTouchingAnything(t *testing.T) {
	server, _ := newTestServer(t)
	_, err := server.Connect(context.Background(), &corev1.ConnectRequest{
		ApiVersion: clientVersion(),
		SessionPlan: &corev1.SessionPlan{Outbounds: []*corev1.OutboundSpec{{
			Id: "a", Protocol: "vless", Endpoint: &corev1.Endpoint{Host: "de.example.com", Port: 443},
		}}},
		ControlAuthenticator: []byte("not the token at all, and long enough to compare"),
		RequestId:            "req-1",
	})
	if status.Code(err) != codes.Unauthenticated {
		t.Fatalf("Connect() with a wrong token = %v, code = %s", err, status.Code(err))
	}
}

func TestConnectRefusesAClientItCannotServe(t *testing.T) {
	server, _ := newTestServer(t)
	_, err := server.Connect(context.Background(), &corev1.ConnectRequest{
		ApiVersion:           &corev1.ApiVersion{Major: 9, Minor: 9},
		ControlAuthenticator: testToken,
	})
	if status.Code(err) != codes.FailedPrecondition {
		t.Errorf("Connect() from a future major = %v, code = %s", err, status.Code(err))
	}
}

func TestConnectResolvesSecretsAndStartsTheSession(t *testing.T) {
	server, store := newTestServer(t)
	response, err := server.Connect(context.Background(), &corev1.ConnectRequest{
		ApiVersion:           clientVersion(),
		RequestId:            "req-2",
		SessionPlan:          validPlan(t, store),
		ControlAuthenticator: testToken,
	})
	if err != nil {
		t.Fatalf("Connect() error = %v", err)
	}
	if response.GetError() != nil {
		t.Fatalf("Connect() failed with %v", response.GetError())
	}
	connection := response.GetStatus().GetConnection()
	if connection.GetValue() != corev1.ConnectionStateValue_CONNECTION_STATE_VALUE_CONNECTED {
		t.Errorf("state = %s, want connected", connection.GetValue())
	}
	if connection.GetSessionId() == "" {
		t.Error("the core did not name the session it started")
	}
	t.Cleanup(func() {
		_, _ = server.Disconnect(context.Background(), &corev1.DisconnectRequest{
			ApiVersion:           clientVersion(),
			ControlAuthenticator: testToken,
		})
	})
}

func TestConnectReportsAPlanItRefusesInBand(t *testing.T) {
	server, _ := newTestServer(t)
	tests := []struct {
		name string
		plan *corev1.SessionPlan
		key  errs.Key
	}{
		{
			name: "no outbounds",
			plan: &corev1.SessionPlan{},
			key:  errs.KeyPlanEmpty,
		},
		{
			name: "unknown secret",
			plan: &corev1.SessionPlan{Outbounds: []*corev1.OutboundSpec{{
				Id:          "out-1",
				Protocol:    "vless",
				Endpoint:    &corev1.Endpoint{Host: "de1.example.com", Port: 443},
				Credentials: &corev1.CredentialsRef{Reference: "s1_missing"},
			}}},
			key: errs.KeySecretNotFound,
		},
		{
			name: "impossible port",
			plan: &corev1.SessionPlan{Outbounds: []*corev1.OutboundSpec{{
				Id:       "out-1",
				Protocol: "vless",
				Endpoint: &corev1.Endpoint{Host: "de1.example.com", Port: 70000},
			}}},
			key: errs.KeyPlanOutbounds,
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			response, err := server.Connect(context.Background(), &corev1.ConnectRequest{
				ApiVersion:           clientVersion(),
				SessionPlan:          tt.plan,
				ControlAuthenticator: testToken,
			})
			if err != nil {
				t.Fatalf("Connect() error = %v, want a failure inside the answer", err)
			}
			if response.GetError().GetUserMessageKey() != string(tt.key) {
				t.Errorf("key = %q, want %q (detail %q)",
					response.GetError().GetUserMessageKey(), tt.key, response.GetError().GetDetailRedacted())
			}
			if response.GetError().GetRequestId() == "" {
				t.Error("the failure carries no request id, so a report cannot be matched to a call")
			}
		})
	}
}

func TestDisconnectRefusesToStopSomeoneElsesSession(t *testing.T) {
	server, store := newTestServer(t)
	response, err := server.Connect(context.Background(), &corev1.ConnectRequest{
		ApiVersion:           clientVersion(),
		SessionPlan:          validPlan(t, store),
		ControlAuthenticator: testToken,
	})
	if err != nil || response.GetError() != nil {
		t.Fatalf("Connect() = %v, %v", err, response.GetError())
	}
	t.Cleanup(func() {
		_, _ = server.Disconnect(context.Background(), &corev1.DisconnectRequest{
			ApiVersion:           clientVersion(),
			ControlAuthenticator: testToken,
		})
	})
	other, err := server.Disconnect(context.Background(), &corev1.DisconnectRequest{
		ApiVersion:           clientVersion(),
		SessionId:            "s_not_the_running_one",
		ControlAuthenticator: testToken,
	})
	if err != nil {
		t.Fatalf("Disconnect() error = %v", err)
	}
	if other.GetError().GetCode() != corev1.SoraErrorCode_SORA_ERROR_CODE_NOT_FOUND {
		t.Errorf("Disconnect() of a foreign session = %v, want not found", other.GetError())
	}
	answer, err := server.GetStatus(context.Background(), &corev1.GetStatusRequest{ApiVersion: clientVersion()})
	if err != nil {
		t.Fatalf("GetStatus() error = %v", err)
	}
	if answer.GetStatus().GetConnection().GetValue() != corev1.ConnectionStateValue_CONNECTION_STATE_VALUE_CONNECTED {
		t.Error("a refused disconnect still stopped the running session")
	}
}

func TestGetStatsWithoutASessionIsNotAFailure(t *testing.T) {
	server, _ := newTestServer(t)
	answer, err := server.GetStats(context.Background(), &corev1.GetStatsRequest{ApiVersion: clientVersion()})
	if err != nil {
		t.Fatalf("GetStats() error = %v", err)
	}
	if answer.GetError() != nil {
		t.Errorf("GetStats() of nothing reported %v", answer.GetError())
	}
	if answer.GetStats() == nil {
		t.Error("GetStats() returned no tick at all, so a client cannot render zero")
	}
}

func TestParseImportStoresSecretsAndReturnsOnlyReferences(t *testing.T) {
	server, store := newTestServer(t)
	// A share link with a password in the query, the way a subscription carries
	// one. The uuid is the credential the core must keep for itself.
	const link = "vless://11111111-1111-4111-8111-111111111111@de1.example.com:443" +
		"?encryption=none&security=tls&sni=de1.example.com#Berlin"
	response, err := server.ParseImport(context.Background(), &corev1.ParseImportRequest{
		ApiVersion: clientVersion(),
		RequestId:  "req-import",
		Payload:    []byte(link),
	})
	if err != nil {
		t.Fatalf("ParseImport() error = %v", err)
	}
	if response.GetError() != nil {
		t.Fatalf("ParseImport() failed with %v", response.GetError())
	}
	outbounds := response.GetSessionPlan().GetOutbounds()
	if len(outbounds) != 1 {
		t.Fatalf("import produced %d outbounds, want 1", len(outbounds))
	}
	reference := outbounds[0].GetCredentials().GetReference()
	if reference == "" {
		t.Fatal("the imported server carries no credential reference")
	}
	if secret.ValidateReference(reference) != nil {
		t.Errorf("the reference %q is not one the store would accept", reference)
	}
	material, err := store.Get(reference)
	if err != nil {
		t.Fatalf("the store does not hold %q: %v", reference, err)
	}
	if !strings.Contains(string(material), "11111111-1111-4111-8111-111111111111") {
		t.Errorf("the stored material does not hold the uuid: %q", material)
	}
	// Nothing that leaves the core may hold the credential.
	rendered := response.String()
	if strings.Contains(rendered, "11111111-1111-4111-8111-111111111111") {
		t.Errorf("the answer leaks the uuid: %s", rendered)
	}
}

func TestParseImportRefusesWhatItCannotParse(t *testing.T) {
	server, _ := newTestServer(t)
	tests := []struct {
		name    string
		payload []byte
		key     errs.Key
	}{
		{"empty", nil, errs.KeySubscriptionEmpty},
		{"not a subscription", []byte("just some text nobody can parse"), errs.KeySubscriptionFormat},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			response, err := server.ParseImport(context.Background(), &corev1.ParseImportRequest{
				ApiVersion: clientVersion(),
				Payload:    tt.payload,
			})
			if err != nil {
				t.Fatalf("ParseImport() error = %v", err)
			}
			if response.GetError().GetUserMessageKey() != string(tt.key) {
				t.Errorf("key = %q, want %q", response.GetError().GetUserMessageKey(), tt.key)
			}
			if response.GetSessionPlan() != nil {
				t.Error("a refused import still returned a plan")
			}
		})
	}
}

func TestSecretLifecycle(t *testing.T) {
	server, store := newTestServer(t)
	reference, err := secret.NewReference()
	if err != nil {
		t.Fatalf("NewReference() error = %v", err)
	}
	put, err := server.PutSecret(context.Background(), &corev1.PutSecretRequest{
		ApiVersion: clientVersion(),
		RequestId:  "req-put",
		Credentials: &corev1.CredentialsRef{
			Reference: reference,
		},
		Material: []byte(`{"uuid":"22222222-2222-4222-8222-222222222222"}`),
	})
	if err != nil {
		t.Fatalf("PutSecret() error = %v", err)
	}
	if put.GetError() != nil {
		t.Fatalf("PutSecret() failed with %v", put.GetError())
	}
	if got, err := store.Get(reference); err != nil || !strings.Contains(string(got), "22222222") {
		t.Errorf("the store holds %q, err = %v", got, err)
	}

	removed, err := server.DeleteSecret(context.Background(), &corev1.DeleteSecretRequest{
		ApiVersion:  clientVersion(),
		Credentials: &corev1.CredentialsRef{Reference: reference},
	})
	if err != nil {
		t.Fatalf("DeleteSecret() error = %v", err)
	}
	if removed.GetError() != nil {
		t.Fatalf("DeleteSecret() failed with %v", removed.GetError())
	}
	if store.Has(reference) {
		t.Error("the secret survived its deletion")
	}
	// Deleting twice is a cleanup path that runs again, and it must succeed.
	again, err := server.DeleteSecret(context.Background(), &corev1.DeleteSecretRequest{
		ApiVersion:  clientVersion(),
		Credentials: &corev1.CredentialsRef{Reference: reference},
	})
	if err != nil || again.GetError() != nil {
		t.Errorf("deleting twice = %v, %v", err, again.GetError())
	}
}

// TestRepeatedImportsDoNotGrowTheStore is the test for the promise the reference
// scheme makes: importing the same subscription again must leave the store with
// the same secrets, not a second copy of each one. A store that grows on every
// refresh is a store that eventually refuses to start, and the credentials in it
// are copies nobody chose to keep.
func TestRepeatedImportsDoNotGrowTheStore(t *testing.T) {
	server, store := newTestServer(t)
	const link = "vless://11111111-1111-4111-8111-111111111111@de1.example.com:443" +
		"?encryption=none&security=tls&sni=de1.example.com#Berlin"

	var references []string
	for attempt := range 3 {
		response, err := server.ParseImport(context.Background(), &corev1.ParseImportRequest{
			ApiVersion: clientVersion(),
			RequestId:  "req-import",
			Payload:    []byte(link),
		})
		if err != nil {
			t.Fatalf("ParseImport() error = %v", err)
		}
		if response.GetError() != nil {
			t.Fatalf("import %d failed with %v", attempt, response.GetError())
		}
		references = append(references, response.GetSessionPlan().GetOutbounds()[0].GetCredentials().GetReference())
	}
	if references[0] != references[1] || references[1] != references[2] {
		t.Errorf("the same server produced different references: %v", references)
	}
	if got := store.Len(); got != 1 {
		t.Errorf("three imports of one server left %d secrets, want 1", got)
	}
	if refs := store.Refs(); len(refs) != 1 || refs[0] != references[0] {
		t.Errorf("the store holds %v, want only %s", refs, references[0])
	}
	// The reference is derived from the server, so it must not carry its host or
	// its name in clear: a reference is written to disk and copied around.
	if strings.Contains(references[0], "de1.example.com") || strings.Contains(references[0], "Berlin") {
		t.Errorf("the reference %q names the server", references[0])
	}
}

func TestSecretMethodsRefuseABadReference(t *testing.T) {
	server, _ := newTestServer(t)
	put, err := server.PutSecret(context.Background(), &corev1.PutSecretRequest{
		ApiVersion:  clientVersion(),
		Credentials: &corev1.CredentialsRef{Reference: "../escape"},
		Material:    []byte("{}"),
	})
	if err != nil {
		t.Fatalf("PutSecret() error = %v", err)
	}
	if put.GetError().GetCode() != corev1.SoraErrorCode_SORA_ERROR_CODE_INVALID_ARGUMENT {
		t.Errorf("PutSecret() with a path reference = %v", put.GetError())
	}
}
