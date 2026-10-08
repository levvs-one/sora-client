package control_test

import (
	"bytes"
	"context"
	"net"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/credentials/insecure"
	"google.golang.org/grpc/status"

	"github.com/levvs-one/sora-client/core/control"
	"github.com/levvs-one/sora-client/core/engine"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
	"github.com/levvs-one/sora-client/core/ipc"
	"github.com/levvs-one/sora-client/core/secret"
	"github.com/levvs-one/sora-client/core/session"
)

// TestClientTalksToTheCoreOverTheTransport exercises a real gRPC client, local
// transport, control plane, and session. Only the engine is stubbed to avoid
// network and device dependencies.
func TestClientTalksToTheCoreOverTheTransport(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	store, err := secret.Open(t.TempDir(), secret.Options{Protector: secret.FileProtector{}})
	if err != nil {
		t.Fatalf("opening the secret store: %v", err)
	}
	defer func() { _ = store.Close() }()

	auth, err := control.NewAuthenticator(testToken)
	if err != nil {
		t.Fatalf("NewAuthenticator() error = %v", err)
	}
	manager := session.NewManager(session.ManagerConfig{
		TunUp:   noAdapter,
		Factory: func(context.Context, *engine.Plan) (engine.Engine, error) { return newStubEngine(), nil },
	})
	plane, err := control.New(control.Config{
		// Reject clients below the supported minor version instead of
		// serving an unreadable contract.
		Version:       control.Version{Major: 1, Minor: 2, MinSupportedMinor: 1},
		Authenticator: auth,
		Sessions:      manager,
		Secrets:       store,
	})
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}

	address := testEndpointAddress(t)
	listener, err := ipc.Listen(ctx, ipc.Options{Address: address})
	if err != nil {
		t.Fatalf("Listen() error = %v", err)
	}
	grpcServer := grpc.NewServer(
		// The transport enforces the four-megabyte plan limit before
		// payload allocation.
		grpc.MaxRecvMsgSize(8<<20),
		grpc.MaxSendMsgSize(16<<20),
	)
	corev1.RegisterCoreControlServer(grpcServer, plane)
	served := make(chan error, 1)
	// Peer checks belong in Accept, matching the real service's transport
	// boundary.
	go func() { served <- grpcServer.Serve(listener) }()

	connection, err := grpc.NewClient(
		// The dialer selects the local endpoint; the gRPC target is
		// unused.
		"passthrough:///sora-core",
		grpc.WithContextDialer(func(ctx context.Context, _ string) (net.Conn, error) {
			return ipc.Dial(ctx, address)
		}),
		grpc.WithTransportCredentials(insecure.NewCredentials()),
		grpc.WithDefaultCallOptions(grpc.MaxCallRecvMsgSize(16<<20)),
	)
	if err != nil {
		t.Fatalf("the client refused to start: %v", err)
	}
	defer func() { _ = connection.Close() }()
	client := corev1.NewCoreControlClient(connection)

	handshake, err := client.Handshake(ctx, &corev1.HandshakeRequest{
		ClientVersion: clientVersion(),
	})
	if err != nil {
		t.Fatalf("Handshake() error = %v", err)
	}
	if handshake.GetNegotiatedVersion().GetMajor() != 1 {
		t.Fatalf("the core answered version %v", handshake.GetNegotiatedVersion())
	}
	if !bytes.Equal(handshake.GetControlAuthenticator(), testToken) {
		t.Fatal("an admitted client must receive the token: it cannot read the token file of a system core")
	}

	// Version failures must include the supported contract in the response.
	stale, err := client.Handshake(ctx, &corev1.HandshakeRequest{
		ClientVersion: &corev1.ApiVersion{Major: 1, Minor: 0},
	})
	if err != nil {
		t.Fatalf("Handshake() with an old client error = %v", err)
	}
	if stale.GetError() == nil {
		t.Error("a client that speaks a version the core dropped was answered with a session")
	}
	if len(stale.GetControlAuthenticator()) != 0 {
		t.Error("a refused client must not receive the token")
	}

	if _, err := client.Connect(ctx, &corev1.ConnectRequest{
		ApiVersion:           clientVersion(),
		SessionPlan:          validPlan(t, store),
		ControlAuthenticator: testToken,
	}); err != nil {
		t.Fatalf("Connect() error = %v", err)
	}

	// Reject bad tokens before reading the plan or starting an engine,
	// leaving the current session unchanged.
	refused, err := client.Connect(ctx, &corev1.ConnectRequest{
		ApiVersion:           clientVersion(),
		SessionPlan:          validPlan(t, store),
		ControlAuthenticator: make([]byte, control.TokenLen),
	})
	if err == nil {
		t.Fatalf("a wrong token was accepted: %v", refused)
	}
	if code := status.Code(err); code != codes.Unauthenticated {
		t.Errorf("a wrong token answered %s, want unauthenticated", code)
	}

	status, err := client.GetStatus(ctx, &corev1.GetStatusRequest{ApiVersion: clientVersion()})
	if err != nil {
		t.Fatalf("GetStatus() error = %v", err)
	}
	connected := status.GetStatus().GetConnection().GetValue() ==
		corev1.ConnectionStateValue_CONNECTION_STATE_VALUE_CONNECTED
	if !connected {
		t.Fatalf("after a successful connect the state is %s",
			status.GetStatus().GetConnection().GetValue())
	}
	sessionID := status.GetStatus().GetConnection().GetSessionId()
	if sessionID == "" {
		t.Fatal("the core did not name the session it started")
	}

	// Requests for another session must be rejected.
	foreign, err := client.GetStatus(ctx, &corev1.GetStatusRequest{
		ApiVersion: clientVersion(),
		SessionId:  "s_not_the_running_one",
	})
	if err != nil {
		t.Fatalf("GetStatus() with a foreign session error = %v", err)
	}
	if foreign.GetError().GetCode() != corev1.SoraErrorCode_SORA_ERROR_CODE_NOT_FOUND {
		t.Errorf("a foreign session answered %v, want not found", foreign.GetError())
	}

	// A fresh stream must replay session startup before live events.
	events, err := client.WatchEvents(ctx, &corev1.WatchEventsRequest{
		ApiVersion: clientVersion(),
		SessionId:  sessionID,
	})
	if err != nil {
		t.Fatalf("WatchEvents() error = %v", err)
	}
	event, err := events.Recv()
	if err != nil {
		t.Fatalf("the event stream is empty: %v", err)
	}
	if event.GetStateChanged() == nil {
		t.Errorf("the first event is %v, want a state change", event)
	}

	// Imported plans must reference credentials present in the store.
	imported, err := client.ParseImport(ctx, &corev1.ParseImportRequest{
		ApiVersion: clientVersion(),
		RequestId:  "e2e-import",
		Payload: []byte("vless://11111111-1111-4111-8111-111111111111@de1.example.com:443" +
			"?encryption=none&security=tls&sni=de1.example.com#Berlin"),
	})
	if err != nil {
		t.Fatalf("ParseImport() error = %v", err)
	}
	if imported.GetError() != nil {
		t.Fatalf("the import failed with %v", imported.GetError())
	}
	reference := imported.GetSessionPlan().GetOutbounds()[0].GetCredentials().GetReference()
	if got, err := store.Get(reference); err != nil || len(got) == 0 {
		t.Errorf("the reference from the plan is not in the store: %v", err)
	}

	if _, err := client.Disconnect(ctx, &corev1.DisconnectRequest{
		ApiVersion:           clientVersion(),
		SessionId:            sessionID,
		ControlAuthenticator: testToken,
	}); err != nil {
		t.Fatalf("Disconnect() error = %v", err)
	}
	after, err := client.GetStatus(ctx, &corev1.GetStatusRequest{ApiVersion: clientVersion()})
	if err != nil {
		t.Fatalf("GetStatus() after a disconnect error = %v", err)
	}
	if after.GetStatus().GetConnection().GetValue() !=
		corev1.ConnectionStateValue_CONNECTION_STATE_VALUE_DISCONNECTED {
		t.Errorf("after a disconnect the state is %s",
			after.GetStatus().GetConnection().GetValue())
	}

	cancel()
	select {
	case <-served:
	case <-time.After(5 * time.Second):
		t.Error("the transport did not stop when the service did")
	}
}

// testEndpointAddress returns an endpoint address distinct from a running core.
func testEndpointAddress(t *testing.T) string {
	t.Helper()
	if strings.HasPrefix(ipc.ListenAddress(), `\\.\pipe\`) {
		return `\\.\pipe\sora-core-e2e-` + strings.ReplaceAll(t.Name(), "/", "-")
	}
	return filepath.Join(t.TempDir(), "core.sock")
}
