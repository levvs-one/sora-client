package mihomo

import (
	"regexp"
	"strconv"
	"time"

	"github.com/levvs-one/sora-client/core/logs"
)

// logLine matches the logfmt mihomo writes, for example
// time="2026-10-06T15:14:37.119654768+03:00" level=info msg="Sniffer is
// closed".
var logLine = regexp.MustCompile(`^time="([^"]+)" level=(\w+) msg=("(?:[^"\\]|\\.)*")`)

// ParseLog reads one mihomo output line.
func (driver) ParseLog(line string) (time.Time, logs.Level, string) {
	m := logLine.FindStringSubmatch(line)
	if m == nil {
		return time.Time{}, logs.LevelInfo, line
	}
	at, _ := time.Parse(time.RFC3339Nano, m[1])
	level, ok := logs.ParseLevel(m[2])
	if !ok {
		level = logs.LevelInfo
	}
	message, err := strconv.Unquote(m[3])
	if err != nil {
		message = m[3]
	}
	return at, level, message
}
