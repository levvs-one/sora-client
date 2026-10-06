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

// Plan is a complete, engine-independent description of one session.
type Plan struct {
	SessionID string
	// Engine pins the engine of this session. Empty lets the core pick the
	// first engine in preference order that carries the plan.
	Engine    Kind
	Outbounds []Outbound
	Groups    []Group
	Rules     []Rule
	DNS       DNS
	Tun       Tun
	Options   Options
}
