package session

import (
	"sync"
	"time"

	"github.com/levvs-one/sora-client/core/errs"
)

// EventKind classifies one event of a session. Each kind maps to one field of
// the CoreEvent oneof in the contract, so the control plane is a translation
// table and nothing more.
type EventKind string

// Kinds of session event.
const (
	EventState    EventKind = "state"
	EventCounters EventKind = "counters"
	EventLog      EventKind = "log"
	EventProbe    EventKind = "probe"
	EventError    EventKind = "error"
)

// Event is one thing that happened in a session. The sequence number is
// assigned by the journal and is strictly increasing within one session, which
// is what lets a client resume a stream after a reconnect without losing its
// place or replaying the whole history.
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
	RetryAfter time.Duration
	LogLine    string
}

// Counters are the traffic counters of a running session. The type is local so
// a future engine backend cannot change the shape a client already reads.
type Counters struct {
	BytesUp           uint64
	BytesDown         uint64
	ActiveConnections int
	At                time.Time
}

// ProbeOutcome is the result of one latency measurement. It travels with the event
// rather than being rebuilt by the control plane, because only the session knows
// which server the measurement was about.
type ProbeOutcome struct {
	ServerID  string
	Reachable bool
	LatencyMS int
	Err       error
}

// Journal keeps the recent history of one session and fans new events out to
// live subscribers.
//
// Two properties matter and both are deliberate. History is bounded, so a core
// that runs for weeks cannot grow without limit. A subscriber that stops
// reading is never allowed to block the session: its events are dropped, the
// drop is counted, and the control plane answers a gap with a fresh status
// snapshot instead of pretending the history was complete.
type Journal struct {
	mu       sync.Mutex
	next     uint64
	capacity int
	history  []Event
	subs     map[chan Event]struct{}
	dropped  uint64
}

// DefaultJournalCapacity keeps roughly a minute of counters and state changes,
// which is enough to reattach an interface that lost its stream.
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

// Append stamps the event with the next sequence number and the current time,
// stores it and delivers it to every live subscriber. The stamped event is
// returned so a caller can log the sequence it produced.
func (j *Journal) Append(ev Event) Event {
	j.mu.Lock()
	j.next++
	ev.Sequence = j.next
	if ev.At.IsZero() {
		ev.At = time.Now()
	}
	j.history = append(j.history, ev)
	if len(j.history) > j.capacity {
		// The slice is trimmed from the front without reallocating: a session
		// that emits a counter tick every second would otherwise allocate once
		// a second for the whole life of the process.
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

// Since returns up to limit events with a sequence greater than after, oldest
// first. It returns whatever the journal still holds, which may be nothing: a
// client that was away longer than the history must reconcile from a status
// snapshot, and the control plane tells it so through the drop count.
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

// Latest reports the sequence number of the most recent event, which is also
// the sequence a client resumes from after a fresh subscribe.
func (j *Journal) Latest() uint64 {
	j.mu.Lock()
	defer j.mu.Unlock()
	return j.next
}

// Dropped reports how many events a slow subscriber missed. The control plane
// reports it so a client knows its view may be incomplete.
func (j *Journal) Dropped() uint64 {
	j.mu.Lock()
	defer j.mu.Unlock()
	return j.dropped
}

// Subscribe registers a live listener with its own buffer. The returned function
// unregisters it and closes the channel; calling it twice is harmless.
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
