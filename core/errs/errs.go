// Package errs defines immutable errors with a machine-readable Code, stable
// localization Key, and redacted Detail. Codes drive transport behavior; keys
// belong to the public contract and clients localize them. Details may change
// and must not be parsed. With methods return copies safe to share.
package errs

import (
	"errors"
	"fmt"
	"strings"
	"time"
)

// Code identifies an error class. The set is closed because new transport
// mappings require a contract change.
type Code string

// Error classes have fixed transport meanings and default catalog keys.
const (
	// CodeVersionMismatch requires a client or core update, not a corrected
	// request.
	CodeVersionMismatch Code = "version_mismatch"
	// CodeInvalidArgument identifies a malformed request such as an invalid
	// ID, port, or rule.
	CodeInvalidArgument Code = "invalid_argument"
	// CodeUnauthenticated marks a caller that failed control-plane
	// authentication or presented a stale session token.
	CodeUnauthenticated Code = "unauthenticated"
	// CodePermissionDenied marks a caller that is authenticated but not
	// allowed to perform the operation.
	CodePermissionDenied Code = "permission_denied"
	// CodeNotFound identifies missing sessions, secret references, or
	// engine binaries.
	CodeNotFound Code = "not_found"
	// CodeFailedPrecondition identifies operations requiring a different
	// core state, such as applying while stopping.
	CodeFailedPrecondition Code = "failed_precondition"
	// CodeResourceExhausted identifies requests exceeding documented
	// limits.
	CodeResourceExhausted Code = "resource_exhausted"
	// CodeDeadlineExceeded marks work that ran out of its own deadline.
	CodeDeadlineExceeded Code = "deadline_exceeded"
	// CodeCancelled marks work stopped by the caller that asked for it.
	CodeCancelled Code = "cancelled"
	// CodeTimeout marks a network operation that timed out on a connection
	// the
	// core opened itself.
	CodeTimeout Code = "timeout"
	// CodeUnavailable identifies an unreachable engine, subscription host,
	// or resolver.
	CodeUnavailable Code = "unavailable"
	// CodeTLS identifies certificate trust, name, or handshake failures.
	CodeTLS Code = "tls"
	// CodeUnsupported identifies intentionally rejected input, such as
	// unknown subscription formats.
	CodeUnsupported Code = "unsupported"
	// CodeInternal identifies a violated invariant requiring a code fix.
	CodeInternal Code = "internal"
)

// Error holds catalog metadata. Its zero value is unusable; construct with New,
// Newf, Wrap, or From.
type Error struct {
	code       Code
	key        Key
	detail     string
	cause      error
	retryable  bool
	retryAfter time.Duration
}

// New creates a catalog error with an optional cause. Catalog metadata
// determines default retry behavior.
func New(code Code, key Key, cause error) *Error {
	e := &Error{code: code, key: key, cause: cause}
	if entry, ok := Lookup(key); ok {
		e.retryable = entry.Retryable
	}
	if cause != nil {
		e.detail = oneLine(cause.Error())
	}
	return e
}

// oneLine collapses detail newlines to prevent forged journal records.
func oneLine(s string) string {
	if !strings.ContainsAny(s, "\r\n") {
		return strings.TrimSpace(s)
	}
	return strings.Join(strings.FieldsFunc(s, func(r rune) bool {
		return r == '\n' || r == '\r'
	}), " ")
}

// Newf creates an error with formatted, untrusted detail. Redact it before
// returning it to a client.
func Newf(code Code, key Key, format string, args ...any) *Error {
	return &Error{code: code, key: key, detail: oneLine(fmt.Sprintf(format, args...))}
}

// WithRetry returns a copy requesting a retry after d. Non-positive d allows
// retry whenever the caller is ready.
func (e *Error) WithRetry(d time.Duration) *Error {
	if e == nil {
		return nil
	}
	c := *e
	c.retryable = true
	c.retryAfter = d
	return &c
}

// WithDetail returns a copy with supplied context absent from the cause, such
// as an HTTP status.
func (e *Error) WithDetail(detail string) *Error {
	if e == nil {
		return nil
	}
	c := *e
	c.detail = detail
	return &c
}

// WithoutCause returns a copy retaining code, key, and detail while dropping
// causes that could expose paths or internal types to clients.
func (e *Error) WithoutCause() *Error {
	if e == nil {
		return nil
	}
	c := *e
	c.cause = nil
	return &c
}

// Code reports the machine-readable class of the failure.
func (e *Error) Code() Code {
	if e == nil {
		return ""
	}
	return e.code
}

// Key reports the stable localization key of the failure.
func (e *Error) Key() Key {
	if e == nil {
		return ""
	}
	return e.key
}

// Detail reports the process-local detail line, which may be empty.
func (e *Error) Detail() string {
	if e == nil {
		return ""
	}
	return e.detail
}

// Retryable reports whether retrying the same operation can plausibly succeed.
func (e *Error) Retryable() bool {
	if e == nil {
		return false
	}
	return e.retryable
}

// RetryAfter reports the delay the core suggests before a retry. It is zero
// when the error is not retryable or when the core has no opinion.
func (e *Error) RetryAfter() time.Duration {
	if e == nil {
		return 0
	}
	return e.retryAfter
}

// Cause reports the wrapped error, or nil when the error is self-contained.
func (e *Error) Cause() error {
	if e == nil {
		return nil
	}
	return e.cause
}

// Error renders code, key, and detail on one log line, excluding the cause
// chain.
func (e *Error) Error() string {
	if e == nil {
		return "<nil>"
	}
	out := string(e.code) + " " + string(e.key)
	if e.detail != "" {
		out += ": " + e.detail
	}
	return out
}

// Unwrap exposes the cause to errors.Is and errors.As.
func (e *Error) Unwrap() error {
	if e == nil {
		return nil
	}
	return e.cause
}

// CodeOf returns an error's class, classifying external errors. Nil returns an
// empty Code.
func CodeOf(err error) Code {
	if err == nil {
		return ""
	}
	var e *Error
	if errors.As(err, &e) {
		return e.code
	}
	return From(err).Code()
}

// KeyOf returns an error's key, classifying external errors. Nil returns an
// empty Key.
func KeyOf(err error) Key {
	if err == nil {
		return ""
	}
	var e *Error
	if errors.As(err, &e) {
		return e.key
	}
	return From(err).Key()
}

// Retryable checks the wrap chain for a catalog error requesting retry.
func Retryable(err error) bool {
	var e *Error
	if errors.As(err, &e) {
		return e.retryable
	}
	return false
}

// RetryAfter returns the catalog retry delay through the wrap chain, or zero
// without a retryable error.
func RetryAfter(err error) time.Duration {
	var e *Error
	if errors.As(err, &e) {
		return e.retryAfter
	}
	return 0
}

// Detail returns the first catalog detail in the chain, or the external error's
// text. Callers must redact it before sending it to clients.
func Detail(err error) string {
	if err == nil {
		return ""
	}
	var e *Error
	if errors.As(err, &e) {
		return e.detail
	}
	return err.Error()
}

// Wrap adds catalog metadata while preserving the cause for errors.Is and
// errors.As.
func Wrap(err error, code Code, key Key) *Error {
	if err == nil {
		return nil
	}
	return New(code, key, err)
}
