package engine

import (
	"errors"
	"fmt"
	"net"
	"regexp"
	"slices"
	"strconv"
	"strings"
)

// Secrets returns every value of the plan that must never reach a log, an
// event or a diagnostic archive.
func (p *Plan) Secrets() []string {
	if p == nil {
		return nil
	}
	out := make([]string, 0, len(p.Outbounds)*4+1)
	for _, o := range p.Outbounds {
		out = append(out, o.Secrets()...)
	}
	if len(p.LocalProxy.Password) >= 4 {
		out = append(out, p.LocalProxy.Password)
	}
	return out
}

// Secrets lists the secret fields of one outbound. Values shorter than four
// characters are skipped: masking them would destroy ordinary log text.
func (o Outbound) Secrets() []string {
	candidates := []string{o.UUID, o.Password, o.UserID, o.ObfsParam, o.PrivateKey, o.OriginalLink}
	if o.Encryption != "none" {
		candidates = append(candidates, o.Encryption)
	}
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

// Identifiers lists the values of one outbound that are not secrets but still
// identify a person or a provider: the server host and the host with its port.
//
// They are masked separately from credentials because a diagnostic that names
// the server a user connected to is a report about that user, and because a
// reviewer needs to see the shape of a problem without seeing whose it is.
func (o Outbound) Identifiers() []string {
	out := make([]string, 0, 3)
	if o.Server != "" {
		out = append(out, o.Server)
		if o.Port != 0 {
			out = append(out, net.JoinHostPort(o.Server, strconv.Itoa(int(o.Port))))
		}
	}
	if o.TLS.ServerName != "" {
		out = append(out, o.TLS.ServerName)
	}
	out = append(out, o.Name)
	return out
}

// Identifiers returns every value of the plan that identifies a server. It is the
// counterpart of Secrets for masking, and the two are used together.
func (p *Plan) Identifiers() []string {
	if p == nil {
		return nil
	}
	out := make([]string, 0, len(p.Outbounds)*3)
	for _, o := range p.Outbounds {
		out = append(out, o.Identifiers()...)
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
	serverless := o.Protocol == ProtocolDirect || o.Protocol == ProtocolBypass
	if !serverless && o.Port == 0 {
		errs = append(errs, fmt.Errorf("outbound %s: port must be between 1 and 65535", o.ID))
	}
	if err := validateServer("outbound "+o.ID, o.Server, !serverless); err != nil {
		errs = append(errs, err)
	}
	if o.Protocol == ProtocolBypass {
		errs = append(errs, o.Bypass.validate(o.ID))
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

	// Groups may contain groups ("Proxy" offering "Auto"), so every name is
	// known before members are checked.
	members := make(map[string][]string, len(p.Groups))
	for _, g := range p.Groups {
		members[g.Name] = g.Outbounds
		if _, clash := ids[g.Name]; clash {
			errs = append(errs, fmt.Errorf("plan: group %q has the id of an outbound", g.Name))
		}
	}
	if (p.LocalProxy.Username == "") != (p.LocalProxy.Password == "") {
		errs = append(errs, errors.New("plan: the local proxy login needs both a username and a password"))
	}
	if strings.ContainsAny(p.LocalProxy.Username, ":@ \r\n") {
		errs = append(errs, errors.New("plan: the local proxy username contains a separator"))
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
			_, isOutbound := ids[ref]
			_, isGroup := members[ref]
			if !isOutbound && !isGroup && !isBuiltInTarget(ref) {
				errs = append(errs, fmt.Errorf("group %q: unknown outbound %q", g.Name, ref))
			}
		}
		if groupCycle(g.Name, members, map[string]bool{}) {
			errs = append(errs, fmt.Errorf("group %q: contains itself through its members", g.Name))
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

// groupCycle reports whether group reaches itself through nested groups.
func groupCycle(group string, members map[string][]string, visiting map[string]bool) bool {
	if visiting[group] {
		return true
	}
	visiting[group] = true
	defer delete(visiting, group)
	for _, m := range members[group] {
		if _, isGroup := members[m]; isGroup && groupCycle(m, members, visiting) {
			return true
		}
	}
	return false
}

// bypassPosition is a zapret split position: bytes, bytes from the end, or a
// marker with an optional offset.
var bypassPosition = regexp.MustCompile(`^(-?[0-9]{1,4}|(method|host|endhost|sld|midsld|endsld|sniext)([+-][0-9]{1,4})?)$`)

func (s *BypassStrategy) validate(id string) error {
	if s == nil {
		return fmt.Errorf("outbound %s: a bypass outbound needs a strategy", id)
	}
	if len(s.SplitPos) == 0 && s.TLSRecord == "" && !s.HostCase && !s.DomainCase && !s.MethodEOL {
		return fmt.Errorf("outbound %s: the bypass strategy changes nothing", id)
	}
	if len(s.SplitPos) > 8 {
		return fmt.Errorf("outbound %s: more than 8 split positions", id)
	}
	for _, pos := range append(slices.Clone(s.SplitPos), s.TLSRecord) {
		if pos != "" && !bypassPosition.MatchString(pos) {
			return fmt.Errorf("outbound %s: %q is not a split position", id, pos)
		}
	}
	if (s.Disorder || s.OOB) && len(s.SplitPos) == 0 {
		return fmt.Errorf("outbound %s: disorder and out-of-band bytes need a split position", id)
	}
	return nil
}
