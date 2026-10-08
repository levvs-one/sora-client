package diagnostics_test

import (
	"archive/zip"
	"bytes"
	"context"
	"errors"
	"io"
	"strings"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/diagnostics"
	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/errs"
	"github.com/levvs-one/sora-client/core/session"
)

// Planted credentials must be absent from report lines and all archive bytes.
const secretValues = "super-secret-password-8383 and-another-token-4711"

// Server hosts must be masked because they identify user connections.
const serverHost = "de1.example.com"

// fakeSource is a session in a fixed state.
type fakeSource struct {
	status session.Status
	events []session.Event
	engine []string
}

func (s *fakeSource) Status() session.Status { return s.status }

func (s *fakeSource) RecentEvents(limit int) []session.Event {
	if len(s.events) <= limit {
		return s.events
	}
	return s.events[len(s.events)-limit:]
}

func (s *fakeSource) EngineLines() []string { return s.engine }

func newCollector(t *testing.T, source diagnostics.Source, opts diagnostics.Options) *diagnostics.Collector {
	t.Helper()
	opts.Source = source
	if opts.Now == nil {
		opts.Now = func() time.Time { return time.Date(2026, 10, 2, 12, 0, 0, 0, time.UTC) }
	}
	collector, err := diagnostics.New(opts)
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}
	return collector
}

func plantedSource() *fakeSource {
	return &fakeSource{
		status: session.Status{
			State:      session.StateConnected,
			SessionID:  "s_0123456789abcdef",
			Reason:     errs.CodeUnavailable,
			Key:        errs.KeyEngineStopped,
			Detail:     "the engine answered for " + secretValues,
			ChangedAt:  time.Date(2026, 10, 2, 11, 59, 0, 0, time.UTC),
			KillSwitch: true,
			TunnelMode: "system",
		},
		events: []session.Event{
			{Kind: session.EventState, State: session.StateConnected, Key: session.KeySelectionChanged},
			{Kind: session.EventLog, LogLine: "dial " + secretValues + " to de1.example.com:443"},
			{Kind: session.EventError, Reason: errs.CodeTimeout, Key: errs.KeyNetworkTimeout, Detail: secretValues},
		},
		engine: []string{"kind: mihomo", "version: 1.19.32", "state: running"},
	}
}

func TestReportDescribesTheSessionAndHidesNothingItShouldNot(t *testing.T) {
	collector := newCollector(t, plantedSource(), diagnostics.Options{
		Redactor: engine.NewRedactor(secretValues, serverHost),
	})
	lines, err := collector.Run(context.Background(), session.Status{})
	if err != nil {
		t.Fatalf("Run() error = %v", err)
	}
	report := strings.Join(lines, "\n")
	for _, want := range []string{
		"Sora diagnostics",
		"state: connected",
		"kill_switch: true",
		"[engine]",
		"version: 1.19.32",
		"[interfaces]",
	} {
		if !strings.Contains(report, want) {
			t.Errorf("the report does not mention %q:\n%s", want, report)
		}
	}
	if strings.Contains(report, secretValues) {
		t.Errorf("the report leaks the planted values:\n%s", report)
	}
}

func TestArchiveCarriesNoSecretInAnyEntry(t *testing.T) {
	collector := newCollector(t, plantedSource(), diagnostics.Options{
		Redactor: engine.NewRedactor(secretValues, serverHost),
	})
	archive, err := collector.Export(context.Background(), session.Status{})
	if err != nil {
		t.Fatalf("Export() error = %v", err)
	}
	reader, err := zip.NewReader(bytes.NewReader(archive), int64(len(archive)))
	if err != nil {
		t.Fatalf("the archive is not a zip: %v", err)
	}
	wanted := map[string]bool{"summary.json": false, "report.txt": false, "events.log": false}
	for _, file := range reader.File {
		if _, known := wanted[file.Name]; !known {
			t.Errorf("the archive holds an unexpected entry %q", file.Name)
		}
		wanted[file.Name] = true
		handle, err := file.Open()
		if err != nil {
			t.Fatalf("opening %q: %v", file.Name, err)
		}
		content, err := io.ReadAll(handle)
		_ = handle.Close()
		if err != nil {
			t.Fatalf("reading %q: %v", file.Name, err)
		}
		if bytes.Contains(content, []byte(secretValues)) {
			t.Errorf("%q leaks the planted values:\n%s", file.Name, content)
		}
		if strings.Contains(string(content), "de1.example.com") {
			t.Errorf("%q names a server: %s", file.Name, content)
		}
	}
	for name, seen := range wanted {
		if !seen {
			t.Errorf("the archive has no %q", name)
		}
	}
}

func TestArchiveRefusesToExceedItsLimit(t *testing.T) {
	collector := newCollector(t, plantedSource(), diagnostics.Options{MaxArchiveBytes: 512})
	if _, err := collector.Export(context.Background(), session.Status{}); errs.KeyOf(err) != errs.KeyDiagnosticsTooLarge {
		t.Errorf("an oversized archive = %v, key = %q", err, errs.KeyOf(err))
	}
}

func TestCollectorRefusesToWorkWithoutASource(t *testing.T) {
	if _, err := diagnostics.New(diagnostics.Options{}); errs.CodeOf(err) != errs.CodeInvalidArgument {
		t.Errorf("a collector without a source = %v", err)
	}
}

func TestReportWorksWithoutARedactorAndSaysSo(t *testing.T) {
	collector := newCollector(t, plantedSource(), diagnostics.Options{})
	lines, err := collector.Run(context.Background(), session.Status{})
	if err != nil {
		t.Fatalf("Run() error = %v", err)
	}
	if len(lines) == 0 {
		t.Fatal("the report is empty")
	}
	// Without a redactor the collector must not pretend the values were
	// masked.
	summary := collector.Summary(session.Status{})
	if summary.Masked {
		t.Error("the summary claims values were masked although no redactor was given")
	}
}

func TestInterfaceLinesNeverListAnAddress(t *testing.T) {
	collector := newCollector(t, &fakeSource{}, diagnostics.Options{})
	lines, err := collector.Run(context.Background(), session.Status{})
	if err != nil {
		t.Fatalf("Run() error = %v", err)
	}
	report := strings.Join(lines, "\n")
	for _, forbidden := range []string{"192.168.", "10.0.", "fe80::", "mac"} {
		if strings.Contains(report, forbidden) {
			t.Errorf("the report contains %q:\n%s", forbidden, report)
		}
	}
}

var _ = errors.New
