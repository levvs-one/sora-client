// Package soraerr provides the typed, redacted error boundary for Sora core.
package soraerr

import (
	"context"
	"crypto/sha256"
	"crypto/x509"
	"encoding/hex"
	"errors"
	"fmt"
	"net"
	"os"
	"sync"
	"syscall"

	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
)

// Code identifies a safe, user-visible error category.
type Code int32

const (
	CodeUnknown            Code = int32(corev1.SoraErrorCode_SORA_ERROR_CODE_INTERNAL)
	CodeVersionMismatch    Code = int32(corev1.SoraErrorCode_SORA_ERROR_CODE_VERSION_MISMATCH)
	CodeUnauthenticated    Code = int32(corev1.SoraErrorCode_SORA_ERROR_CODE_UNAUTHENTICATED)
	CodeInvalidArgument    Code = int32(corev1.SoraErrorCode_SORA_ERROR_CODE_INVALID_ARGUMENT)
	CodeFailedPrecondition Code = int32(corev1.SoraErrorCode_SORA_ERROR_CODE_FAILED_PRECONDITION)
	CodeNotFound           Code = int32(corev1.SoraErrorCode_SORA_ERROR_CODE_NOT_FOUND)
	CodeResourceExhausted  Code = int32(corev1.SoraErrorCode_SORA_ERROR_CODE_RESOURCE_EXHAUSTED)
	CodeDeadlineExceeded   Code = int32(corev1.SoraErrorCode_SORA_ERROR_CODE_DEADLINE_EXCEEDED)
	CodeUnavailable        Code = int32(corev1.SoraErrorCode_SORA_ERROR_CODE_UNAVAILABLE)
	CodeInternal           Code = int32(corev1.SoraErrorCode_SORA_ERROR_CODE_INTERNAL)
)

// Domain groups catalogue entries.
type Domain string

const (
	DomainConnection  Domain = "Connection"
	DomainNetwork     Domain = "Network"
	DomainPlatform    Domain = "Platform"
	DomainDiagnostics Domain = "Diagnostics"
)

// Severity is the operational importance of an error.
type Severity string

const (
	SeverityInfo     Severity = "Info"
	SeverityWarning  Severity = "Warning"
	SeverityError    Severity = "Error"
	SeverityCritical Severity = "Critical"
)

// Action is the safe recovery action suggested by the catalogue.
type Action string

const (
	ActionNone            Action = "None"
	ActionCheckConnection Action = "CheckConnection"
	ActionChangeServer    Action = "ChangeServer"
	ActionSendReport      Action = "SendReport"
)

// Entry is the canonical metadata for a Code.
type Entry struct {
	Code         Code
	Domain       Domain
	Severity     Severity
	Retryable    bool
	UserTitleKey string
	UserCauseKey string
	Action       Action
}

var entries = map[Code]Entry{
	CodeUnknown:            {CodeUnknown, DomainDiagnostics, SeverityError, false, "errors.internal.title", "errors.internal.cause", ActionSendReport},
	CodeVersionMismatch:    {CodeVersionMismatch, DomainConnection, SeverityError, false, "errors.version_mismatch.title", "errors.version_mismatch.cause", ActionNone},
	CodeUnauthenticated:    {CodeUnauthenticated, DomainConnection, SeverityError, false, "errors.unauthenticated.title", "errors.unauthenticated.cause", ActionChangeServer},
	CodeInvalidArgument:    {CodeInvalidArgument, DomainDiagnostics, SeverityError, false, "errors.invalid_argument.title", "errors.invalid_argument.cause", ActionNone},
	CodeFailedPrecondition: {CodeFailedPrecondition, DomainConnection, SeverityError, false, "errors.failed_precondition.title", "errors.failed_precondition.cause", ActionCheckConnection},
	CodeNotFound:           {CodeNotFound, DomainDiagnostics, SeverityError, false, "errors.not_found.title", "errors.not_found.cause", ActionNone},
	CodeResourceExhausted:  {CodeResourceExhausted, DomainPlatform, SeverityError, true, "errors.resource_exhausted.title", "errors.resource_exhausted.cause", ActionCheckConnection},
	CodeDeadlineExceeded:   {CodeDeadlineExceeded, DomainNetwork, SeverityWarning, true, "errors.deadline_exceeded.title", "errors.deadline_exceeded.cause", ActionCheckConnection},
	CodeUnavailable:        {CodeUnavailable, DomainNetwork, SeverityWarning, true, "errors.unavailable.title", "errors.unavailable.cause", ActionCheckConnection},
	CodeInternal:           {CodeInternal, DomainDiagnostics, SeverityError, false, "errors.internal.title", "errors.internal.cause", ActionSendReport},
}

// Catalog returns the entry for code. Unknown codes use the generic entry.
func Catalog(code Code) Entry {
	if e, ok := entries[code]; ok {
		return e
	}
	return entries[CodeUnknown]
}

// Entries returns a copy of the complete catalogue.
func Entries() []Entry {
	out := make([]Entry, 0, len(entries))
	for _, e := range entries {
		out = append(out, e)
	}
	return out
}

// Error is a classified error with safe detail and an optional cause.
type Error struct {
	code        Code
	detail      string
	cause       error
	fingerprint string
}

// New creates a classified error and redacts its detail before storing it.
func New(code Code, detail string, cause error) *Error {
	return &Error{code: code, detail: DefaultRedaction.Filter(detail), cause: cause}
}

// Wrap classifies a cause and adds safe detail.
func Wrap(cause error, detail string) *Error {
	c := Classify(cause)
	if c == nil {
		return nil
	}
	c.detail = DefaultRedaction.Filter(detail)
	return c
}

// Code returns the error category.
func (e *Error) Code() Code {
	if e == nil {
		return CodeUnknown
	}
	return e.code
}

// Entry returns catalogue metadata for the error.
func (e *Error) Entry() Entry { return Catalog(e.Code()) }

// Detail returns redacted diagnostic detail.
func (e *Error) Detail() string {
	if e == nil {
		return ""
	}
	return e.detail
}

// Fingerprint returns the stable identifier for an unknown cause.
func (e *Error) Fingerprint() string {
	if e == nil {
		return ""
	}
	return e.fingerprint
}

// Error implements error without exposing the raw cause.
func (e *Error) Error() string {
	if e == nil {
		return "<nil>"
	}
	if e.detail == "" {
		return e.Entry().UserCauseKey
	}
	return e.Entry().UserCauseKey + ": " + e.detail
}

// Unwrap implements errors.Unwrap.
func (e *Error) Unwrap() error {
	if e == nil {
		return nil
	}
	return e.cause
}

// Is matches another typed Sora error by code.
func (e *Error) Is(target error) bool { t, ok := target.(*Error); return ok && e.Code() == t.Code() }

// As supports errors.As through the standard library.
func (e *Error) As(target any) bool {
	p, ok := target.(**Error)
	if ok {
		*p = e
		return true
	}
	return false
}

// ToProto converts the error to the wire contract. Only redacted detail is sent.
func (e *Error) ToProto() *corev1.SoraError {
	if e == nil {
		return nil
	}
	entry := e.Entry()
	return &corev1.SoraError{Code: corev1.SoraErrorCode(e.code), UserMessageKey: entry.UserCauseKey, DetailRedacted: e.detail, Retryable: entry.Retryable}
}

var matcherState struct {
	sync.RWMutex
	matchers []func(error) (Code, bool)
}

// RegisterMatcher adds a concurrent-safe classifier extension.
func RegisterMatcher(m func(error) (Code, bool)) {
	if m == nil {
		return
	}
	matcherState.Lock()
	matcherState.matchers = append(matcherState.matchers, m)
	matcherState.Unlock()
}

// Classify maps common Go and OS errors to catalogue codes.
func Classify(err error) *Error {
	if err == nil {
		return nil
	}
	if e, ok := err.(*Error); ok {
		return e
	}
	matcherState.RLock()
	ms := append([]func(error) (Code, bool){}, matcherState.matchers...)
	matcherState.RUnlock()
	for _, m := range ms {
		if code, ok := m(err); ok {
			return New(code, "", err)
		}
	}
	code := CodeInternal
	var dns *net.DNSError
	var op *net.OpError
	var authority x509.UnknownAuthorityError
	switch {
	case errors.Is(err, context.DeadlineExceeded):
		code = CodeDeadlineExceeded
	case errors.Is(err, context.Canceled):
		code = CodeUnavailable
	case errors.Is(err, syscall.ECONNREFUSED), errors.Is(err, syscall.ECONNRESET):
		code = CodeUnavailable
	case errors.Is(err, os.ErrPermission):
		code = CodeUnauthenticated
	case errors.As(err, &authority):
		code = CodeUnauthenticated
	case errors.As(err, &dns), errors.As(err, &op):
		code = CodeUnavailable
	}
	out := New(code, "", err)
	if code == CodeInternal {
		sum := sha256.Sum256([]byte(err.Error()))
		out.fingerprint = hex.EncodeToString(sum[:8])
	}
	return out
}

// MustCode returns code or panics if it is not registered.
func MustCode(code Code) Code {
	if _, ok := entries[code]; !ok {
		panic(fmt.Sprintf("unknown Sora error code %d", code))
	}
	return code
}

var _ error = (*Error)(nil)
