package mihomo

import (
	"errors"
	"os"
	"path/filepath"
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/supervise"
)

func TestFakeIPCacheResetOnUpgradeAndPoolChange(t *testing.T) {
	rt := supervise.Runtime{HomeDir: t.TempDir()}
	cache := filepath.Join(rt.HomeDir, "cache.db")
	p := &engine.Plan{DNS: engine.DNS{Enabled: true, Mode: string(engine.DNSFakeIP)}}
	for _, pool := range []string{"", "198.18.0.0/16", "198.19.0.0/16"} {
		if err := os.WriteFile(cache, []byte("stale cache contents"), 0o600); err != nil {
			t.Fatal(err)
		}
		p.DNS.FakeIPRange = pool
		if err := (driver{}).PrepareStart(p, rt); err != nil {
			t.Fatal(err)
		}
		_, err := os.Stat(cache)
		if pool == "198.18.0.0/16" {
			if err != nil {
				t.Fatalf("equivalent pool must keep persistent cache: %v", err)
			}
		} else if !errors.Is(err, os.ErrNotExist) {
			t.Fatalf("changed or unversioned pool retained cache: %v", err)
		}
	}
}

func TestFailedCacheResetDoesNotRecordNewPool(t *testing.T) {
	rt := supervise.Runtime{HomeDir: t.TempDir()}
	cache := filepath.Join(rt.HomeDir, "cache.db")
	if err := os.MkdirAll(filepath.Join(cache, "occupied"), 0o700); err != nil {
		t.Fatal(err)
	}
	p := &engine.Plan{DNS: engine.DNS{Enabled: true, Mode: string(engine.DNSFakeIP)}}
	if err := (driver{}).PrepareStart(p, rt); err == nil {
		t.Fatal("failed reset must prevent startup")
	}
	if _, err := os.Stat(filepath.Join(rt.HomeDir, "fakeip-pool")); !errors.Is(err, os.ErrNotExist) {
		t.Fatalf("failed reset recorded a pool: %v", err)
	}
}
