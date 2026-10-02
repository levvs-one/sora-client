// Package diagnostics collects what a user sends when something is wrong.
//
// Two rules decide everything here. First, an archive may only be built from
// values that are already masked: the collector masks again on the way out, and the
// test proves that a secret planted in a session never reaches the bytes. A user who
// attaches a file to a bug report is doing the one thing the core must never punish
// them for.
//
// Second, the report is worth reading. Interface names with their flags and the
// number of addresses, the engine build, the session state with its cause, the
// counters and the last events are what a maintainer actually needs. Local
// addresses, host names and server names are not in it: they identify a person and
// a provider, and they are the first thing a report would leak.
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

// Defaults of one collection.
const (
	// DefaultMaxArchiveBytes is the largest archive the collector produces.
	DefaultMaxArchiveBytes = 8 << 20
	// DefaultEventCount is how many recent events go into a report.
	DefaultEventCount = 200
	// archiveFormat is written into the archive so a future format can be told
	// apart from this one without guessing.
	archiveFormat = "sora-diagnostics/1"
)

// Source is what the collector reads. It is an interface so the collector can be
// tested against a fixed state, and so a platform may add what it knows without
// changing this package.
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
	// Redactor masks anything that may identify a server or a credential. It is
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

// Compile-time proof that the collector satisfies what the control plane asks for,
// so a change to either side fails here first.
var _ interface {
	Run(ctx context.Context, status session.Status) ([]string, error)
	Export(ctx context.Context, status session.Status) ([]byte, error)
} = (*Collector)(nil)

// Run answers with the report as lines. Every line is masked on the way out,
// because a line is what a user copies into a chat window.
func (c *Collector) Run(_ context.Context, _ session.Status) ([]string, error) {
	lines := c.report()
	if len(lines) == 0 {
		return nil, errs.Newf(errs.CodeInternal, errs.KeyDiagnosticsFailed,
			"diagnostics: the source produced nothing to report")
	}
	return lines, nil
}

// Export answers with an archive a user can attach to a bug report.
func (c *Collector) Export(_ context.Context, status session.Status) ([]byte, error) {
	report := c.report()
	summary, err := json.MarshalIndent(c.Summary(status), "", "  ")
	if err != nil {
		return nil, errs.Wrap(err, errs.CodeInternal, errs.KeyDiagnosticsFailed)
	}

	archive := &bytes.Buffer{}
	writer := zip.NewWriter(archive)
	// The entries are written in a fixed order and under fixed names, so two
	// archives of the same state differ only in the values. That is what makes two
	// reports comparable when someone reports a difference between them.
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

// joinLines renders lines for a file, one per line, with a trailing newline so
// the file reads the same in any editor on any platform.
func joinLines(lines []string) string {
	out := make([]byte, 0, 64*len(lines))
	for _, line := range lines {
		out = append(out, line...)
		out = append(out, '\n')
	}
	return string(out)
}

// Summary is the machine-readable part of an archive and of any structured
// status a client may ask for later. It is exported because a caller that wants to
// compare two reports should not have to unzip them.
type Summary struct {
	Format   string         `json:"format"`
	Core     string         `json:"core"`
	OS       string         `json:"os"`
	Arch     string         `json:"arch"`
	Contract session.Status `json:"session"`
	Masked   bool           `json:"values_masked"`
	Events   int            `json:"events_collected"`
}

// Summary renders the state as structured data for a maintainer who wants to
// compare two reports. The session id is left out on purpose: it identifies one
// run of one machine and is of no use to anyone reading a bug report.
func (c *Collector) Summary(status session.Status) Summary {
	return Summary{
		Format: archiveFormat,
		Core:   coreVersion,
		OS:     goOS,
		Arch:   goArch,
		Contract: session.Status{
			State:       status.State,
			Reason:      status.Reason,
			Key:         status.Key,
			ChangedAt:   status.ChangedAt,
			RetryAfter:  status.RetryAfter,
			KillSwitch:  status.KillSwitch,
			SystemProxy: status.SystemProxy,
			TunnelMode:  status.TunnelMode,
		},
		Masked: c.redactor != nil,
		Events: c.events,
	}
}
