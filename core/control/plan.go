package control

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"net"
	"net/url"
	"strconv"
	"strings"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/errs"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
	"github.com/levvs-one/sora-client/core/parser"
)

// Limits of one request, taken from the comments of the contract. They are
// checked before anything is allocated, so a hostile or broken client cannot make
// the core build a plan of any size it likes.
const (
	// MaxPlanBytes is the largest plan the contract accepts.
	MaxPlanBytes = 4 << 20
	// MaxImportBytes is the largest payload ParseImport accepts.
	MaxImportBytes = 16 << 20
	// MaxProbeEndpoints is the largest number of endpoints one probe request
	// may carry.
	MaxProbeEndpoints = 256
)

// resolver turns a reference from the plan into the credential material behind
// it. The control plane never sees the material of a plan it did not resolve, and
// the interface never receives it back.
type resolver interface {
	Get(reference string) ([]byte, error)
}

// parseCredential reads the stored material of one outbound. The document is a
// flat map written by the import pipeline; a document the core cannot read is
// refused rather than partially applied, because half a credential is a
// connection that fails for a reason the user cannot see.
func parseCredential(material []byte) map[string]string {
	out := make(map[string]string, 12)
	if len(material) == 0 {
		return out
	}
	_ = json.Unmarshal(material, &out)
	return out
}

// credentialDocument renders the material of one outbound for storage. Only the
// fields the core understands are written, so a future field cannot leak into a
// vault by accident.
func credentialDocument(spec parser.OutboundSpec) ([]byte, error) {
	values := map[string]string{
		"uuid":         spec.UUID,
		"password":     spec.Password,
		"method":       spec.Cipher,
		"user":         spec.User,
		"flow":         spec.Flow,
		"public_key":   spec.PublicKey,
		"short_id":     spec.ShortID,
		"server_name":  spec.ServerName,
		"fingerprint":  spec.Fingerprint,
		"spider_x":     spec.SpiderX,
		"mode":         spec.Mode,
		"path":         spec.Path,
		"host_header":  spec.HostHeader,
		"service_name": spec.ServiceName,
		"alpn":         strings.Join(spec.ALPN, ","),
		"security":     spec.Security,
		"encryption":   spec.Options["encryption"],
	}
	// Obfuscation parameters travel in the free-form options of a parsed link,
	// because only some protocols have them. They are copied explicitly instead
	// of being merged wholesale: a link is untrusted input and a wholesale copy
	// would let a subscription write arbitrary keys into the vault. Links spell
	// the obfuscation password three ways; the vault knows one.
	values["obfs"] = spec.Options["obfs"]
	for _, key := range []string{"obfs_param", "obfs-password", "obfs_password"} {
		if value := spec.Options[key]; value != "" {
			values["obfs_param"] = value
			break
		}
	}
	if strings.EqualFold(spec.Protocol, "wireguard") {
		key, addresses, peers := wireguardMaterial(spec)
		values["private_key"] = key
		values["addresses"] = strings.Join(addresses, ",")
		if len(peers) > 0 {
			raw, err := json.Marshal(peers)
			if err != nil {
				return nil, errs.Wrap(err, errs.CodeInternal, errs.KeySecretStoreUnavailable)
			}
			values["peers"] = string(raw)
		}
		if awg := amneziaMaterial(spec.Options); len(awg) > 0 {
			raw, err := json.Marshal(awg)
			if err != nil {
				return nil, errs.Wrap(err, errs.CodeInternal, errs.KeySecretStoreUnavailable)
			}
			values["amneziawg"] = string(raw)
		}
	}
	if spec.AllowInsecure {
		values["insecure"] = "1"
	}
	for key, value := range values {
		if value == "" {
			delete(values, key)
		}
	}
	document, err := json.Marshal(values)
	if err != nil {
		return nil, errs.Wrap(err, errs.CodeInternal, errs.KeySecretStoreUnavailable)
	}
	return document, nil
}

func kinds(names []string) []engine.Kind {
	out := make([]engine.Kind, 0, len(names))
	for _, n := range names {
		out = append(out, engine.Kind(n))
	}
	return out
}

// planFromProto converts the plan of a Connect request into the engine plan.
//
// Two things happen here that a client cannot be trusted to do. Every outbound is
// checked against the limits and against the plan it belongs to, and every
// credential is resolved from the secret store into the engine plan, which is the
// only place the material exists.
func planFromProto(in *corev1.SessionPlan, sessionID string, secrets resolver) (*engine.Plan, error) {
	if in == nil {
		return nil, errs.Newf(errs.CodeInvalidArgument, errs.KeyPlanEmpty, "control: the request carries no plan")
	}
	if len(in.GetOutbounds()) == 0 {
		return nil, errs.Newf(errs.CodeInvalidArgument, errs.KeyPlanEmpty, "control: the plan has no outbounds")
	}
	if len(in.GetOutbounds()) > engine.MaxOutbounds {
		return nil, errs.Newf(errs.CodeResourceExhausted, errs.KeyPlanTooLarge,
			"control: the plan carries %d outbounds, the limit is %d", len(in.GetOutbounds()), engine.MaxOutbounds)
	}
	if len(in.GetRoutes()) > engine.MaxRules {
		return nil, errs.Newf(errs.CodeResourceExhausted, errs.KeyPlanTooLarge,
			"control: the plan carries %d rules, the limit is %d", len(in.GetRoutes()), engine.MaxRules)
	}

	defences := in.GetAntiCensorship()
	plan := &engine.Plan{
		SessionID: sessionID,
		Engines:   kinds(in.GetEngines()),
		Options: engine.Options{Mode: "rule", Fragment: engine.Fragment{
			Enabled:  defences.GetTlsFragment(),
			Packets:  defences.GetFragmentPackets(),
			Length:   defences.GetFragmentLength(),
			Interval: defences.GetFragmentInterval(),
		}},
		Tun: engine.Tun{
			Enabled: in.GetTunnelMode() == corev1.TunnelMode_TUNNEL_MODE_SYSTEM,
		},
	}
	seen := make(map[string]struct{}, len(in.GetOutbounds()))
	for index, spec := range in.GetOutbounds() {
		outbound, err := outboundFromProto(index, spec, secrets)
		if err != nil {
			return nil, err
		}
		if _, duplicate := seen[outbound.ID]; duplicate {
			return nil, errs.Newf(errs.CodeInvalidArgument, errs.KeyPlanDuplicateID,
				"control: two outbounds share the id %q", outbound.ID)
		}
		seen[outbound.ID] = struct{}{}
		plan.Outbounds = append(plan.Outbounds, outbound)
	}
	if mode := in.GetTunnelMode(); mode == corev1.TunnelMode_TUNNEL_MODE_UNSPECIFIED {
		return nil, errs.Newf(errs.CodeInvalidArgument, errs.KeyPlanTunnel,
			"control: the plan does not say which tunnel it wants")
	}
	// The rules of the contract carry only a destination and a target, which is
	// what a client can express without knowing the grammar of an engine. The
	// type is derived from the shape of the destination so that one rule means
	// the same thing in every engine and in every future client.
	for _, route := range in.GetRoutes() {
		rule, err := ruleFromProto(route)
		if err != nil {
			return nil, err
		}
		if _, ok := seen[rule.Target]; !ok && !isBuiltInTarget(rule.Target) {
			return nil, errs.Newf(errs.CodeInvalidArgument, errs.KeyPlanUnknownTarget,
				"control: rule %q points at %q, which is not in this plan", rule.Value, rule.Target)
		}
		plan.Rules = append(plan.Rules, rule)
	}
	plan.DNS = dnsFromProto(in.GetDnsPolicy())
	if err := checkDNS(plan.DNS); err != nil {
		return nil, err
	}
	for _, entry := range in.GetBypassSettings().GetRules() {
		if err := checkBypass(entry); err != nil {
			return nil, err
		}
	}
	if err := plan.Validate(); err != nil {
		return nil, errs.Wrap(err, errs.CodeInvalidArgument, errs.KeyPlanGroupsInvalid)
	}
	return plan, nil
}

// isBuiltInTarget reports whether a rule may point at a destination that the
// engine owns rather than at something the plan lists.
func isBuiltInTarget(target string) bool {
	switch target {
	case "direct", "block", "reject":
		return true
	default:
		return false
	}
}

// checkDNS refuses a resolver the engine could not use, with the key that names
// the problem instead of a general "the plan is invalid".
func checkDNS(dns engine.DNS) error {
	for _, server := range dns.Servers {
		if server.Address == "" {
			return errs.Newf(errs.CodeInvalidArgument, errs.KeyPlanDNSInvalid,
				"control: a resolver has no address")
		}
	}
	return nil
}

// checkBypass refuses an entry that is not a domain, an address or a network.
func checkBypass(entry string) error {
	trimmed := strings.TrimSpace(entry)
	if trimmed == "" {
		return errs.Newf(errs.CodeInvalidArgument, errs.KeyPlanBypassInvalid,
			"control: a bypass entry is empty")
	}
	if strings.ContainsAny(trimmed, " \t\r\n") {
		return errs.Newf(errs.CodeInvalidArgument, errs.KeyPlanBypassInvalid,
			"control: a bypass entry holds whitespace")
	}
	return nil
}

// outboundFromProto converts one outbound and resolves its credential reference.
func outboundFromProto(index int, spec *corev1.OutboundSpec, secrets resolver) (engine.Outbound, error) {
	id := strings.TrimSpace(spec.GetId())
	if id == "" {
		return engine.Outbound{}, errs.Newf(errs.CodeInvalidArgument, errs.KeyPlanOutbounds,
			"control: outbound %d has no id", index)
	}
	port := spec.GetEndpoint().GetPort()
	if port > 0xffff {
		return engine.Outbound{}, errs.Newf(errs.CodeInvalidArgument, errs.KeyPlanOutbounds,
			"control: outbound %q has port %d, which is not a port", id, port)
	}
	outbound := engine.Outbound{
		ID:       id,
		Name:     spec.GetDisplayName(),
		Protocol: engine.Protocol(spec.GetProtocol()),
		Server:   spec.GetEndpoint().GetHost(),
		Port:     uint16(port),
		Transport: engine.Transport{
			Type: orDefault(spec.GetTransport(), "tcp"),
		},
		TLS: engine.TLS{Enabled: !strings.EqualFold(spec.GetSecurity(), "none")},
	}
	// An outbound without a name makes a list unreadable, so the id is used.
	if outbound.Name == "" {
		outbound.Name = id
	}
	if reference := spec.GetCredentials().GetReference(); reference != "" {
		if secrets == nil {
			return engine.Outbound{}, errs.Newf(errs.CodeFailedPrecondition, errs.KeySecretStoreUnavailable,
				"control: outbound %q needs a secret but the core has no store", id)
		}
		material, err := secrets.Get(reference)
		if err != nil {
			return engine.Outbound{}, errs.Wrap(err, errs.CodeNotFound, errs.KeySecretNotFound)
		}
		if err := applyCredential(&outbound, parseCredential(material)); err != nil {
			return engine.Outbound{}, errs.Newf(errs.CodeInvalidArgument, errs.KeyPlanOutbounds,
				"control: outbound %q: %v", id, err)
		}
	}
	return outbound, nil
}

// applyCredential fills the credential fields of an outbound from stored
// material. The keys are the ones credentialDocument writes and nothing else is
// read: a material document is data from the store, not a set of instructions.
func applyCredential(outbound *engine.Outbound, values map[string]string) error {
	outbound.UUID = values["uuid"]
	outbound.Password = values["password"]
	outbound.Cipher = values["method"]
	outbound.UserID = values["user"]
	outbound.Flow = values["flow"]
	outbound.Obfs = values["obfs"]
	outbound.ObfsParam = values["obfs_param"]
	outbound.PublicKey = values["public_key"]
	outbound.ShortID = values["short_id"]
	outbound.Encryption = values["encryption"]
	outbound.TLS.ServerName = values["server_name"]
	outbound.TLS.Fingerprint = values["fingerprint"]
	if insecure, ok := values["insecure"]; ok {
		outbound.TLS.Insecure = insecure == "1" || strings.EqualFold(insecure, "true")
	}
	if alpn := values["alpn"]; alpn != "" {
		outbound.TLS.ALPN = strings.Split(alpn, ",")
	}
	// REALITY is a security mode of its own: the engines need the public key
	// and short id in the TLS block, not as loose credential fields.
	if strings.EqualFold(values["security"], "reality") {
		outbound.TLS.Enabled = true
		outbound.TLS.Reality = true
		outbound.TLS.RealityPublicKey = values["public_key"]
		outbound.TLS.RealityShortID = values["short_id"]
		outbound.TLS.SpiderX = values["spider_x"]
	}
	outbound.Transport.Path = values["path"]
	outbound.Transport.Host = values["host_header"]
	outbound.Transport.Service = values["service_name"]
	outbound.Transport.Mode = values["mode"]
	outbound.PrivateKey = values["private_key"]
	if addresses := values["addresses"]; addresses != "" {
		outbound.Addresses = strings.Split(addresses, ",")
	}
	if peers := values["peers"]; peers != "" {
		// A document that does not decode leaves the outbound without peers,
		// and the plan validation names the outbound that cannot connect.
		_ = json.Unmarshal([]byte(peers), &outbound.Peers)
	}
	if raw := values["amneziawg"]; raw != "" {
		awg, err := amneziaFrom(raw)
		if err != nil {
			return err
		}
		outbound.Amnezia = awg
	}
	return nil
}

// amneziaKeys are the AmneziaWG parameters of a configuration file, in the
// lower case the parser stores interface keys in.
var amneziaKeys = []string{"jc", "jmin", "jmax", "s1", "s2", "s3", "s4", "h1", "h2", "h3", "h4",
	"i1", "i2", "i3", "i4", "i5", "j1", "j2", "j3", "itime"}

// amneziaMaterial keeps the AmneziaWG parameters of an import and nothing
// else: an import is untrusted input, so only known keys reach the vault.
func amneziaMaterial(options map[string]string) map[string]string {
	out := map[string]string{}
	for _, key := range amneziaKeys {
		if v := strings.TrimSpace(options[key]); v != "" {
			out[key] = v
		}
	}
	return out
}

// amneziaFrom restores the AmneziaWG parameters from the vault. A value that
// is not a number where the protocol wants one fails the plan instead of
// connecting with a parameter the server does not expect.
func amneziaFrom(raw string) (*engine.AmneziaWG, error) {
	var v map[string]string
	if err := json.Unmarshal([]byte(raw), &v); err != nil {
		return nil, err
	}
	number := func(key string) (int, error) {
		if v[key] == "" {
			return 0, nil
		}
		n, err := strconv.Atoi(v[key])
		if err != nil {
			return 0, fmt.Errorf("amneziawg %s: %q is not a number", key, v[key])
		}
		return n, nil
	}
	a := &engine.AmneziaWG{H1: v["h1"], H2: v["h2"], H3: v["h3"], H4: v["h4"],
		I1: v["i1"], I2: v["i2"], I3: v["i3"], I4: v["i4"], I5: v["i5"], J1: v["j1"], J2: v["j2"], J3: v["j3"]}
	for key, field := range map[string]*int{"jc": &a.Jc, "jmin": &a.Jmin, "jmax": &a.Jmax,
		"s1": &a.S1, "s2": &a.S2, "s3": &a.S3, "s4": &a.S4, "itime": &a.Itime} {
		n, err := number(key)
		if err != nil {
			return nil, err
		}
		*field = n
	}
	return a, nil
}

// wireguardMaterial collects the private key, the interface addresses and the
// peers of a WireGuard import. A .conf file carries them in its sections; a
// wireguard:// link carries the key as user info and the rest as query.
func wireguardMaterial(spec parser.OutboundSpec) (key string, addresses []string, peers []engine.WireGuardPeer) {
	key = spec.Options["privatekey"]
	if key == "" {
		key, _ = url.PathUnescape(spec.Password)
	}
	for _, a := range strings.Split(spec.Options["address"], ",") {
		a = strings.TrimSpace(a)
		switch {
		case a == "":
			continue
		case !strings.Contains(a, "/") && strings.Contains(a, ":"):
			a += "/128"
		case !strings.Contains(a, "/"):
			a += "/32"
		}
		addresses = append(addresses, a)
	}
	split := func(list []string) []string {
		var out []string
		for _, v := range list {
			if v = strings.TrimSpace(v); v != "" {
				out = append(out, v)
			}
		}
		return out
	}
	for _, p := range spec.Peers {
		peers = append(peers, engine.WireGuardPeer{
			PublicKey: p.PublicKey, PreSharedKey: p.PreSharedKey, Endpoint: p.Endpoint,
			AllowedIPs: split(p.AllowedIPs), PersistentKeepalive: p.PersistentKeepalive,
		})
	}
	if len(peers) == 0 && spec.Options["publickey"] != "" {
		peers = append(peers, engine.WireGuardPeer{
			PublicKey:    spec.Options["publickey"],
			PreSharedKey: spec.Options["presharedkey"],
			Endpoint:     net.JoinHostPort(spec.Host, strconv.Itoa(int(spec.Port))),
			AllowedIPs:   split(strings.Split(spec.Options["allowedips"], ",")),
		})
	}
	return key, addresses, peers
}

// ruleFromProto converts one routing rule.
func ruleFromProto(route *corev1.RoutingRule) (engine.Rule, error) {
	destination := strings.TrimSpace(route.GetDestination())
	if destination == "" {
		return engine.Rule{}, errs.Newf(errs.CodeInvalidArgument, errs.KeyPlanRuleInvalid,
			"control: a rule has no destination")
	}
	target := strings.TrimSpace(route.GetOutboundId())
	if target == "" {
		return engine.Rule{}, errs.Newf(errs.CodeInvalidArgument, errs.KeyPlanRuleInvalid,
			"control: rule %q has no target", destination)
	}
	kind := ruleTypeOf(destination)
	return engine.Rule{Type: kind, Value: ruleValue(kind, destination), Target: target}, nil
}

// ruleValue strips the type prefix: the engines add their own.
func ruleValue(kind engine.RuleType, destination string) string {
	if prefix, ok := rulePrefixes[kind]; ok {
		return strings.TrimPrefix(destination, prefix)
	}
	return destination
}

// rulePrefixes follow the Xray routing vocabulary that subscriptions use:
// "domain:" matches a domain and its subdomains, "full:" one exact name.
var rulePrefixes = map[engine.RuleType]string{
	engine.RuleGeoSite:      "geosite:",
	engine.RuleGeoIP:        "geoip:",
	engine.RuleRuleSet:      "ruleset:",
	engine.RuleDomainSuffix: "domain:",
	engine.RuleDomain:       "full:",
}

// ruleTypeOf derives the rule type from the shape of a destination.
func ruleTypeOf(destination string) engine.RuleType {
	switch {
	case strings.HasPrefix(destination, "geosite:"):
		return engine.RuleGeoSite
	case strings.HasPrefix(destination, "geoip:"):
		return engine.RuleGeoIP
	case strings.HasPrefix(destination, "ruleset:"):
		return engine.RuleRuleSet
	case strings.HasPrefix(destination, "domain:"):
		return engine.RuleDomainSuffix
	case strings.HasPrefix(destination, "full:"):
		return engine.RuleDomain
	case strings.Contains(destination, "/"):
		return engine.RuleIPCIDR
	case strings.Contains(destination, ":"):
		return engine.RulePort
	default:
		return engine.RuleDomainKeyword
	}
}

// dnsFromProto converts the resolver settings of a request.
func dnsFromProto(policy *corev1.DnsPolicy) engine.DNS {
	if policy == nil || len(policy.GetServers()) == 0 {
		return engine.DNS{}
	}
	out := engine.DNS{
		Enabled: true,
		Mode:    "rule",
		Sniff:   true,
	}
	for index, address := range policy.GetServers() {
		if len(out.Servers) >= engine.MaxDNSServers {
			break
		}
		host, port, transport := splitDNSServer(address)
		out.Servers = append(out.Servers, engine.DNSServer{
			Tag:       "dns-" + strconv.Itoa(index),
			Transport: transport,
			Address:   host,
			Port:      port,
		})
	}
	return out
}

// splitDNSServer reads "tls://dns.example.com:853" into its parts. A port that is
// not a number is not a port, and the address is then used as it is.
func splitDNSServer(address string) (host string, port uint16, transport engine.DNSTransport) {
	transport = engine.DNSPlain
	rest := strings.TrimSpace(address)
	for _, candidate := range []struct {
		prefix    string
		transport engine.DNSTransport
	}{
		{"https://", engine.DNSHTTPS},
		{"h3://", engine.DNSHTTPS},
		{"tls://", engine.DNSTLS},
		{"tcp://", engine.DNSTCP},
		{"quic://", engine.DNSQUIC},
	} {
		if strings.HasPrefix(strings.ToLower(rest), candidate.prefix) {
			transport = candidate.transport
			rest = rest[len(candidate.prefix):]
			break
		}
	}
	rest = strings.TrimSuffix(rest, "/dns-query")
	if head, tail, found := strings.Cut(rest, ":"); found {
		if parsed, err := strconv.ParseUint(tail, 10, 16); err == nil {
			return head, uint16(parsed), transport
		}
	}
	return rest, 0, transport
}

// orDefault returns value when it is not empty and fallback otherwise.
func orDefault(value, fallback string) string {
	if strings.TrimSpace(value) == "" {
		return fallback
	}
	return value
}

// referenceOf is the reference a stored secret lives under.
//
// It is derived from the identity of the server, not minted at random, and that
// choice is what keeps the store from growing without bound. A subscription
// imported every morning would otherwise write a second, third and fourth copy of
// the same credential under a new name each time, and nothing would ever remove
// them: the core cannot tell a reference the user still uses from one an earlier
// import invented. With a reference that follows the server, a re-import
// overwrites the material and the number of secrets stays the number of servers
// the user actually has.
func referenceOf(spec parser.OutboundSpec) (string, error) {
	sum := sha256.Sum256([]byte(spec.StableKey()))
	// The prefix says what the reference is, the digest says which server it
	// belongs to, and neither carries a name or a host: a reference is stored,
	// logged and compared, and a reference that identifies its server in clear
	// would be the leak this package exists to prevent.
	return "s1_" + hex.EncodeToString(sum[:16]), nil
}

// outboundToProto renders one parsed server for the interface. The credential
// never appears here: the reference is the only thing that crosses the wire, and
// the core resolves it when the plan is applied.
func outboundToProto(spec parser.OutboundSpec, reference string) *corev1.OutboundSpec {
	return &corev1.OutboundSpec{
		Id:          spec.StableKey(),
		DisplayName: spec.DisplayName,
		Protocol:    spec.Protocol,
		Transport:   spec.Transport,
		Security:    spec.Security,
		Endpoint:    &corev1.Endpoint{Host: spec.Host, Port: uint32(spec.Port)},
		Credentials: &corev1.CredentialsRef{Reference: reference},
	}
}
