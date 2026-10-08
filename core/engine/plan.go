package engine

import (
	"encoding/json"
	"net/netip"
)

// Limits mirror the sora.core.v1 contract. A plan that exceeds them is
// rejected before any engine sees it.
const (
	MaxOutbounds      = 5000
	MaxGroups         = 500
	MaxRules          = 10000
	MaxIDLen          = 128
	MaxNameBytes      = 256
	MaxHeaderCount    = 32
	MaxDNSServers     = 32
	TestURLProduction = "https://www.gstatic.com/generate_204"
)

// Protocol is an outbound protocol name as used in plans.
type Protocol string

// Outbound protocols a plan may hold, named as the control plane names them.
const (
	ProtocolVLESS       Protocol = "vless"
	ProtocolVMess       Protocol = "vmess"
	ProtocolTrojan      Protocol = "trojan"
	ProtocolShadowsocks Protocol = "shadowsocks"
	ProtocolHysteria2   Protocol = "hysteria2"
	ProtocolTUIC        Protocol = "tuic"
	ProtocolWireGuard   Protocol = "wireguard"
	ProtocolSOCKS5      Protocol = "socks5"
	ProtocolHTTP        Protocol = "http"
	ProtocolAnyTLS      Protocol = "anytls"
	// ProtocolBypass reshapes direct TLS and HTTP handshakes with zapret to
	// evade DPI. It requires no server.
	ProtocolBypass Protocol = "bypass"
	// ProtocolXrayProfile runs a provider's full Xray configuration within
	// the session, preserving outbounds, balancers, and routing. Only Xray
	// supports it.
	ProtocolXrayProfile Protocol = "xray-profile"
	ProtocolDirect      Protocol = "direct"
)

// GroupType is how the engine chooses between the members of a group.
type GroupType string

// Strategies the engine uses to pick a member of a group.
const (
	GroupSelect      GroupType = "select"
	GroupURLTest     GroupType = "url-test"
	GroupFallback    GroupType = "fallback"
	GroupLoadBalance GroupType = "load-balance"
)

// TLS holds transport security parameters of an outbound.
type TLS struct {
	Enabled     bool
	ServerName  string
	ALPN        []string
	Fingerprint string
	Insecure    bool
	Reality     bool
	// RealityPublicKey and other REALITY parameters are public but masked
	// because they identify a server.
	RealityPublicKey string
	RealityShortID   string
	SpiderX          string
}

// Transport holds the stream transport of an outbound.
type Transport struct {
	// Type is tcp, ws, grpc, h2, httpupgrade or xhttp.
	Type        string
	Path        string
	Host        string
	Service     string
	Headers     map[string]string
	Prefix      string
	IdleTimeout int
	// Mode is the XHTTP mode: auto, packet-up, stream-up or stream-one.
	Mode string
}

// WireGuardPeer is one WireGuard peer of an outbound.
type WireGuardPeer struct {
	PublicKey           string
	PreSharedKey        string
	Endpoint            string
	AllowedIPs          []string
	PersistentKeepalive int
}

// Outbound is one server the plan can route traffic through.
type Outbound struct {
	ID   string
	Name string

	Protocol  Protocol
	Transport Transport
	TLS       TLS

	Server string
	Port   uint16

	// UUID and the following credential fields must be masked in logs and
	// events.
	UUID       string
	Password   string
	Cipher     string
	UserID     string
	Flow       string
	Obfs       string
	ObfsParam  string
	PrivateKey string
	PublicKey  string
	ShortID    string
	// Encryption configures VLESS. Empty or "none" disables it; other
	// values use Xray's post-quantum VLESS Encryption.
	Encryption string

	Peers []WireGuardPeer
	// Amnezia turns a WireGuard outbound into AmneziaWG. Nil is plain
	// WireGuard.
	Amnezia *AmneziaWG
	// Bypass is the strategy of a bypass outbound.
	Bypass *BypassStrategy
	// Profile contains a provider's Xray configuration and credentials, so
	// the entire value is secret.
	Profile json.RawMessage
	// Addresses lists WireGuard interface CIDRs, required for the tunnel to
	// carry traffic.
	Addresses []string

	// Tags come from subscriptions and drive grouping in the interface.
	Tags         []string
	CountryCode  string
	ProviderID   string
	OriginalLink string
}

// Group is a user-selectable set of outbounds.
type Group struct {
	Name      string
	Type      GroupType
	Outbounds []string
	URL       string
	Interval  int
	Tolerance int
	Lazy      bool
	Hidden    bool
	Icon      string
	Provider  string
	Include   []string
	Exclude   []string
}

// RuleType is a rule matcher as named in the sora.core.v1 contract.
type RuleType string

// Rule matchers a plan may carry.
const (
	RuleDomain        RuleType = "domain"
	RuleDomainSuffix  RuleType = "domain-suffix"
	RuleDomainKeyword RuleType = "domain-keyword"
	RuleIPCIDR        RuleType = "ip-cidr"
	RuleIPSuffix      RuleType = "ip-suffix"
	RuleGeoIP         RuleType = "geoip"
	RuleGeoSite       RuleType = "geosite"
	RuleRuleSet       RuleType = "rule-set"
	RulePort          RuleType = "port"
	RuleSrcPort       RuleType = "src-port"
	RuleProcess       RuleType = "process"
	RuleProtocol      RuleType = "protocol"
	RuleMatchAll      RuleType = "all"
)

// Rule routes a matching destination to an outbound or a group.
type Rule struct {
	Type      RuleType
	Value     string
	Target    string
	NoResolve bool
}

// DNSTransport is how a DNS server is reached.
type DNSTransport string

// Transports a DNS server of the plan can be reached by.
const (
	DNSPlain  DNSTransport = "udp"
	DNSTCP    DNSTransport = "tcp"
	DNSTLS    DNSTransport = "tls"
	DNSHTTPS  DNSTransport = "https"
	DNSQUIC   DNSTransport = "quic"
	DNSSystem DNSTransport = "system"
	DNSFakeIP DNSTransport = "fakeip"
)

// DNSServer is one resolver of the plan.
type DNSServer struct {
	Tag       string
	Transport DNSTransport
	Address   string
	Port      uint16
	Dialer    string
	Suffixes  []string
	ProxyOnly bool
}

// DNS is the resolver setup of the plan.
type DNS struct {
	Enabled          bool
	Mode             string // rule, fakeip, redir-host
	FakeIPRange      string
	Servers          []DNSServer
	NameserverPolicy map[string][]string
	DisableCache     bool
	Sniff            bool
	HijackTun        []string
}

// TunDevice names Sora's adapter to avoid collisions and allow startup checks.
const TunDevice = "sora0"

// Tun is the virtual network interface setup of the plan.
type Tun struct {
	IPv4             netip.Prefix
	IPv6             netip.Prefix
	Enabled          bool
	Stack            string // system, gvisor, mixed
	DeviceName       string
	MTU              int
	StrictRoute      bool
	AutoRoute        bool
	RouteAddressSets []string
	IncludeApps      []string
	ExcludeApps      []string
}

// AmneziaWG holds configuration-file obfuscation parameters that must match the
// server. Zero values are omitted to retain engine defaults.
type AmneziaWG struct {
	Jc, Jmin, Jmax int
	S1, S2, S3, S4 int
	// H1..H4 are message type headers: a number, or a range in AmneziaWG
	// 2.0.
	H1, H2, H3, H4 string
	// I1..I5 are the signature packets of AmneziaWG 1.5 and 2.0.
	I1, I2, I3, I4, I5 string
	J1, J2, J3         string
	Itime              int
}

// BypassStrategy defines zapret handshake shaping. Positions are byte offsets,
// negative from the end, or markers (method, host, endhost, sld, midsld,
// endsld, sniext) with optional +N or -N.
type BypassStrategy struct {
	SplitPos []string
	// Disorder sends the second part of a split first.
	Disorder bool
	// OOB sends an out-of-band byte with the split.
	OOB bool
	// TLSRecord splits the ClientHello into two TLS records at a position.
	TLSRecord string
	// HostCase reshapes HTTP header casing; DomainCase and MethodEOL also
	// reshape plain HTTP requests.
	HostCase   bool
	DomainCase bool
	MethodEOL  bool
}

// Fragment splits proxy TLS ClientHello messages across TCP segments to evade
// SNI matching on a single segment.
type Fragment struct {
	Enabled bool
	// Packets selects Xray segments ("tlshello" or "1-3"); Length sets
	// bytes ("100-200") and Interval sets milliseconds ("10-20"). Engines
	// with only a switch use Enabled.
	Packets  string
	Length   string
	Interval string
}

// Options configures engine-wide plan settings.
type Options struct {
	LogLevel       string
	Mode           string // rule, global, direct
	UnifiedDelay   bool
	FindProcess    bool
	GeoData        bool
	AllowLAN       bool
	IPv6           bool
	ProfileStorage bool
	TestURL        string
	GeoSiteURL     string
	GeoIPURL       string
	Fragment       Fragment
}

// LocalProxy opens a loopback HTTP/SOCKS5 listener only for system proxy mode
// or explicit requests. Other local applications can use it and discover the
// upstream server address.
type LocalProxy struct {
	Enabled bool
	// Username and Password restrict the listener to authenticated
	// applications. System proxies cannot supply a login.
	Username string
	Password string
}

// Plan is a complete, engine-independent description of one session.
type Plan struct {
	SessionID string
	// Engines is the engine preference of this session, best first. Empty
	// uses the core default; a single entry pins that engine.
	Engines []Kind
	// PrivateControl requires Unix sockets, named pipes, or no controller,
	// preventing discovery through listening network ports.
	PrivateControl bool
	LocalProxy     LocalProxy

	Outbounds []Outbound
	Groups    []Group
	Rules     []Rule
	DNS       DNS
	Tun       Tun
	Options   Options
}
