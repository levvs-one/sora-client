package diagnostics

import (
	"fmt"
	"net"
	"runtime"
	"sort"
	"strconv"
	"strings"
	"time"

	"github.com/levvs-one/sora-client/core/session"
)

// coreVersion identifies the single-binary core build in reports.
const coreVersion = "0.1.0-dev"

var (
	goOS   = runtime.GOOS
	goArch = runtime.GOARCH
)

// report renders session, engine, and environment details in a fixed order for
// line-by-line comparison.
func (c *Collector) report() []string {
	status := c.source.Status()
	lines := []string{
		"Sora diagnostics",
		"core: " + coreVersion + " (" + goOS + "/" + goArch + ")",
		"collected: " + c.now().UTC().Format(time.RFC3339),
		"",
		"[session]",
		"state: " + status.State.String(),
		"id: " + orNone(status.SessionID),
		"changed: " + timeOrNone(status.ChangedAt),
		"cause: " + causeOrNone(status),
		"retry_after: " + durationOrNone(status.RetryAfter),
		"kill_switch: " + strconv.FormatBool(status.KillSwitch),
		"tunnel_mode: " + orNone(status.TunnelMode),
		"",
		"[engine]",
	}
	engine := c.source.EngineLines()
	if len(engine) == 0 {
		lines = append(lines, "no engine is running")
	}
	lines = append(lines, engine...)
	return append(lines, c.environment()...)
}

// eventLines renders recent journal events and masks them again at the
// collector boundary.
func (c *Collector) eventLines() []string {
	events := c.source.RecentEvents(c.events)
	out := make([]string, 0, len(events))
	for _, event := range events {
		out = append(out, c.mask(renderEvent(event)))
	}
	return out
}

// renderEvent puts one event on one line.
func renderEvent(event session.Event) string {
	var b strings.Builder
	b.WriteString(strconv.FormatUint(event.Sequence, 10))
	b.WriteString(" ")
	b.WriteString(string(event.Kind))
	if event.State != 0 {
		b.WriteString(" state=")
		b.WriteString(event.State.String())
	}
	if event.Key != "" {
		b.WriteString(" key=")
		b.WriteString(string(event.Key))
	}
	if event.Detail != "" {
		b.WriteString(" detail=")
		b.WriteString(event.Detail)
	}
	if event.LogLine != "" {
		b.WriteString(" line=")
		b.WriteString(event.LogLine)
	}
	return b.String()
}

// environment describes the machine and process. Interface addresses are
// counted instead of listed to avoid exposing local networks.
func (c *Collector) environment() []string {
	var memory runtime.MemStats
	runtime.ReadMemStats(&memory)
	lines := []string{
		"go: " + runtime.Version(),
		"os: " + goOS + "/" + goArch,
		"cpus: " + strconv.Itoa(runtime.NumCPU()),
		"goroutines: " + strconv.Itoa(runtime.NumGoroutine()),
		"heap_alloc: " + strconv.FormatUint(memory.HeapAlloc, 10),
		"sys: " + strconv.FormatUint(memory.Sys, 10),
		"gc_cycles: " + strconv.Itoa(int(memory.NumGC)),
		"",
		"[interfaces]",
	}
	lines = append(lines, interfaceLines()...)
	return lines
}

// interfaceLines describes every interface by name, flags and how many
// addresses
// of each family it has.
func interfaceLines() []string {
	interfaces, err := net.Interfaces()
	if err != nil {
		return []string{"the interfaces of this machine cannot be read: " + err.Error()}
	}
	sort.Slice(interfaces, func(i, j int) bool { return interfaces[i].Name < interfaces[j].Name })
	out := make([]string, 0, len(interfaces))
	for _, item := range interfaces {
		addresses, err := item.Addrs()
		if err != nil {
			out = append(out, fmt.Sprintf("%s %s mtu=%d addresses=unknown",
				item.Name, flagsOf(item.Flags), item.MTU))
			continue
		}
		var v4, v6 int
		for _, address := range addresses {
			if ip, _, err := net.ParseCIDR(address.String()); err == nil {
				if ip.To4() != nil {
					v4++
					continue
				}
				v6++
			}
		}
		out = append(out, fmt.Sprintf("%s %s mtu=%d ipv4=%d ipv6=%d",
			item.Name, flagsOf(item.Flags), item.MTU, v4, v6))
	}
	return out
}

// flagsOf renders interface flags in ip-link notation. Down interfaces omit the
// "up" flag.
func flagsOf(flags net.Flags) string {
	var letters []rune
	for flag, letter := range map[net.Flags]rune{
		net.FlagUp:           'u',
		net.FlagLoopback:     'l',
		net.FlagPointToPoint: 'p',
	} {
		if flags&flag != 0 {
			letters = append(letters, letter)
		}
	}
	sort.Slice(letters, func(i, j int) bool { return letters[i] < letters[j] })
	return string(letters)
}

// causeOrNone renders why the session is in its state.
func causeOrNone(status session.Status) string {
	if status.Reason == "" && status.Key == "" {
		return "none"
	}
	return string(status.Reason) + " " + string(status.Key)
}

func timeOrNone(at time.Time) string {
	if at.IsZero() {
		return "none"
	}
	return at.UTC().Format(time.RFC3339)
}

func durationOrNone(d time.Duration) string {
	if d <= 0 {
		return "none"
	}
	return d.String()
}

func orNone(value string) string {
	if strings.TrimSpace(value) == "" {
		return "none"
	}
	return value
}
