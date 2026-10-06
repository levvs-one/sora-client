package supervise

import (
	"strings"
	"testing"
)

func TestLineWriterJoinsChunksIntoLines(t *testing.T) {
	var got []string
	w := &lineWriter{emit: func(s string) { got = append(got, s) }}
	for _, chunk := range []string{"first li", "ne\r\nsecond\nthi", "rd\n"} {
		if _, err := w.Write([]byte(chunk)); err != nil {
			t.Fatal(err)
		}
	}
	if strings.Join(got, "|") != "first line|second|third" {
		t.Fatalf("lines = %q", got)
	}
	got = nil
	_, _ = w.Write([]byte(strings.Repeat("x", maxLine+1)))
	if len(got) != 1 {
		t.Fatal("a line the engine never ends must still be emitted")
	}
}
