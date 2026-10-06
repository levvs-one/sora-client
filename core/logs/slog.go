package logs

import (
	"context"
	"log/slog"
	"strings"
)

// Handler records the structured log of the core service in the center, next
// to the engines, and passes every record on to the next handler.
type Handler struct {
	center *Center
	next   slog.Handler
	attrs  []slog.Attr
	group  string
}

// NewHandler wraps next; next keeps writing where it wrote before.
func NewHandler(center *Center, next slog.Handler) *Handler {
	return &Handler{center: center, next: next}
}

// Enabled lets debug records through, so the capture level of the center, not
// the level of the service log, decides what the log center keeps.
func (h *Handler) Enabled(ctx context.Context, level slog.Level) bool {
	return level >= slog.LevelDebug || h.next.Enabled(ctx, level)
}

// Handle records the message with its attributes as key=value pairs.
func (h *Handler) Handle(ctx context.Context, r slog.Record) error {
	var b strings.Builder
	b.WriteString(r.Message)
	write := func(a slog.Attr) bool {
		key := a.Key
		if h.group != "" {
			key = h.group + "." + key
		}
		b.WriteString(" " + key + "=" + a.Value.String())
		return true
	}
	for _, a := range h.attrs {
		write(a)
	}
	r.Attrs(write)
	h.center.Write(r.Time, slogLevel(r.Level), SourceCore, b.String())
	if h.next.Enabled(ctx, r.Level) {
		return h.next.Handle(ctx, r)
	}
	return nil
}

// WithAttrs returns a handler that adds attrs to every record.
func (h *Handler) WithAttrs(attrs []slog.Attr) slog.Handler {
	c := *h
	c.attrs = append(append([]slog.Attr{}, h.attrs...), attrs...)
	c.next = h.next.WithAttrs(attrs)
	return &c
}

// WithGroup returns a handler that qualifies keys with name.
func (h *Handler) WithGroup(name string) slog.Handler {
	c := *h
	if c.group != "" {
		name = c.group + "." + name
	}
	c.group = name
	c.next = h.next.WithGroup(name)
	return &c
}

func slogLevel(l slog.Level) Level {
	switch {
	case l >= slog.LevelError:
		return LevelError
	case l >= slog.LevelWarn:
		return LevelWarning
	case l >= slog.LevelInfo:
		return LevelInfo
	}
	return LevelDebug
}
