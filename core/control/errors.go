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

// The control plane reports failures in two places, and the split is deliberate.
//
// A failure the caller can act on is returned inside the response, in SoraError:
// the interface already holds that response and reads the key from it. A failure
// of the connection itself is returned as a gRPC status: a caller that cannot
// authenticate, cannot speak the contract, or was cancelled never gets far enough
// to read a field. Mixing the two is what makes a client write two error paths,
// so the rule is: domain failures in band, transport failures as a status.

// wireCodes maps a catalog class onto the error code of the contract. The two
// sets are not identical and were not meant to be: the contract speaks to every
// client, the catalog speaks to this implementation.
var wireCodes = map[errs.Code]corev1.SoraErrorCode{
	errs.CodeVersionMismatch:    corev1.SoraErrorCode_SORA_ERROR_CODE_VERSION_MISMATCH,
	errs.CodeUnauthenticated:    corev1.SoraErrorCode_SORA_ERROR_CODE_UNAUTHENTICATED,
	errs.CodePermissionDenied:   corev1.SoraErrorCode_SORA_ERROR_CODE_PERMISSION_DENIED,
	errs.CodeInvalidArgument:    corev1.SoraErrorCode_SORA_ERROR_CODE_INVALID_ARGUMENT,
	errs.CodeUnsupported:        corev1.SoraErrorCode_SORA_ERROR_CODE_INVALID_ARGUMENT,
	errs.CodeFailedPrecondition: corev1.SoraErrorCode_SORA_ERROR_CODE_FAILED_PRECONDITION,
	errs.CodeAlreadyExists:      corev1.SoraErrorCode_SORA_ERROR_CODE_FAILED_PRECONDITION,
	errs.CodeNotFound:           corev1.SoraErrorCode_SORA_ERROR_CODE_NOT_FOUND,
	errs.CodeResourceExhausted:  corev1.SoraErrorCode_SORA_ERROR_CODE_RESOURCE_EXHAUSTED,
	errs.CodeDeadlineExceeded:   corev1.SoraErrorCode_SORA_ERROR_CODE_DEADLINE_EXCEEDED,
	errs.CodeTimeout:            corev1.SoraErrorCode_SORA_ERROR_CODE_DEADLINE_EXCEEDED,
	errs.CodeCancelled:          corev1.SoraErrorCode_SORA_ERROR_CODE_CANCELLED,
	errs.CodeUnavailable:        corev1.SoraErrorCode_SORA_ERROR_CODE_UNAVAILABLE,
	errs.CodeTLS:                corev1.SoraErrorCode_SORA_ERROR_CODE_UNAVAILABLE,
	errs.CodeInternal:           corev1.SoraErrorCode_SORA_ERROR_CODE_INTERNAL,
}

// statusCodes maps a catalog class onto a transport status. Only the classes
// that describe the connection itself get a status; everything else stays in the
// response, so a client does not have to parse a status to show a message.
var statusCodes = map[errs.Code]codes.Code{
	errs.CodeVersionMismatch:  codes.FailedPrecondition,
	errs.CodeUnauthenticated:  codes.Unauthenticated,
	errs.CodePermissionDenied: codes.PermissionDenied,
	errs.CodeCancelled:        codes.Canceled,
	errs.CodeDeadlineExceeded: codes.DeadlineExceeded,
	errs.CodeTimeout:          codes.DeadlineExceeded,
	errs.CodeInternal:         codes.Internal,
}

// transportOnly lists the classes that are never returned inside a response,
// because nobody who could act on it would ever read that response.
var transportOnly = map[errs.Code]struct{}{
	errs.CodeUnauthenticated:  {},
	errs.CodePermissionDenied: {},
	errs.CodeVersionMismatch:  {},
}

// toWire renders err as the error message of the contract. The detail is masked
// first: the core decides what may leave the process, and the control plane is
// the last place where that decision can still be enforced.
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
	// An empty key would leave the interface with nothing to translate, so a
	// failure that lost its key falls back to the generic internal line.
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

// transportStatus renders err as a gRPC status, or nil when the failure belongs
// inside the response instead.
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
	// The status text names the class and the key, never the detail: a status
	// line is written to access logs that nobody masks.
	return status.Error(code, string(classified.Code())+" "+string(classified.Key()))
}

// durationOrNil renders a delay, or nothing when there is none. A zero duration
// in the contract would read as "retry immediately", which is never what the core
// means when it has no opinion.
func durationOrNil(d time.Duration) *durationpb.Duration {
	if d <= 0 {
		return nil
	}
	return durationpb.New(d)
}

// timestampOrNil renders a moment, or nothing when there is none.
func timestampOrNil(at time.Time) *timestamppb.Timestamp {
	if at.IsZero() {
		return nil
	}
	return timestamppb.New(at)
}

// counter narrows a non-negative counter to the width of the contract field.
// The conversion is guarded rather than asserted: a counter that somehow arrived
// negative would otherwise become a number near the top of the range, and a
// client would show an impossible value instead of a wrong one.
func counter(value int) uint64 {
	if value <= 0 {
		return 0
	}
	return uint64(value) //nolint:gosec // guarded above, so the value cannot be negative
}

// latency narrows a measured delay for the contract field, which is in
// milliseconds and cannot hold a negative value.
func latency(value int) uint32 {
	if value <= 0 {
		return 0
	}
	if value > math.MaxUint32 {
		return math.MaxUint32
	}
	return uint32(value)
}
