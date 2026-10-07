package control_test

import (
	"context"
	"strings"
	"testing"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"github.com/levvs-one/sora-client/core/control"
	"github.com/levvs-one/sora-client/core/engine"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
	"github.com/levvs-one/sora-client/core/logs"
	"github.com/levvs-one/sora-client/core/secret"
	"github.com/levvs-one/sora-client/core/session"
)

// trackingEngine is a stub engine that also has a connection list.
type trackingEngine struct {
	*stubEngine
	closed []string
}

func (e *trackingEngine) Connections(context.Context) ([]engine.Connection, error) {
	return []engine.Connection{{ID: "c1", Network: "tcp", Host: "example.org", Port: 443, Chain: []string{"Proxy", "Tokyo"}, Download: 10}}, nil
}

func (e *trackingEngine) CloseConnection(_ context.Context, id string) error {
	e.closed = append(e.closed, id)
	return nil
}

func (e *trackingEngine) CloseConnections(context.Context) error {
	e.closed = append(e.closed, "*")
	return nil
}

func newLogServer(t *testing.T, eng engine.Engine) (*control.Server, *logs.Center, *secret.Store) {
	t.Helper()
	store, err := secret.Open(t.TempDir(), secret.Options{Protector: secret.FileProtector{}})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = store.Close() })
	auth, err := control.NewAuthenticator(testToken)
	if err != nil {
		t.Fatal(err)
	}
	center := logs.New(logs.Settings{CaptureLevel: logs.LevelDebug})
	server, err := control.New(control.Config{
		Version: control.Version{Major: 1, Minor: 2, MinSupportedMinor: 1}, Authenticator: auth, Secrets: store, Logs: center,
		Sessions: session.NewManager(session.ManagerConfig{
			TunUp:   noAdapter,
			Factory: func(context.Context, *engine.Plan) (engine.Engine, error) { return eng, nil },
		}),
	})
	if err != nil {
		t.Fatal(err)
	}
	return server, center, store
}

func TestLogCenterRefusesACallerWithoutTheToken(t *testing.T) {
	server, center, _ := newLogServer(t, newStubEngine())
	center.Write(time.Now(), logs.LevelInfo, "xray", "secret place")
	_, err := server.QueryLogs(context.Background(), &corev1.QueryLogsRequest{ApiVersion: clientVersion()})
	if status.Code(err) != codes.Unauthenticated {
		t.Fatalf("QueryLogs without a token = %v", err)
	}
	_, err = server.ListConnections(context.Background(), &corev1.ListConnectionsRequest{ApiVersion: clientVersion(), ControlAuthenticator: []byte("wrong")})
	if status.Code(err) != codes.Unauthenticated {
		t.Fatalf("ListConnections with a wrong token = %v", err)
	}
}

func TestQueryFilterExportAndSettings(t *testing.T) {
	server, center, _ := newLogServer(t, newStubEngine())
	ctx := context.Background()
	for i, line := range []string{"engine started", "dial failed", "dial failed again"} {
		level := logs.LevelInfo
		if i > 0 {
			level = logs.LevelError
		}
		center.Write(time.Now(), level, "mihomo", line)
	}
	got, err := server.QueryLogs(ctx, &corev1.QueryLogsRequest{ApiVersion: clientVersion(), ControlAuthenticator: testToken,
		Filter: &corev1.LogFilter{MinLevel: corev1.LogLevel_LOG_LEVEL_ERROR, Pattern: "^dial"}, Limit: 1})
	if err != nil || got.GetError() != nil {
		t.Fatalf("QueryLogs = %v, %v", got.GetError(), err)
	}
	if len(got.GetEntries()) != 1 || got.GetEntries()[0].GetMessage() != "dial failed again" || got.GetBeforeSequence() == 0 || got.GetStats().GetTotal() != 3 {
		t.Fatalf("page = %v", got)
	}
	bad, _ := server.QueryLogs(ctx, &corev1.QueryLogsRequest{ApiVersion: clientVersion(), ControlAuthenticator: testToken,
		Filter: &corev1.LogFilter{Pattern: "("}})
	if bad.GetError().GetUserMessageKey() != "core.logs.filter_invalid" {
		t.Fatalf("an invalid expression = %v", bad.GetError())
	}

	export, err := server.ExportLogs(ctx, &corev1.ExportLogsRequest{ApiVersion: clientVersion(), ControlAuthenticator: testToken,
		Format: corev1.LogExportFormat_LOG_EXPORT_FORMAT_CSV})
	if err != nil || !strings.HasSuffix(export.GetFileName(), ".csv") || strings.Count(string(export.GetData()), "\n") != 4 {
		t.Fatalf("export = %q %s, %v", export.GetData(), export.GetFileName(), err)
	}

	set, err := server.SetLogSettings(ctx, &corev1.SetLogSettingsRequest{ApiVersion: clientVersion(), ControlAuthenticator: testToken,
		Settings: &corev1.LogSettings{CaptureLevel: corev1.LogLevel_LOG_LEVEL_WARNING, MaxEntries: 1 << 30}})
	if err != nil || set.GetSettings().GetCaptureLevel() != corev1.LogLevel_LOG_LEVEL_WARNING || set.GetSettings().GetMaxEntries() > 200000 {
		t.Fatalf("settings = %v, %v: a client cannot make the record unbounded", set.GetSettings(), err)
	}
	center.Write(time.Now(), logs.LevelInfo, "mihomo", "below the capture level")
	if _, err := server.ClearLogs(ctx, &corev1.ClearLogsRequest{ApiVersion: clientVersion(), ControlAuthenticator: testToken}); err != nil {
		t.Fatal(err)
	}
	if after, _ := server.QueryLogs(ctx, &corev1.QueryLogsRequest{ApiVersion: clientVersion(), ControlAuthenticator: testToken}); len(after.GetEntries()) != 0 {
		t.Fatalf("after clear = %v", after.GetEntries())
	}
}

type logStream struct {
	grpc.ServerStream
	ctx  context.Context
	sent []*corev1.LogEntry
	stop func()
	want int
}

func (s *logStream) Context() context.Context { return s.ctx }
func (s *logStream) Send(e *corev1.LogEntry) error {
	s.sent = append(s.sent, e)
	if len(s.sent) == s.want {
		s.stop()
	}
	return nil
}

func TestWatchLogsReplaysThenFollows(t *testing.T) {
	server, center, _ := newLogServer(t, newStubEngine())
	center.Write(time.Now(), logs.LevelInfo, "core", "one")
	center.Write(time.Now(), logs.LevelInfo, "core", "two")
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	stream := &logStream{ctx: ctx, stop: cancel, want: 2}
	go func() {
		time.Sleep(100 * time.Millisecond)
		center.Write(time.Now(), logs.LevelWarning, "xray", "three")
	}()
	if err := server.WatchLogs(&corev1.WatchLogsRequest{ApiVersion: clientVersion(), ControlAuthenticator: testToken, AfterSequence: 1}, stream); err != nil {
		t.Fatal(err)
	}
	if len(stream.sent) != 2 || stream.sent[0].GetMessage() != "two" || stream.sent[1].GetMessage() != "three" {
		t.Fatalf("watch = %v", stream.sent)
	}
}

func TestConnectionCenterListsAndCloses(t *testing.T) {
	eng := &trackingEngine{stubEngine: newStubEngine()}
	server, _, store := newLogServer(t, eng)
	ctx := context.Background()
	none, err := server.ListConnections(ctx, &corev1.ListConnectionsRequest{ApiVersion: clientVersion(), ControlAuthenticator: testToken})
	if err != nil || none.GetError().GetUserMessageKey() != "core.connections.unavailable" {
		t.Fatalf("without a session = %v, %v", none.GetError(), err)
	}
	connected, err := server.Connect(ctx, &corev1.ConnectRequest{ApiVersion: clientVersion(), SessionPlan: validPlan(t, store), ControlAuthenticator: testToken})
	if err != nil || connected.GetError() != nil {
		t.Fatalf("Connect = %v, %v", connected.GetError(), err)
	}
	t.Cleanup(func() {
		_, _ = server.Disconnect(ctx, &corev1.DisconnectRequest{ApiVersion: clientVersion(), ControlAuthenticator: testToken})
	})
	list, err := server.ListConnections(ctx, &corev1.ListConnectionsRequest{ApiVersion: clientVersion(), ControlAuthenticator: testToken})
	if err != nil || len(list.GetConnections()) != 1 || list.GetConnections()[0].GetHost() != "example.org" || len(list.GetConnections()[0].GetChain()) != 2 {
		t.Fatalf("connections = %v, %v", list, err)
	}
	if _, err := server.CloseConnection(ctx, &corev1.CloseConnectionRequest{ApiVersion: clientVersion(), ControlAuthenticator: testToken, ConnectionId: "c1"}); err != nil || len(eng.closed) != 1 {
		t.Fatalf("close = %v, closed %v", err, eng.closed)
	}
}
