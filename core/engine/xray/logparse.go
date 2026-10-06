package xray

import (
	"regexp"
	"time"

	"github.com/levvs-one/sora-client/core/logs"
)

// logLine matches Xray output, for example
// "2026/10/06 15:14:37.122282 [Warning] core: Xray 26.3.27 started". Access
// log lines carry no level; they record one connection each and count as
// debug, so the default capture level keeps them out.
var logLine = regexp.MustCompile(`^(\d{4}/\d{2}/\d{2} \d{2}:\d{2}:\d{2}(?:\.\d+)?) (?:\[(\w+)\] )?(.*)$`)

// ParseLog reads one Xray output line. Xray writes local time.
func (*driver) ParseLog(line string) (time.Time, logs.Level, string) {
	m := logLine.FindStringSubmatch(line)
	if m == nil {
		return time.Time{}, logs.LevelInfo, line
	}
	at, _ := time.ParseInLocation("2006/01/02 15:04:05.999999", m[1], time.Local)
	level, ok := logs.ParseLevel(m[2])
	if !ok {
		level = logs.LevelDebug
	}
	return at, level, m[3]
}
