// Package diagnostics collects redacted reports and archives. It includes
// interface flags and address counts, engine build, session state and cause,
// counters, and recent events. It omits local addresses, hosts, and server
// names, and masks output again before returning it.
package diagnostics

import (
	"archive/zip"
	"bytes"
	"context"
	"encoding/json"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/errs"
	"github.com/levvs-one/sora-client/core/session"
)

const (
	// DefaultMaxArchiveBytes is the largest archive the collector produces.
	DefaultMaxArchiveBytes = 8 << 20
	// DefaultEventCount is how many recent events go into a report.
	DefaultEventCount = 200
	// archiveFormat identifies the archive format for version detection.
	archiveFormat = "sora-diagnostics/1"
)

// Source supplies collector data, allowing fixed-state tests and
// platform-specific reporting.
type Source interface {
	// Status reports the session as it is right now.
	Status() session.Status
	// RecentEvents returns the last events of the session, oldest first.
	RecentEvents(limit int) []session.Event
	// EngineLines describes the engine build and its state.
	EngineLines() []string
}

// Options configures a collector.
type Options struct {
	// Source is what the collector reads.
	Source Source
	// Redactor masks anything that may identify a server or a credential.
	// It is
	// optional, and the report says so when it is missing.
	Redactor *engine.Redactor
	// MaxArchiveBytes is the largest archive produced.
	MaxArchiveBytes int
	// EventCount is how many recent events go into a report.
	EventCount int
	// Now supplies timestamps.
	Now func() time.Time
}

// Collector produces reports and archives.
type Collector struct {
	source   Source
	redactor *engine.Redactor
	maxBytes int
	events   int
	now      func() time.Time
}

// New returns a collector with the defaults filled in.
func New(opts Options) (*Collector, error) {
	if opts.Source == nil {
		return nil, errs.Newf(errs.CodeInvalidArgument, errs.KeyDiagnosticsFailed,
			"diagnostics: no source to read")
	}
	if opts.MaxArchiveBytes <= 0 {
		opts.MaxArchiveBytes = DefaultMaxArchiveBytes
	}
	if opts.EventCount <= 0 {
		opts.EventCount = DefaultEventCount
	}
	if opts.Now == nil {
		opts.Now = time.Now
	}
	return &Collector{
		source:   opts.Source,
		redactor: opts.Redactor,
		maxBytes: opts.MaxArchiveBytes,
		events:   opts.EventCount,
		now:      opts.Now,
	}, nil
}

var _ interface {
	Run(ctx context.Context, status session.Status) ([]string, error)
	Export(ctx context.Context, status session.Status) ([]byte, error)
} = (*Collector)(nil)

// Run returns report lines, masking each line before it leaves the core.
func (c *Collector) Run(_ context.Context, _ session.Status) ([]string, error) {
	lines := c.report()
	if len(lines) == 0 {
		return nil, errs.Newf(errs.CodeInternal, errs.KeyDiagnosticsFailed,
			"diagnostics: the source produced nothing to report")
	}
	return lines, nil
}

// Export returns a redacted archive for bug reports.
func (c *Collector) Export(_ context.Context, status session.Status) ([]byte, error) {
	report := c.report()
	summary, err := json.MarshalIndent(c.Summary(status), "", "  ")
	if err != nil {
		return nil, errs.Wrap(err, errs.CodeInternal, errs.KeyDiagnosticsFailed)
	}

	archive := &bytes.Buffer{}
	writer := zip.NewWriter(archive)
	// Fixed entry names and order make archives comparable across reports.
	entries := []struct {
		name    string
		content []byte
	}{
		{"summary.json", append(summary, '\n')},
		{"report.txt", []byte(joinLines(report))},
		{"events.log", []byte(joinLines(c.eventLines()))},
	}
	for _, entry := range entries {
		file, err := writer.Create(entry.name)
		if err != nil {
			return nil, errs.Wrap(err, errs.CodeInternal, errs.KeyDiagnosticsFailed)
		}
		if _, err := file.Write([]byte(c.mask(string(entry.content)))); err != nil {
			return nil, errs.Wrap(err, errs.CodeInternal, errs.KeyDiagnosticsFailed)
		}
	}
	if err := writer.Close(); err != nil {
		return nil, errs.Wrap(err, errs.CodeInternal, errs.KeyDiagnosticsFailed)
	}
	if archive.Len() > c.maxBytes {
		return nil, errs.Newf(errs.CodeResourceExhausted, errs.KeyDiagnosticsTooLarge,
			"diagnostics: the archive is %d bytes, the limit is %d", archive.Len(), c.maxBytes)
	}
	return archive.Bytes(), nil
}

// mask applies the redactor to text that leaves the process.
func (c *Collector) mask(text string) string {
	if c.redactor == nil {
		return text
	}
	return c.redactor.String(text)
}

// joinLines joins report lines with a trailing newline for consistent text-file
// output.
func joinLines(lines []string) string {
	out := make([]byte, 0, 64*len(lines))
	for _, line := range lines {
		out = append(out, line...)
		out = append(out, '\n')
	}
	return string(out)
}

// Summary is the exported, machine-readable archive state, also available
// without unpacking the archive.
type Summary struct {
	Format   string         `json:"format"`
	Core     string         `json:"core"`
	OS       string         `json:"os"`
	Arch     string         `json:"arch"`
	Contract session.Status `json:"session"`
	Masked   bool           `json:"values_masked"`
	Events   int            `json:"events_collected"`
}

// Summary returns structured state for report comparison. It omits the session
// ID because it identifies a specific run without helping diagnostics.
func (c *Collector) Summary(status session.Status) Summary {
	return Summary{
		Format: archiveFormat,
		Core:   coreVersion,
		OS:     goOS,
		Arch:   goArch,
		Contract: session.Status{
			State:      status.State,
			Reason:     status.Reason,
			Key:        status.Key,
			ChangedAt:  status.ChangedAt,
			RetryAfter: status.RetryAfter,
			KillSwitch: status.KillSwitch,
			TunnelMode: status.TunnelMode,
		},
		Masked: c.redactor != nil,
		Events: c.events,
	}
}
