package singbox

import (
	"testing"

	"github.com/levvs-one/sora-client/core/logs"
)

// Real output of sing-box 1.14.2 with --disable-color and no timestamps.
func TestParseLogReadsSingBoxLines(t *testing.T) {
	at, level, msg := driver{}.ParseLog(`DEBUG[0002] [1403639248 0ms] dns: lookup domain www.gstatic.com`)
	if !at.IsZero() || level != logs.LevelDebug || msg != "[1403639248 0ms] dns: lookup domain www.gstatic.com" {
		t.Fatalf("%v %s %q", at, level, msg)
	}
	if _, level, _ := (driver{}).ParseLog(`WARN[0010] router: rule-set not ready`); level != logs.LevelWarning {
		t.Fatalf("WARN = %s", level)
	}
}
