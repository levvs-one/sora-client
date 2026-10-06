// Package mihomo drives MetaCubeX/mihomo as an engine of Sora.
//
// Sora never links mihomo as a library. mihomo is GPL-3.0 software shipped as
// its own binary and driven over its local controller API. That keeps the
// license boundary clean, keeps an engine crash from taking the core service
// down with it, and lets Sora update the engine without a rebuild.
//
// Render turns an engine.Plan into the YAML mihomo reads, and the client of
// package clashapi talks to the external controller bound to the loopback
// interface only. Facts about keys, endpoints and flags are recorded with
// sources in docs/research/mihomo-engine.md.
package mihomo

// Ports and limits used when Sora starts one engine process.
const (
	// DefaultMixedPort is used only when a render has no reserved port.
	DefaultMixedPort = 7890
	// MaxConfigBytes bounds the rendered config before it reaches the engine.
	MaxConfigBytes = 8 << 20
)

// Default geodata mirrors. mihomo downloads them into its home directory.
const (
	GeoSiteDefaultURL = "https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geosite.dat"
	GeoIPDefaultURL   = "https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/country.mmdb"
	GeoASNDefaultURL  = "https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geosite.dat"
)

// Runtime holds the values the supervisor chooses for one run. They are
// separate from the plan because one plan is applied many times.
type Runtime struct {
	// HomeDir is passed as -d. mihomo resolves relative paths against it.
	HomeDir string
	// ControllerAddr is host:port of the loopback controller, e.g. 127.0.0.1:23456.
	ControllerAddr string
	// Secret authorizes the controller API. mihomo accepts an empty secret,
	// Sora never does: a loopback port is reachable by every local user.
	Secret string
	// MixedPort is the local http+socks listener. A free port is chosen when 0.
	MixedPort int
	// TestURL is the default latency probe for groups without one.
	TestURL string
}

// config is the root of the YAML mihomo reads. Only mihomo keys appear here,
// and an unset key is left out rather than written empty: mihomo reads some
// empty values as explicit settings.
type config struct {
	MixedPort          int                      `yaml:"mixed-port"`
	AllowLAN           bool                     `yaml:"allow-lan"`
	BindAddress        string                   `yaml:"bind-address,omitempty"`
	Mode               string                   `yaml:"mode"`
	LogLevel           string                   `yaml:"log-level"`
	IPv6               *bool                    `yaml:"ipv6,omitempty"`
	ExternalController string                   `yaml:"external-controller,omitempty"`
	Secret             string                   `yaml:"secret,omitempty"`
	UnifiedDelay       *bool                    `yaml:"unified-delay,omitempty"`
	TCPConcurrent      *bool                    `yaml:"tcp-concurrent,omitempty"`
	FindProcessMode    string                   `yaml:"find-process-mode,omitempty"`
	GlobalUA           string                   `yaml:"global-ua,omitempty"`
	GeodataMode        *bool                    `yaml:"geodata-mode,omitempty"`
	GeodataLoader      string                   `yaml:"geodata-loader,omitempty"`
	GeoAutoUpdate      *bool                    `yaml:"geo-auto-update,omitempty"`
	GeoUpdateInterval  int                      `yaml:"geo-update-interval,omitempty"`
	GeoX               map[string]string        `yaml:"geox-url,omitempty"`
	Profile            *profile                 `yaml:"profile,omitempty"`
	DNS                *dnsConfig               `yaml:"dns,omitempty"`
	Tun                *tunConfig               `yaml:"tun,omitempty"`
	Proxies            []proxy                  `yaml:"proxies,omitempty"`
	ProxyGroups        []proxyGroup             `yaml:"proxy-groups,omitempty"`
	ProxyProviders     map[string]proxyProvider `yaml:"proxy-providers,omitempty"`
	Rules              []string                 `yaml:"rules,omitempty"`
}

// profile keeps user choices across restarts.
type profile struct {
	StoreSelected bool `yaml:"store-selected"`
	StoreFakeIP   bool `yaml:"store-fake-ip"`
}

// proxy is one mihomo proxy entry. mihomo documents name, type, server and
// port as required; everything else is protocol specific and omitted when
// empty.
type proxy struct {
	Name   string `yaml:"name"`
	Type   string `yaml:"type"`
	Server string `yaml:"server,omitempty"`
	Port   int    `yaml:"port,omitempty"`
	UDP    *bool  `yaml:"udp,omitempty"`
	TFO    *bool  `yaml:"tfo,omitempty"`
	MPTCP  *bool  `yaml:"mptcp,omitempty"`
	IPVer  string `yaml:"ip-version,omitempty"`
	Tag    string `yaml:"tag,omitempty"`
	Dialer string `yaml:"dialer-proxy,omitempty"`

	UUID          string `yaml:"uuid,omitempty"`
	Flow          string `yaml:"flow,omitempty"`
	AlterID       int    `yaml:"alterId,omitempty"`
	Cipher        string `yaml:"cipher,omitempty"`
	Password      string `yaml:"password,omitempty"`
	Username      string `yaml:"username,omitempty"`
	Obfs          string `yaml:"obfs,omitempty"`
	ObfsParam     string `yaml:"obfs-param,omitempty"`
	ObfsPassword  string `yaml:"obfs-password,omitempty"`
	Protocol      string `yaml:"protocol,omitempty"`
	ProtocolParam string `yaml:"protocol-param,omitempty"`
	TLS           *bool  `yaml:"tls,omitempty"`

	Network     string            `yaml:"network,omitempty"`
	WSPath      string            `yaml:"ws-path,omitempty"`
	WSHeaders   map[string]string `yaml:"ws-headers,omitempty"`
	GRPCService string            `yaml:"grpc-service-name,omitempty"`
	H2Path      string            `yaml:"h2-path,omitempty"`
	H2Host      string            `yaml:"h2-host,omitempty"`
	HTTPath     string            `yaml:"http-path,omitempty"`
	Headers     map[string]string `yaml:"headers,omitempty"`

	SNI            string   `yaml:"sni,omitempty"`
	SkipCertVerify *bool    `yaml:"skip-cert-verify,omitempty"`
	Fingerprint    string   `yaml:"client-fingerprint,omitempty"`
	ALPN           []string `yaml:"alpn,omitempty"`
	Reality        *reality `yaml:"reality-opts,omitempty"`

	PrivateKey string          `yaml:"private-key,omitempty"`
	IPs        []string        `yaml:"ips,omitempty"`
	MTU        int             `yaml:"mtu,omitempty"`
	Peers      []wireguardPeer `yaml:"peers,omitempty"`
	Smux       *smux           `yaml:"smux,omitempty"`
}

// wireguardPeer is one WireGuard peer.
type wireguardPeer struct {
	PublicKey           string   `yaml:"public-key"`
	PresharedKey        string   `yaml:"preshared-key,omitempty"`
	Endpoint            string   `yaml:"endpoint,omitempty"`
	AllowedIPs          []string `yaml:"allowed-ips,omitempty"`
	PersistentKeepalive int      `yaml:"persistent-keepalive,omitempty"`
}

// smux enables multiplexing for one outbound.
type smux struct {
	Enabled        bool   `yaml:"enabled"`
	Protocol       string `yaml:"protocol,omitempty"`
	MaxConnections int    `yaml:"max-connections,omitempty"`
	MinStreams     int    `yaml:"min-streams,omitempty"`
	Padding        bool   `yaml:"padding,omitempty"`
	OnlyTCP        *bool  `yaml:"only-tcp,omitempty"`
}

// reality carries the VLESS Reality parameters of one outbound.
type reality struct {
	PublicKey string `yaml:"public-key,omitempty"`
	ShortID   string `yaml:"short-id,omitempty"`
}

// proxyGroup is one selectable group. Interval is in seconds and Timeout is
// in milliseconds, exactly as mihomo documents them.
type proxyGroup struct {
	Name            string   `yaml:"name"`
	Type            string   `yaml:"type"`
	Proxies         []string `yaml:"proxies,omitempty"`
	Use             []string `yaml:"use,omitempty"`
	URL             string   `yaml:"url,omitempty"`
	Interval        int      `yaml:"interval,omitempty"`
	Timeout         int      `yaml:"timeout,omitempty"`
	MaxFailed       int      `yaml:"max-failed-times,omitempty"`
	Tolerance       int      `yaml:"tolerance,omitempty"`
	Lazy            *bool    `yaml:"lazy,omitempty"`
	Hidden          *bool    `yaml:"hidden,omitempty"`
	Icon            string   `yaml:"icon,omitempty"`
	ExpectedStatus  []int    `yaml:"expected-status,omitempty"`
	DefaultSelected string   `yaml:"default-selected,omitempty"`
	Filter          string   `yaml:"filter,omitempty"`
	ExcludeFilter   string   `yaml:"exclude-filter,omitempty"`
	DisableUDP      *bool    `yaml:"disable-udp,omitempty"`
}

// proxyProvider is one subscription source handled by the engine itself.
type proxyProvider struct {
	Type          string          `yaml:"type"`
	URL           string          `yaml:"url,omitempty"`
	Path          string          `yaml:"path,omitempty"`
	Interval      int             `yaml:"interval,omitempty"`
	Proxy         string          `yaml:"proxy,omitempty"`
	SizeLimit     string          `yaml:"size-limit,omitempty"`
	Health        *providerHealth `yaml:"health-check,omitempty"`
	Filter        string          `yaml:"filter,omitempty"`
	ExcludeFilter string          `yaml:"exclude-filter,omitempty"`
	ExcludeType   string          `yaml:"exclude-type,omitempty"`
}

// providerHealth is the health-check block of a proxy provider.
type providerHealth struct {
	Enable   bool   `yaml:"enable"`
	URL      string `yaml:"url,omitempty"`
	Interval int    `yaml:"interval,omitempty"`
	Timeout  int    `yaml:"timeout,omitempty"`
	Lazy     *bool  `yaml:"lazy,omitempty"`
}

// dnsConfig is the mihomo resolver block.
type dnsConfig struct {
	Enable                bool                `yaml:"enable"`
	Listen                string              `yaml:"listen,omitempty"`
	IPv6                  *bool               `yaml:"ipv6,omitempty"`
	EnhancedMode          string              `yaml:"enhanced-mode,omitempty"`
	FakeIPRange           string              `yaml:"fake-ip-range,omitempty"`
	FakeIPFilter          []string            `yaml:"fake-ip-filter,omitempty"`
	CacheAlgorithm        string              `yaml:"cache-algorithm,omitempty"`
	RespectRules          *bool               `yaml:"respect-rules,omitempty"`
	DefaultNameserver     []string            `yaml:"default-nameserver,omitempty"`
	Nameserver            []string            `yaml:"nameserver,omitempty"`
	Fallback              []string            `yaml:"fallback,omitempty"`
	NameserverPolicy      map[string][]string `yaml:"nameserver-policy,omitempty"`
	ProxyServerNameserver []string            `yaml:"proxy-server-nameserver,omitempty"`
	DirectNameserver      []string            `yaml:"direct-nameserver,omitempty"`
}

// tunConfig is the mihomo tun block. Stack defaults to gvisor upstream; Sora
// asks for mixed unless the caller needs the system stack.
type tunConfig struct {
	Enable              bool     `yaml:"enable"`
	Stack               string   `yaml:"stack,omitempty"`
	Device              string   `yaml:"device,omitempty"`
	MTU                 int      `yaml:"mtu,omitempty"`
	AutoRoute           *bool    `yaml:"auto-route,omitempty"`
	AutoDetectInterface *bool    `yaml:"auto-detect-interface,omitempty"`
	DNSHijack           []string `yaml:"dns-hijack,omitempty"`
	StrictRoute         *bool    `yaml:"strict-route,omitempty"`
	RouteAddress        []string `yaml:"route-address,omitempty"`
	RouteExcludeAddress []string `yaml:"route-exclude-address,omitempty"`
	IncludePackage      []string `yaml:"include-package,omitempty"`
	ExcludePackage      []string `yaml:"exclude-package,omitempty"`
	Inet6Address        string   `yaml:"inet6-address,omitempty"`
}
