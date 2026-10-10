package logs

import (
	"testing"
	"time"
)

func BenchmarkFullLogWrite(b *testing.B) {
	c := New(Settings{CaptureLevel: LevelDebug})
	for i := 0; i < DefaultMaxEntries; i++ {
		c.Write(time.Unix(int64(i)*60, 0), LevelInfo, SourceCore, "connection opened")
	}
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		c.Write(time.Unix(int64(DefaultMaxEntries+i)*60, 0), LevelInfo, SourceCore, "connection opened")
	}
}

func TestEvictionReleasesDiscardedMessages(t *testing.T) {
	c := New(Settings{MaxEntries: 3})
	for i := 0; i < 3; i++ {
		c.Write(time.Unix(int64(i)*60, 0), LevelInfo, SourceCore, "connection opened")
	}
	storage := c.entries[:cap(c.entries)]
	c.SetSettings(Settings{MaxEntries: 1})
	for _, e := range storage[:2] {
		if e.Message != "" || e.Source != "" {
			t.Fatal("evicted entries retain their message in the backing storage")
		}
	}
	if p := c.Query(Filter{}, 0, 0); len(p.Entries) != 1 || p.Entries[0].Seq != 3 {
		t.Fatalf("retained page = %+v", p)
	}
}
