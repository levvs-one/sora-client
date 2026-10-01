// Package errs is the error catalog of the Sora core.
//
// Every failure that leaves the core carries three independent things: a
// machine-readable Code, a stable localization Key the interface turns into
// text, and a Detail line that has already passed through the redactor. The
// core never writes user-facing sentences, because wording belongs to the
// interface and only the interface knows the language.
//
// The separation is deliberate and load-bearing. Code answers "what kind of
// failure is this" and drives transport behaviour: retry, back off, or
// refuse. Key answers "what should the reader be told" and is part of the
// public contract, so it changes only together with the contract. Detail
// answers "what happened in this process" and is disposable: it may change
// between releases and nothing ever parses it.
//
// An Error is immutable. The With methods return a copy, so an error can be
// annotated on its way up a call stack and shared without a data race.
package errs

import (
	"errors"
	"fmt"
	"strings"
	"time"
)

// Code is the machine-readable class of a failure. The set is closed: the
// control plane maps every code onto a transport status, so a new class is a
// contract change rather than something that appears at runtime.
type Code string

// Error classes. Each one has a single transport meaning and a single default
// catalog key, so a caller that does not care about wording can build an error
// from the code alone.
const (
	// CodeVersionMismatch marks a caller that speaks a contract version the
	// core cannot serve. It is its own code because the fix is an update on
	// one side, not a corrected request.
	CodeVersionMismatch Code = "version_mismatch"
	// CodeInvalidArgument marks a request the core understood and rejected:
	// an empty identifier, a port out of range, a malformed rule.
	CodeInvalidArgument Code = "invalid_argument"
	// CodeUnauthenticated marks a caller that failed control-plane
	// authentication or presented a stale session token.
	CodeUnauthenticated Code = "unauthenticated"
	// CodePermissionDenied marks a caller that is authenticated but not
	// allowed to perform the operation.
	CodePermissionDenied Code = "permission_denied"
	// CodeNotFound marks a lookup of something the core does not have: an
	// unknown session, an unknown secret reference, a missing engine binary.
	CodeNotFound Code = "not_found"
	// CodeAlreadyExists marks a create that collided with existing state.
	CodeAlreadyExists Code = "already_exists"
	// CodeFailedPrecondition marks an operation that needs a state the core is
	// not in, for example applying a plan while the session is stopping.
	CodeFailedPrecondition Code = "failed_precondition"
	// CodeResourceExhausted marks a request beyond a documented limit, such as
	// a plan with more outbounds than the contract allows.
	CodeResourceExhausted Code = "resource_exhausted"
	// CodeDeadlineExceeded marks work that ran out of its own deadline.
	CodeDeadlineExceeded Code = "deadline_exceeded"
	// CodeCancelled marks work stopped by the caller that asked for it.
	CodeCancelled Code = "cancelled"
	// CodeTimeout marks a network operation that timed out on a connection the
	// core opened itself.
	CodeTimeout Code = "timeout"
	// CodeUnavailable marks a dependency that is not reachable right now: the
	// engine process, a subscription host, a name server.
	CodeUnavailable Code = "unavailable"
	// CodeTLS marks a transport security failure: an untrusted certificate, a
	// name mismatch, a handshake the peer cut off.
	CodeTLS Code = "tls"
	// CodeUnsupported marks input the core deliberately refuses, such as a
	// subscription in a format no parser claims.
	CodeUnsupported Code = "unsupported"
	// CodeInternal marks a bug: an invariant the core believed in was false.
	// Anything classified here is a defect to fix, not a condition to handle.
	CodeInternal Code = "internal"
)

// Error is a catalog error. The zero value is not useful: build one with New,
// Newf or Wrap, or let From classify an error that arrived from elsewhere.
type Error struct {
	code       Code
	key        Key
	detail     string
	cause      error
	retryable  bool
	retryAfter time.Duration
}

// New builds a catalog error. cause may be nil when the failure is the answer
// itself rather than a wrapper around something else; the catalog then decides
// whether the error asks for a retry.
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

// oneLine collapses a detail so that one failure always renders as one log
// line. A cause that carries a newline would otherwise split a log record and
// let a caller forge extra lines in the journal.
func oneLine(s string) string {
	if !strings.ContainsAny(s, "\r\n") {
		return strings.TrimSpace(s)
	}
	return strings.Join(strings.FieldsFunc(s, func(r rune) bool {
		return r == '\n' || r == '\r'
	}), " ")
}

// Newf builds a catalog error whose detail is a formatted message. The result
// is untrusted text: the control plane runs it through the redactor before it
// can reach a client.
func Newf(code Code, key Key, format string, args ...any) *Error {
	return &Error{code: code, key: key, detail: oneLine(fmt.Sprintf(format, args...))}
}

// WithRetry returns a copy of e that asks the caller to retry after d. A
// non-positive d means "retry when the caller is ready", which is the right
// hint for a failure with no natural delay of its own.
func (e *Error) WithRetry(d time.Duration) *Error {
	if e == nil {
		return nil
	}
	c := *e
	c.retryable = true
	c.retryAfter = d
	return &c
}

// WithDetail returns a copy of e whose detail is the given text. It exists for
// the case where the useful context is not in the cause, for example
// "subscription answered 403" where the cause is a bare status error.
func (e *Error) WithDetail(detail string) *Error {
	if e == nil {
		return nil
	}
	c := *e
	c.detail = detail
	return &c
}

// WithoutCause returns a copy of e that keeps the code, the key and the detail
// but drops the cause. The control plane uses it so a wrapped error cannot
// smuggle a file path or an internal type name into a client.
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

// Error renders the catalog line for logs: code, key and detail, never the
// cause chain, so one failure stays one line.
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

// CodeOf reports the catalog class of err, classifying it when err did not
// come from the catalog. It returns an empty Code for a nil error.
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

// KeyOf reports the catalog key of err, classifying it when err did not come
// from the catalog. It returns an empty Key for a nil error.
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

// Retryable reports whether err is a catalog error that asks for a retry,
// looking through the whole wrap chain.
func Retryable(err error) bool {
	var e *Error
	if errors.As(err, &e) {
		return e.retryable
	}
	return false
}

// RetryAfter reports the retry delay err asks for, looking through the wrap
// chain. It returns zero when err is not a retryable catalog error.
func RetryAfter(err error) time.Duration {
	var e *Error
	if errors.As(err, &e) {
		return e.retryAfter
	}
	return 0
}

// Detail returns the detail line of the first catalog error in the chain, or
// the text of err itself when err came from outside the catalog. Callers that
// hand the result to a client must pass it through the redactor first.
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

// Wrap attaches catalog metadata to an error that already exists and keeps it
// as the cause, so errors.Is and errors.As keep working through the chain.
func Wrap(err error, code Code, key Key) *Error {
	if err == nil {
		return nil
	}
	return New(code, key, err)
}
