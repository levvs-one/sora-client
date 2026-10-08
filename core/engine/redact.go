package engine

import (
	"regexp"
	"sort"
	"strings"
	"sync"
)

// Redactor masks credentials in engine output, controller errors, and events
// before they leave the core. It matches plan values exactly and uses patterns
// for unknown values such as engine-generated tokens.
type Redactor struct {
	mu     sync.Mutex
	values []string
	build  *strings.Replacer
}

// NewRedactor returns a redactor seeded with the plan secrets.
func NewRedactor(values ...string) *Redactor {
	r := &Redactor{}
	r.Add(values...)
	return r
}

// Add registers values to mask. Values shorter than four characters are ignored
// to preserve ordinary log text.
func (r *Redactor) Add(values ...string) {
	added := false
	r.mu.Lock()
	for _, v := range values {
		if len(v) < 4 {
			continue
		}
		duplicate := false
		for _, have := range r.values {
			if have == v {
				duplicate = true
				break
			}
		}
		if !duplicate {
			r.values = append(r.values, v)
			added = true
		}
	}
	if added {
		// Match longest secrets first so strings.Replacer cannot
		// partially mask a longer value.
		sort.SliceStable(r.values, func(i, j int) bool { return len(r.values[i]) > len(r.values[j]) })
		r.build = nil
	}
	r.mu.Unlock()
}

// String masks one piece of text.
func (r *Redactor) String(s string) string {
	if s == "" {
		return s
	}
	r.mu.Lock()
	if r.build == nil {
		pairs := make([]string, 0, len(r.values)*2)
		for _, v := range r.values {
			pairs = append(pairs, v, "[masked]")
		}
		r.build = strings.NewReplacer(pairs...)
	}
	out := r.build.Replace(s)
	r.mu.Unlock()
	return maskPatterns(out)
}

// Err masks an error, keeping the wrap chain so errors.Is still works.
func (r *Redactor) Err(err error) error {
	if err == nil {
		return nil
	}
	return &maskedError{Redactor: r, cause: err}
}

type maskedError struct {
	Redactor *Redactor
	cause    error
}

func (e *maskedError) Error() string { return e.Redactor.String(e.cause.Error()) }
func (e *maskedError) Unwrap() error { return e.cause }

var (
	uuidPattern     = regexp.MustCompile(`(?i)[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}`)
	keyValuePattern = regexp.MustCompile(`(?i)\b(uuid|password|passwd|secret|token|private-key|preshared-key|pre-shared-key|obfs-password|psk)\b([=: ]+)(\S+)`)
	userInfoPattern = regexp.MustCompile(`(?i)\b(https?|socks5|vless|vmess|trojan|ss)://[^/\s:@]+:[^@\s]+@`)
)

// maskPatterns masks identifiers, credential pairs, and URL credentials whose
// exact values are unknown.
func maskPatterns(s string) string {
	s = userInfoPattern.ReplaceAllString(s, "${1}://[masked]@")
	s = keyValuePattern.ReplaceAllString(s, "${1}${2}[masked]")
	s = uuidPattern.ReplaceAllString(s, "[masked]")
	return s
}
