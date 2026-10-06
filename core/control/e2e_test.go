package control_test

import (
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

// TestClientTalksToTheCoreOverTheTransport is the one test that crosses every
// boundary the product is built on: a real gRPC client, over the real local
// transport, against the real control plane, into a real session with a stub
// engine.
//
// Every other test stops at one of those boundaries with a fake on the other side,
// which is what let a lost event and an ignored session identifier survive. Here
// nothing is stubbed except the engine itself, which is the only part that needs
// a network and a device.
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
		Factory: func(context.Context, *engine.Plan) (engine.Engine, error) { return newStubEngine(), nil },
	})
	plane, err := control.New(control.Config{
		// The core answers the versions from the second minor on: a client older
		// than that is told so instead of being served a contract it cannot read.
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
		// The largest answer the contract defines is a plan of four megabytes; a
		// larger request is refused by the transport before the core allocates
		// anything for it.
		grpc.MaxRecvMsgSize(8<<20),
		grpc.MaxSendMsgSize(16<<20),
	)
	corev1.RegisterCoreControlServer(grpcServer, plane)
	served := make(chan error, 1)
	// The listener is handed to gRPC as it is: the peer rule lives in Accept, so
	// the boundary is the same for the real service and for this test.
	go func() { served <- grpcServer.Serve(listener) }()

	connection, err := grpc.NewClient(
		// The target is a placeholder: the transport is the local endpoint, and
		// everything the client needs to reach it is in the dialer.
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

	// The handshake needs no token, which is what a client does first.
	handshake, err := client.Handshake(ctx, &corev1.HandshakeRequest{
		ClientVersion: clientVersion(),
	})
	if err != nil {
		t.Fatalf("Handshake() error = %v", err)
	}
	if handshake.GetNegotiatedVersion().GetMajor() != 1 {
		t.Fatalf("the core answered version %v", handshake.GetNegotiatedVersion())
	}

	// A client that is too old is refused, and it is refused in band: the answer
	// tells it what the core speaks so it can update itself.
	stale, err := client.Handshake(ctx, &corev1.HandshakeRequest{
		ClientVersion: &corev1.ApiVersion{Major: 1, Minor: 0},
	})
	if err != nil {
		t.Fatalf("Handshake() with an old client error = %v", err)
	}
	if stale.GetError() == nil {
		t.Error("a client that speaks a version the core dropped was answered with a session")
	}

	if _, err := client.Connect(ctx, &corev1.ConnectRequest{
		ApiVersion:           clientVersion(),
		SessionPlan:          validPlan(t, store),
		ControlAuthenticator: testToken,
	}); err != nil {
		t.Fatalf("Connect() error = %v", err)
	}

	// A wrong token is refused at the transport, before the plan is read and
	// before the engine is started: a caller that cannot authenticate gets
	// nothing, and the running session is left alone.
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

	// A client that names another session is refused, which is the check that was
	// missing when this test was written.
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

	// The event stream starts with the history the client missed, and the first
	// event a fresh client sees is the session coming up.
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

	// An import over the same connection stores what it stores and answers with
	// a plan whose references the store knows.
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

// testEndpointAddress returns an address for the endpoint that cannot collide with
// a running core.
func testEndpointAddress(t *testing.T) string {
	t.Helper()
	if strings.HasPrefix(ipc.ListenAddress(), `\\.\pipe\`) {
		return `\\.\pipe\sora-core-e2e-` + strings.ReplaceAll(t.Name(), "/", "-")
	}
	return filepath.Join(t.TempDir(), "core.sock")
}
