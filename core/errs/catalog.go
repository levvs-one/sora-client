package errs

import "sort"

// Key is a stable identifier of one line of the catalog. It is the only part
// of an error the interface is allowed to read, so keys are part of the public
// contract: a summary may be reworded and a key may be added, but an existing
// key is never given a new meaning.
type Key string

// Catalog keys, grouped by the subsystem that raises them. The dot-separated
// prefix is the subsystem and the rest names the condition.
const (
	// Contract and transport.
	KeyAPIVersionMismatch Key = "core.api.version_mismatch"
	KeyUnauthenticated    Key = "core.auth.unauthenticated"
	KeyPermissionDenied   Key = "core.auth.permission_denied"
	KeyInvalidRequest     Key = "core.request.invalid"
	KeyRequestTooLarge    Key = "core.request.too_large"
	KeyUnknownSession     Key = "core.session.unknown"
	KeySessionRequired    Key = "core.session.required"
	KeySessionBusy        Key = "core.session.busy"
	KeyInternal           Key = "core.internal.unexpected"
	KeyCancelled          Key = "core.request.cancelled"
	KeyDeadlineExceeded   Key = "core.request.deadline_exceeded"

	// Plans.
	KeyPlanEmpty          Key = "core.plan.empty"
	KeyPlanTooLarge       Key = "core.plan.too_large"
	KeyPlanOutbounds      Key = "core.plan.outbounds_invalid"
	KeyPlanDuplicateID    Key = "core.plan.duplicate_id"
	KeyPlanUnknownTarget  Key = "core.plan.unknown_target"
	KeyPlanRuleInvalid    Key = "core.plan.rule_invalid"
	KeyPlanTunnel         Key = "core.plan.tunnel_unsupported"
	KeyPlanDNSInvalid     Key = "core.plan.dns_invalid"
	KeyPlanBypassInvalid  Key = "core.plan.bypass_invalid"
	KeyPlanGroupsInvalid  Key = "core.plan.groups_invalid"
	KeyPlanTestURLInvalid Key = "core.plan.test_url_invalid"

	// Engine.
	KeyEngineBinaryMissing  Key = "core.engine.binary_missing"
	KeyEngineBinaryUnusable Key = "core.engine.binary_unusable"
	KeyEngineStartFailed    Key = "core.engine.start_failed"
	KeyEngineApplyFailed    Key = "core.engine.apply_failed"
	KeyEngineStopFailed     Key = "core.engine.stop_failed"
	KeyEngineStopped        Key = "core.engine.stopped"
	KeyEngineUnsupported    Key = "core.engine.unsupported"
	KeyEngineVersionTooOld  Key = "core.engine.version_too_old"
	KeyEngineRestartSpent   Key = "core.engine.restart_budget_spent"
	KeyEngineOutputDenied   Key = "core.engine.output_denied"
	KeyEngineProbeFailed    Key = "core.engine.probe_failed"

	// Subscriptions and import.
	KeySubscriptionEmpty     Key = "core.subscription.empty"
	KeySubscriptionTooLarge  Key = "core.subscription.too_large"
	KeySubscriptionFetch     Key = "core.subscription.fetch_failed"
	KeySubscriptionStatus    Key = "core.subscription.status"
	KeySubscriptionRedirect  Key = "core.subscription.redirect_rejected"
	KeySubscriptionScheme    Key = "core.subscription.scheme_unsupported"
	KeySubscriptionFormat    Key = "core.subscription.format_unknown"
	KeySubscriptionNoServers Key = "core.subscription.no_servers"
	KeySubscriptionAllFailed Key = "core.subscription.all_servers_failed"

	// Secret store.
	//nolint:gosec // a localization key, not a credential
	KeySecretReferenceInvalid Key = "core.secret.reference_invalid"
	KeySecretExists           Key = "core.secret.exists"
	KeySecretNotFound         Key = "core.secret.not_found"
	KeySecretTooLarge         Key = "core.secret.too_large"
	KeySecretStoreLocked      Key = "core.secret.store_locked"
	KeySecretStoreCorrupt     Key = "core.secret.store_corrupt"
	KeySecretStoreUnavailable Key = "core.secret.store_unavailable"

	// System guard: kill switch, proxy, cleanup on exit.
	KeyGuardNeedsElevation Key = "core.guard.needs_elevation"
	KeyGuardProxyFailed    Key = "core.guard.proxy_failed"
	KeyGuardFirewallFail   Key = "core.guard.firewall_failed"
	KeyGuardRestoreFailed  Key = "core.guard.restore_failed"
	KeyGuardUnsupported    Key = "core.guard.unsupported"

	// Probing and diagnostics.
	KeyProbeInvalidEndpoint Key = "core.probe.invalid_endpoint"
	KeyProbeNoEndpoints     Key = "core.probe.no_endpoints"
	KeyProbeTooMany         Key = "core.probe.too_many"
	KeyDiagnosticsFailed    Key = "core.diagnostics.failed"
	KeyDiagnosticsTooLarge  Key = "core.diagnostics.too_large"

	// Generic conditions raised while classifying an error that arrived from
	// the network, the filesystem or the standard library.
	KeyNotFound          Key = "core.generic.not_found"
	KeyNetworkFailed     Key = "core.network.failed"
	KeyNetworkTimeout    Key = "core.network.timeout"
	KeyConnectionRefused Key = "core.network.connection_refused"
	KeyTLSCertificate    Key = "core.tls.certificate"
)

// Entry documents one catalog line. Summary is written for auditors and for
// translators; it is never shown to a user, because the interface owns the
// wording and ships it in its own resources.
type Entry struct {
	Code      Code
	Retryable bool
	Summary   string
}

var catalog = map[Key]Entry{
	// Contract and transport.
	KeyAPIVersionMismatch: {CodeVersionMismatch, false, "the interface and the core speak different contract versions"},
	KeyUnauthenticated:    {CodeUnauthenticated, false, "control-plane authentication failed or the token is stale"},
	KeyPermissionDenied:   {CodePermissionDenied, false, "the caller is authenticated but not allowed to do this"},
	KeyInvalidRequest:     {CodeInvalidArgument, false, "the request is malformed or holds a value the core will not accept"},
	KeyRequestTooLarge:    {CodeResourceExhausted, false, "the request exceeds a documented contract limit"},
	KeyUnknownSession:     {CodeNotFound, false, "the session id is unknown to the core"},
	KeySessionRequired:    {CodeFailedPrecondition, false, "the operation needs an active session"},
	KeySessionBusy:        {CodeFailedPrecondition, true, "another connect or disconnect is already running"},
	KeyInternal:           {CodeInternal, false, "an internal invariant was false, which is a defect"},
	KeyCancelled:          {CodeCancelled, false, "the caller cancelled the request"},
	KeyDeadlineExceeded:   {CodeDeadlineExceeded, true, "the request ran out of its deadline"},

	// Plans.
	KeyPlanEmpty:          {CodeInvalidArgument, false, "the plan has no outbounds"},
	KeyPlanTooLarge:       {CodeResourceExhausted, false, "the plan is larger than the contract allows"},
	KeyPlanOutbounds:      {CodeInvalidArgument, false, "an outbound is missing fields or holds impossible values"},
	KeyPlanDuplicateID:    {CodeInvalidArgument, false, "two outbounds share one id"},
	KeyPlanUnknownTarget:  {CodeInvalidArgument, false, "a rule points at an outbound or group that does not exist"},
	KeyPlanRuleInvalid:    {CodeInvalidArgument, false, "a rule has an unknown type or an unsafe value"},
	KeyPlanTunnel:         {CodeInvalidArgument, false, "the requested tunnel mode is not supported"},
	KeyPlanDNSInvalid:     {CodeInvalidArgument, false, "a resolver address or transport is not usable"},
	KeyPlanBypassInvalid:  {CodeInvalidArgument, false, "a bypass entry is not a domain, address or CIDR"},
	KeyPlanGroupsInvalid:  {CodeInvalidArgument, false, "a group is empty, cyclic or measures latency without a url"},
	KeyPlanTestURLInvalid: {CodeInvalidArgument, false, "the latency test url is not an absolute https url"},

	// Engine.
	KeyEngineBinaryMissing:  {CodeNotFound, false, "the engine binary is not installed for this platform"},
	KeyEngineBinaryUnusable: {CodeInvalidArgument, false, "the engine binary cannot be executed"},
	KeyEngineStartFailed:    {CodeUnavailable, true, "the engine process did not start"},
	KeyEngineApplyFailed:    {CodeInternal, true, "the engine rejected the configuration"},
	KeyEngineStopFailed:     {CodeInternal, true, "the engine did not stop within the grace period"},
	KeyEngineStopped:        {CodeUnavailable, true, "the engine process exited"},
	KeyEngineUnsupported:    {CodeUnsupported, false, "no installed engine provides the features this plan needs"},
	KeyEngineVersionTooOld:  {CodeUnsupported, false, "the installed engine is older than the contract requires"},
	KeyEngineRestartSpent:   {CodeUnavailable, true, "the engine kept dying and the restart budget is spent"},
	KeyEngineOutputDenied:   {CodePermissionDenied, false, "the engine refused to write the requested configuration path"},
	KeyEngineProbeFailed:    {CodeInternal, true, "the engine did not answer its control api"},

	// Subscriptions and import.
	KeySubscriptionEmpty:     {CodeInvalidArgument, false, "the subscription body is empty"},
	KeySubscriptionTooLarge:  {CodeResourceExhausted, false, "the subscription body is larger than the import limit"},
	KeySubscriptionFetch:     {CodeUnavailable, true, "the subscription host could not be reached"},
	KeySubscriptionStatus:    {CodeUnavailable, false, "the subscription host answered with an error status"},
	KeySubscriptionRedirect:  {CodeInvalidArgument, false, "the subscription host redirected somewhere not allowed"},
	KeySubscriptionScheme:    {CodeUnsupported, false, "the subscription reference is not an http or https url"},
	KeySubscriptionFormat:    {CodeUnsupported, false, "no parser claims this payload"},
	KeySubscriptionNoServers: {CodeInvalidArgument, false, "the payload parsed but produced no usable server"},
	KeySubscriptionAllFailed: {CodeUnavailable, true, "every server in the subscription failed to start"},

	// Secret store.
	KeySecretReferenceInvalid: {CodeInvalidArgument, false, "the secret reference is not a well formed opaque id"},
	KeySecretExists:           {CodeAlreadyExists, false, "a secret is already stored under that reference"},
	KeySecretNotFound:         {CodeNotFound, false, "no secret is stored under that reference"},
	KeySecretTooLarge:         {CodeResourceExhausted, false, "the secret is larger than the store allows"},
	KeySecretStoreLocked:      {CodeFailedPrecondition, true, "the secret store is locked by another writer"},
	KeySecretStoreCorrupt:     {CodeInternal, false, "the secret store failed its integrity check"},
	KeySecretStoreUnavailable: {CodeInternal, true, "the secret store cannot be read or written right now"},

	// System guard.
	KeyGuardNeedsElevation: {CodePermissionDenied, false, "changing system settings requires elevation"},
	KeyGuardProxyFailed:    {CodeInternal, true, "the system proxy could not be configured"},
	KeyGuardFirewallFail:   {CodeInternal, true, "the kill switch rules could not be installed"},
	KeyGuardRestoreFailed:  {CodeInternal, true, "system settings could not be restored to their previous state"},
	KeyGuardUnsupported:    {CodeUnsupported, false, "this platform has no implementation for that guard"},

	// Probing and diagnostics.
	KeyProbeInvalidEndpoint: {CodeInvalidArgument, false, "an endpoint has no host or an impossible port"},
	KeyProbeNoEndpoints:     {CodeInvalidArgument, false, "the probe request carries no endpoints"},
	KeyProbeTooMany:         {CodeResourceExhausted, false, "the probe request carries more endpoints than allowed"},
	KeyDiagnosticsFailed:    {CodeInternal, false, "diagnostics could not be collected"},
	KeyDiagnosticsTooLarge:  {CodeResourceExhausted, false, "the diagnostics archive is larger than allowed"},

	// Generic conditions.
	KeyNotFound:          {CodeNotFound, false, "the requested object does not exist"},
	KeyNetworkFailed:     {CodeUnavailable, true, "the network connection failed"},
	KeyNetworkTimeout:    {CodeTimeout, true, "the network did not answer in time"},
	KeyConnectionRefused: {CodeUnavailable, true, "the server refused the connection"},
	KeyTLSCertificate:    {CodeTLS, false, "the peer certificate was untrusted, expired or for another name"},
}

// Lookup returns the catalog entry for a key.
func Lookup(key Key) (Entry, bool) {
	entry, ok := catalog[key]
	return entry, ok
}

// Keys returns every catalog key in sorted order. Contract tests and the
// diagnostics report use it to prove that code and catalog agree.
func Keys() []Key {
	out := make([]Key, 0, len(catalog))
	for key := range catalog {
		out = append(out, key)
	}
	sort.Slice(out, func(i, j int) bool { return out[i] < out[j] })
	return out
}

// DefaultKey reports the catalog key a bare code maps to, so a caller that has
// nothing more specific can build an error from the code alone.
func DefaultKey(code Code) Key {
	for _, key := range Keys() {
		if catalog[key].Code == code {
			return key
		}
	}
	return KeyInternal
}
