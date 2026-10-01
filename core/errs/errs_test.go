package errs_test

import (
	"errors"
	"fmt"
	"sort"
	"strings"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/errs"
)

// declaredCodes lists every code the package defines. The catalog test walks it
// so a new code cannot reach the catalog without also being listed here, which
// is what keeps the set closed and reviewable.
var declaredCodes = []errs.Code{
	errs.CodeVersionMismatch,
	errs.CodeInvalidArgument,
	errs.CodeUnauthenticated,
	errs.CodePermissionDenied,
	errs.CodeNotFound,
	errs.CodeAlreadyExists,
	errs.CodeFailedPrecondition,
	errs.CodeResourceExhausted,
	errs.CodeDeadlineExceeded,
	errs.CodeCancelled,
	errs.CodeTimeout,
	errs.CodeUnavailable,
	errs.CodeTLS,
	errs.CodeUnsupported,
	errs.CodeInternal,
}

func TestCatalogEntriesAreComplete(t *testing.T) {
	known := make(map[errs.Code]struct{}, len(declaredCodes))
	for _, code := range declaredCodes {
		known[code] = struct{}{}
	}
	keys := errs.Keys()
	if len(keys) == 0 {
		t.Fatal("catalog is empty")
	}
	if !sort.SliceIsSorted(keys, func(i, j int) bool { return keys[i] < keys[j] }) {
		t.Fatalf("Keys() is not sorted: %v", keys)
	}
	seen := make(map[errs.Key]struct{}, len(keys))
	for _, key := range keys {
		if _, dup := seen[key]; dup {
			t.Fatalf("duplicate key %q", key)
		}
		seen[key] = struct{}{}
		if !strings.HasPrefix(string(key), "core.") {
			t.Errorf("key %q has no subsystem prefix", key)
		}
		if strings.ToLower(string(key)) != string(key) {
			t.Errorf("key %q is not lowercase", key)
		}
		entry, ok := errs.Lookup(key)
		if !ok {
			t.Errorf("key %q is missing from Lookup", key)
			continue
		}
		if entry.Summary == "" {
			t.Errorf("key %q has no summary", key)
		}
		if _, ok := known[entry.Code]; !ok {
			t.Errorf("key %q uses undeclared code %q", key, entry.Code)
		}
	}
}

func TestEveryCodeHasACatalogKey(t *testing.T) {
	for _, code := range declaredCodes {
		key := errs.DefaultKey(code)
		entry, ok := errs.Lookup(key)
		if !ok {
			t.Errorf("DefaultKey(%q) = %q, which is not in the catalog", code, key)
			continue
		}
		if entry.Code != code {
			t.Errorf("DefaultKey(%q) = %q, which belongs to %q", code, key, entry.Code)
		}
	}
	if got := errs.DefaultKey("no-such-code"); got != errs.KeyInternal {
		t.Errorf("DefaultKey of an unknown code = %q, want %q", got, errs.KeyInternal)
	}
}

func TestNewTakesRetryabilityFromTheCatalog(t *testing.T) {
	retryable := errs.New(errs.CodeUnavailable, errs.KeyEngineStopped, nil)
	if !retryable.Retryable() {
		t.Error("a stopped engine must be retryable, the catalog says so")
	}
	fatal := errs.New(errs.CodeInvalidArgument, errs.KeyPlanEmpty, nil)
	if fatal.Retryable() {
		t.Error("an empty plan cannot be fixed by retrying")
	}
	unknown := errs.New(errs.CodeInternal, errs.Key("core.test.unknown"), nil)
	if unknown.Retryable() {
		t.Error("a key outside the catalog must not invent retryability")
	}
}

func TestDetailStaysOnOneLine(t *testing.T) {
	cause := errors.New("first line\nsecond line\r\nthird")
	err := errs.New(errs.CodeInternal, errs.KeyInternal, cause)
	if strings.ContainsAny(err.Error(), "\r\n") {
		t.Fatalf("rendered error spans lines: %q", err.Error())
	}
	if got, want := err.Detail(), "first line second line third"; got != want {
		t.Errorf("detail = %q, want %q", got, want)
	}
	formatted := errs.Newf(errs.CodeInternal, errs.KeyInternal, "a=%d\nb=%d", 1, 2)
	if got, want := formatted.Detail(), "a=1 b=2"; got != want {
		t.Errorf("formatted detail = %q, want %q", got, want)
	}
}

func TestAnnotationsReturnCopies(t *testing.T) {
	cause := errors.New("boom")
	base := errs.New(errs.CodeUnavailable, errs.KeyEngineStopped, cause)
	withRetry := base.WithRetry(2 * time.Second)
	withDetail := base.WithDetail("subscription answered 403")
	withoutCause := base.WithoutCause()

	if base.Retryable() != withRetry.Retryable() {
		t.Error("WithRetry must not change the base error")
	}
	if !withRetry.Retryable() || withRetry.RetryAfter() != 2*time.Second {
		t.Errorf("WithRetry produced %v/%v", withRetry.Retryable(), withRetry.RetryAfter())
	}
	if base.Detail() != cause.Error() {
		t.Errorf("WithDetail must not change the base error, got %q", base.Detail())
	}
	if got := withDetail.Detail(); got != "subscription answered 403" {
		t.Errorf("detail = %q", got)
	}
	if withoutCause.Cause() != nil {
		t.Error("WithoutCause kept the cause")
	}
	if got := errs.Detail(withoutCause); got != cause.Error() {
		t.Errorf("detail of the cause-free copy = %q", got)
	}
	if base.Cause() != cause {
		t.Error("WithoutCause must not change the base error")
	}
	if errs.RetryAfter(base) != 0 {
		t.Error("the base error must keep a zero retry delay")
	}
}

func TestWrapKeepsTheCauseChain(t *testing.T) {
	sentinel := errors.New("engine exited with status 1")
	err := errs.Wrap(sentinel, errs.CodeUnavailable, errs.KeyEngineStopped)
	if !errors.Is(err, sentinel) {
		t.Error("errors.Is cannot see the cause")
	}
	if err.Cause() != sentinel {
		t.Error("Cause did not return the sentinel")
	}
	if errs.Wrap(nil, errs.CodeInternal, errs.KeyInternal) != nil {
		t.Error("wrapping nil must stay nil")
	}
	var target *errs.Error
	if !errors.As(fmt.Errorf("outer: %w", err), &target) {
		t.Error("errors.As cannot reach the catalog error through a wrapper")
	}
	if target.Code() != errs.CodeUnavailable {
		t.Errorf("code = %q, want %q", target.Code(), errs.CodeUnavailable)
	}
}

func TestPackageHelpersLookThroughTheChain(t *testing.T) {
	if errs.CodeOf(nil) != "" {
		t.Error("CodeOf(nil) must be empty")
	}
	wrapped := fmt.Errorf("outer: %w", errs.Newf(errs.CodeTLS, errs.KeyTLSCertificate, "expired"))
	if got := errs.CodeOf(wrapped); got != errs.CodeTLS {
		t.Errorf("CodeOf = %q, want %q", got, errs.CodeTLS)
	}
	if !errs.Retryable(fmt.Errorf("outer: %w", errs.New(errs.CodeTimeout, errs.KeyNetworkTimeout, nil))) {
		t.Error("Retryable must look through the chain")
	}
	if errs.Retryable(errors.New("plain")) {
		t.Error("a non-catalog error must not claim to be retryable")
	}
	delayed := errs.New(errs.CodeTimeout, errs.KeyNetworkTimeout, nil).WithRetry(5 * time.Second)
	if got := errs.RetryAfter(fmt.Errorf("outer: %w", delayed)); got != 5*time.Second {
		t.Errorf("RetryAfter = %v, want 5s", got)
	}
	if got := errs.Detail(errors.New("plain")); got != "plain" {
		t.Errorf("Detail of a foreign error = %q", got)
	}
}

func TestRenderedErrorNamesTheCatalogLine(t *testing.T) {
	err := errs.Newf(errs.CodeResourceExhausted, errs.KeyRequestTooLarge, "plan is %d bytes", 5<<20)
	want := "resource_exhausted core.request.too_large: plan is 5242880 bytes"
	if got := err.Error(); got != want {
		t.Errorf("Error() = %q, want %q", got, want)
	}
	bare := errs.New(errs.CodeInternal, errs.KeyInternal, nil)
	if got := bare.Error(); got != "internal core.internal.unexpected" {
		t.Errorf("Error() without detail = %q", got)
	}
	if got := (*errs.Error)(nil).Error(); got != "<nil>" {
		t.Errorf("nil error renders as %q", got)
	}
	var nilErr *errs.Error
	if nilErr.Code() != "" || nilErr.Key() != "" || nilErr.Detail() != "" ||
		nilErr.Retryable() || nilErr.RetryAfter() != 0 ||
		nilErr.Cause() != nil || nilErr.Unwrap() != nil {
		t.Error("a nil catalog error must answer every accessor with the zero value")
	}
}
