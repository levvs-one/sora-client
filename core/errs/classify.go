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

// From classifies an error that did not come from the catalog and returns it as
// one. An error that is already in the catalog is returned unchanged, so
// calling From twice never loses a specific key.
//
// Two details are deliberately rebuilt rather than copied. A url.Error keeps
// the full request URL, and a subscription URL is a bearer token, so the URL
// never reaches a detail line. A net.OpError keeps the server address, and a
// server address identifies one provider account, so only the operation and
// the cause survive. Both losses are the point: the interface gets a
// meaningful cause and neither the core nor the user learns a secret.
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

// fromURLError classifies the wrapped cause and rebuilds the detail from the
// operation alone. The URL is dropped rather than masked: a redactor that
// half-removes a token is worse than one that never sees it.
func fromURLError(err *url.Error) *Error {
	inner := From(err.Err)
	detail := err.Op
	if inner.Detail() != "" {
		detail += ": " + inner.Detail()
	}
	return &Error{code: inner.code, key: inner.key, detail: detail, retryable: inner.retryable}
}

// fromPathError classifies a filesystem failure and keeps the operation out of
// the detail line. A local path carries the account name of the user, and the
// interface has no reason to learn it.
func fromPathError(err *fs.PathError) *Error {
	inner := From(err.Err)
	detail := err.Op
	if inner.Detail() != "" {
		detail += ": " + inner.Detail()
	}
	return &Error{code: inner.code, key: inner.key, detail: detail, retryable: inner.retryable}
}

// netDetail rebuilds a network error without the addresses it carries.
// net.OpError embeds the local and the remote endpoint, and net.DNSError embeds
// the queried name, which for a subscription is the provider account. The
// operation and the cause survive, so the diagnosis stays intact while neither
// the account nor the layout of the machine leaves the core.
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

// fromCertificateError turns a trust failure into a catalog error with a fixed
// detail line. The detail is written here instead of taken from the cause for
// two reasons at once: an x509 error prints the certificate subject and the
// requested name, which identifies a provider account, and some x509 errors
// panic when rendered without a certificate attached. A privileged service must
// neither leak the name nor die while describing a handshake.
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

// invalidReason names the certificate problems worth telling apart during
// support work. The reasons x509 adds over time fall through to a single
// phrase on purpose: a support engineer needs to know the chain was rejected,
// not which of forty internal reasons fired, and the raw value is a number
// nobody can act on.
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

// isRefused reports whether a peer actively refused the connection, which is a
// different diagnosis from an unreachable network and gets its own message.
func isRefused(err error) bool {
	return errors.Is(err, syscall.ECONNREFUSED)
}

// isNetworkFailure reports whether the error is one of the conditions that mean
// "the path to the server did not work", as opposed to "the server said no".
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
