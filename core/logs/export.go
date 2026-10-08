package logs

import (
	"bytes"
	"encoding/csv"
	"encoding/json"
	"fmt"
	"strconv"
	"strings"
	"time"
)

// Format is an export format.
type Format int

// Export formats serve reports (text), tools (JSON Lines), and spreadsheets
// (CSV).
const (
	FormatText Format = iota + 1
	FormatJSONLines
	FormatCSV
)

// MaxExportBytes keeps exports within the transport's response limit.
const MaxExportBytes = 32 << 20

// Export renders entries oldest first, returning bytes, filename, and media
// type for client-side saving.
func Export(entries []Entry, format Format, at time.Time) (data []byte, name, mediaType string, err error) {
	var buf bytes.Buffer
	stamp := at.UTC().Format("20060102-150405")
	switch format {
	case FormatText:
		for _, e := range entries {
			fmt.Fprintf(&buf, "%s %-7s %-8s %s", e.Time.Format("2006-01-02 15:04:05.000"), strings.ToUpper(e.Level.String()), "["+e.Source+"]", e.Message)
			if e.Repeat > 1 {
				fmt.Fprintf(&buf, " (x%d)", e.Repeat)
			}
			buf.WriteByte('\n')
		}
		name, mediaType = "sora-logs-"+stamp+".txt", "text/plain; charset=utf-8"
	case FormatJSONLines:
		enc := json.NewEncoder(&buf)
		for _, e := range entries {
			if err := enc.Encode(jsonEntry{e.Seq, e.Time.Format(time.RFC3339Nano), e.Level.String(), e.Source, e.Message, e.Repeat}); err != nil {
				return nil, "", "", err
			}
		}
		name, mediaType = "sora-logs-"+stamp+".jsonl", "application/x-ndjson"
	case FormatCSV:
		w := csv.NewWriter(&buf)
		_ = w.Write([]string{"sequence", "time", "level", "source", "message", "repeat"})
		for _, e := range entries {
			_ = w.Write([]string{strconv.FormatUint(e.Seq, 10), e.Time.Format(time.RFC3339Nano), e.Level.String(),
				cell(e.Source), cell(e.Message), strconv.FormatUint(uint64(e.Repeat), 10)})
		}
		w.Flush()
		if err := w.Error(); err != nil {
			return nil, "", "", err
		}
		name, mediaType = "sora-logs-"+stamp+".csv", "text/csv; charset=utf-8"
	default:
		return nil, "", "", fmt.Errorf("logs: unknown export format %d", format)
	}
	if buf.Len() > MaxExportBytes {
		return nil, "", "", fmt.Errorf("logs: the export is %d bytes, the limit is %d; narrow the filter", buf.Len(), MaxExportBytes)
	}
	return buf.Bytes(), name, mediaType, nil
}

type jsonEntry struct {
	Seq     uint64 `json:"seq"`
	Time    string `json:"time"`
	Level   string `json:"level"`
	Source  string `json:"source"`
	Message string `json:"message"`
	Repeat  uint32 `json:"repeat"`
}

// cell escapes spreadsheet formulas in untrusted engine messages that may
// include server output.
func cell(s string) string {
	if s != "" && strings.ContainsRune("=+-@\t\r", rune(s[0])) {
		return "'" + s
	}
	return s
}
