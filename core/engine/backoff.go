package engine

import (
	"context"
	"errors"
	"math/rand"
	"sync"
	"time"
)

// ErrBudgetExhausted stops the supervision loop when the engine keeps dying.
var ErrBudgetExhausted = errors.New("engine: restart budget exhausted")

// Backoff schedules engine restart attempts.
type Backoff struct {
	Initial time.Duration
	Max     time.Duration
	Factor  float64
	// Rand returns a value in [0,1). Tests replace it to get stable delays.
	Rand func() float64
}

// DefaultBackoff starts at 500ms and caps at 2min, so a broken engine is
// retried quickly at first and then settles into a quiet retry loop.
func DefaultBackoff() Backoff {
	return Backoff{Initial: 500 * time.Millisecond, Max: 2 * time.Minute, Factor: 2, Rand: rand.Float64}
}

// Delay returns how long to wait before attempt n, counting from zero.
// Jitter is random between 50% and 100% of the computed delay so that many
// machines behind one subscription endpoint do not retry in lockstep.
func (b Backoff) Delay(n int) time.Duration {
	initial := b.Initial
	if initial <= 0 {
		initial = 500 * time.Millisecond
	}
	factor := b.Factor
	if factor < 1 {
		factor = 2
	}
	ceiling := b.Max
	if ceiling <= 0 {
		ceiling = 2 * time.Minute
	}
	d := time.Duration(float64(initial))
	for i := 0; i < n && d < ceiling; i++ {
		d = time.Duration(float64(d) * factor)
	}
	if d > ceiling {
		d = ceiling
	}
	rnd := b.Rand
	if rnd == nil {
		rnd = rand.Float64
	}
	return time.Duration(float64(d)*(0.5+0.5*rnd())) / time.Millisecond * time.Millisecond
}

// Wait sleeps the delay for attempt n and reports ctx cancellation.
func (b Backoff) Wait(ctx context.Context, n int) error {
	d := b.Delay(n)
	if d <= 0 {
		return ctx.Err()
	}
	timer := time.NewTimer(d)
	defer timer.Stop()
	select {
	case <-ctx.Done():
		return ctx.Err()
	case <-timer.C:
		return nil
	}
}

// RestartBudget allows at most limit restarts inside window. A long healthy run
// clears the budget, so a crash from a year ago cannot block a reconnect.
type RestartBudget struct {
	mu       sync.Mutex
	limit    int
	window   time.Duration
	attempts []time.Time
	now      func() time.Time
}

// NewRestartBudget builds a budget. limit <= 0 disables restarting.
func NewRestartBudget(limit int, window time.Duration, now func() time.Time) *RestartBudget {
	if now == nil {
		now = time.Now
	}
	if window <= 0 {
		window = 10 * time.Minute
	}
	return &RestartBudget{limit: limit, window: window, now: now}
}

// Allow records an attempt and reports whether it is still inside the budget.
func (b *RestartBudget) Allow() bool {
	b.mu.Lock()
	defer b.mu.Unlock()
	if b.limit <= 0 {
		return false
	}
	cutoff := b.now().Add(-b.window)
	kept := b.attempts[:0]
	for _, t := range b.attempts {
		if t.After(cutoff) {
			kept = append(kept, t)
		}
	}
	b.attempts = kept
	if len(b.attempts) >= b.limit {
		return false
	}
	b.attempts = append(b.attempts, b.now())
	return true
}

// Used returns how many attempts are inside the current window.
func (b *RestartBudget) Used() int {
	b.mu.Lock()
	defer b.mu.Unlock()
	return len(b.attempts)
}

// Reset forgets the window, for example after a manual reconnect by the user.
func (b *RestartBudget) Reset() {
	b.mu.Lock()
	defer b.mu.Unlock()
	b.attempts = nil
}
