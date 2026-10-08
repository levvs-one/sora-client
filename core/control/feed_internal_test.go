package control

import (
	"testing"

	"github.com/levvs-one/sora-client/core/session"
)

// TestEventFeedLosesNothingAndRepeatsNothing checks that reconnecting clients
// receive every later event once, including arrivals during replay. It tests
// the journal-to-stream boundary directly.
func TestEventFeedLosesNothingAndRepeatsNothing(t *testing.T) {
	journal := session.NewJournal(64)
	for range 5 {
		journal.Append(session.Event{Kind: session.EventState, State: session.StateConnecting})
	}

	const gap = 20
	feed := newEventFeed(journal, 3, nil)
	defer feed.close()

	// Events arriving between subscription and replay must not be lost.
	appended := make([]uint64, 0, gap)
	for i := 0; i < gap; i++ {
		appended = append(appended, journal.Append(session.Event{
			Kind:  session.EventState,
			State: session.StateConnected,
		}).Sequence)
	}

	history := feed.history()
	replayed := make(map[uint64]int, len(history))
	for _, event := range history {
		replayed[event.Sequence]++
	}
	if len(history) == 0 || history[0].Sequence != 4 {
		t.Fatalf("the replay starts at %v, want the event after sequence 3", history)
	}
	for _, sequence := range appended {
		if replayed[sequence] > 0 {
			t.Errorf("sequence %d was replayed although it arrived after the head", sequence)
		}
	}
	for _, want := range appended {
		select {
		case event := <-feed.live:
			if event.Sequence != want {
				t.Fatalf("the live stream delivered sequence %d, want %d", event.Sequence, want)
			}
		default:
			t.Fatalf("the live stream lost sequence %d", want)
		}
	}
}

// TestEventFeedRespectsTheSequenceTheClientNamed checks that replay excludes
// events at or before the client's cursor.
func TestEventFeedRespectsTheSequenceTheClientNamed(t *testing.T) {
	journal := session.NewJournal(64)
	for i := range 10 {
		journal.Append(session.Event{Kind: session.EventState, State: session.State(i % 5)})
	}
	feed := newEventFeed(journal, 7, nil)
	defer feed.close()

	history := feed.history()
	if len(history) != 3 {
		t.Fatalf("a client that has seen 7 received %d events, want 3", len(history))
	}
	if history[0].Sequence != 8 || history[1].Sequence != 9 || history[2].Sequence != 10 {
		t.Errorf("the replay is %v, want sequences 8, 9 and 10", history)
	}
}
