package mihomo

import (
	"testing"

	"github.com/levvs-one/sora-client/core/logs"
)

// TestParseLogReadsMihomoLogfmt checks real mihomo 1.19.32 debug output.
func TestParseLogReadsMihomoLogfmt(t *testing.T) {
	at, level, msg := driver{}.ParseLog(`time="2026-10-06T15:14:38.620076011+03:00" level=debug msg="[Rule] use \"default\" rules"`)
	if at.Year() != 2026 || level != logs.LevelDebug || msg != `[Rule] use "default" rules` {
		t.Fatalf("%v %s %q", at, level, msg)
	}
	if _, level, msg := (driver{}).ParseLog("panic: unexpected"); level != logs.LevelInfo || msg != "panic: unexpected" {
		t.Fatalf("an unknown line is kept as it is: %s %q", level, msg)
	}
}
