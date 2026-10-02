//go:build windows

package guard_test

import (
	"context"
	"testing"

	"golang.org/x/sys/windows/registry"

	"github.com/levvs-one/sora-client/core/errs"
	"github.com/levvs-one/sora-client/core/guard"
)

// TestRegistryProxyRoundTrip proves the promise the guard makes on a Windows
// desktop: the proxy is pointed at the engine and the previous state comes back,
// including the case where the proxy was off and the values did not exist.
//
// The test works on the real key of the running user and restores it in a cleanup,
// because a fake registry would prove nothing about the API this code uses. It
// refuses to run when the key cannot be opened, rather than pretending to pass.
func TestRegistryProxyRoundTrip(t *testing.T) {
	const keyPath = `Software\Microsoft\Windows\CurrentVersion\Internet Settings`
	before, err := readProxyKey(keyPath)
	if err != nil {
		t.Skipf("the proxy key of this account cannot be read: %v", err)
	}
	t.Cleanup(func() { restoreProxyKey(t, keyPath, before) })

	proxy := guard.NewRegistryProxy()
	if err := proxy.Apply(context.Background(), "127.0.0.1:7890"); err != nil {
		t.Fatalf("Apply() error = %v", err)
	}
	current, err := proxy.Current(context.Background())
	if err != nil {
		t.Fatalf("Current() error = %v", err)
	}
	if current != "127.0.0.1:7890" {
		t.Errorf("Current() = %q, want the loopback address", current)
	}
	if err := proxy.Apply(context.Background(), "127.0.0.1:7890"); err != nil {
		t.Fatalf("applying twice error = %v", err)
	}
	if err := proxy.Restore(context.Background()); err != nil {
		t.Fatalf("Restore() error = %v", err)
	}
	after, err := readProxyKey(keyPath)
	if err != nil {
		t.Fatalf("reading the key after a restore: %v", err)
	}
	if after != before {
		t.Errorf("the key after a restore is %+v, want %+v", after, before)
	}
	if err := proxy.Restore(context.Background()); err != nil {
		t.Errorf("restoring twice = %v", err)
	}
}

// TestRegistryProxyRefusesARemoteAddress proves that the guard cannot point a
// user's traffic at a machine it does not own.
func TestRegistryProxyRefusesARemoteAddress(t *testing.T) {
	proxy := guard.NewRegistryProxy()
	for _, address := range []string{"", "example.com:8080", "127.0.0.1", "127.0.0.1:", "10.0.0.1:3128"} {
		if err := proxy.Apply(context.Background(), address); err == nil {
			t.Errorf("the proxy accepted %q", address)
		} else if errs.CodeOf(err) == errs.CodeInternal {
			t.Errorf("applying %q was reported as an internal fault: %v", address, err)
		}
	}
}

// proxyValues is the part of the proxy key this test cares about.
type proxyValues struct {
	enabledSet  bool
	enabled     uint64
	serverSet   bool
	server      string
	overrideSet bool
	override    string
}

func readProxyKey(path string) (proxyValues, error) {
	key, err := registry.OpenKey(registry.CURRENT_USER, path, registry.QUERY_VALUE)
	if err != nil {
		return proxyValues{}, err
	}
	defer func() { _ = key.Close() }()
	var out proxyValues
	if value, _, err := key.GetIntegerValue("ProxyEnable"); err == nil {
		out.enabledSet, out.enabled = true, value
	}
	if value, _, err := key.GetStringValue("ProxyServer"); err == nil {
		out.serverSet, out.server = true, value
	}
	if value, _, err := key.GetStringValue("ProxyOverride"); err == nil {
		out.overrideSet, out.override = true, value
	}
	return out, nil
}

func restoreProxyKey(t *testing.T, path string, values proxyValues) {
	t.Helper()
	key, err := registry.OpenKey(registry.CURRENT_USER, path, registry.SET_VALUE)
	if err != nil {
		return
	}
	defer func() { _ = key.Close() }()
	if values.enabledSet {
		_ = key.SetDWordValue("ProxyEnable", uint32(values.enabled))
	} else {
		_ = key.DeleteValue("ProxyEnable")
	}
	if values.serverSet {
		_ = key.SetStringValue("ProxyServer", values.server)
	} else {
		_ = key.DeleteValue("ProxyServer")
	}
	if values.overrideSet {
		_ = key.SetStringValue("ProxyOverride", values.override)
	} else {
		_ = key.DeleteValue("ProxyOverride")
	}
}
