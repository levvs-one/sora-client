package xray

import (
	"testing"

	"github.com/levvs-one/sora-client/core/logs"
)

// Real output of Xray 26.3.27 at debug level, including an access log line.
func TestParseLogReadsXrayLines(t *testing.T) {
	d := &driver{}
	at, level, msg := d.ParseLog(`2026/10/06 15:14:37.122282 [Warning] core: Xray 26.3.27 started`)
	if at.Year() != 2026 || at.Nanosecond() != 122282000 || level != logs.LevelWarning || msg != "core: Xray 26.3.27 started" {
		t.Fatalf("%v %s %q", at, level, msg)
	}
	if _, level, _ := d.ParseLog(`2026/10/06 07:45:44.068049 from tcp:127.0.0.1:38204 accepted tcp:www.gstatic.com:443 [mixed-in >> direct]`); level != logs.LevelDebug {
		t.Fatalf("an access line is debug, got %s", level)
	}
	if _, level, msg := d.ParseLog(`A unified platform for anti-censorship.`); level != logs.LevelInfo || msg == "" {
		t.Fatalf("the banner is kept at info: %s %q", level, msg)
	}
}
