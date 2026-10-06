// Package logs is the log center of the Sora core: one bounded, in-memory
// record of what the core and every engine said, which the interface queries,
// watches, filters and exports.
//
// Nothing here touches the disk. A log of a tunnel is a list of the places a
// person visited and of the servers they use, and a file of it survives the
// session, the uninstall and a device inspection. The record lives in memory
// only, bounded by entries and by bytes, and leaves the process only through
// an explicit export.
package logs

import (
	"regexp"
	"slices"
	"strings"
	"sync"
	"time"
)

// Level is the severity of an entry. The zero value is not a level.
type Level int8

// Severities in increasing order.
const (
	LevelDebug Level = iota + 1
	LevelInfo
	LevelWarning
	LevelError
)

var levelNames = map[Level]string{LevelDebug: "debug", LevelInfo: "info", LevelWarning: "warning", LevelError: "error"}

func (l Level) String() string {
	if n, ok := levelNames[l]; ok {
		return n
	}
	return "unknown"
}

// ParseLevel accepts the level names the engines and the core use.
func ParseLevel(s string) (Level, bool) {
	switch strings.ToLower(strings.TrimSpace(s)) {
	case "trace", "debug", "dbg":
		return LevelDebug, true
	case "info", "information", "notice":
		return LevelInfo, true
	case "warn", "warning":
		return LevelWarning, true
	case "error", "err", "fatal", "panic", "critical":
		return LevelError, true
	}
	return 0, false
}

// SourceCore names entries the core service itself wrote. Engine entries carry
// the engine kind.
const SourceCore = "core"

// Entry is one log record. Message is already masked when it is stored.
type Entry struct {
	Seq     uint64
	Time    time.Time
	Level   Level
	Source  string
	Message string
	// Repeat counts identical consecutive messages folded into this entry; 1
	// for a message seen once. Time is the time of the latest one.
	Repeat uint32
}

func (e Entry) size() int { return len(e.Message) + len(e.Source) + 48 }

// Settings are the switches of the log center. They change at runtime and
// apply to the next entry.
type Settings struct {
	// CaptureLevel drops entries below it before they are stored. Engines run
	// at debug level, so lowering it takes effect at once, without a restart.
	CaptureLevel Level
	// RecordDestinations keeps the hosts and addresses of the sites a user
	// visits in engine messages. Off, they are replaced before storage.
	RecordDestinations bool
	// MaxEntries and MaxBytes bound the record; the oldest entries go first.
	MaxEntries int
	MaxBytes   int
}

// Limits of the record. MaxBytes counts message bytes plus a fixed overhead
// per entry, so a flood of short lines is bounded too.
const (
	DefaultMaxEntries = 20000
	DefaultMaxBytes   = 8 << 20
	MaxMessageBytes   = 4 << 10
	// foldWindow is how long an identical message keeps folding into the
	// previous entry instead of becoming a new one.
	foldWindow = 30 * time.Second
)

// DefaultSettings capture info and above and keep destinations out.
func DefaultSettings() Settings {
	return Settings{CaptureLevel: LevelInfo, MaxEntries: DefaultMaxEntries, MaxBytes: DefaultMaxBytes}
}

func (s Settings) normalized() Settings {
	if _, ok := levelNames[s.CaptureLevel]; !ok {
		s.CaptureLevel = LevelInfo
	}
	if s.MaxEntries <= 0 {
		s.MaxEntries = DefaultMaxEntries
	}
	if s.MaxBytes <= 0 {
		s.MaxBytes = DefaultMaxBytes
	}
	return s
}

// Center is the log record. It is safe for concurrent use, and Append never
// blocks on a reader.
type Center struct {
	mu       sync.Mutex
	settings Settings
	entries  []Entry // oldest first
	bytes    int
	next     uint64
	dropped  uint64 // entries evicted by the bounds
	watchers map[*watcher]struct{}
	now      func() time.Time
}

// New returns an empty log center.
func New(settings Settings) *Center {
	return &Center{settings: settings.normalized(), next: 1, watchers: map[*watcher]struct{}{}, now: time.Now}
}

// Settings returns the current switches.
func (c *Center) Settings() Settings {
	c.mu.Lock()
	defer c.mu.Unlock()
	return c.settings
}

// SetSettings changes the switches. Shrinking the bounds evicts at once.
func (c *Center) SetSettings(s Settings) Settings {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.settings = s.normalized()
	c.evict()
	return c.settings
}

// Write records one message. It is the single entry point for the core and the
// engines; the message must already be masked of credentials.
func (c *Center) Write(at time.Time, level Level, source, message string) {
	message = strings.TrimRight(message, "\r\n")
	if message == "" {
		return
	}
	if len(message) > MaxMessageBytes {
		message = message[:MaxMessageBytes] + " [cut]"
	}
	if at.IsZero() {
		at = c.now()
	}
	c.mu.Lock()
	defer c.mu.Unlock()
	if level < c.settings.CaptureLevel {
		return
	}
	if !c.settings.RecordDestinations && source != SourceCore {
		message = HideDestinations(message)
	}
	if n := len(c.entries); n > 0 {
		last := &c.entries[n-1]
		if last.Source == source && last.Level == level && last.Message == message && at.Sub(last.Time) < foldWindow {
			last.Repeat++
			last.Time = at
			c.notify(*last)
			return
		}
	}
	e := Entry{Seq: c.next, Time: at, Level: level, Source: source, Message: message, Repeat: 1}
	c.next++
	c.entries = append(c.entries, e)
	c.bytes += e.size()
	c.evict()
	c.notify(e)
}

func (c *Center) evict() {
	drop := 0
	for drop < len(c.entries) && (len(c.entries)-drop > c.settings.MaxEntries || c.bytes > c.settings.MaxBytes) {
		c.bytes -= c.entries[drop].size()
		drop++
	}
	if drop == 0 {
		return
	}
	c.dropped += uint64(drop)
	// Copy instead of reslicing, so the evicted messages can be collected.
	c.entries = append(c.entries[:0:0], c.entries[drop:]...)
}

// Clear removes every entry. Sequence numbers keep growing, so a client that
// holds a cursor never confuses a new entry with an old one.
func (c *Center) Clear() {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.entries = nil
	c.bytes = 0
}

// Filter selects entries. Zero values select everything.
type Filter struct {
	MinLevel Level
	Sources  []string
	// Contains matches the message case-insensitively.
	Contains string
	// Pattern is a regular expression on the message. Go regular expressions
	// run in linear time, so a hostile pattern cannot stall the core.
	Pattern *regexp.Regexp
	Since   time.Time
	Until   time.Time
}

// MaxPatternLen bounds a filter expression.
const MaxPatternLen = 512

// CompilePattern checks and compiles a filter expression.
func CompilePattern(expr string) (*regexp.Regexp, error) {
	if expr == "" {
		return nil, nil
	}
	if len(expr) > MaxPatternLen {
		return nil, errPatternTooLong
	}
	return regexp.Compile("(?i)" + expr)
}

func (f Filter) match(e Entry) bool {
	if e.Level < f.MinLevel {
		return false
	}
	if len(f.Sources) > 0 && !slices.Contains(f.Sources, e.Source) {
		return false
	}
	if !f.Since.IsZero() && e.Time.Before(f.Since) {
		return false
	}
	if !f.Until.IsZero() && e.Time.After(f.Until) {
		return false
	}
	if f.Contains != "" && !strings.Contains(strings.ToLower(e.Message), strings.ToLower(f.Contains)) {
		return false
	}
	return f.Pattern == nil || f.Pattern.MatchString(e.Message)
}

// Page is one answer of Query.
type Page struct {
	// Entries are newest first.
	Entries []Entry
	// Before is the cursor of the next, older page; zero when there is none.
	Before uint64
	Stats  Stats
}

// Stats describes the whole record, not only the matching entries, so the
// interface can show what a filter hides.
type Stats struct {
	ByLevel  map[Level]int
	BySource map[string]int
	Total    int
	Bytes    int
	MaxBytes int
	// Dropped counts entries the bounds evicted since the core started.
	Dropped uint64
}

// MaxPage bounds one page.
const MaxPage = 1000

// Query returns up to limit matching entries older than before (zero: from the
// newest), newest first.
func (c *Center) Query(f Filter, before uint64, limit int) Page {
	if limit <= 0 || limit > MaxPage {
		limit = MaxPage
	}
	c.mu.Lock()
	defer c.mu.Unlock()
	page := Page{Stats: c.stats()}
	for i := len(c.entries) - 1; i >= 0; i-- {
		e := c.entries[i]
		if before != 0 && e.Seq >= before {
			continue
		}
		if !f.match(e) {
			continue
		}
		if len(page.Entries) == limit {
			page.Before = page.Entries[len(page.Entries)-1].Seq
			break
		}
		page.Entries = append(page.Entries, e)
	}
	return page
}

// Matching returns every matching entry, oldest first, for an export.
func (c *Center) Matching(f Filter) []Entry {
	c.mu.Lock()
	defer c.mu.Unlock()
	var out []Entry
	for _, e := range c.entries {
		if f.match(e) {
			out = append(out, e)
		}
	}
	return out
}

func (c *Center) stats() Stats {
	s := Stats{ByLevel: map[Level]int{}, BySource: map[string]int{}, Total: len(c.entries),
		Bytes: c.bytes, MaxBytes: c.settings.MaxBytes, Dropped: c.dropped}
	for _, e := range c.entries {
		s.ByLevel[e.Level]++
		s.BySource[e.Source]++
	}
	return s
}
