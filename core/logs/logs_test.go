package logs

import (
	"bytes"
	"encoding/csv"
	"encoding/json"
	"fmt"
	"log/slog"
	"strings"
	"testing"
	"time"
)

var t0 = time.Date(2026, 10, 6, 15, 0, 0, 0, time.UTC)

func record(c *Center, n int, level Level, source string) {
	for i := 0; i < n; i++ {
		c.Write(t0.Add(time.Duration(i)*time.Minute), level, source, fmt.Sprintf("message %d", i))
	}
}

func TestCaptureLevelDropsBeforeStorage(t *testing.T) {
	c := New(Settings{CaptureLevel: LevelWarning})
	c.Write(t0, LevelInfo, "xray", "dropped")
	c.Write(t0, LevelError, "xray", "kept")
	if p := c.Query(Filter{}, 0, 0); len(p.Entries) != 1 || p.Entries[0].Message != "kept" {
		t.Fatalf("entries = %+v", p.Entries)
	}
	c.SetSettings(Settings{CaptureLevel: LevelDebug})
	c.Write(t0, LevelDebug, "xray", "now kept")
	if p := c.Query(Filter{}, 0, 0); len(p.Entries) != 2 {
		t.Fatalf("a lower capture level must apply to the next entry: %+v", p.Entries)
	}
}

func TestBoundsEvictTheOldestByCountAndBytes(t *testing.T) {
	c := New(Settings{CaptureLevel: LevelDebug, MaxEntries: 10})
	record(c, 25, LevelInfo, "core")
	p := c.Query(Filter{}, 0, 0)
	if len(p.Entries) != 10 || p.Entries[9].Message != "message 15" || p.Stats.Dropped != 15 {
		t.Fatalf("entries %d, oldest %q, dropped %d", len(p.Entries), p.Entries[9].Message, p.Stats.Dropped)
	}
	c = New(Settings{CaptureLevel: LevelDebug, MaxBytes: 1000})
	for i := 0; i < 100; i++ {
		c.Write(t0.Add(time.Duration(i)*time.Minute), LevelInfo, "core", strings.Repeat("x", 100)+fmt.Sprint(i))
	}
	if s := c.Query(Filter{}, 0, 0).Stats; s.Bytes > 1000 || s.Total == 0 {
		t.Fatalf("byte bound not kept: %+v", s)
	}
}

func TestIdenticalMessagesFold(t *testing.T) {
	c := New(Settings{CaptureLevel: LevelDebug})
	sub := c.Watch(Filter{}, 0)
	defer sub.Close()
	for i := 0; i < 5; i++ {
		c.Write(t0.Add(time.Duration(i)*time.Second), LevelWarning, "mihomo", "dial failed")
	}
	c.Write(t0.Add(time.Minute), LevelWarning, "mihomo", "dial failed")
	p := c.Query(Filter{}, 0, 0)
	if len(p.Entries) != 2 || p.Entries[1].Repeat != 5 {
		t.Fatalf("five quick repeats fold into one entry, a late one starts a new entry: %+v", p.Entries)
	}
	var last Entry
	for i := 0; i < 6; i++ {
		last = <-sub.C
	}
	if last.Seq != p.Entries[0].Seq {
		t.Fatalf("a watcher sees the fold as an update of the same entry: %+v", last)
	}
}

func TestFilterAndPaging(t *testing.T) {
	c := New(Settings{CaptureLevel: LevelDebug})
	record(c, 30, LevelInfo, "sing-box")
	record(c, 30, LevelError, "xray")
	pattern, err := CompilePattern(`message 1\d$`)
	if err != nil {
		t.Fatal(err)
	}
	p := c.Query(Filter{MinLevel: LevelWarning, Sources: []string{"xray"}, Pattern: pattern}, 0, 4)
	if len(p.Entries) != 4 || p.Entries[0].Message != "message 19" || p.Before == 0 {
		t.Fatalf("first page = %+v", p)
	}
	next := c.Query(Filter{MinLevel: LevelWarning, Sources: []string{"xray"}, Pattern: pattern}, p.Before, 100)
	if len(next.Entries) != 6 || next.Entries[5].Message != "message 10" || next.Before != 0 {
		t.Fatalf("second page = %+v", next.Entries)
	}
	if p.Stats.ByLevel[LevelInfo] != 30 || p.Stats.BySource["xray"] != 30 {
		t.Fatalf("stats describe the whole record: %+v", p.Stats)
	}
	if got := c.Query(Filter{Contains: "MESSAGE 29", Since: t0.Add(29 * time.Minute)}, 0, 0); len(got.Entries) != 2 {
		t.Fatalf("contains is case-insensitive and since bounds time: %+v", got.Entries)
	}
	if _, err := CompilePattern(strings.Repeat("a", MaxPatternLen+1)); err == nil {
		t.Fatal("an overlong expression must be refused")
	}
}

func TestWatchReplaysAfterTheCursorThenFollows(t *testing.T) {
	c := New(Settings{CaptureLevel: LevelDebug})
	record(c, 5, LevelInfo, "core")
	sub := c.Watch(Filter{}, 3)
	defer sub.Close()
	c.Write(t0.Add(time.Hour), LevelError, "core", "live")
	var got []string
	for i := 0; i < 3; i++ {
		got = append(got, (<-sub.C).Message)
	}
	if strings.Join(got, ",") != "message 3,message 4,live" {
		t.Fatalf("watch = %v", got)
	}
}

func TestSlowWatcherLosesInsteadOfBlocking(t *testing.T) {
	c := New(Settings{CaptureLevel: LevelDebug})
	sub := c.Watch(Filter{}, 0)
	defer sub.Close()
	done := make(chan struct{})
	go func() {
		record(c, watchBuffer+100, LevelInfo, "core")
		close(done)
	}()
	select {
	case <-done:
	case <-time.After(5 * time.Second):
		t.Fatal("a slow watcher blocked the writer")
	}
	if sub.Lost() != 100 {
		t.Fatalf("lost = %d", sub.Lost())
	}
}

func TestDestinationsAreHiddenUnlessRecorded(t *testing.T) {
	line := "from 127.0.0.1:38204 accepted tcp:www.example.org:443 [mixed-in >> o0001] via [2001:db8::1]:443 and 2001:db8:0:0::7 at 15:02:43"
	got := HideDestinations(line)
	for _, leaked := range []string{"example.org", "127.0.0.1", "2001:db8"} {
		if strings.Contains(got, leaked) {
			t.Errorf("%q leaked: %s", leaked, got)
		}
	}
	if !strings.Contains(got, "15:02:43") || !strings.Contains(got, "mixed-in >> o0001") {
		t.Errorf("times and engine tags must stay: %s", got)
	}

	c := New(Settings{CaptureLevel: LevelDebug})
	c.Write(t0, LevelInfo, "xray", "dial www.example.org:443")
	c.Write(t0, LevelInfo, SourceCore, "listening on core.sock")
	c.SetSettings(Settings{CaptureLevel: LevelDebug, RecordDestinations: true})
	c.Write(t0, LevelInfo, "xray", "dial www.example.org:443")
	p := c.Query(Filter{}, 0, 0)
	if p.Entries[2].Message != "dial [destination]" || p.Entries[0].Message != "dial www.example.org:443" {
		t.Fatalf("entries = %+v", p.Entries)
	}
}

func TestExportFormats(t *testing.T) {
	entries := []Entry{
		{Seq: 1, Time: t0, Level: LevelError, Source: "xray", Message: "=HYPERLINK(\"x\")", Repeat: 3},
		{Seq: 2, Time: t0, Level: LevelInfo, Source: "core", Message: "ready", Repeat: 1},
	}
	text, name, _, err := Export(entries, FormatText, t0)
	if err != nil || !strings.Contains(string(text), "ERROR   [xray]") || !strings.Contains(string(text), "(x3)") || !strings.HasSuffix(name, ".txt") {
		t.Fatalf("text = %q, %s, %v", text, name, err)
	}
	jsonl, _, _, err := Export(entries, FormatJSONLines, t0)
	if err != nil {
		t.Fatal(err)
	}
	var first map[string]any
	if err := json.Unmarshal(bytes.SplitN(jsonl, []byte("\n"), 2)[0], &first); err != nil || first["level"] != "error" {
		t.Fatalf("jsonl = %s, %v", jsonl, err)
	}
	raw, _, _, err := Export(entries, FormatCSV, t0)
	if err != nil {
		t.Fatal(err)
	}
	rows, err := csv.NewReader(bytes.NewReader(raw)).ReadAll()
	if err != nil || len(rows) != 3 || rows[1][4] != "'=HYPERLINK(\"x\")" {
		t.Fatalf("csv rows = %v, %v: a formula must not reach a spreadsheet as one", rows, err)
	}
}

func TestSlogRecordsTheCoreInTheCenter(t *testing.T) {
	c := New(Settings{CaptureLevel: LevelDebug})
	var out bytes.Buffer
	log := slog.New(NewHandler(c, slog.NewTextHandler(&out, &slog.HandlerOptions{Level: slog.LevelWarn})))
	log.With("component", "guard").Debug("armed", "rules", 3)
	p := c.Query(Filter{}, 0, 0)
	if len(p.Entries) != 1 || p.Entries[0].Message != "armed component=guard rules=3" || p.Entries[0].Source != SourceCore {
		t.Fatalf("entries = %+v", p.Entries)
	}
	if out.Len() != 0 {
		t.Fatalf("the service log keeps its own level: %q", out.String())
	}
}
