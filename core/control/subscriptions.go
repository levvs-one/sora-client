package control

import (
	"context"
	"crypto/rand"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"net/url"
	"sort"
	"strconv"
	"strings"
	"sync"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/protobuf/proto"
	"google.golang.org/protobuf/types/known/durationpb"
	"google.golang.org/protobuf/types/known/timestamppb"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/errs"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
	"github.com/levvs-one/sora-client/core/parser"
	"github.com/levvs-one/sora-client/core/subscription"
)

// The core keeps subscriptions itself, so they stay current while the
// interface is closed. Everything about a subscription lives in the vault: the
// link is the credential, and the server list names hosts.
const (
	maxSubscriptions       = 100
	defaultUpdateInterval  = 24 * time.Hour
	minUpdateInterval      = time.Hour
	maxUpdateInterval      = 30 * 24 * time.Hour
	subscriptionFetchLimit = 2 * time.Minute
	// schedulerCheck bounds one scheduler sleep. Go timers run on the monotonic
	// clock, which stops while the machine sleeps; a timer set for six hours
	// would miss an update that fell due during a night of sleep.
	schedulerCheck = 5 * time.Minute
	// parallelUpdates bounds the fetches the scheduler runs at once.
	parallelUpdates = 4
	// recordVersion is the format of a stored record. A new format adds a case
	// to decodeRecord that reads the old one, so an upgrade never loses a
	// subscription.
	recordVersion = 1
	// listChunkBytes keeps every stored piece of a server list under the
	// vault's limit for one entry.
	listChunkBytes = 60 << 10
)

// Vault references of subscription data. A subscription id is 16 hex
// characters, so every reference stays inside the vault's 64-byte limit.
func recordRef(id string) string         { return "u1_" + id + "_rec" }
func listRef(id string, part int) string { return "u1_" + id + "_l" + strconv.Itoa(part) }

// serverRefFor names the vault entry of a server of one subscription. The
// subscription owns these entries alone, so the servers a provider drops can
// be removed without touching servers imported by hand.
func serverRefFor(id string) func(parser.OutboundSpec) (string, error) {
	return func(spec parser.OutboundSpec) (string, error) {
		sum := sha256.Sum256([]byte(spec.StableKey()))
		return "u1_" + id + "_" + hex.EncodeToString(sum[:12]), nil
	}
}

// storedError is the failure of the last attempt, kept so the interface can
// explain it after a restart of the core.
type storedError struct {
	Code   errs.Code `json:"code"`
	Key    errs.Key  `json:"key"`
	Detail string    `json:"detail"`
}

type subscriptionRecord struct {
	Version     int               `json:"v"`
	ID          string            `json:"id"`
	URL         string            `json:"url"`
	Name        string            `json:"name,omitempty"`
	UserAgent   string            `json:"ua,omitempty"`
	AutoUpdate  bool              `json:"auto"`
	Interval    time.Duration     `json:"interval,omitempty"`
	Created     time.Time         `json:"created"`
	LastAttempt time.Time         `json:"last_attempt,omitzero"`
	LastSuccess time.Time         `json:"last_success,omitzero"`
	Failures    int               `json:"failures,omitempty"`
	LastError   *storedError      `json:"last_error,omitempty"`
	Info        subscription.Info `json:"info"`
	Servers     []string          `json:"servers,omitempty"`
	ListParts   int               `json:"list_parts,omitempty"`
}

// decodeRecord reads a stored record of any format this core knows.
func decodeRecord(raw []byte) (*subscriptionRecord, error) {
	var head struct {
		Version int `json:"v"`
	}
	if err := json.Unmarshal(raw, &head); err != nil {
		return nil, err
	}
	switch head.Version {
	case recordVersion:
		var rec subscriptionRecord
		if err := json.Unmarshal(raw, &rec); err != nil {
			return nil, err
		}
		return &rec, nil
	}
	return nil, fmt.Errorf("subscription record format %d is newer than this core", head.Version)
}

// subscriptionBook holds the subscriptions and updates them on schedule.
type subscriptionBook struct {
	srv     *Server
	backoff engine.Backoff
	now     func() time.Time

	mu       sync.Mutex
	records  map[string]*subscriptionRecord
	lists    map[string][]*corev1.OutboundSpec
	updating map[string]bool
	watchers map[chan *corev1.SubscriptionState]struct{}
	wake     chan struct{}
}

func newSubscriptionBook(srv *Server) *subscriptionBook {
	b := &subscriptionBook{
		srv:      srv,
		backoff:  engine.Backoff{Initial: time.Minute, Max: time.Hour, Factor: 2},
		now:      time.Now,
		records:  map[string]*subscriptionRecord{},
		lists:    map[string][]*corev1.OutboundSpec{},
		updating: map[string]bool{},
		watchers: map[chan *corev1.SubscriptionState]struct{}{},
		wake:     make(chan struct{}, 1),
	}
	b.load()
	return b
}

// load reads every stored subscription. A record this core cannot read is
// left in the vault untouched, so a downgrade does not destroy it.
func (b *subscriptionBook) load() {
	if b.srv.secrets == nil {
		return
	}
	for _, ref := range b.srv.secrets.Refs() {
		if !strings.HasPrefix(ref, "u1_") || !strings.HasSuffix(ref, "_rec") {
			continue
		}
		raw, err := b.srv.secrets.Get(ref)
		if err != nil {
			continue
		}
		rec, err := decodeRecord(raw)
		if err != nil || rec.ID == "" {
			continue
		}
		b.records[rec.ID] = rec
		b.lists[rec.ID] = b.loadList(rec)
	}
}

func (b *subscriptionBook) loadList(rec *subscriptionRecord) []*corev1.OutboundSpec {
	var raw []byte
	for part := range rec.ListParts {
		chunk, err := b.srv.secrets.Get(listRef(rec.ID, part))
		if err != nil {
			return nil
		}
		raw = append(raw, chunk...)
	}
	var list corev1.FetchSubscriptionResponse
	if proto.Unmarshal(raw, &list) != nil {
		return nil
	}
	return list.GetOutbounds()
}

func newSubscriptionID() (string, error) {
	buf := make([]byte, 8)
	if _, err := rand.Read(buf); err != nil {
		return "", errs.Wrap(err, errs.CodeInternal, errs.KeySecretStoreUnavailable)
	}
	return hex.EncodeToString(buf), nil
}

// normalizedLink is how two links are compared for duplicates.
func normalizedLink(raw string) (string, error) {
	u, err := subscription.ValidateReference(raw)
	if err != nil {
		return "", err
	}
	u.Scheme, u.Host = strings.ToLower(u.Scheme), strings.ToLower(u.Host)
	u.Fragment = ""
	return u.String(), nil
}

func checkInterval(d *durationpb.Duration) (time.Duration, error) {
	if d == nil {
		return 0, nil
	}
	v := d.AsDuration()
	if v < minUpdateInterval || v > maxUpdateInterval {
		return 0, errs.Newf(errs.CodeInvalidArgument, errs.KeySubscriptionInterval,
			"control: the update interval must be between %s and %s", minUpdateInterval, maxUpdateInterval)
	}
	return v, nil
}

// save creates or changes a subscription. A new subscription, or one whose
// link changed, is fetched at once.
func (b *subscriptionBook) save(in *corev1.SubscriptionSettings) (*corev1.SubscriptionState, error) {
	if b.srv.secrets == nil {
		return nil, errs.Newf(errs.CodeFailedPrecondition, errs.KeySecretStoreUnavailable,
			"control: this core cannot store subscriptions")
	}
	agent := strings.TrimSpace(in.GetUserAgent())
	if _, err := subscription.UserAgentFor(agent); err != nil {
		return nil, err
	}
	interval, err := checkInterval(in.GetUpdateInterval())
	if err != nil {
		return nil, err
	}
	link := ""
	if strings.TrimSpace(in.GetUrl()) != "" {
		if link, err = normalizedLink(in.GetUrl()); err != nil {
			return nil, err
		}
	}

	b.mu.Lock()
	defer b.mu.Unlock()
	if link != "" {
		for id, rec := range b.records {
			if rec.URL == link && id != in.GetId() {
				return nil, errs.Newf(errs.CodeInvalidArgument, errs.KeySubscriptionDuplicate,
					"control: subscription %s already has this link", id)
			}
		}
	}
	var rec subscriptionRecord
	fetchNow := false
	if in.GetId() == "" {
		if link == "" {
			return nil, errs.Newf(errs.CodeInvalidArgument, errs.KeySubscriptionScheme,
				"control: a new subscription needs a link")
		}
		if len(b.records) >= maxSubscriptions {
			return nil, errs.Newf(errs.CodeResourceExhausted, errs.KeySubscriptionLimit,
				"control: the core keeps at most %d subscriptions", maxSubscriptions)
		}
		id, err := newSubscriptionID()
		if err != nil {
			return nil, err
		}
		rec = subscriptionRecord{Version: recordVersion, ID: id, URL: link, Created: b.now().UTC()}
		fetchNow = true
	} else {
		existing, ok := b.records[in.GetId()]
		if !ok {
			return nil, errs.Newf(errs.CodeNotFound, errs.KeySubscriptionNotFound, "control: no subscription %s", in.GetId())
		}
		rec = *existing
		if link != "" && link != rec.URL {
			rec.URL, rec.Failures, rec.LastError = link, 0, nil
			fetchNow = true
		}
	}
	rec.Name = strings.TrimSpace(in.GetName())
	rec.UserAgent = agent
	rec.AutoUpdate = in.GetAutoUpdate()
	rec.Interval = interval
	if err := b.persistLocked(&rec, nil, nil); err != nil {
		return nil, err
	}
	b.records[rec.ID] = &rec
	state := b.stateLocked(rec.ID)
	b.notifyLocked(state)
	if fetchNow {
		go func() { _, _ = b.refresh(context.Background(), rec.ID) }()
	}
	b.poke()
	return state, nil
}

// persistLocked writes a record together with the vault changes of an update,
// in one change of the vault.
func (b *subscriptionBook) persistLocked(rec *subscriptionRecord, puts map[string][]byte, deletes []string) error {
	raw, err := json.Marshal(rec)
	if err != nil {
		return errs.Wrap(err, errs.CodeInternal, errs.KeySecretStoreUnavailable)
	}
	if puts == nil {
		puts = map[string][]byte{}
	}
	puts[recordRef(rec.ID)] = raw
	return b.srv.secrets.Apply(puts, deletes)
}

func (b *subscriptionBook) delete(id string) error {
	b.mu.Lock()
	defer b.mu.Unlock()
	rec, ok := b.records[id]
	if !ok {
		return errs.Newf(errs.CodeNotFound, errs.KeySubscriptionNotFound, "control: no subscription %s", id)
	}
	deletes := append([]string{recordRef(id)}, rec.Servers...)
	for part := range rec.ListParts {
		deletes = append(deletes, listRef(id, part))
	}
	if err := b.srv.secrets.Apply(nil, deletes); err != nil {
		return err
	}
	delete(b.records, id)
	delete(b.lists, id)
	b.notifyLocked(&corev1.SubscriptionState{Settings: &corev1.SubscriptionSettings{Id: id}, Deleted: true})
	return nil
}

// refresh fetches one subscription now. A refresh that is already running is
// not started twice: the caller gets the current state with updating set.
func (b *subscriptionBook) refresh(ctx context.Context, id string) (*corev1.SubscriptionState, error) {
	b.mu.Lock()
	rec, ok := b.records[id]
	if !ok {
		b.mu.Unlock()
		return nil, errs.Newf(errs.CodeNotFound, errs.KeySubscriptionNotFound, "control: no subscription %s", id)
	}
	if b.updating[id] {
		state := b.stateLocked(id)
		b.mu.Unlock()
		return state, nil
	}
	if b.srv.fetcher == nil {
		b.mu.Unlock()
		return nil, errs.Newf(errs.CodeUnsupported, errs.KeySubscriptionFetch, "control: this core cannot fetch subscriptions")
	}
	b.updating[id] = true
	link, agent := rec.URL, rec.UserAgent
	b.notifyLocked(b.stateLocked(id))
	b.mu.Unlock()

	ctx, cancel := context.WithTimeout(ctx, subscriptionFetchLimit)
	defer cancel()
	fetched, err := b.srv.fetcher.Fetch(ctx, link, subscription.FetchOptions{UserAgent: agent})
	answered := err == nil
	var servers []importedServer
	if err == nil {
		servers, err = b.srv.parsePayload(fetched.Body, serverRefFor(id))
	}

	b.mu.Lock()
	defer b.mu.Unlock()
	delete(b.updating, id)
	current, ok := b.records[id]
	if !ok || current.URL != link {
		// Deleted, or given another link, while the fetch ran: this answer
		// belongs to nothing that still exists.
		return nil, errs.Newf(errs.CodeNotFound, errs.KeySubscriptionNotFound, "control: subscription %s changed during the update", id)
	}
	next := *current
	next.LastAttempt = b.now().UTC()
	if err == nil {
		err = b.applyUpdateLocked(&next, fetched.Info, servers)
	}
	if err != nil {
		// A failed update keeps the last good servers: a provider that is down
		// for an hour must not empty the user's list.
		next.Failures++
		// The panel answered even when its body did not parse: its title,
		// usage and announcement still tell the person whose subscription
		// this is and what the provider says.
		if answered {
			next.Info = fetched.Info
		}
		failure := errs.From(err)
		next.LastError = &storedError{Code: failure.Code(), Key: failure.Key(), Detail: errs.Detail(err)}
		if perr := b.persistLocked(&next, nil, nil); perr != nil {
			return nil, perr
		}
	}
	b.records[id] = &next
	state := b.stateLocked(id)
	b.notifyLocked(state)
	b.poke()
	return state, err
}

// applyUpdateLocked stores a successful update: the new server credentials, the
// new list, and the record, while the servers the provider dropped and the
// list parts no longer needed are removed, all in one change of the vault.
func (b *subscriptionBook) applyUpdateLocked(rec *subscriptionRecord, info subscription.Info, servers []importedServer) error {
	list := &corev1.FetchSubscriptionResponse{}
	puts := map[string][]byte{}
	keep := map[string]bool{}
	refs := make([]string, 0, len(servers))
	for _, s := range servers {
		puts[s.reference] = s.document
		keep[s.reference] = true
		refs = append(refs, s.reference)
		list.Outbounds = append(list.Outbounds, s.spec)
	}
	raw, err := proto.Marshal(list)
	if err != nil {
		return errs.Wrap(err, errs.CodeInternal, errs.KeySecretStoreUnavailable)
	}
	parts := 0
	for start := 0; start < len(raw); start += listChunkBytes {
		puts[listRef(rec.ID, parts)] = raw[start:min(start+listChunkBytes, len(raw))]
		parts++
	}
	var deletes []string
	for _, ref := range rec.Servers {
		if !keep[ref] {
			deletes = append(deletes, ref)
		}
	}
	for part := parts; part < rec.ListParts; part++ {
		deletes = append(deletes, listRef(rec.ID, part))
	}
	sort.Strings(refs)
	updated := *rec
	updated.Servers, updated.ListParts = refs, parts
	updated.Info = info
	updated.LastSuccess, updated.Failures, updated.LastError = updated.LastAttempt, 0, nil
	if err := b.persistLocked(&updated, puts, deletes); err != nil {
		return err
	}
	*rec = updated
	b.lists[rec.ID] = list.GetOutbounds()
	return nil
}

// interval is how often a subscription is fetched: the user's choice, then
// the provider's, then a day.
func (rec *subscriptionRecord) interval() time.Duration {
	switch {
	case rec.Interval > 0:
		return rec.Interval
	case rec.Info.UpdateInterval >= minUpdateInterval:
		return min(rec.Info.UpdateInterval, maxUpdateInterval)
	}
	return defaultUpdateInterval
}

// nextUpdate is when the scheduler fetches a subscription next; zero when it
// does not update on its own. After a failure the retry comes sooner than the
// interval, with a growing pause, so a network that is back is noticed soon
// and a provider that is down is not hammered.
func (b *subscriptionBook) nextUpdate(rec *subscriptionRecord) time.Time {
	if !rec.AutoUpdate {
		return time.Time{}
	}
	if rec.LastAttempt.IsZero() {
		return rec.Created
	}
	if rec.Failures > 0 {
		retry := b.backoff
		retry.Max = min(retry.Max, rec.interval())
		return rec.LastAttempt.Add(retry.Delay(rec.Failures - 1))
	}
	return rec.LastSuccess.Add(rec.interval())
}

// run is the scheduler. It starts every update that is due, then sleeps until
// the next one, a change, or schedulerCheck, whichever comes first.
func (b *subscriptionBook) run(ctx context.Context) {
	slots := make(chan struct{}, parallelUpdates)
	for {
		now := b.now()
		wait := schedulerCheck
		b.mu.Lock()
		var due []string
		for id, rec := range b.records {
			at := b.nextUpdate(rec)
			if at.IsZero() || b.updating[id] {
				continue
			}
			if !at.After(now) {
				due = append(due, id)
			} else if d := at.Sub(now); d < wait {
				wait = d
			}
		}
		b.mu.Unlock()
		for _, id := range due {
			select {
			case slots <- struct{}{}:
			case <-ctx.Done():
				return
			}
			go func() {
				defer func() { <-slots }()
				_, _ = b.refresh(ctx, id)
			}()
		}
		timer := time.NewTimer(wait)
		select {
		case <-ctx.Done():
			timer.Stop()
			return
		case <-b.wake:
		case <-timer.C:
		}
		timer.Stop()
	}
}

// poke wakes the scheduler after a change.
func (b *subscriptionBook) poke() {
	select {
	case b.wake <- struct{}{}:
	default:
	}
}

func (b *subscriptionBook) list() []*corev1.SubscriptionState {
	b.mu.Lock()
	defer b.mu.Unlock()
	ids := make([]string, 0, len(b.records))
	for id := range b.records {
		ids = append(ids, id)
	}
	// The order the user added them in, which does not move under them.
	sort.Slice(ids, func(i, j int) bool {
		a, c := b.records[ids[i]], b.records[ids[j]]
		if !a.Created.Equal(c.Created) {
			return a.Created.Before(c.Created)
		}
		return ids[i] < ids[j]
	})
	out := make([]*corev1.SubscriptionState, 0, len(ids))
	for _, id := range ids {
		out = append(out, b.stateLocked(id))
	}
	return out
}

func (b *subscriptionBook) stateLocked(id string) *corev1.SubscriptionState {
	rec := b.records[id]
	settings := &corev1.SubscriptionSettings{Id: rec.ID, Name: rec.Name, UserAgent: rec.UserAgent, AutoUpdate: rec.AutoUpdate}
	if rec.Interval > 0 {
		settings.UpdateInterval = durationpb.New(rec.Interval)
	}
	state := &corev1.SubscriptionState{
		Settings:    settings,
		Info:        subscriptionInfoToWire(rec.Info),
		Outbounds:   b.lists[id],
		Updating:    b.updating[id],
		DisplayName: displayName(rec),
	}
	if !rec.LastSuccess.IsZero() {
		state.LastUpdate = timestamppb.New(rec.LastSuccess)
	}
	if at := b.nextUpdate(rec); !at.IsZero() {
		state.NextUpdate = timestamppb.New(at)
	}
	if rec.LastError != nil {
		state.LastError = toWire(errs.Newf(rec.LastError.Code, rec.LastError.Key, "%s", rec.LastError.Detail), nil, "")
	}
	return state
}

// displayName is never empty, so the list never shows a blank row.
func displayName(rec *subscriptionRecord) string {
	if rec.Name != "" {
		return rec.Name
	}
	if rec.Info.Title != "" {
		return rec.Info.Title
	}
	if u, err := url.Parse(rec.URL); err == nil && u.Hostname() != "" {
		return u.Hostname()
	}
	return rec.ID
}

// watch delivers every change of a subscription. A slow watcher loses
// changes instead of slowing the core; ListSubscriptions fills the gap.
func (b *subscriptionBook) watch() (chan *corev1.SubscriptionState, func()) {
	ch := make(chan *corev1.SubscriptionState, 64)
	b.mu.Lock()
	b.watchers[ch] = struct{}{}
	b.mu.Unlock()
	return ch, func() {
		b.mu.Lock()
		defer b.mu.Unlock()
		if _, ok := b.watchers[ch]; ok {
			delete(b.watchers, ch)
			close(ch)
		}
	}
}

func (b *subscriptionBook) notifyLocked(state *corev1.SubscriptionState) {
	for ch := range b.watchers {
		select {
		case ch <- state:
		default:
		}
	}
}

// SaveSubscription creates or changes a subscription.
func (s *Server) SaveSubscription(_ context.Context, req *corev1.SaveSubscriptionRequest) (*corev1.SaveSubscriptionResponse, error) {
	if err := s.authorize(req.GetApiVersion(), req.GetControlAuthenticator()); err != nil {
		return nil, err
	}
	state, err := s.subs.save(req.GetSettings())
	if err != nil {
		return &corev1.SaveSubscriptionResponse{Error: toWire(err, nil, "")}, nil
	}
	return &corev1.SaveSubscriptionResponse{State: state}, nil
}

// ListSubscriptions answers every subscription in the order it was added.
func (s *Server) ListSubscriptions(_ context.Context, req *corev1.ListSubscriptionsRequest) (*corev1.ListSubscriptionsResponse, error) {
	if err := s.authorize(req.GetApiVersion(), req.GetControlAuthenticator()); err != nil {
		return nil, err
	}
	return &corev1.ListSubscriptionsResponse{Subscriptions: s.subs.list()}, nil
}

// DeleteSubscription removes a subscription with its servers and credentials.
func (s *Server) DeleteSubscription(_ context.Context, req *corev1.DeleteSubscriptionRequest) (*corev1.DeleteSubscriptionResponse, error) {
	if err := s.authorize(req.GetApiVersion(), req.GetControlAuthenticator()); err != nil {
		return nil, err
	}
	if err := s.subs.delete(req.GetId()); err != nil {
		return &corev1.DeleteSubscriptionResponse{Error: toWire(err, nil, "")}, nil
	}
	return &corev1.DeleteSubscriptionResponse{}, nil
}

// RefreshSubscription fetches a subscription now and answers its new state. A
// failed fetch answers the state, which keeps the last good servers, with the
// error.
func (s *Server) RefreshSubscription(ctx context.Context, req *corev1.RefreshSubscriptionRequest) (*corev1.RefreshSubscriptionResponse, error) {
	if err := s.authorize(req.GetApiVersion(), req.GetControlAuthenticator()); err != nil {
		return nil, err
	}
	state, err := s.subs.refresh(ctx, req.GetId())
	out := &corev1.RefreshSubscriptionResponse{State: state}
	if err != nil {
		out.Error = toWire(err, nil, "")
	}
	return out, nil
}

// WatchSubscriptions answers every subscription, then every change as it
// happens.
func (s *Server) WatchSubscriptions(req *corev1.WatchSubscriptionsRequest, stream grpc.ServerStreamingServer[corev1.SubscriptionState]) error {
	if err := s.authorize(req.GetApiVersion(), req.GetControlAuthenticator()); err != nil {
		return err
	}
	changes, stop := s.subs.watch()
	defer stop()
	for _, state := range s.subs.list() {
		if err := stream.Send(state); err != nil {
			return err
		}
	}
	ctx := stream.Context()
	for {
		select {
		case <-ctx.Done():
			return nil
		case state := <-changes:
			if err := stream.Send(state); err != nil {
				return err
			}
		}
	}
}
