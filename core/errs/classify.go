package errs

import (
	"context"
	"crypto/tls"
	"crypto/x509"
	"errors"
	"io"
	"io/fs"
	"net"
	"net/url"
	"os"
	"strconv"
	"syscall"
)

// From classifies external errors and preserves existing catalog errors. It
// removes bearer URLs and local/remote addresses from details, retaining
// operations and causes for diagnosis.
func From(err error) *Error {
	if err == nil {
		return nil
	}
	var catalogErr *Error
	if errors.As(err, &catalogErr) {
		return catalogErr
	}
	switch {
	case errors.Is(err, context.Canceled):
		return New(CodeCancelled, KeyCancelled, err)
	case errors.Is(err, context.DeadlineExceeded):
		return New(CodeDeadlineExceeded, KeyDeadlineExceeded, err)
	}
	var urlErr *url.Error
	if errors.As(err, &urlErr) {
		return fromURLError(urlErr)
	}
	var pathErr *fs.PathError
	if errors.As(err, &pathErr) {
		return fromPathError(pathErr)
	}
	if certErr, ok := fromCertificateError(err); ok {
		return certErr
	}
	var netErr net.Error
	if errors.As(err, &netErr) && netErr.Timeout() {
		return New(CodeTimeout, KeyNetworkTimeout, netDetail(err))
	}
	switch {
	case isRefused(err):
		return New(CodeUnavailable, KeyConnectionRefused, netDetail(err))
	case isNetworkFailure(err):
		return New(CodeUnavailable, KeyNetworkFailed, netDetail(err))
	case errors.Is(err, io.ErrUnexpectedEOF):
		return New(CodeUnavailable, KeyNetworkFailed, netDetail(err))
	}
	switch {
	case errors.Is(err, fs.ErrNotExist), os.IsNotExist(err):
		return New(CodeNotFound, KeyNotFound, err)
	case errors.Is(err, fs.ErrPermission), errors.Is(err, os.ErrPermission):
		return New(CodePermissionDenied, KeyPermissionDenied, err)
	}
	return New(CodeInternal, KeyInternal, err)
}

// fromURLError classifies the cause and retains only the operation, excluding
// bearer URLs entirely.
func fromURLError(err *url.Error) *Error {
	inner := From(err.Err)
	detail := err.Op
	if inner.Detail() != "" {
		detail += ": " + inner.Detail()
	}
	return &Error{code: inner.code, key: inner.key, detail: detail, retryable: inner.retryable}
}

// fromPathError classifies filesystem errors without operation or path details
// that may expose account names.
func fromPathError(err *fs.PathError) *Error {
	inner := From(err.Err)
	detail := err.Op
	if inner.Detail() != "" {
		detail += ": " + inner.Detail()
	}
	return &Error{code: inner.code, key: inner.key, detail: detail, retryable: inner.retryable}
}

// netDetail retains network operations and causes while excluding endpoints and
// queried names that identify users or providers.
func netDetail(err error) error {
	var opErr *net.OpError
	if errors.As(err, &opErr) {
		if opErr.Err == nil {
			return errors.New(opErr.Op)
		}
		return &opErrCause{op: opErr.Op, err: opErr.Err}
	}
	var dnsErr *net.DNSError
	if errors.As(err, &dnsErr) {
		if dnsErr.Err == "" {
			return errors.New("lookup")
		}
		return errors.New("lookup: " + dnsErr.Err)
	}
	return err
}

// opErrCause is the address-free rendering of a net.OpError.
type opErrCause struct {
	op  string
	err error
}

func (e *opErrCause) Error() string { return e.op + ": " + e.err.Error() }
func (e *opErrCause) Unwrap() error { return e.err }

// fromCertificateError uses fixed trust-failure details to avoid exposing
// certificate subjects or names. It also avoids x509 formatting panics when
// certificates are absent.
func fromCertificateError(err error) (*Error, bool) {
	var verification *tls.CertificateVerificationError
	if errors.As(err, &verification) {
		return fromCertificateError(verification.Err)
	}
	fail := func(detail string) (*Error, bool) {
		return &Error{code: CodeTLS, key: KeyTLSCertificate, detail: detail}, true
	}
	var unknown x509.UnknownAuthorityError
	if errors.As(err, &unknown) {
		return fail("the certificate is signed by an unknown authority")
	}
	var hostname x509.HostnameError
	if errors.As(err, &hostname) {
		return fail("the certificate is valid for another name")
	}
	var invalid x509.CertificateInvalidError
	if errors.As(err, &invalid) {
		return fail("the certificate is not usable: " + invalidReason(invalid.Reason))
	}
	var insecure x509.InsecureAlgorithmError
	if errors.As(err, &insecure) {
		return fail("the certificate uses an insecure algorithm")
	}
	var record tls.RecordHeaderError
	if errors.As(err, &record) {
		return fail("the peer did not answer with a TLS handshake")
	}
	var alert tls.AlertError
	if errors.As(err, &alert) {
		return fail("the peer aborted the handshake with alert " + strconv.Itoa(int(alert)))
	}
	return nil, false
}

// invalidReason distinguishes supported certificate failures and gives unknown
// future reasons a generic rejection detail.
func invalidReason(reason x509.InvalidReason) string {
	switch reason {
	case x509.Expired:
		return "it expired"
	case x509.NameMismatch:
		return "it is issued for another name"
	case x509.CANotAuthorizedForThisName:
		return "its issuer does not allow this name"
	case x509.NotAuthorizedToSign:
		return "its issuer is not allowed to sign it"
	case x509.IncompatibleUsage:
		return "its usage does not cover this handshake"
	default:
		return "the chain was rejected"
	}
}

// isRefused distinguishes an active connection refusal from an unreachable
// network.
func isRefused(err error) bool {
	return errors.Is(err, syscall.ECONNREFUSED)
}

// isNetworkFailure identifies connectivity failures distinct from server
// refusals.
func isNetworkFailure(err error) bool {
	return errors.Is(err, syscall.ECONNRESET) ||
		errors.Is(err, syscall.EHOSTUNREACH) ||
		errors.Is(err, syscall.ENETUNREACH) ||
		errors.Is(err, syscall.ENETDOWN) ||
		errors.Is(err, syscall.ETIMEDOUT) ||
		errors.Is(err, syscall.EPIPE) ||
		errors.Is(err, syscall.EHOSTDOWN) ||
		errors.Is(err, net.ErrClosed)
}
