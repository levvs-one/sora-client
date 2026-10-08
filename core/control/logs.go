package control

import (
	"context"
	"maps"
	"math"
	"slices"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/types/known/timestamppb"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/errs"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
	"github.com/levvs-one/sora-client/core/logs"
)

// Logs and connection lists expose destinations, so these methods require a
// token even on the account-restricted transport.

// authorize checks the API version, then the token, returning transport errors.
func (s *Server) authorize(version *corev1.ApiVersion, token []byte) error {
	if _, err := s.checkVersion(version); err != nil {
		return transportStatus(err)
	}
	if err := s.auth.Check(token); err != nil {
		return transportStatus(err)
	}
	return nil
}

func (s *Server) logCenter() (*logs.Center, error) {
	if s.logs == nil {
		return nil, errs.Newf(errs.CodeUnsupported, errs.KeyLogsUnavailable, "control: this core keeps no log record")
	}
	return s.logs, nil
}

var levelsToWire = map[logs.Level]corev1.LogLevel{
	logs.LevelDebug:   corev1.LogLevel_LOG_LEVEL_DEBUG,
	logs.LevelInfo:    corev1.LogLevel_LOG_LEVEL_INFO,
	logs.LevelWarning: corev1.LogLevel_LOG_LEVEL_WARNING,
	logs.LevelError:   corev1.LogLevel_LOG_LEVEL_ERROR,
}

func levelFromWire(l corev1.LogLevel) logs.Level {
	for level, wire := range levelsToWire {
		if wire == l {
			return level
		}
	}
	return 0
}

func entryToWire(e logs.Entry) *corev1.LogEntry {
	return &corev1.LogEntry{Sequence: e.Seq, Time: timestamppb.New(e.Time), Level: levelsToWire[e.Level],
		Source: e.Source, Message: e.Message, Repeat: e.Repeat}
}

func filterFromWire(f *corev1.LogFilter) (logs.Filter, error) {
	pattern, err := logs.CompilePattern(f.GetPattern())
	if err != nil {
		return logs.Filter{}, errs.Newf(errs.CodeInvalidArgument, errs.KeyLogFilterInvalid,
			"control: the log filter expression is not usable")
	}
	out := logs.Filter{MinLevel: levelFromWire(f.GetMinLevel()), Sources: f.GetSources(), Contains: f.GetContains(), Pattern: pattern}
	if f.GetSince() != nil {
		out.Since = f.GetSince().AsTime()
	}
	if f.GetUntil() != nil {
		out.Until = f.GetUntil().AsTime()
	}
	if !out.Since.IsZero() && !out.Until.IsZero() && out.Until.Before(out.Since) {
		return logs.Filter{}, errs.Newf(errs.CodeInvalidArgument, errs.KeyLogFilterInvalid,
			"control: the log filter ends before it starts")
	}
	return out, nil
}

func statsToWire(st logs.Stats) *corev1.LogStats {
	out := &corev1.LogStats{Total: count(st.Total), Bytes: count(st.Bytes), MaxBytes: count(st.MaxBytes), Dropped: st.Dropped}
	for _, level := range []logs.Level{logs.LevelDebug, logs.LevelInfo, logs.LevelWarning, logs.LevelError} {
		out.ByLevel = append(out.ByLevel, &corev1.LogLevelCount{Level: levelsToWire[level], Count: count(st.ByLevel[level])})
	}
	sources := slices.Sorted(maps.Keys(st.BySource))
	for _, source := range sources {
		out.BySource = append(out.BySource, &corev1.LogSourceCount{Source: source, Count: count(st.BySource[source])})
	}
	return out
}

// count converts a non-negative size to the wire type.
func count(n int) uint64 {
	if n < 0 {
		return 0
	}
	return uint64(n)
}

// bound clamps a setting to the wire uint32 range.
func bound(n int) uint32 {
	switch {
	case n < 0:
		return 0
	case int64(n) > math.MaxUint32:
		return math.MaxUint32
	}
	return uint32(n)
}

// QueryLogs returns one log page, newest first.
func (s *Server) QueryLogs(_ context.Context, req *corev1.QueryLogsRequest) (*corev1.QueryLogsResponse, error) {
	if err := s.authorize(req.GetApiVersion(), req.GetControlAuthenticator()); err != nil {
		return nil, err
	}
	center, err := s.logCenter()
	if err != nil {
		return &corev1.QueryLogsResponse{Error: toWire(err, nil, "")}, nil
	}
	filter, err := filterFromWire(req.GetFilter())
	if err != nil {
		return &corev1.QueryLogsResponse{Error: toWire(err, nil, "")}, nil
	}
	page := center.Query(filter, req.GetBeforeSequence(), int(req.GetLimit()))
	out := &corev1.QueryLogsResponse{BeforeSequence: page.Before, Stats: statsToWire(page.Stats)}
	for _, e := range page.Entries {
		out.Entries = append(out.Entries, entryToWire(e))
	}
	return out, nil
}

// WatchLogs replays entries after the cursor and follows new entries. Slow
// clients receive RESOURCE_EXHAUSTED and resume from their last sequence
// without blocking engines.
func (s *Server) WatchLogs(req *corev1.WatchLogsRequest, stream grpc.ServerStreamingServer[corev1.LogEntry]) error {
	if err := s.authorize(req.GetApiVersion(), req.GetControlAuthenticator()); err != nil {
		return err
	}
	center, err := s.logCenter()
	if err != nil {
		return transportStatus(err)
	}
	filter, err := filterFromWire(req.GetFilter())
	if err != nil {
		return transportStatus(err)
	}
	sub := center.Watch(filter, req.GetAfterSequence())
	defer sub.Close()
	ctx := stream.Context()
	for {
		select {
		case <-ctx.Done():
			return nil
		case e := <-sub.C:
			if err := stream.Send(entryToWire(e)); err != nil {
				return err
			}
			if sub.Lost() > 0 {
				return status.Error(codes.ResourceExhausted, "control: the log watcher fell behind; resume from the last sequence")
			}
		}
	}
}

// exportFormats maps the wire format onto the log center format.
var exportFormats = map[corev1.LogExportFormat]logs.Format{
	corev1.LogExportFormat_LOG_EXPORT_FORMAT_UNSPECIFIED: logs.FormatText,
	corev1.LogExportFormat_LOG_EXPORT_FORMAT_JSON_LINES:  logs.FormatJSONLines,
	corev1.LogExportFormat_LOG_EXPORT_FORMAT_CSV:         logs.FormatCSV,
}

// ExportLogs renders matching entries in memory. The client saves the result;
// the core does not write a file.
func (s *Server) ExportLogs(_ context.Context, req *corev1.ExportLogsRequest) (*corev1.ExportLogsResponse, error) {
	if err := s.authorize(req.GetApiVersion(), req.GetControlAuthenticator()); err != nil {
		return nil, err
	}
	center, err := s.logCenter()
	if err != nil {
		return &corev1.ExportLogsResponse{Error: toWire(err, nil, "")}, nil
	}
	filter, err := filterFromWire(req.GetFilter())
	if err != nil {
		return &corev1.ExportLogsResponse{Error: toWire(err, nil, "")}, nil
	}
	format, ok := exportFormats[req.GetFormat()]
	if !ok {
		err := errs.Newf(errs.CodeInvalidArgument, errs.KeyLogFilterInvalid, "control: unknown export format")
		return &corev1.ExportLogsResponse{Error: toWire(err, nil, "")}, nil
	}
	data, name, media, err := logs.Export(center.Matching(filter), format, time.Now())
	if err != nil {
		err = errs.Newf(errs.CodeResourceExhausted, errs.KeyLogExportFailed, "control: %v", err)
		return &corev1.ExportLogsResponse{Error: toWire(err, nil, "")}, nil
	}
	return &corev1.ExportLogsResponse{Data: data, FileName: name, MediaType: media}, nil
}

// ClearLogs empties the record.
func (s *Server) ClearLogs(_ context.Context, req *corev1.ClearLogsRequest) (*corev1.ClearLogsResponse, error) {
	if err := s.authorize(req.GetApiVersion(), req.GetControlAuthenticator()); err != nil {
		return nil, err
	}
	center, err := s.logCenter()
	if err != nil {
		return &corev1.ClearLogsResponse{Error: toWire(err, nil, "")}, nil
	}
	center.Clear()
	return &corev1.ClearLogsResponse{}, nil
}

func settingsToWire(st logs.Settings) *corev1.LogSettings {
	return &corev1.LogSettings{CaptureLevel: levelsToWire[st.CaptureLevel], RecordDestinations: st.RecordDestinations,
		MaxEntries: bound(st.MaxEntries), MaxBytes: bound(st.MaxBytes)}
}

// Limit client settings to bound log memory usage.
const (
	maxLogEntries = 200000
	maxLogBytes   = 64 << 20
)

// GetLogSettings returns the log center settings.
func (s *Server) GetLogSettings(_ context.Context, req *corev1.GetLogSettingsRequest) (*corev1.GetLogSettingsResponse, error) {
	if err := s.authorize(req.GetApiVersion(), req.GetControlAuthenticator()); err != nil {
		return nil, err
	}
	center, err := s.logCenter()
	if err != nil {
		return &corev1.GetLogSettingsResponse{Error: toWire(err, nil, "")}, nil
	}
	return &corev1.GetLogSettingsResponse{Settings: settingsToWire(center.Settings())}, nil
}

// SetLogSettings updates settings starting with the next entry.
func (s *Server) SetLogSettings(_ context.Context, req *corev1.SetLogSettingsRequest) (*corev1.SetLogSettingsResponse, error) {
	if err := s.authorize(req.GetApiVersion(), req.GetControlAuthenticator()); err != nil {
		return nil, err
	}
	center, err := s.logCenter()
	if err != nil {
		return &corev1.SetLogSettingsResponse{Error: toWire(err, nil, "")}, nil
	}
	in := req.GetSettings()
	applied := center.SetSettings(logs.Settings{
		CaptureLevel:       levelFromWire(in.GetCaptureLevel()),
		RecordDestinations: in.GetRecordDestinations(),
		MaxEntries:         min(int(in.GetMaxEntries()), maxLogEntries),
		MaxBytes:           min(int(in.GetMaxBytes()), maxLogBytes),
	})
	return &corev1.SetLogSettingsResponse{Settings: settingsToWire(applied)}, nil
}

// ListConnections returns the running session's live connections.
func (s *Server) ListConnections(ctx context.Context, req *corev1.ListConnectionsRequest) (*corev1.ListConnectionsResponse, error) {
	if err := s.authorize(req.GetApiVersion(), req.GetControlAuthenticator()); err != nil {
		return nil, err
	}
	running, err := s.runningSession(req.GetSessionId())
	if err != nil {
		return &corev1.ListConnectionsResponse{Error: toWire(err, nil, "")}, nil
	}
	list, err := running.Connections(ctx)
	if err != nil {
		return &corev1.ListConnectionsResponse{Error: toWire(err, nil, "")}, nil
	}
	out := &corev1.ListConnectionsResponse{}
	for _, c := range list {
		out.Connections = append(out.Connections, connectionToWire(c))
	}
	return out, nil
}

// CloseConnection drops one live connection of the running session.
func (s *Server) CloseConnection(ctx context.Context, req *corev1.CloseConnectionRequest) (*corev1.CloseConnectionResponse, error) {
	if err := s.authorize(req.GetApiVersion(), req.GetControlAuthenticator()); err != nil {
		return nil, err
	}
	running, err := s.runningSession(req.GetSessionId())
	if err != nil {
		return &corev1.CloseConnectionResponse{Error: toWire(err, nil, "")}, nil
	}
	if err := running.CloseConnection(ctx, req.GetConnectionId()); err != nil {
		return &corev1.CloseConnectionResponse{Error: toWire(err, nil, "")}, nil
	}
	return &corev1.CloseConnectionResponse{}, nil
}

// connectionSession exposes session operations needed by the connection center.
type connectionSession interface {
	Connections(ctx context.Context) ([]engine.Connection, error)
	CloseConnection(ctx context.Context, id string) error
}

func (s *Server) runningSession(named string) (connectionSession, error) {
	if err := s.checkSession(named); err != nil {
		return nil, err
	}
	running := s.sessions.Current()
	if running == nil {
		return nil, errs.Newf(errs.CodeFailedPrecondition, errs.KeyConnectionsUnavailable,
			"control: no session is running")
	}
	return running, nil
}

func connectionToWire(c engine.Connection) *corev1.Connection {
	return &corev1.Connection{Id: c.ID, Network: c.Network, Host: c.Host, Port: uint32(c.Port), Process: c.Process,
		Rule: c.Rule, Chain: c.Chain, Upload: c.Upload, Download: c.Download, Start: timestamppb.New(c.Start)}
}
