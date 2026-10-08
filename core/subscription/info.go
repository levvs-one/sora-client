package subscription

import (
	"bytes"
	"encoding/base64"
	"mime"
	"net/http"
	"net/url"
	"strconv"
	"strings"
	"time"
	"unicode"
	"unicode/utf8"
)

// Info contains provider metadata from Remnawave/Marzban headers or leading
// "#key: value" body lines, following panel formats and Hiddify's profile
// parser.
type Info struct {
	// Title is the name the provider gave the subscription.
	Title string
	// UpdateInterval is how often the provider asks to be fetched; zero
	// when
	// it did not say.
	UpdateInterval time.Duration
	// HasUsage reports whether the provider sent traffic figures at all.
	HasUsage bool
	Upload   uint64
	Download uint64
	// Total is the traffic allowance in bytes; zero means unlimited.
	Total uint64
	// Expire is when the subscription ends; zero means it does not.
	Expire time.Time
	// WebPageURL and SupportURL are the provider's pages for the user.
	WebPageURL string
	SupportURL string
	// Announce is a short message from the provider to the user.
	Announce string
}

// Bound provider-controlled text and update intervals to prevent oversized
// displays or excessive fetches.
const (
	maxTitleRunes    = 128
	maxAnnounceRunes = 2048
	maxURLBytes      = 2048
	maxIntervalHours = 24 * 365
	// bodyHeaderLines bounds the leading lines inspected for metadata.
	bodyHeaderLines = 10
)

// infoKeys are the keys read from headers and from the body.
var infoKeys = []string{
	"profile-title", "profile-update-interval", "subscription-userinfo",
	"profile-web-page-url", "support-url", "announce", "content-disposition",
}

// parseInfo reads metadata, preferring response headers over matching body
// keys.
func parseInfo(header http.Header, body []byte) Info {
	values := bodyHeaders(body)
	for _, key := range infoKeys {
		if v := strings.TrimSpace(header.Get(key)); v != "" {
			values[key] = v
		}
	}

	var info Info
	info.Title = cleanText(decodeMarked(values["profile-title"]), maxTitleRunes, false)
	if info.Title == "" {
		info.Title = cleanText(dispositionName(values["content-disposition"]), maxTitleRunes, false)
	}
	if hours, err := strconv.Atoi(values["profile-update-interval"]); err == nil && hours > 0 && hours <= maxIntervalHours {
		info.UpdateInterval = time.Duration(hours) * time.Hour
	}
	if raw := values["subscription-userinfo"]; raw != "" {
		info.HasUsage, info.Upload, info.Download, info.Total, info.Expire = parseUsage(raw)
	}
	info.WebPageURL = cleanURL(values["profile-web-page-url"])
	info.SupportURL = cleanURL(values["support-url"])
	info.Announce = cleanText(decodeMarked(values["announce"]), maxAnnounceRunes, true)
	return info
}

// parseUsage reads upload, download, and total bytes plus expiry in Unix
// seconds. Missing or invalid fields become zero.
func parseUsage(raw string) (ok bool, upload, download, total uint64, expire time.Time) {
	fields := map[string]uint64{}
	for _, part := range strings.Split(raw, ";") {
		key, value, found := strings.Cut(part, "=")
		if !found {
			continue
		}
		n, err := strconv.ParseUint(strings.TrimSpace(value), 10, 64)
		if err != nil {
			continue
		}
		fields[strings.ToLower(strings.TrimSpace(key))] = n
	}
	_, hasUp := fields["upload"]
	_, hasDown := fields["download"]
	if !hasUp && !hasDown {
		return false, 0, 0, 0, time.Time{}
	}
	if seconds := fields["expire"]; seconds > 0 && seconds < 1<<40 {
		expire = time.Unix(int64(seconds), 0).UTC()
	}
	return true, fields["upload"], fields["download"], fields["total"], expire
}

// bodyHeaders reads "#key: value" and "//key: value" lines from the top of the
// body, which may itself be base64.
func bodyHeaders(body []byte) map[string]string {
	text := body
	if decoded, ok := decodeBody(body); ok {
		text = decoded
	}
	out := map[string]string{}
	for i, line := range strings.Split(string(text), "\n") {
		if i == bodyHeaderLines {
			break
		}
		line = strings.TrimSpace(line)
		var rest string
		switch {
		case strings.HasPrefix(line, "#"):
			rest = line[1:]
		case strings.HasPrefix(line, "//"):
			rest = line[2:]
		default:
			continue
		}
		key, value, found := strings.Cut(rest, ":")
		if !found {
			continue
		}
		out[strings.ToLower(strings.TrimSpace(key))] = strings.TrimSpace(value)
	}
	return out
}

// decodeBody decodes base64 subscription bodies.
func decodeBody(body []byte) ([]byte, bool) {
	clean := bytes.Map(func(r rune) rune {
		if unicode.IsSpace(r) {
			return -1
		}
		return r
	}, body)
	for _, enc := range []*base64.Encoding{base64.StdEncoding, base64.RawStdEncoding, base64.URLEncoding, base64.RawURLEncoding} {
		if out, err := enc.DecodeString(string(clean)); err == nil && utf8.Valid(out) {
			return out, true
		}
	}
	return nil, false
}

// decodeMarked reads "base64:<text>" metadata used by panels for non-ASCII
// names and messages.
func decodeMarked(v string) string {
	rest, marked := strings.CutPrefix(v, "base64:")
	if !marked {
		return v
	}
	for _, enc := range []*base64.Encoding{base64.StdEncoding, base64.RawStdEncoding, base64.URLEncoding, base64.RawURLEncoding} {
		if out, err := enc.DecodeString(strings.TrimSpace(rest)); err == nil && utf8.Valid(out) {
			return string(out)
		}
	}
	return ""
}

// dispositionName extracts the Content-Disposition filename without its
// extension.
func dispositionName(v string) string {
	if v == "" {
		return ""
	}
	_, params, err := mime.ParseMediaType(v)
	if err != nil {
		return ""
	}
	name := params["filename"]
	if i := strings.LastIndexByte(name, '.'); i > 0 {
		name = name[:i]
	}
	return name
}

// cleanText drops control characters, keeps line breaks only where asked and
// cuts the text to limit runes.
func cleanText(v string, limit int, multiline bool) string {
	var b strings.Builder
	n := 0
	for _, r := range strings.TrimSpace(v) {
		if n == limit {
			break
		}
		keepBreak := multiline && r == '\n'
		if unicode.IsControl(r) && !keepBreak {
			continue
		}
		b.WriteRune(r)
		n++
	}
	return strings.TrimSpace(b.String())
}

// cleanURL allows HTTP, HTTPS, and Telegram links used by provider support
// pages.
func cleanURL(v string) string {
	v = strings.TrimSpace(v)
	if v == "" || len(v) > maxURLBytes {
		return ""
	}
	u, err := url.Parse(v)
	if err != nil {
		return ""
	}
	switch strings.ToLower(u.Scheme) {
	case "https", "http":
		if u.Host == "" {
			return ""
		}
	case "tg":
	default:
		return ""
	}
	return u.String()
}
