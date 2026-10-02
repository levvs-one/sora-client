// Package singbox runs sing-box as a supervised child process and implements
// engine.Engine on top of its HTTP REST API (compatible with Clash API).
package singbox

// JSONConfig is the sing-box configuration rendered from an engine.Plan.
type JSONConfig struct {
	Log          LogConfig          `json:"log"`
	DNS          DNSConfig          `json:"dns"`
	Inbounds     []Inbound          `json:"inbounds"`
	Outbounds    []Outbound         `json:"outbounds"`
	Route        RouteConfig        `json:"route"`
	Experimental ExperimentalConfig `json:"experimental,omitempty"`
}

// LogConfig configures logging.
type LogConfig struct {
	Level     string `json:"level"`
	Output    string `json:"output"`
	Timestamp bool   `json:"timestamp"`
}

// DNSConfig configures DNS.
type DNSConfig struct {
	Servers  []DNSServer `json:"servers"`
	Rules    []DNSRule   `json:"rules,omitempty"`
	Final    string      `json:"final,omitempty"`
	Strategy string      `json:"strategy"`
}

// DNSServer is a DNS server entry.
type DNSServer struct {
	Address  string `json:"address"`
	Strategy string `json:"strategy,omitempty"`
	Detour   string `json:"detour,omitempty"`
}

// DNSRule routes DNS queries.
type DNSRule struct {
	DomainSuffix []string `json:"domain_suffix,omitempty"`
	Domain       []string `json:"domain,omitempty"`
	Server       string   `json:"server"`
	Action       string   `json:"action,omitempty"`
}

// Inbound is an inbound connection.
type Inbound struct {
	Type       string `json:"type"`
	Tag        string `json:"tag"`
	Listen     string `json:"listen,omitempty"`
	ListenPort int    `json:"listen_port,omitempty"`
	Sniff      bool   `json:"sniff,omitempty"`
}

// Outbound is an outbound connection.
type Outbound struct {
	Type       string           `json:"type"`
	Tag        string           `json:"tag"`
	Server     string           `json:"server,omitempty"`
	ServerPort int              `json:"server_port,omitempty"`
	UUID       string           `json:"uuid,omitempty"`
	Password   string           `json:"password,omitempty"`
	Method     string           `json:"method,omitempty"`
	Flow       string           `json:"flow,omitempty"`
	TLS        *TLSConfig       `json:"tls,omitempty"`
	Transport  *TransportConfig `json:"transport,omitempty"`
	Multiplex  *MultiplexConfig `json:"multiplex,omitempty"`
	Outbounds  []string         `json:"outbounds,omitempty"`
	Dialer     string           `json:"dialer,omitempty"`
	Detour     string           `json:"detour,omitempty"`
}

// TLSConfig configures TLS.
type TLSConfig struct {
	Enabled         bool           `json:"enabled"`
	ServerName      string         `json:"server_name,omitempty"`
	Insecure        bool           `json:"insecure,omitempty"`
	CertificatePath string         `json:"certificate_path,omitempty"`
	KeyPath         string         `json:"key_path,omitempty"`
	ALPN            []string       `json:"alpn,omitempty"`
	Fingerprint     string         `json:"fingerprint,omitempty"`
	UTLS            *UTLSConfig    `json:"utls,omitempty"`
	Reality         *RealityConfig `json:"reality,omitempty"`
}

// UTLSConfig configures uTLS.
type UTLSConfig struct {
	Enabled     bool   `json:"enabled"`
	Fingerprint string `json:"fingerprint"`
}

// RealityConfig configures REALITY.
type RealityConfig struct {
	Enabled   bool   `json:"enabled"`
	PublicKey string `json:"public_key"`
	ShortID   string `json:"short_id,omitempty"`
}

// TransportConfig configures transport.
type TransportConfig struct {
	Type        string              `json:"type"`
	Path        string              `json:"path,omitempty"`
	Headers     map[string][]string `json:"headers,omitempty"`
	ServiceName string              `json:"service_name,omitempty"`
	Mode        string              `json:"mode,omitempty"`
}

// MultiplexConfig configures multiplexing.
type MultiplexConfig struct {
	Enabled        bool   `json:"enabled"`
	Protocol       string `json:"protocol"`
	MaxStreams     int    `json:"max_streams,omitempty"`
	MaxConnections int    `json:"max_connections,omitempty"`
	MinStreams     int    `json:"min_streams,omitempty"`
	Padding        bool   `json:"padding,omitempty"`
}

// RouteConfig configures routing.
type RouteConfig struct {
	Rules               []RouteRule `json:"rules"`
	Final               string      `json:"final"`
	AutoDetectInterface bool        `json:"auto_detect_interface,omitempty"`
}

// RouteRule is a routing rule.
type RouteRule struct {
	Type         string      `json:"type"`
	Mode         string      `json:"mode,omitempty"`
	Rules        []RouteRule `json:"rules,omitempty"`
	DomainSuffix []string    `json:"domain_suffix,omitempty"`
	Domain       []string    `json:"domain,omitempty"`
	IPCIDR       []string    `json:"ip_cidr,omitempty"`
	GeoIP        []string    `json:"geoip,omitempty"`
	GeoSite      []string    `json:"geosite,omitempty"`
	Process      []string    `json:"process,omitempty"`
	ProcessName  []string    `json:"process_name,omitempty"`
	PackageName  []string    `json:"package_name,omitempty"`
	Port         []int       `json:"port,omitempty"`
	PortRange    string      `json:"port_range,omitempty"`
	Network      string      `json:"network,omitempty"`
	Protocol     string      `json:"protocol,omitempty"`
	Inbound      []string    `json:"inbound,omitempty"`
	Outbound     string      `json:"outbound,omitempty"`
	User         []string    `json:"user,omitempty"`
	UID          []int       `json:"uid,omitempty"`
	GID          []int       `json:"gid,omitempty"`
	Mark         []int       `json:"mark,omitempty"`
	Realm        []string    `json:"realm,omitempty"`
	ClashMode    string      `json:"clash_mode,omitempty"`
	Invert       bool        `json:"invert,omitempty"`
}

// ExperimentalConfig for experimental features.
type ExperimentalConfig struct {
	ClashAPI *ClashAPIConfig `json:"clash_api,omitempty"`
}

// ClashAPIConfig configures the REST API (Clash-compatible).
type ClashAPIConfig struct {
	Enabled bool   `json:"enabled"`
	Listen  string `json:"listen"`
	Secret  string `json:"secret,omitempty"`
}
