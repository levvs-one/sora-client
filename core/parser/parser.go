package parser

import (
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"net"
	"net/url"
	"regexp"
	"strconv"
	"strings"
	"unicode/utf8"

	"gopkg.in/yaml.v3"
)

const MaxInputSize = 16 << 20
const DefaultMaxItems = 20000

var (
	ErrEmptySource = errors.New("parser: empty source")
	ErrInputTooLarge = errors.New("parser: input exceeds 16 MiB")
	ErrUnsupported = errors.New("parser: unsupported format")
	ErrInvalid = errors.New("parser: invalid entry")
)

type Format string
const (
	FormatUnknown Format = "unknown"
	FormatSubscription Format = "https-subscription"
	FormatHTTPSubscription Format = "http-subscription"
	FormatLink Format = "share-link"
	FormatBase64 Format = "base64-list"
	FormatSIP008 Format = "sip008"
	FormatClash Format = "clash-yaml"
	FormatSingBox Format = "sing-box-json"
	FormatXray Format = "xray-json"
	FormatWireGuard Format = "wireguard-conf"
	FormatPlainList Format = "plain-list"
)

type Detection struct { Format Format; Reason string }
type ImportDetector struct { MaxItems int }
func (d ImportDetector) Detect(src []byte) (Detection, error) {
	if len(src) == 0 || strings.TrimSpace(string(src)) == "" { return Detection{}, ErrEmptySource }
	if len(src) > MaxInputSize { return Detection{}, ErrInputTooLarge }
	s := strings.TrimSpace(string(src))
	if strings.HasPrefix(strings.ToLower(s), "https://") { return Detection{Format: FormatSubscription}, nil }
	if strings.HasPrefix(strings.ToLower(s), "http://") { return Detection{Format: FormatHTTPSubscription, Reason: "subscriptions require HTTPS"}, nil }
	if hasShareScheme(s) { return Detection{Format: FormatLink}, nil }
	if strings.HasPrefix(s, "{") || strings.HasPrefix(s, "[") {
		var v any
		if json.Unmarshal([]byte(s), &v) == nil { return classifyJSON(v), nil }
	}
	if strings.Contains(s, "proxies:") { return Detection{Format: FormatClash}, nil }
	if looksWireGuard(s) { return Detection{Format: FormatWireGuard}, nil }
	if b, ok := decodeBase64(s); ok && (hasShareScheme(string(b)) || looksLinkList(string(b))) { return Detection{Format: FormatBase64}, nil }
	if looksLinkList(s) { return Detection{Format: FormatPlainList}, nil }
	return Detection{Format: FormatUnknown, Reason: "no supported parser matched"}, ErrUnsupported
}

func hasShareScheme(s string) bool { for _, line := range strings.Fields(s) { p := strings.ToLower(strings.TrimSpace(line)); for _, x := range []string{"vless://","vmess://","trojan://","ss://","socks://","socks5://","http://","https://","hysteria2://","hy2://","tuic://","wireguard://","wg://"} { if strings.HasPrefix(p,x) { return true } } }; return false }
func looksLinkList(s string) bool { n:=0; for _, l:=range strings.Split(s,"\n") { if hasShareScheme(strings.TrimSpace(l)) { n++ } }; return n>0 }
func looksWireGuard(s string) bool { return strings.Contains(s,"[Interface]") && strings.Contains(s,"[Peer]") }
func classifyJSON(v any) Detection { m,ok:=v.(map[string]any); if !ok { if a,ok:=v.([]any); ok && len(a)>0 { if _,yes:=a[0].(map[string]any); yes { return Detection{Format:FormatXray} } }; return Detection{Format:FormatUnknown} }; if _,ok:=m["outbounds"]; ok { return Detection{Format:FormatSingBox} }; if _,ok:=m["servers"]; ok { return Detection{Format:FormatSIP008} }; if _,ok:=m["inbounds"]; ok { return Detection{Format:FormatXray} }; return Detection{Format:FormatUnknown} }

func decodeBase64(s string) ([]byte,bool) { clean:=strings.Map(func(r rune) rune { if r=='\r'||r=='\n'||r==' '||r=='\t' { return -1 }; return r },s); for _, enc:=range []*base64.Encoding{base64.StdEncoding,base64.RawStdEncoding,base64.URLEncoding,base64.RawURLEncoding} { n:=len(clean)%4; x:=clean; if n!=0 { x += strings.Repeat("=",4-n) }; if b,e:=enc.DecodeString(x); e==nil && utf8.Valid(b) { return b,true } }; return nil,false }

type OutboundSpec struct {
	ID, DisplayName, Protocol, Transport, Security string
	Host string; Port uint16; UUID, Password, User, Cipher string
	PublicKey, ShortID, ServerName, Fingerprint, Flow, Path, HostHeader, ServiceName, Mode string
	ALPN []string; CountryCode string
	Options map[string]string
}
func (o OutboundSpec) StableKey() string { h:=sha256.Sum256([]byte(o.Protocol+"\x00"+o.Host+"\x00"+strconv.Itoa(int(o.Port))+"\x00"+o.UUID+"\x00"+o.Password+"\x00"+o.User)); return o.Protocol+":"+o.Host+":"+strconv.Itoa(int(o.Port))+":"+hex.EncodeToString(h[:8]) }

func (o *OutboundSpec) validate() error { if o.Protocol==""||o.Host==""||o.Port<1 { return ErrInvalid }; if o.Port>65535 { return ErrInvalid }; if o.Protocol=="vless"||o.Protocol=="vmess" { if o.UUID!="" && !uuidRE.MatchString(o.UUID) { return fmt.Errorf("%w: invalid UUID",ErrInvalid) } }; return nil }
var uuidRE=regexp.MustCompile(`^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$`)

type ItemReason struct { Index int; Reason string }
type ImportReport struct { Imported, SkippedDuplicates, Unsupported, Invalid int; UnsupportedItems, InvalidItems, DuplicateItems []ItemReason }
type ImportResult struct { Format Format; Servers []OutboundSpec; Report ImportReport }
type LinkParser struct { MaxItems int }
func (p LinkParser) Parse(src []byte) (ImportResult,error) { if len(src)>MaxInputSize{return ImportResult{},ErrInputTooLarge}; d,e:=ImportDetector{MaxItems:p.limit()}.Detect(src); if e!=nil && d.Format!=FormatUnknown && d.Format!=FormatHTTPSubscription{return ImportResult{Format:d.Format},e}; if d.Format==FormatHTTPSubscription{return ImportResult{Format:d.Format},ErrUnsupported}; s:=strings.TrimSpace(string(src)); switch d.Format { case FormatBase64: b,_:=decodeBase64(s); s=string(b); d.Format=FormatPlainList; case FormatSIP008,FormatSingBox,FormatXray: return p.parseJSON([]byte(s),d.Format); case FormatClash: return p.parseYAML([]byte(s)); case FormatWireGuard: return p.parseWG(s) }; return p.parseList(s,d.Format) }
func (p LinkParser) limit() int { if p.MaxItems<=0{return DefaultMaxItems}; return p.MaxItems }
func (p LinkParser) parseList(s string, f Format) (ImportResult,error) { r:=ImportResult{Format:f}; seen:=make(map[string]struct{}); for i,line:=range strings.Split(s,"\n") { if len(r.Servers)>=p.limit(){r.Report.Unsupported++;r.Report.UnsupportedItems=append(r.Report.UnsupportedItems,ItemReason{i,"item limit exceeded"});continue}; line=strings.TrimSpace(line); if line==""{continue}; o,e:=parseLink(line); if e!=nil { if errors.Is(e,ErrUnsupported){r.Report.Unsupported++;r.Report.UnsupportedItems=append(r.Report.UnsupportedItems,ItemReason{i,safeReason(e)})}else{r.Report.Invalid++;r.Report.InvalidItems=append(r.Report.InvalidItems,ItemReason{i,safeReason(e)})};continue }; k:=o.StableKey(); if _,ok:=seen[k];ok{r.Report.SkippedDuplicates++;r.Report.DuplicateItems=append(r.Report.DuplicateItems,ItemReason{i,"duplicate server"});continue}; seen[k]=struct{}{}; r.Servers=append(r.Servers,o);r.Report.Imported++ }; if len(r.Servers)==0&&r.Report.Unsupported==0&&r.Report.Invalid==0{return r,ErrUnsupported}; return r,nil }
func safeReason(e error) string { if errors.Is(e,ErrUnsupported){return "unsupported protocol or option"}; if errors.Is(e,ErrInvalid){return "invalid link fields"}; return "invalid entry" }

func parseLink(raw string)(OutboundSpec,error) { u,e:=url.Parse(strings.TrimSpace(raw)); if e!=nil{return OutboundSpec{},ErrInvalid}; proto:=strings.ToLower(u.Scheme); if proto==""{return OutboundSpec{},ErrInvalid}; if proto=="vmess" { return parseVMess(u) }; if proto=="wireguard"||proto=="wg" { return parseWireURL(u) }; supported:=map[string]bool{"vless":true,"trojan":true,"ss":true,"socks":true,"socks5":true,"http":true,"https":true,"hysteria2":true,"hy2":true,"tuic":true}; if !supported[proto]{return OutboundSpec{},ErrUnsupported}; host:=u.Hostname(); port,e:=parsePort(u.Port()); if e!=nil{return OutboundSpec{},ErrInvalid}; o:=OutboundSpec{Protocol:proto,Host:host,Port:port,Options:map[string]string{}}; if u.User!=nil{o.User=u.User.Username(); o.Password,_=u.User.Password()}; if proto=="ss" { if u.User!=nil && o.Password=="" { if b,ok:=decodeBase64(o.User);ok { parts:=strings.SplitN(string(b),":",2);if len(parts)==2{o.Cipher,o.Password=parts[0],parts[1]} } }; if o.Cipher=="" {o.Cipher=o.User;o.User=""}; o.Transport="tcp" } else { o.Transport=getq(u,"type","transport"); if o.Transport==""{o.Transport="tcp"}; o.Security=getq(u,"security","tls"); o.UUID=o.User; if proto=="vless" && o.Security=="" {o.Security="none"} }; if o.Transport=="ws"||o.Transport=="httpupgrade"||o.Transport=="xhttp"||o.Transport=="splithttp" {o.Path=getq(u,"path","path");o.HostHeader=getq(u,"host","host")}; o.ServerName=getq(u,"sni","sni");o.PublicKey=getq(u,"pbk","publicKey");o.ShortID=getq(u,"sid","shortId");o.Fingerprint=getq(u,"fp","fingerprint");o.Flow=getq(u,"flow","flow");o.ServiceName=getq(u,"serviceName","serviceName");o.Mode=getq(u,"mode","mode"); if a:=getq(u,"alpn","alpn");a!=""{o.ALPN=strings.Split(a,",")}; o.DisplayName=fragmentName(u.Fragment); o.CountryCode=countryCode(o.DisplayName); if err:=o.validate();err!=nil{return OutboundSpec{},err}; return o,nil }
func parsePort(s string)(uint16,error){if s==""{return 0,ErrInvalid}; n,e:=strconv.Atoi(s);if e!=nil||n<1||n>65535{return 0,ErrInvalid};return uint16(n),nil}
func getq(u *url.URL, keys ...string)string{for _,k:=range keys{if v:=u.Query().Get(k);v!=""{return v}};return ""}
func fragmentName(s string)string{v,e:=url.QueryUnescape(s);if e==nil{return v};return s}
func countryCode(s string)string{r:=[]rune(s);if len(r)<2{return ""};a,b:=r[0],r[1];if a>=0x1F1E6&&a<=0x1F1FF&&b>=0x1F1E6&&b<=0x1F1FF{return string([]rune{a,b})};return ""}

func parseVMess(u *url.URL)(OutboundSpec,error){ raw:=strings.TrimPrefix(u.Opaque,"//");if raw==""{raw=strings.TrimPrefix(u.Path,"/")}; if b,ok:=decodeBase64(raw);ok{var v map[string]any;if json.Unmarshal(b,&v)==nil{o:=OutboundSpec{Protocol:"vmess",Transport:"tcp",Security:"auto",Options:map[string]string{}};o.Host,_=v["add"].(string);o.UUID,_=v["id"].(string);o.DisplayName,_=v["ps"].(string);if n,ok:=v["port"].(float64);ok{o.Port=uint16(n)};o.Transport,_=v["net"].(string);o.Security,_=v["tls"].(string);if o.Transport==""{o.Transport="tcp"};if e:=o.validate();e!=nil{return OutboundSpec{},e};return o,nil}}}; return OutboundSpec{},ErrInvalid }
func parseWireURL(u *url.URL)(OutboundSpec,error){p,e:=parsePort(u.Port());if e!=nil{return OutboundSpec{},e};o:=OutboundSpec{Protocol:"wireguard",Host:u.Hostname(),Port:p,User:u.User.Username(),Password:u.User.String(),Options:map[string]string{}};o.DisplayName=fragmentName(u.Fragment);return o,nil}

func (p LinkParser) parseJSON(b []byte, f Format)(ImportResult,error){var v any;if json.Unmarshal(b,&v)!=nil{return ImportResult{Format:f},ErrInvalid};r:=ImportResult{Format:f};var items []any;switch x:=v.(type){case []any:items=x;case map[string]any:if a,ok:=x["servers"].([]any);ok{items=a}else if a,ok:=x["outbounds"].([]any);ok{items=a}else if a,ok:=x["outbound"].([]any);ok{items=a}else{items=[]any{x}}};for i,item:=range items{m,ok:=item.(map[string]any);if !ok{continue};o:=OutboundSpec{Options:map[string]string{}};if f==FormatSIP008{o.Protocol,_=m["type"].(string);o.Host,_=m["server"].(string);o.Port=uint16(number(m["server_port"]));o.Password,_=m["password"].(string);o.Cipher,_=m["method"].(string)}else{o.Protocol,_=m["type"].(string);o.Host,_=m["server"].(string);o.Port=uint16(number(m["server_port"]));o.UUID,_=m["uuid"].(string);o.Password,_=m["password"].(string);o.Security,_=m["tls"].(string);o.Transport,_=m["transport"].(string)};if o.Protocol==""{r.Report.Unsupported++;continue};if e:=o.validate();e!=nil{r.Report.Invalid++;continue};r.Servers=append(r.Servers,o);r.Report.Imported++};return r,nil}
func number(v any)int{switch n:=v.(type){case float64:return int(n);case int:return n;case string:i,_:=strconv.Atoi(n);return i};return 0}
func (p LinkParser) parseYAML(b []byte)(ImportResult,error){var v struct{Proxies []map[string]any `yaml:"proxies"`};if yaml.Unmarshal(b,&v)!=nil{return ImportResult{Format:FormatClash},ErrInvalid};r:=ImportResult{Format:FormatClash};for _,m:=range v.Proxies{o:=OutboundSpec{Options:map[string]string{}};o.Protocol,_=m["type"].(string);o.Host,_=m["server"].(string);o.Port=uint16(number(m["port"]));o.Password,_=m["password"].(string);o.UUID,_=m["uuid"].(string);o.DisplayName,_=m["name"].(string);if e:=o.validate();e!=nil{r.Report.Invalid++;continue};r.Servers=append(r.Servers,o);r.Report.Imported++};return r,nil}
func (p LinkParser) parseWG(s string)(ImportResult,error){o:=OutboundSpec{Protocol:"wireguard",Transport:"udp",Options:map[string]string{}};section:="";for _,line:=range strings.Split(s,"\n"){line=strings.TrimSpace(line);if strings.HasPrefix(line,"["){section=strings.ToLower(line);continue};kv:=strings.SplitN(line,"=",2);if len(kv)!=2{continue};k:=strings.ToLower(strings.TrimSpace(kv[0]));v:=strings.TrimSpace(kv[1]);if section=="[interface]"{o.Options[k]=v};if section=="[peer]"&&k=="endpoint"{h,p,e:=net.SplitHostPort(v);if e==nil{o.Host=h;o.Port,_=parsePort(p)}}};if e:=o.validate();e!=nil{return ImportResult{Format:FormatWireGuard},e};return ImportResult{Format:FormatWireGuard,Servers:[]OutboundSpec{o},Report:ImportReport{Imported:1}},nil}
