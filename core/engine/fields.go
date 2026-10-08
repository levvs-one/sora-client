package engine

import (
	"errors"
	"fmt"
	"net"
	"net/url"
	"strings"
	"unicode"
)

func (d DNS) validate() error {
	if !d.Enabled {
		return nil
	}
	var errs []error
	switch d.Mode {
	case "", "rule", "redir-host", string(DNSFakeIP):
	default:
		errs = append(errs, fmt.Errorf("dns: unknown mode %q", d.Mode))
	}
	if len(d.Servers) > MaxDNSServers {
		errs = append(errs, fmt.Errorf("dns: %d servers exceeds the limit of %d", len(d.Servers), MaxDNSServers))
	}
	for _, s := range d.Servers {
		if s.Address == "" {
			errs = append(errs, fmt.Errorf("dns server %q: empty address", s.Tag))
			continue
		}
		if s.Transport != DNSSystem && net.ParseIP(s.Address) == nil && !isDomain(s.Address) {
			errs = append(errs, fmt.Errorf("dns server %q: %q is neither an address nor a hostname", s.Tag, s.Address))
		}
	}
	if d.Mode == string(DNSFakeIP) && d.FakeIPRange != "" {
		if _, _, err := net.ParseCIDR(d.FakeIPRange); err != nil {
			errs = append(errs, fmt.Errorf("dns: fake-ip range %q is not a CIDR", d.FakeIPRange))
		}
	}
	return errors.Join(errs...)
}

func (t Tun) validate() error {
	if !t.Enabled {
		return nil
	}
	var errs []error
	switch t.Stack {
	case "", "system", "gvisor", "mixed":
	default:
		errs = append(errs, fmt.Errorf("tun: unknown stack %q", t.Stack))
	}
	if t.MTU != 0 && (t.MTU < 576 || t.MTU > 1500) {
		errs = append(errs, fmt.Errorf("tun: mtu %d out of range 576..1500", t.MTU))
	}
	errs = append(errs, validateDisplayName("tun", t.DeviceName))
	return errors.Join(errs...)
}

func (o Options) validate() error {
	var errs []error
	switch o.LogLevel {
	case "", "silent", "error", "warning", "info", "debug":
	default:
		errs = append(errs, fmt.Errorf("options: unknown log level %q", o.LogLevel))
	}
	switch o.Mode {
	case "", "rule", "global", "direct":
	default:
		errs = append(errs, fmt.Errorf("options: unknown mode %q", o.Mode))
	}
	errs = append(errs, validateTestURL("options", o.TestURL))
	for _, u := range []string{o.GeoSiteURL, o.GeoIPURL} {
		if u != "" && !strings.HasPrefix(u, "https://") {
			errs = append(errs, fmt.Errorf("options: geodata download must use https: %q", u))
		}
	}
	return errors.Join(errs...)
}

// validateDisplayName rejects untrusted subscription names that would break
// logs, lists, or controller requests.
func validateDisplayName(what, name string) error {
	if name == "" {
		return nil
	}
	if len(name) > MaxNameBytes {
		return fmt.Errorf("%s: name is longer than %d bytes", what, MaxNameBytes)
	}
	if strings.TrimSpace(name) != name || strings.ContainsAny(name, "\r\n\t\x00") {
		return fmt.Errorf("%s: name %q contains control characters or padding", what, name)
	}
	for _, r := range name {
		if unicode.IsControl(r) {
			return fmt.Errorf("%s: name %q contains control characters", what, name)
		}
	}
	return nil
}

// validateServer accepts IPv4, IPv6 and hostnames only, never a URL.
func validateServer(what, server string, required bool) error {
	if server == "" {
		if required {
			return fmt.Errorf("%s: empty server address", what)
		}
		return nil
	}
	if strings.ContainsAny(server, "/@:? ") {
		return fmt.Errorf("%s: server %q must be a bare host or address", what, server)
	}
	if strings.HasPrefix(server, "[") && strings.HasSuffix(server, "]") {
		server = server[1 : len(server)-1]
	}
	if net.ParseIP(server) != nil {
		return nil
	}
	if !isDomain(server) {
		return fmt.Errorf("%s: server %q is not a valid hostname", what, server)
	}
	return nil
}

// validateTestURL keeps latency probes on plain endpoints without credentials.
func validateTestURL(what, raw string) error {
	if raw == "" {
		return nil
	}
	u, err := url.Parse(raw)
	if err != nil {
		return fmt.Errorf("%s: test url is unparsable", what)
	}
	if u.Scheme != "https" && u.Scheme != "http" {
		return fmt.Errorf("%s: test url must be http or https", what)
	}
	if u.User != nil || u.Fragment != "" {
		return fmt.Errorf("%s: test url must not carry credentials or a fragment", what)
	}
	return nil
}

func validHeaderToken(s string) bool {
	if s == "" {
		return false
	}
	for _, r := range s {
		switch {
		case r >= 'a' && r <= 'z', r >= 'A' && r <= 'Z', r >= '0' && r <= '9':
		case r == '-', r == '_', r == '.', r == '!':
		default:
			return false
		}
	}
	return true
}

// isDomain reports whether s is a printable hostname with at least one dot.
func isDomain(s string) bool {
	if s == "" || len(s) > 253 || !strings.Contains(s, ".") {
		return false
	}
	labels := strings.Split(s, ".")
	for _, label := range labels {
		if label == "" || len(label) > 63 {
			return false
		}
		if strings.HasPrefix(label, "-") || strings.HasSuffix(label, "-") {
			return false
		}
		for _, r := range label {
			switch {
			case r >= 'a' && r <= 'z', r >= 'A' && r <= 'Z', r >= '0' && r <= '9', r == '-', r == '_':
			default:
				return false
			}
		}
	}
	return true
}
