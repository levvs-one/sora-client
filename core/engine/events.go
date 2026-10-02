package engine

import (
	"sync"
	"time"
)

// Counters are the traffic counters of a running session.
type Counters struct {
	BytesUp           uint64
	BytesDown         uint64
	ActiveConnections int
	MemoryBytes       uint64
	At                time.Time
}

// GroupStatus is the live state of one selectable group.
type GroupStatus struct {
	Name      string
	Type      GroupType
	Selected  string
	All       []string
	Hidden    bool
	Icon      string
	TestURL   string
	Provider  string
	UpdatedAt time.Time
	LatencyMS map[string]int
}

// EventKind classifies an Event.
type EventKind string

// Kinds of engine notifications reported on the event channel.
const (
	EventState      EventKind = "state"
	EventLog        EventKind = "log"
	EventCounters   EventKind = "counters"
	EventGroup      EventKind = "group"
	EventRestart    EventKind = "restart"
	EventEngineDown EventKind = "engine-down"
	EventFatal      EventKind = "fatal"
)

// Event is one engine notification for the control plane. Message is safe to
// show after masking; Err carries the machine-readable cause.
type Event struct {
	Kind     EventKind
	State    State
	Message  string
	Err      error
	Counters Counters
	Group    *GroupStatus
	At       time.Time
}

// EventBus fans engine events out to subscribers. Publishing never blocks the
// engine: a slow subscriber loses events and the counter records how many, so
// the control plane reconciles by polling instead of pretending nothing was
// lost.
type EventBus struct {
	mu      sync.Mutex
	subs    map[chan Event]struct{}
	dropped int64
	queue   int
}

// NewEventBus returns a bus with queueLen events of buffer per subscriber.
func NewEventBus(queueLen int) *EventBus {
	if queueLen <= 0 {
		queueLen = 64
	}
	return &EventBus{subs: make(map[chan Event]struct{}), queue: queueLen}
}

// Publish delivers ev to every subscriber without blocking.
func (b *EventBus) Publish(ev Event) {
	if ev.At.IsZero() {
		ev.At = time.Now()
	}
	b.mu.Lock()
	defer b.mu.Unlock()
	for ch := range b.subs {
		select {
		case ch <- ev:
		default:
			b.dropped++
		}
	}
}

// Subscribe registers a listener. Call the returned function to unsubscribe.
func (b *EventBus) Subscribe() (<-chan Event, func()) {
	b.mu.Lock()
	defer b.mu.Unlock()
	ch := make(chan Event, b.queue)
	b.subs[ch] = struct{}{}
	return ch, func() {
		b.mu.Lock()
		defer b.mu.Unlock()
		if _, ok := b.subs[ch]; ok {
			delete(b.subs, ch)
			close(ch)
		}
	}
}

// Dropped reports how many events were lost because a subscriber was slow.
func (b *EventBus) Dropped() int64 {
	b.mu.Lock()
	defer b.mu.Unlock()
	return b.dropped
}
