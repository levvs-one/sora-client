package singbox

import (
	"regexp"
	"time"

	"github.com/levvs-one/sora-client/core/logs"
)

// logLine matches sing-box output without colours and timestamps, for example
// "INFO[0002] [1403639248 0ms] outbound/direct[direct]: outbound connection to …".
// The bracketed number is seconds since start, so the time of reading is used.
var logLine = regexp.MustCompile(`^(TRACE|DEBUG|INFO|WARN|ERROR|FATAL|PANIC)\[\d+\] (.*)$`)

// ParseLog reads one sing-box output line.
func (driver) ParseLog(line string) (time.Time, logs.Level, string) {
	m := logLine.FindStringSubmatch(line)
	if m == nil {
		return time.Time{}, logs.LevelInfo, line
	}
	level, _ := logs.ParseLevel(m[1])
	return time.Time{}, level, m[2]
}
