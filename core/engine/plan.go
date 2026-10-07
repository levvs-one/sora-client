package engine

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
	// ProtocolBypass reaches sites directly, with the TLS and HTTP handshake
	// reshaped by zapret so that DPI does not recognise the site. No server.
	ProtocolBypass Protocol = "bypass"
	ProtocolDirect Protocol = "direct"
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
	// Reality parameters. None of them is a secret, but they are still
	// masked in logs because they identify one server.
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

	// Everything below is secret material and is masked in logs and events.
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
	// Encryption is the VLESS encryption setting. Empty and "none" mean
	// none; anything else is the post-quantum VLESS Encryption of Xray.
	Encryption string

	Peers []WireGuardPeer
	// Amnezia turns a WireGuard outbound into AmneziaWG. Nil is plain
	// WireGuard.
	Amnezia *AmneziaWG
	// Bypass is the strategy of a bypass outbound.
	Bypass *BypassStrategy
	// Addresses are the interface addresses of a WireGuard outbound, in CIDR
	// form. A WireGuard tunnel cannot carry traffic without them.
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

// TunDevice is the adapter a Sora session brings up. It has a name of its own,
// so it never collides with an adapter another program owns, and so the core
// can see whether the engine really brought it up.
const TunDevice = "sora0"

// Tun is the virtual network interface setup of the plan.
type Tun struct {
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

// AmneziaWG holds the obfuscation parameters of an AmneziaWG tunnel, named as
// the AmneziaWG configuration file names them. Every value must match the
// server; zero values are not written, so the engine keeps its own default.
type AmneziaWG struct {
	Jc, Jmin, Jmax int
	S1, S2, S3, S4 int
	// H1..H4 are message type headers: a number, or a range in AmneziaWG 2.0.
	H1, H2, H3, H4 string
	// I1..I5 are the signature packets of AmneziaWG 1.5 and 2.0.
	I1, I2, I3, I4, I5 string
	J1, J2, J3         string
	Itime              int
}

// BypassStrategy is how zapret reshapes a handshake. Positions follow zapret:
// a number of bytes, negative from the end, or a marker (method, host,
// endhost, sld, midsld, endsld, sniext) with an optional +N or -N.
type BypassStrategy struct {
	SplitPos []string
	// Disorder sends the second part of a split first.
	Disorder bool
	// OOB sends an out-of-band byte with the split.
	OOB bool
	// TLSRecord splits the ClientHello into two TLS records at a position.
	TLSRecord string
	// HostCase, DomainCase and MethodEOL reshape plain HTTP requests.
	HostCase   bool
	DomainCase bool
	MethodEOL  bool
}

// Fragment splits the TLS ClientHello of proxy connections into several TCP
// segments. It defeats DPI boxes that match the SNI of a single segment, which
// is how most SNI blocking in Russia, Iran and China works today.
type Fragment struct {
	Enabled bool
	// Packets, Length and Interval follow Xray: "tlshello" or a range of TCP
	// segments such as "1-3", the segment length in bytes ("100-200") and
	// the pause between segments in milliseconds ("10-20"). Engines that only
	// know an on/off switch use Enabled alone.
	Packets  string
	Length   string
	Interval string
}

// Options are the engine-wide switches of a plan.
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

// LocalProxy is the loopback HTTP and SOCKS5 listener of a session. Any
// application on the machine can reach a loopback port, send traffic through
// it and learn the address of the server behind it, which is how apps find
// and report VPN servers. The listener therefore exists only when the session
// needs it (system proxy mode) or the user asked for it.
type LocalProxy struct {
	Enabled bool
	// Username and Password require a login. A system proxy cannot carry one,
	// so a login fits a listener the user hands to chosen applications.
	Username string
	Password string
}

// Plan is a complete, engine-independent description of one session.
type Plan struct {
	SessionID string
	// Engines is the engine preference of this session, best first. Empty
	// uses the core default; a single entry pins that engine.
	Engines []Kind
	// PrivateControl keeps every engine control channel off the network: the
	// session runs only on an engine controlled through a unix socket or a
	// named pipe, so a port scan finds nothing that answers.
	PrivateControl bool
	LocalProxy     LocalProxy

	Outbounds []Outbound
	Groups    []Group
	Rules     []Rule
	DNS       DNS
	Tun       Tun
	Options   Options
}
