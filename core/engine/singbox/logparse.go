package singbox

import (
	"regexp"
	"time"

	"github.com/levvs-one/sora-client/core/logs"
)

// logLine matches sing-box output without colors or timestamps. Bracketed time
// is elapsed seconds, so records use the read time.
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
