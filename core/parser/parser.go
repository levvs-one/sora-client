// Package parser converts links, base64 lists, sing-box/Xray JSON, Clash YAML,
// and WireGuard configs to OutboundSpec. Detection is separate from parsing;
// unsupported or malformed items are reported without failing the entire
// import.
package parser

import (
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"math"
	"net"
	"net/url"
	"regexp"
	"strconv"
	"strings"
	"unicode/utf8"

	"gopkg.in/yaml.v3"

	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
)

const (
	// MaxInputSize is the largest payload the parser is willing to inspect.
	MaxInputSize = 16 << 20
	// DefaultMaxItems caps how many outbounds a single import may produce.
	DefaultMaxItems = 20000
)

// Parser sentinel errors support errors.Is and contain no user data, making
// them safe to log.
var (
	ErrEmptySource   = errors.New("parser: empty source")
	ErrInputTooLarge = errors.New("parser: input exceeds 16 MiB")
	ErrUnsupported   = errors.New("parser: unsupported format")
	ErrInvalid       = errors.New("parser: invalid entry")
)

// Format names a subscription payload shape recognised by ImportDetector.
type Format string

// Detected formats do not guarantee that every contained item is parseable.
const (
	FormatUnknown          Format = "unknown"
	FormatSubscription     Format = "https-subscription"
	FormatHTTPSubscription Format = "http-subscription"
	FormatLink             Format = "share-link"
	FormatBase64           Format = "base64-list"
	FormatSIP008           Format = "sip008"
	FormatClash            Format = "clash-yaml"
	FormatSingBox          Format = "sing-box-json"
	FormatXray             Format = "xray-json"
	FormatWireGuard        Format = "wireguard-conf"
	FormatPlainList        Format = "plain-list"
)

// Detection records the detected Format and a short diagnostic Reason.
type Detection struct {
	Format Format
	Reason string
}

// ImportDetector identifies formats without parsing. MaxItems bounds list
// expansion; zero uses DefaultMaxItems. Concurrent use is safe.
type ImportDetector struct{ MaxItems int }

// Detect identifies src's format. Empty or oversized input returns an empty
// Detection; other errors include the best format guess.
func (d ImportDetector) Detect(src []byte) (Detection, error) {
	if len(src) == 0 || strings.TrimSpace(string(src)) == "" {
		return Detection{}, ErrEmptySource
	}
	if len(src) > MaxInputSize {
		return Detection{}, ErrInputTooLarge
	}
	s := strings.TrimSpace(string(src))
	low := strings.ToLower(s)
	if strings.HasPrefix(low, "https://") {
		return Detection{Format: FormatSubscription}, nil
	}
	if strings.HasPrefix(low, "http://") {
		return Detection{Format: FormatHTTPSubscription, Reason: "subscriptions require HTTPS"}, nil
	}
	if hasScheme(s) {
		return Detection{Format: FormatLink}, nil
	}
	if strings.HasPrefix(s, "{") || strings.HasPrefix(s, "[") {
		var v any
		if json.Unmarshal([]byte(s), &v) == nil {
			return classifyJSON(v), nil
		}
	}
	if strings.Contains(s, "proxies:") {
		return Detection{Format: FormatClash}, nil
	}
	if looksWG(s) {
		return Detection{Format: FormatWireGuard}, nil
	}
	if b, ok := decodeBase64(s); ok && (hasScheme(string(b)) || looksList(string(b))) {
		return Detection{Format: FormatBase64}, nil
	}
	if looksList(s) {
		return Detection{Format: FormatPlainList}, nil
	}
	return Detection{Format: FormatUnknown, Reason: "no supported parser matched"}, ErrUnsupported
}
func hasScheme(s string) bool {
	for _, l := range strings.Fields(s) {
		p := strings.ToLower(strings.TrimSpace(l))
		for _, x := range []string{"vless://", "vmess://", "trojan://", "ss://", "socks://", "socks5://", "http://", "https://", "hysteria2://", "hy2://", "tuic://", "wireguard://", "wg://"} {
			if strings.HasPrefix(p, x) {
				return true
			}
		}
	}
	return false
}
func looksList(s string) bool {
	n := 0
	for _, l := range strings.Split(s, "\n") {
		if hasScheme(strings.TrimSpace(l)) {
			n++
		}
	}
	return n > 0
}
func looksWG(s string) bool {
	return strings.Contains(s, "[Interface]") && strings.Contains(s, "[Peer]")
}
func classifyJSON(v any) Detection {
	m, ok := v.(map[string]any)
	if !ok {
		if a, ok := v.([]any); ok && len(a) > 0 {
			if _, ok := a[0].(map[string]any); ok {
				return Detection{Format: FormatXray}
			}
		}
		return Detection{}
	}
	if _, ok := m["outbounds"]; ok {
		return Detection{Format: FormatSingBox}
	}
	if _, ok := m["servers"]; ok {
		return Detection{Format: FormatSIP008}
	}
	if _, ok := m["inbounds"]; ok {
		return Detection{Format: FormatXray}
	}
	return Detection{}
}
func decodeBase64(s string) ([]byte, bool) {
	clean := strings.Map(func(r rune) rune {
		if r == '\r' || r == '\n' || r == ' ' || r == '\t' {
			return -1
		}
		return r
	}, s)
	for _, e := range []*base64.Encoding{base64.StdEncoding, base64.RawStdEncoding, base64.URLEncoding, base64.RawURLEncoding} {
		x := clean
		if n := len(x) % 4; n != 0 {
			x += strings.Repeat("=", 4-n)
		}
		if b, err := e.DecodeString(x); err == nil && utf8.Valid(b) {
			return b, true
		}
	}
	return nil, false
}

// OutboundSpec describes a parsed server independently of engines. Options
// retains additional fields to avoid silently losing unsupported settings
// during import.
type OutboundSpec struct {
	ID, DisplayName, Protocol, Transport, Security                                                  string
	Host                                                                                            string
	Port                                                                                            uint16
	UUID, Password, User, Cipher                                                                    string
	PublicKey, ShortID, SpiderX, ServerName, Fingerprint, Flow, Path, HostHeader, ServiceName, Mode string
	ALPN                                                                                            []string
	CountryCode                                                                                     string
	AllowInsecure                                                                                   bool
	Options                                                                                         map[string]string
	Peers                                                                                           []WireGuardPeer
}

// WireGuardPeer is one WireGuard peer as described by a wg-conf file or a
// wireguard:// link. PersistentKeepalive is measured in seconds.
type WireGuardPeer struct {
	PublicKey, PreSharedKey, Endpoint string
	AllowedIPs, Reserved              []string
	PersistentKeepalive               int
}

// StableKey hashes protocol, endpoint, ID, and user to identify a server across
// imports without exposing IDs.
func (o OutboundSpec) StableKey() string {
	// Exclude passwords from identity to avoid storing password hashes.
	material := o.Protocol + "\x00" + o.Host + "\x00" + strconv.Itoa(int(o.Port)) + "\x00" + o.UUID + "\x00" + o.User
	// Names distinguish profiles sharing an endpoint. Exclude mutable
	// provider rules so updates preserve saved selections.
	if o.Protocol == "xray-profile" {
		material += "\x00" + o.DisplayName
	}
	h := sha256.Sum256([]byte(material))
	return o.Protocol + ":" + o.Host + ":" + strconv.Itoa(int(o.Port)) + ":" + hex.EncodeToString(h[:8])
}
func (o *OutboundSpec) validate() error {
	// uint16 permits only zero as an invalid port here; larger values are
	// rejected during parsing.
	if o.Protocol == "" || o.Host == "" || o.Port < 1 {
		return ErrInvalid
	}
	if o.Protocol == "vless" || o.Protocol == "vmess" || o.Protocol == "tuic" {
		if o.UUID != "" && !uuidRE.MatchString(o.UUID) {
			return fmt.Errorf("%w: invalid UUID", ErrInvalid)
		}
	}
	return nil
}

var uuidRE = regexp.MustCompile(`^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$`)

// ToProto converts a validated canonical specification to the stable fields of
// the control-plane model.
func (o OutboundSpec) ToProto() (*corev1.OutboundSpec, error) {
	if err := o.validate(); err != nil {
		return nil, err
	}
	return &corev1.OutboundSpec{Id: o.ID, DisplayName: o.DisplayName, Protocol: o.Protocol, Transport: o.Transport, Security: o.Security, Endpoint: &corev1.Endpoint{Host: o.Host, Port: uint32(o.Port)}, Credentials: &corev1.CredentialsRef{Reference: o.UUID}}, nil
}

// ItemReason identifies a skipped source position and a stable readable reason.
type ItemReason struct {
	Index  int
	Reason string
}

// ImportReport counts all candidate items, including skipped entries, for a
// complete import summary.
type ImportReport struct {
	Imported, SkippedDuplicates, Unsupported, Invalid int
	UnsupportedItems, InvalidItems, DuplicateItems    []ItemReason
}

// ImportResult holds the detected format, validated outbounds, and skipped-item
// report.
type ImportResult struct {
	Format  Format
	Servers []OutboundSpec
	Report  ImportReport
}

// LinkParser parses without mutating src and is safe for concurrent use.
// MaxItems bounds results; zero uses DefaultMaxItems.
type LinkParser struct{ MaxItems int }

func (p LinkParser) limit() int {
	if p.MaxItems <= 0 {
		return DefaultMaxItems
	}
	return p.MaxItems
}

// Parse returns valid outbounds and reports skipped items. Errors indicate an
// unusable whole payload: empty, oversized, or unsupported format.
func (p LinkParser) Parse(src []byte) (ImportResult, error) {
	if len(src) > MaxInputSize {
		return ImportResult{}, ErrInputTooLarge
	}
	d, e := (ImportDetector{p.limit()}).Detect(src)
	if e != nil && d.Format != FormatHTTPSubscription && d.Format != FormatUnknown {
		return ImportResult{Format: d.Format}, e
	}
	if d.Format == FormatHTTPSubscription {
		return ImportResult{Format: d.Format}, ErrUnsupported
	}
	s := strings.TrimSpace(string(src))
	switch d.Format {
	case FormatBase64:
		b, _ := decodeBase64(s)
		s = string(b)
		d.Format = FormatPlainList
	case FormatSIP008, FormatSingBox, FormatXray:
		return p.parseJSON([]byte(s), d.Format)
	case FormatClash:
		return p.parseYAML([]byte(s))
	case FormatWireGuard:
		return p.parseWG(s)
	}
	return p.parseList(s, d.Format)
}
func (p LinkParser) parseList(s string, f Format) (ImportResult, error) {
	r := ImportResult{Format: f}
	seen := map[string]struct{}{}
	for i, l := range strings.Split(s, "\n") {
		if len(r.Servers) >= p.limit() {
			r.Report.Unsupported++
			r.Report.UnsupportedItems = append(r.Report.UnsupportedItems, ItemReason{i, "item limit exceeded"})
			continue
		}
		l = strings.TrimSpace(l)
		if l == "" {
			continue
		}
		o, e := parseLink(l)
		if e != nil {
			if errors.Is(e, ErrUnsupported) {
				r.Report.Unsupported++
				r.Report.UnsupportedItems = append(r.Report.UnsupportedItems, ItemReason{i, "unsupported protocol or option"})
			} else {
				r.Report.Invalid++
				r.Report.InvalidItems = append(r.Report.InvalidItems, ItemReason{i, "invalid link fields"})
			}
			continue
		}
		k := o.StableKey()
		if _, ok := seen[k]; ok {
			r.Report.SkippedDuplicates++
			r.Report.DuplicateItems = append(r.Report.DuplicateItems, ItemReason{i, "duplicate server"})
			continue
		}
		seen[k] = struct{}{}
		r.Servers = append(r.Servers, o)
		r.Report.Imported++
	}
	if len(r.Servers) == 0 && r.Report.Unsupported == 0 && r.Report.Invalid == 0 {
		return r, ErrUnsupported
	}
	return r, nil
}
func parseLink(raw string) (OutboundSpec, error) {
	u, e := url.Parse(strings.TrimSpace(raw))
	if e != nil {
		return OutboundSpec{}, ErrInvalid
	}
	proto := strings.ToLower(u.Scheme)
	if proto == "vmess" {
		return parseVMess(u)
	}
	if proto == "wireguard" || proto == "wg" {
		return parseWireURL(u)
	}
	if !map[string]bool{"vless": true, "trojan": true, "ss": true, "socks": true, "socks5": true, "http": true, "https": true, "hysteria2": true, "hy2": true, "tuic": true}[proto] {
		return OutboundSpec{}, ErrUnsupported
	}
	p, e := parsePort(u.Port())
	if e != nil {
		return OutboundSpec{}, e
	}
	o := OutboundSpec{Protocol: proto, Host: u.Hostname(), Port: p, Transport: "tcp", Security: "none", Options: map[string]string{}}
	if u.User != nil {
		o.User = u.User.Username()
		o.Password, _ = u.User.Password()
	}
	for k, v := range u.Query() {
		if len(v) > 0 {
			o.Options[k] = v[0]
		}
	}
	switch proto {
	case "ss":
		o.Cipher = o.User
		if b, ok := decodeBase64(o.User); ok {
			parts := strings.SplitN(string(b), ":", 2)
			if len(parts) == 2 {
				o.Cipher, o.Password = parts[0], parts[1]
			}
		}
		if o.Password == "" {
			o.Password = getq(u, "password")
		}
	case "tuic":
		o.UUID = o.User
		o.Security = "tls"
	default:
		o.UUID = o.User
		o.Transport = getq(u, "type", "transport")
		o.Security = getq(u, "security")
		if o.Security == "" && proto == "vless" {
			o.Security = "none"
		}
	}
	o.Path = getq(u, "path")
	o.HostHeader = getq(u, "host")
	o.ServiceName = getq(u, "serviceName", "service_name")
	o.Mode = getq(u, "mode")
	o.PublicKey = getq(u, "pbk", "public-key")
	o.ShortID = getq(u, "sid", "short-id")
	o.SpiderX = getq(u, "spx")
	o.ServerName = getq(u, "sni")
	o.Fingerprint = getq(u, "fp")
	o.Flow = getq(u, "flow")
	o.AllowInsecure = parseBool(getq(u, "allowInsecure", "insecure", "skip-cert-verify"))
	if a := getq(u, "alpn"); a != "" {
		o.ALPN = strings.Split(a, ",")
	}
	for _, k := range []string{"mport", "pinSHA256", "pin_sha256", "obfs", "obfs-password", "obfs_password", "congestion_control", "udp_relay_mode"} {
		if v := getq(u, k); v != "" {
			o.Options[k] = v
		}
	}
	if o.Security == "" {
		// Default security follows protocol semantics: trojan,
		// hysteria2, and HTTPS use TLS; others do not. Empty security
		// would incorrectly enable TLS for plain SOCKS downstream.
		switch proto {
		case "trojan", "hysteria2", "hy2", "https":
			o.Security = "tls"
		default:
			o.Security = "none"
		}
	}
	// Normalize link schemes to engine protocol names.
	o.Protocol = map[string]string{"ss": "shadowsocks", "socks": "socks5", "hy2": "hysteria2", "https": "http"}[proto]
	if o.Protocol == "" {
		o.Protocol = proto
	}
	o.DisplayName = fragmentName(u.Fragment)
	o.CountryCode = countryCode(o.DisplayName)
	return o, o.validate()
}
func parseBool(s string) bool { v, _ := strconv.ParseBool(s); return v }
func parsePort(s string) (uint16, error) {
	n, e := strconv.Atoi(s)
	if e != nil || n < 1 || n > 65535 {
		return 0, ErrInvalid
	}
	return uint16(n), nil
}
func getq(u *url.URL, ks ...string) string {
	for _, k := range ks {
		if v := u.Query().Get(k); v != "" {
			return v
		}
	}
	return ""
}
func fragmentName(s string) string {
	v, e := url.QueryUnescape(s)
	if e == nil {
		return v
	}
	return s
}
func countryCode(s string) string {
	r := []rune(s)
	if len(r) >= 2 && r[0] >= 0x1F1E6 && r[0] <= 0x1F1FF && r[1] >= 0x1F1E6 && r[1] <= 0x1F1FF {
		return string(r[:2])
	}
	return ""
}
func parseVMess(u *url.URL) (OutboundSpec, error) {
	raw := strings.TrimPrefix(u.Opaque, "//")
	if raw == "" {
		raw = strings.TrimPrefix(u.Path, "/")
	}
	if b, ok := decodeBase64(raw); ok {
		var v map[string]any
		if json.Unmarshal(b, &v) == nil {
			return mapJSONSpec(v, "vmess")
		}
	}
	if u.Hostname() == "" {
		return OutboundSpec{}, ErrInvalid
	}
	o := OutboundSpec{Protocol: "vmess", Host: u.Hostname(), Transport: "tcp", Security: "auto", Options: map[string]string{}}
	o.Port, _ = parsePort(u.Port())
	if u.User != nil {
		o.UUID = u.User.Username()
		o.Password, _ = u.User.Password()
	}
	for k, v := range u.Query() {
		if len(v) > 0 {
			o.Options[k] = v[0]
		}
	}
	o.Transport = getq(u, "type", "transport")
	if o.Transport == "" {
		o.Transport = "tcp"
	}
	o.Security = getq(u, "security")
	if o.Security == "" {
		o.Security = "auto"
	}
	o.DisplayName = fragmentName(u.Fragment)
	return o, o.validate()
}
func parseWireURL(u *url.URL) (OutboundSpec, error) {
	p, e := parsePort(u.Port())
	if e != nil {
		return OutboundSpec{}, e
	}
	o := OutboundSpec{Protocol: "wireguard", Host: u.Hostname(), Port: p, Transport: "udp", DisplayName: fragmentName(u.Fragment), Options: map[string]string{}}
	for k, v := range u.Query() {
		if len(v) > 0 {
			o.Options[k] = v[0]
		}
	}
	if u.User != nil {
		o.Password = u.User.String()
	}
	return o, o.validate()
}
func mapJSONSpec(m map[string]any, fallback string) (OutboundSpec, error) {
	o := OutboundSpec{Protocol: fallback, Transport: "tcp", Options: map[string]string{}}
	if s, ok := m["type"].(string); ok {
		o.Protocol = s
	}
	for _, k := range []string{"server", "address", "host"} {
		if s, ok := m[k].(string); ok && o.Host == "" {
			o.Host = s
		}
	}
	o.Port = portNumber(m["server_port"])
	if o.Port == 0 {
		o.Port = portNumber(m["port"])
	}
	o.UUID = stringValue(m["uuid"])
	o.Password = stringValue(m["password"])
	o.Cipher = stringValue(m["method"])
	o.Transport = stringValue(m["network"])
	if o.Transport == "" {
		o.Transport = stringValue(m["transport"])
	}
	if o.Transport == "" {
		o.Transport = "tcp"
	}
	o.Flow = stringValue(m["flow"])
	o.DisplayName = stringValue(m["tag"])
	o.Security = stringValue(m["security"])
	for k, v := range m {
		if b, err := json.Marshal(v); err == nil {
			o.Options[k] = string(b)
		}
	}
	return o, o.validate()
}
func stringValue(v any) string {
	if s, ok := v.(string); ok {
		return s
	}
	return ""
}

// portNumber returns zero outside 1..65535 so validation rejects invalid ports
// instead of truncating them.
func portNumber(v any) uint16 {
	n := number(v)
	if n < 1 || n > math.MaxUint16 {
		return 0
	}
	return uint16(n)
}

// number converts JSON number representations to int, returning zero for
// invalid or overflowing values.
func number(v any) int {
	switch n := v.(type) {
	case float64:
		if n < 0 || n > math.MaxInt32 {
			return 0
		}
		return int(n)
	case int:
		return n
	case uint64:
		if n > uint64(math.MaxInt32) {
			return 0
		}
		return int(n)
	case string:
		i, _ := strconv.Atoi(n)
		return i
	}
	return 0
}
func (p LinkParser) parseJSON(b []byte, f Format) (ImportResult, error) {
	var v any
	if json.Unmarshal(b, &v) != nil {
		return ImportResult{Format: f}, ErrInvalid
	}
	items := []any{}
	switch x := v.(type) {
	case []any:
		items = x
	case map[string]any:
		if a, ok := x["outbounds"].([]any); ok {
			items = a
		} else if a, ok := x["servers"].([]any); ok {
			items = a
		} else if a, ok := x["outbound"].([]any); ok {
			items = a
		} else if f == FormatXray {
			items = xrayItems(x)
		} else {
			items = []any{x}
		}
	}
	r := ImportResult{Format: f}
	// Treat full Xray configurations, including Remnawave lists, as
	// separate provider profiles.
	if m, ok := v.(map[string]any); ok && isXrayConfig(m) {
		items = []any{m}
	}
	for _, it := range items {
		m, ok := it.(map[string]any)
		if !ok {
			continue
		}
		if isXrayConfig(m) {
			o, e := profileSpec(m)
			if e != nil {
				r.Report.Invalid++
				continue
			}
			r.Servers = append(r.Servers, o)
			r.Report.Imported++
			continue
		}
		o, e := mapJSONSpec(m, "")
		if e != nil {
			r.Report.Invalid++
			continue
		}
		if o.Protocol == "" {
			r.Report.Unsupported++
			continue
		}
		r.Servers = append(r.Servers, o)
		r.Report.Imported++
	}
	return r, nil
}

// isXrayConfig distinguishes full configurations by Xray-shaped outbounds with
// protocol and settings fields.
func isXrayConfig(m map[string]any) bool {
	outs, ok := m["outbounds"].([]any)
	if !ok || len(outs) == 0 {
		return false
	}
	first, ok := outs[0].(map[string]any)
	if !ok {
		return false
	}
	_, hasProtocol := first["protocol"]
	return hasProtocol
}

// profileSpec stores compacted configuration in Options["profile"]. The default
// outbound supplies endpoint, transport, and security for display and
// measurement.
func profileSpec(m map[string]any) (OutboundSpec, error) {
	raw, err := json.Marshal(m)
	if err != nil {
		return OutboundSpec{}, ErrInvalid
	}
	o := OutboundSpec{Protocol: "xray-profile", Options: map[string]string{"profile": string(raw)}}
	o.DisplayName = strings.TrimSpace(stringValue(m["remarks"]))
	for _, it := range m["outbounds"].([]any) {
		ob, ok := it.(map[string]any)
		if !ok {
			continue
		}
		switch stringValue(ob["protocol"]) {
		case "freedom", "blackhole", "dns", "loopback", "":
			continue
		}
		o.Host, o.Port = xrayEndpoint(ob)
		if ss, ok := ob["streamSettings"].(map[string]any); ok {
			o.Transport = stringValue(ss["network"])
			o.Security = stringValue(ss["security"])
		}
		break
	}
	if o.Transport == "" {
		o.Transport = "tcp"
	}
	if o.Security == "" {
		o.Security = "none"
	}
	if o.DisplayName == "" {
		o.DisplayName = o.Host
	}
	o.CountryCode = countryCode(o.DisplayName)
	return o, o.validate()
}

// xrayEndpoint reads settings.vnext, settings.servers, or newer flat
// settings.address endpoints.
func xrayEndpoint(ob map[string]any) (string, uint16) {
	settings, _ := ob["settings"].(map[string]any)
	for _, key := range []string{"vnext", "servers", "peers"} {
		if list, ok := settings[key].([]any); ok && len(list) > 0 {
			if first, ok := list[0].(map[string]any); ok {
				host := stringValue(first["address"])
				if host == "" {
					host = stringValue(first["endpoint"])
				}
				return host, portNumber(first["port"])
			}
		}
	}
	return stringValue(settings["address"]), portNumber(settings["port"])
}

func xrayItems(m map[string]any) []any {
	if a, ok := m["outbounds"].([]any); ok {
		return a
	}
	return []any{m}
}
func (p LinkParser) parseYAML(b []byte) (ImportResult, error) {
	var root struct {
		Proxies []map[string]any `yaml:"proxies"`
	}
	if yaml.Unmarshal(b, &root) != nil {
		return ImportResult{Format: FormatClash}, ErrInvalid
	}
	r := ImportResult{Format: FormatClash}
	for _, m := range root.Proxies {
		o, e := mapJSONSpec(m, "")
		if e != nil {
			r.Report.Invalid++
			continue
		}
		o.DisplayName = stringValue(m["name"])
		r.Servers = append(r.Servers, o)
		r.Report.Imported++
	}
	return r, nil
}
func (p LinkParser) parseWG(s string) (ImportResult, error) {
	o := OutboundSpec{Protocol: "wireguard", Transport: "udp", Options: map[string]string{}}
	section := ""
	var peer WireGuardPeer
	for _, line := range strings.Split(s, "\n") {
		line = strings.TrimSpace(line)
		if strings.HasPrefix(line, "[") {
			if section == "[peer]" {
				o.Peers = append(o.Peers, peer)
				peer = WireGuardPeer{}
			}
			section = strings.ToLower(line)
			continue
		}
		kv := strings.SplitN(line, "=", 2)
		if len(kv) != 2 {
			continue
		}
		k := strings.ToLower(strings.TrimSpace(kv[0]))
		v := strings.TrimSpace(kv[1])
		if section == "[interface]" {
			o.Options[k] = v
		}
		if section == "[peer]" {
			switch k {
			case "publickey":
				peer.PublicKey = v
			case "presharedkey":
				peer.PreSharedKey = v
			case "endpoint":
				peer.Endpoint = v
				h, p, e := net.SplitHostPort(v)
				if e == nil {
					o.Host = h
					o.Port, _ = parsePort(p)
				}
			case "allowedips":
				peer.AllowedIPs = strings.Split(v, ",")
			case "persistentkeepalive":
				peer.PersistentKeepalive, _ = strconv.Atoi(v)
			}
		}
	}
	if section == "[peer]" {
		o.Peers = append(o.Peers, peer)
	}
	if e := o.validate(); e != nil {
		return ImportResult{Format: FormatWireGuard}, e
	}
	return ImportResult{Format: FormatWireGuard, Servers: []OutboundSpec{o}, Report: ImportReport{Imported: 1}}, nil
}
