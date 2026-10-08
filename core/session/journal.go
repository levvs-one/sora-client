package session

import (
	"sync"
	"time"

	"github.com/levvs-one/sora-client/core/errs"
)

// EventKind maps session events to CoreEvent oneof fields for control-plane
// translation.
type EventKind string

// Kinds of session event.
const (
	EventState    EventKind = "state"
	EventCounters EventKind = "counters"
	EventLog      EventKind = "log"
	EventProbe    EventKind = "probe"
	EventError    EventKind = "error"
	EventGroup    EventKind = "group"
)

// Event records a session change. Journal-assigned sequence numbers increase
// within the session so clients can resume streams after reconnecting.
type Event struct {
	Sequence   uint64
	At         time.Time
	Kind       EventKind
	State      State
	Reason     errs.Code
	Key        errs.Key
	Detail     string
	Counters   Counters
	Probe      *ProbeOutcome
	Switch     *GroupSwitch
	RetryAfter time.Duration
	LogLine    string
}

// GroupSwitch is a fallback group that moved to another member on its own.
// Selected is an outbound id or the name of a nested group.
type GroupSwitch struct {
	Group    string
	Selected string
}

// Counters defines session traffic totals independently of engine types to
// preserve the client contract.
type Counters struct {
	BytesUp           uint64
	BytesDown         uint64
	ActiveConnections int
	At                time.Time
}

// ProbeOutcome carries latency results with their session-known server
// identity, avoiding reconstruction by the control plane.
type ProbeOutcome struct {
	ServerID  string
	Reachable bool
	LatencyMS int
	Err       error
}

// Journal stores bounded session history and publishes without blocking. Slow
// subscribers lose counted events; clients reconcile gaps with a fresh status
// snapshot.
type Journal struct {
	mu       sync.Mutex
	next     uint64
	capacity int
	history  []Event
	subs     map[chan Event]struct{}
	dropped  uint64
}

// DefaultJournalCapacity retains roughly a minute of counters and state changes
// for client reattachment.
const DefaultJournalCapacity = 512

// NewJournal returns a journal that keeps capacity events of history.
func NewJournal(capacity int) *Journal {
	if capacity <= 0 {
		capacity = DefaultJournalCapacity
	}
	return &Journal{
		capacity: capacity,
		history:  make([]Event, 0, capacity),
		subs:     make(map[chan Event]struct{}),
	}
}

// Append assigns sequence and time, stores and publishes the event, and returns
// the stamped value for log correlation.
func (j *Journal) Append(ev Event) Event {
	j.mu.Lock()
	j.next++
	ev.Sequence = j.next
	if ev.At.IsZero() {
		ev.At = time.Now()
	}
	j.history = append(j.history, ev)
	if len(j.history) > j.capacity {
		// Trim history without reallocating the slice on every counter
		// tick.
		j.history = append(j.history[:0], j.history[len(j.history)-j.capacity:]...)
	}
	subs := make([]chan Event, 0, len(j.subs))
	for ch := range j.subs {
		subs = append(subs, ch)
	}
	j.mu.Unlock()

	for _, ch := range subs {
		select {
		case ch <- ev:
		default:
			j.mu.Lock()
			j.dropped++
			j.mu.Unlock()
		}
	}
	return ev
}

// Since returns retained events after the cursor, oldest first, up to limit.
// Clients beyond retained history need a status snapshot; drop counts signal
// incomplete delivery.
func (j *Journal) Since(after uint64, limit int) []Event {
	j.mu.Lock()
	defer j.mu.Unlock()
	if limit <= 0 || limit > j.capacity {
		limit = j.capacity
	}
	out := make([]Event, 0, limit)
	for _, ev := range j.history {
		if ev.Sequence <= after {
			continue
		}
		out = append(out, ev)
		if len(out) == limit {
			break
		}
	}
	return out
}

// Latest returns the newest event sequence for stream resumption.
func (j *Journal) Latest() uint64 {
	j.mu.Lock()
	defer j.mu.Unlock()
	return j.next
}

// Dropped counts missed subscriber events so clients can detect incomplete
// state.
func (j *Journal) Dropped() uint64 {
	j.mu.Lock()
	defer j.mu.Unlock()
	return j.dropped
}

// Subscribe creates a buffered live listener. The returned cancellation
// function unregisters and closes it safely on repeated calls.
func (j *Journal) Subscribe(buffer int) (<-chan Event, func()) {
	if buffer <= 0 {
		buffer = 64
	}
	ch := make(chan Event, buffer)
	j.mu.Lock()
	j.subs[ch] = struct{}{}
	j.mu.Unlock()
	var once sync.Once
	cancel := func() {
		once.Do(func() {
			j.mu.Lock()
			defer j.mu.Unlock()
			if _, ok := j.subs[ch]; ok {
				delete(j.subs, ch)
				close(ch)
			}
		})
	}
	return ch, cancel
}
