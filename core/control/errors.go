package control

import (
	"math"
	"time"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/types/known/durationpb"
	"google.golang.org/protobuf/types/known/timestamppb"

	"github.com/levvs-one/sora-client/core/errs"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
)

// Domain failures use SoraError responses. Authentication, version, and
// cancellation failures use gRPC status because the caller cannot use a normal
// response.

// wireCodes maps implementation error classes to the client contract's error
// codes.
var wireCodes = map[errs.Code]corev1.SoraErrorCode{
	errs.CodeVersionMismatch:    corev1.SoraErrorCode_SORA_ERROR_CODE_VERSION_MISMATCH,
	errs.CodeUnauthenticated:    corev1.SoraErrorCode_SORA_ERROR_CODE_UNAUTHENTICATED,
	errs.CodePermissionDenied:   corev1.SoraErrorCode_SORA_ERROR_CODE_PERMISSION_DENIED,
	errs.CodeInvalidArgument:    corev1.SoraErrorCode_SORA_ERROR_CODE_INVALID_ARGUMENT,
	errs.CodeUnsupported:        corev1.SoraErrorCode_SORA_ERROR_CODE_INVALID_ARGUMENT,
	errs.CodeFailedPrecondition: corev1.SoraErrorCode_SORA_ERROR_CODE_FAILED_PRECONDITION,
	errs.CodeNotFound:           corev1.SoraErrorCode_SORA_ERROR_CODE_NOT_FOUND,
	errs.CodeResourceExhausted:  corev1.SoraErrorCode_SORA_ERROR_CODE_RESOURCE_EXHAUSTED,
	errs.CodeDeadlineExceeded:   corev1.SoraErrorCode_SORA_ERROR_CODE_DEADLINE_EXCEEDED,
	errs.CodeTimeout:            corev1.SoraErrorCode_SORA_ERROR_CODE_DEADLINE_EXCEEDED,
	errs.CodeCancelled:          corev1.SoraErrorCode_SORA_ERROR_CODE_CANCELLED,
	errs.CodeUnavailable:        corev1.SoraErrorCode_SORA_ERROR_CODE_UNAVAILABLE,
	errs.CodeTLS:                corev1.SoraErrorCode_SORA_ERROR_CODE_UNAVAILABLE,
	errs.CodeInternal:           corev1.SoraErrorCode_SORA_ERROR_CODE_INTERNAL,
}

// statusCodes maps connection errors to gRPC status codes. Domain errors stay
// in responses.
var statusCodes = map[errs.Code]codes.Code{
	errs.CodeVersionMismatch:  codes.FailedPrecondition,
	errs.CodeUnauthenticated:  codes.Unauthenticated,
	errs.CodePermissionDenied: codes.PermissionDenied,
	errs.CodeCancelled:        codes.Canceled,
	errs.CodeDeadlineExceeded: codes.DeadlineExceeded,
	errs.CodeTimeout:          codes.DeadlineExceeded,
	errs.CodeInternal:         codes.Internal,
}

// transportOnly lists errors returned exclusively as gRPC statuses.
var transportOnly = map[errs.Code]struct{}{
	errs.CodeUnauthenticated:  {},
	errs.CodePermissionDenied: {},
	errs.CodeVersionMismatch:  {},
}

// toWire converts an error to SoraError and masks its detail before it leaves
// the core.
func toWire(err error, mask func(string) string, requestID string) *corev1.SoraError {
	if err == nil {
		return nil
	}
	classified := errs.From(err)
	code, ok := wireCodes[classified.Code()]
	if !ok {
		code = corev1.SoraErrorCode_SORA_ERROR_CODE_INTERNAL
	}
	detail := classified.Detail()
	if mask != nil {
		detail = mask(detail)
	}
	// Use the generic internal key when no translatable error key is
	// available.
	key := string(classified.Key())
	if key == "" {
		key = string(errs.KeyInternal)
	}
	return &corev1.SoraError{
		Code:           code,
		UserMessageKey: key,
		DetailRedacted: detail,
		Retryable:      classified.Retryable(),
		RequestId:      requestID,
		RetryAfter:     durationOrNil(classified.RetryAfter()),
	}
}

// transportStatus returns a gRPC status for transport errors and nil for domain
// errors.
func transportStatus(err error) error {
	if err == nil {
		return nil
	}
	classified := errs.From(err)
	if _, transport := transportOnly[classified.Code()]; !transport {
		return nil
	}
	code, ok := statusCodes[classified.Code()]
	if !ok {
		code = codes.Unknown
	}
	// Status text excludes details because access logs may not redact them.
	return status.Error(code, string(classified.Code())+" "+string(classified.Key()))
}

// durationOrNil returns a wire delay or nil when unset. Zero would incorrectly
// request an immediate retry.
func durationOrNil(d time.Duration) *durationpb.Duration {
	if d <= 0 {
		return nil
	}
	return durationpb.New(d)
}

// timestampOrNil returns a wire timestamp or nil when unset.
func timestampOrNil(at time.Time) *timestamppb.Timestamp {
	if at.IsZero() {
		return nil
	}
	return timestamppb.New(at)
}

// counter clamps non-negative counters to the wire field's range. Negative
// values become zero instead of overflowing.
func counter(value int) uint64 {
	if value <= 0 {
		return 0
	}
	return uint64(value) //nolint:gosec // guarded above, so the value cannot be negative
}

// latency converts a delay to non-negative milliseconds for the wire field.
func latency(value int) uint32 {
	if value <= 0 {
		return 0
	}
	// Compared as int64: on a 32-bit platform an int never exceeds the
	// limit
	// and the constant does not fit in an int.
	if int64(value) > math.MaxUint32 {
		return math.MaxUint32
	}
	return uint32(value)
}
