package engine

import (
	"errors"
	"fmt"
	"strings"
)

// Secrets returns every value of the plan that must never reach a log, an
// event or a diagnostic archive.
func (p *Plan) Secrets() []string {
	if p == nil {
		return nil
	}
	out := make([]string, 0, len(p.Outbounds)*4)
	for _, o := range p.Outbounds {
		out = append(out, o.Secrets()...)
	}
	return out
}

// Secrets lists the secret fields of one outbound. Values shorter than four
// characters are skipped: masking them would destroy ordinary log text.
func (o Outbound) Secrets() []string {
	candidates := []string{o.UUID, o.Password, o.UserID, o.ObfsParam, o.PrivateKey, o.OriginalLink}
	for _, p := range o.Peers {
		candidates = append(candidates, p.PreSharedKey)
	}
	out := make([]string, 0, len(candidates))
	for _, c := range candidates {
		if len(c) >= 4 {
			out = append(out, c)
		}
	}
	return out
}

// Warnings returns machine-readable codes for allowed but risky choices. The
// interface localizes them, so no user text lives in the core.
func (o Outbound) Warnings() []string {
	var out []string
	if o.TLS.Insecure && o.Protocol != ProtocolDirect {
		out = append(out, "insecure-certificate")
	}
	if o.TLS.Enabled && o.TLS.ServerName == "" && o.Protocol != ProtocolDirect {
		out = append(out, "tls-server-name-missing")
	}
	if o.Transport.Type == "ws" && !o.TLS.Enabled {
		out = append(out, "websocket-without-tls")
	}
	return out
}

// Validate checks one outbound on its own, without engine capabilities.
func (o Outbound) Validate() error {
	var errs []error
	if o.ID == "" {
		errs = append(errs, errors.New("outbound: empty id"))
	} else if len(o.ID) > MaxIDLen {
		errs = append(errs, fmt.Errorf("outbound %q: id longer than %d bytes", o.ID, MaxIDLen))
	}
	if err := validateDisplayName("outbound "+o.ID, o.Name); err != nil {
		errs = append(errs, err)
	}
	if o.Protocol == "" {
		errs = append(errs, fmt.Errorf("outbound %s: empty protocol", o.ID))
	}
	if o.Protocol != ProtocolDirect && o.Port == 0 {
		errs = append(errs, fmt.Errorf("outbound %s: port must be between 1 and 65535", o.ID))
	}
	if err := validateServer("outbound "+o.ID, o.Server, o.Protocol != ProtocolDirect); err != nil {
		errs = append(errs, err)
	}
	if len(o.TLS.ALPN) > 8 {
		errs = append(errs, fmt.Errorf("outbound %s: too many ALPN entries", o.ID))
	}
	if len(o.Transport.Headers) > MaxHeaderCount {
		errs = append(errs, fmt.Errorf("outbound %s: more than %d headers", o.ID, MaxHeaderCount))
	}
	for k, v := range o.Transport.Headers {
		if !validHeaderToken(k) || strings.ContainsAny(v, "\r\n") {
			errs = append(errs, fmt.Errorf("outbound %s: header %q is not a safe HTTP header", o.ID, k))
		}
	}
	return errors.Join(errs...)
}

// Validate checks the plan as a whole: limits, identifiers, references between
// rules and groups, and the engine-independent rules of every outbound.
func (p *Plan) Validate() error {
	if p == nil {
		return errors.New("plan: nil plan")
	}
	var errs []error
	if strings.TrimSpace(p.SessionID) == "" {
		errs = append(errs, errors.New("plan: empty session id"))
	}
	if len(p.Outbounds) == 0 {
		errs = append(errs, errors.New("plan: no outbounds"))
	}
	if len(p.Outbounds) > MaxOutbounds {
		errs = append(errs, fmt.Errorf("plan: %d outbounds exceeds the limit of %d", len(p.Outbounds), MaxOutbounds))
	}
	if len(p.Groups) > MaxGroups {
		errs = append(errs, fmt.Errorf("plan: %d groups exceeds the limit of %d", len(p.Groups), MaxGroups))
	}
	if len(p.Rules) > MaxRules {
		errs = append(errs, fmt.Errorf("plan: %d rules exceeds the limit of %d", len(p.Rules), MaxRules))
	}

	ids := make(map[string]struct{}, len(p.Outbounds))
	for _, o := range p.Outbounds {
		errs = append(errs, o.Validate())
		if _, dup := ids[o.ID]; dup {
			errs = append(errs, fmt.Errorf("plan: duplicate outbound id %q", o.ID))
		}
		ids[o.ID] = struct{}{}
	}

	names := make(map[string]struct{}, len(p.Groups))
	for _, g := range p.Groups {
		errs = append(errs, g.validate())
		if g.needsProbe() && g.URL == "" && p.Options.TestURL == "" {
			errs = append(errs, fmt.Errorf("plan: group %q measures latency, but the plan has no test url", g.Name))
		}
		errs = append(errs, validateTestURL("group "+g.Name, g.URL))
		if _, dup := names[g.Name]; dup {
			errs = append(errs, fmt.Errorf("plan: duplicate group name %q", g.Name))
		}
		names[g.Name] = struct{}{}
		for _, ref := range g.Outbounds {
			if _, ok := ids[ref]; !ok {
				errs = append(errs, fmt.Errorf("group %q: unknown outbound %q", g.Name, ref))
			}
		}
	}

	for _, r := range p.Rules {
		errs = append(errs, r.validate())
		if r.Target == "" {
			errs = append(errs, fmt.Errorf("rule %s %q: empty target", r.Type, r.Value))
			continue
		}
		_, isOutbound := ids[r.Target]
		_, isGroup := names[r.Target]
		if !isOutbound && !isGroup && !isBuiltInTarget(r.Target) {
			errs = append(errs, fmt.Errorf("rule %s %q: unknown target %q", r.Type, r.Value, r.Target))
		}
	}

	errs = append(errs, p.DNS.validate(), p.Tun.validate(), p.Options.validate())
	return errors.Join(errs...)
}
