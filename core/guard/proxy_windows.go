//go:build windows

package guard

import (
	"context"
	"errors"
	"math"
	"sync"

	"golang.org/x/sys/windows/registry"

	"github.com/levvs-one/sora-client/core/errs"
)

// The system proxy of a Windows desktop lives in one registry key. That is the whole
// mechanism, and the whole reason a restore is possible: the previous values are
// read before the first write and put back afterwards, including the case where the
// proxy was off and the values did not exist at all.
const (
	internetSettingsKey = `Software\Microsoft\Windows\CurrentVersion\Internet Settings`
	valueProxyEnable    = "ProxyEnable"
	valueProxyServer    = "ProxyServer"
	valueProxyOverride  = "ProxyOverride"
)

// proxyOverride is the list of destinations that must not go through the proxy.
// A tunnel installed on a machine with an intranet must keep that intranet
// reachable, so this list is fixed rather than empty.
const proxyOverride = "localhost;127.*;<local>"

// RegistryProxy changes the system proxy of the current user. The key is per user,
// so the core only ever changes the proxy of the account it runs for, and a machine
// with several accounts keeps each of them separate.
type RegistryProxy struct {
	mu       sync.Mutex
	snapshot *proxySnapshot
}

// proxySnapshot is the state of the key before the first write. A nil field means
// the value did not exist, and restoring must delete it again rather than write an
// empty one: an empty ProxyServer is not the same as an absent one to every program
// that reads this key.
type proxySnapshot struct {
	enabled  *uint32
	server   *string
	override *string
}

// NewRegistryProxy returns a proxy for the current user.
func NewRegistryProxy() *RegistryProxy { return &RegistryProxy{} }

// Apply points the system proxy at address, remembering the previous state once.
func (p *RegistryProxy) Apply(_ context.Context, address string) error {
	if err := validateAddress(address); err != nil {
		return err
	}
	p.mu.Lock()
	defer p.mu.Unlock()
	if p.snapshot != nil {
		// Already pointing at the engine. Rewriting the same values tells every
		// application on the machine that its settings changed, which makes
		// software re-read the proxy and reconnect for no reason.
		return nil
	}
	key, err := openInternetSettings(registry.SET_VALUE | registry.QUERY_VALUE)
	if err != nil {
		return err
	}
	defer func() { _ = key.Close() }()

	snapshot, err := readProxySnapshot(key)
	if err != nil {
		return err
	}
	if err := setDWORD(key, valueProxyEnable, 1); err != nil {
		return err
	}
	if err := setString(key, valueProxyServer, address); err != nil {
		return err
	}
	if err := setString(key, valueProxyOverride, proxyOverride); err != nil {
		return err
	}
	p.snapshot = snapshot
	return nil
}

// Restore puts back the state that was in force before the first Apply. Restoring
// without a snapshot succeeds and changes nothing, so a cleanup path may run twice.
func (p *RegistryProxy) Restore(_ context.Context) error {
	p.mu.Lock()
	defer p.mu.Unlock()
	if p.snapshot == nil {
		return nil
	}
	snapshot := p.snapshot
	p.snapshot = nil
	key, err := openInternetSettings(registry.SET_VALUE | registry.QUERY_VALUE)
	if err != nil {
		return err
	}
	defer func() { _ = key.Close() }()
	return writeProxySnapshot(key, snapshot)
}

// Current reports where the system proxy points, empty when it is off.
func (p *RegistryProxy) Current(_ context.Context) (string, error) {
	key, err := openInternetSettings(registry.QUERY_VALUE)
	if err != nil {
		return "", err
	}
	defer func() { _ = key.Close() }()
	enabled, _, err := key.GetIntegerValue(valueProxyEnable)
	if err != nil {
		if isNotFound(err) {
			return "", nil
		}
		return "", errs.Wrap(err, errs.CodeInternal, errs.KeyGuardProxyFailed)
	}
	if enabled == 0 {
		return "", nil
	}
	server, _, err := key.GetStringValue(valueProxyServer)
	if err != nil {
		if isNotFound(err) {
			return "", nil
		}
		return "", errs.Wrap(err, errs.CodeInternal, errs.KeyGuardProxyFailed)
	}
	return server, nil
}

// openInternetSettings opens the key of the current user.
func openInternetSettings(access uint32) (registry.Key, error) {
	key, err := registry.OpenKey(registry.CURRENT_USER, internetSettingsKey, access)
	if err != nil {
		var zero registry.Key
		return zero, errs.Wrap(err, errs.CodeInternal, errs.KeyGuardProxyFailed)
	}
	return key, nil
}

// readProxySnapshot reads the values a restore needs.
func readProxySnapshot(key registry.Key) (*proxySnapshot, error) {
	snapshot := &proxySnapshot{}
	if value, _, err := key.GetIntegerValue(valueProxyEnable); err == nil {
		// The registry reports a 32 bit value as 64 bits. The narrowing is exact
		// because the value was written as a DWORD, and a key edited by hand with
		// a larger number is treated as "on" rather than truncated to something
		// that would look like a different setting.
		enabled := uint32(min(value, math.MaxUint32)) //nolint:gosec // bounded by the check
		snapshot.enabled = &enabled
	} else if !isNotFound(err) {
		return nil, errs.Wrap(err, errs.CodeInternal, errs.KeyGuardProxyFailed)
	}
	if value, _, err := key.GetStringValue(valueProxyServer); err == nil {
		snapshot.server = &value
	} else if !isNotFound(err) {
		return nil, errs.Wrap(err, errs.CodeInternal, errs.KeyGuardProxyFailed)
	}
	if value, _, err := key.GetStringValue(valueProxyOverride); err == nil {
		snapshot.override = &value
	} else if !isNotFound(err) {
		return nil, errs.Wrap(err, errs.CodeInternal, errs.KeyGuardProxyFailed)
	}
	return snapshot, nil
}

// writeProxySnapshot puts back what was read, deleting values that did not exist.
func writeProxySnapshot(key registry.Key, snapshot *proxySnapshot) error {
	if err := restoreDWORD(key, valueProxyEnable, snapshot.enabled); err != nil {
		return err
	}
	if err := restoreString(key, valueProxyServer, snapshot.server); err != nil {
		return err
	}
	return restoreString(key, valueProxyOverride, snapshot.override)
}

// restoreDWORD writes a value back, or deletes it when it did not exist.
func restoreDWORD(key registry.Key, name string, value *uint32) error {
	if value == nil {
		if err := deleteValue(key, name); err != nil {
			return err
		}
		return nil
	}
	return setDWORD(key, name, *value)
}

// restoreString writes a value back, or deletes it when it did not exist.
func restoreString(key registry.Key, name string, value *string) error {
	if value == nil {
		if err := deleteValue(key, name); err != nil {
			return err
		}
		return nil
	}
	return setString(key, name, *value)
}

// deleteValue removes a value, treating an absent value as the state it wanted.
func deleteValue(key registry.Key, name string) error {
	if err := key.DeleteValue(name); err != nil && !isNotFound(err) {
		return errs.Wrap(err, errs.CodeInternal, errs.KeyGuardRestoreFailed)
	}
	return nil
}

func setDWORD(key registry.Key, name string, value uint32) error {
	if err := key.SetDWordValue(name, value); err != nil {
		return errs.Wrap(err, errs.CodeInternal, errs.KeyGuardProxyFailed)
	}
	return nil
}

func setString(key registry.Key, name, value string) error {
	if err := key.SetStringValue(name, value); err != nil {
		return errs.Wrap(err, errs.CodeInternal, errs.KeyGuardProxyFailed)
	}
	return nil
}

// isNotFound reports whether an error means the value or key is absent.
func isNotFound(err error) bool {
	return errors.Is(err, registry.ErrNotExist)
}

// PlatformProxy returns the proxy this platform has, which is the registry of the
// current user on Windows and nothing anywhere else.
func PlatformProxy() Proxy { return NewRegistryProxy() }
