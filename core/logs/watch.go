package logs

import "errors"

var errPatternTooLong = errors.New("logs: filter expression is too long")

// watchBuffer is the room a watcher has for live entries beyond its replay.
const watchBuffer = 512

type watcher struct {
	filter Filter
	ch     chan Entry
	lost   uint64
}

// Subscription is a live view of the record.
type Subscription struct {
	C      <-chan Entry
	center *Center
	w      *watcher
}

// Watch replays the matching entries newer than after and then delivers new
// ones as they are written. A folded repeat arrives again with the same Seq
// and a higher Repeat, so a client updates the line it already shows. A
// watcher that falls behind loses entries instead of slowing the engines;
// Lost says how many, and Query fills the gap.
func (c *Center) Watch(f Filter, after uint64) *Subscription {
	c.mu.Lock()
	defer c.mu.Unlock()
	var replay []Entry
	for _, e := range c.entries {
		if e.Seq > after && f.match(e) {
			replay = append(replay, e)
		}
	}
	w := &watcher{filter: f, ch: make(chan Entry, len(replay)+watchBuffer)}
	for _, e := range replay {
		w.ch <- e
	}
	c.watchers[w] = struct{}{}
	return &Subscription{C: w.ch, center: c, w: w}
}

// Lost reports how many entries this watcher missed because it was slow.
func (s *Subscription) Lost() uint64 {
	s.center.mu.Lock()
	defer s.center.mu.Unlock()
	return s.w.lost
}

// Close ends the subscription and closes C.
func (s *Subscription) Close() {
	s.center.mu.Lock()
	defer s.center.mu.Unlock()
	if _, ok := s.center.watchers[s.w]; ok {
		delete(s.center.watchers, s.w)
		close(s.w.ch)
	}
}

// notify runs with c.mu held.
func (c *Center) notify(e Entry) {
	for w := range c.watchers {
		if !w.filter.match(e) {
			continue
		}
		select {
		case w.ch <- e:
		default:
			w.lost++
		}
	}
}
