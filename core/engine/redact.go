package engine

import (
	"regexp"
	"sort"
	"strings"
	"sync"
)

// Redactor masks secret material before text leaves the core process: engine
// stderr, controller errors and event messages all pass through it.
//
// Two mechanisms work together. Exact values come from the active plan, so any
// credential Sora knows about is masked wherever it appears. Patterns cover
// what Sora does not know in advance, such as a token the engine prints itself.
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

// Add records more values to mask. Short values are ignored: masking a three
// character string would turn ordinary log text into noise.
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
		// Longest first: strings.Replacer picks the earliest alternative, and a
		// shorter secret must not hide a longer one that contains it.
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

// maskPatterns hides the shapes Sora recognizes even when the exact value is
// unknown: identifiers, key-value pairs and credentials inside a URL.
func maskPatterns(s string) string {
	s = userInfoPattern.ReplaceAllString(s, "${1}://[masked]@")
	s = keyValuePattern.ReplaceAllString(s, "${1}${2}[masked]")
	s = uuidPattern.ReplaceAllString(s, "[masked]")
	return s
}
