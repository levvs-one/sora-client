package errs_test

import (
	"context"
	"crypto/tls"
	"crypto/x509"
	"errors"
	"io"
	"io/fs"
	"net"
	"net/url"
	"strings"
	"syscall"
	"testing"

	"github.com/levvs-one/sora-client/core/errs"
)

// timeoutError is a net.Error whose only interesting property is that it timed
// out, which is what the standard library hands back on a stalled dial.
type timeoutError struct{}

func (timeoutError) Error() string   { return "i/o timeout" }
func (timeoutError) Timeout() bool   { return true }
func (timeoutError) Temporary() bool { return true }

func TestFromContext(t *testing.T) {
	cancelled := errs.From(context.Canceled)
	if cancelled.Code() != errs.CodeCancelled || cancelled.Key() != errs.KeyCancelled {
		t.Errorf("context.Canceled classified as %q/%q", cancelled.Code(), cancelled.Key())
	}
	if cancelled.Retryable() {
		t.Error("a cancelled request is not retryable, the caller chose it")
	}
	expired := errs.From(context.DeadlineExceeded)
	if expired.Code() != errs.CodeDeadlineExceeded || expired.Key() != errs.KeyDeadlineExceeded {
		t.Errorf("context.DeadlineExceeded classified as %q/%q", expired.Code(), expired.Key())
	}
	if !expired.Retryable() {
		t.Error("an expired deadline may be retried with a longer one")
	}
}

func TestFromURLErrorKeepsTheTokenOutOfTheDetail(t *testing.T) {
	const token = "eyJhbGciOiJIUzI1NiJ9.super-secret-token"
	raw := &url.Error{
		Op:  "Get",
		URL: "https://provider.example/sub/" + token + "?client=1",
		Err: &net.OpError{Op: "dial", Net: "tcp", Err: timeoutError{}},
	}
	got := errs.From(raw)
	if got.Code() != errs.CodeTimeout {
		t.Errorf("code = %q, want %q", got.Code(), errs.CodeTimeout)
	}
	if got.Key() != errs.KeyNetworkTimeout {
		t.Errorf("key = %q, want %q", got.Key(), errs.KeyNetworkTimeout)
	}
	if !got.Retryable() {
		t.Error("a timed out fetch is retryable")
	}
	if got.Detail() == "" {
		t.Error("the detail lost the operation entirely")
	}
	for _, forbidden := range []string{token, "provider.example", "sub/"} {
		if strings.Contains(got.Detail(), forbidden) {
			t.Errorf("detail %q leaks %q", got.Detail(), forbidden)
		}
	}
	if strings.Contains(got.Error(), token) {
		t.Errorf("rendered error leaks the token: %q", got.Error())
	}
	if got.Cause() != nil {
		t.Error("the url.Error must not stay in the chain, it carries the token")
	}
}

func TestFromCertificateFailures(t *testing.T) {
	unknownAuthority := x509.UnknownAuthorityError{}
	hostname := x509.HostnameError{Host: "provider.example"}
	expired := x509.CertificateInvalidError{Reason: x509.Expired}
	verification := &tls.CertificateVerificationError{Err: unknownAuthority}
	alert := tls.AlertError(42) // the numeric value of a bad certificate alert
	for name, raw := range map[string]error{
		"unknown authority": unknownAuthority,
		"wrong name":        hostname,
		"expired":           expired,
		"verification":      verification,
		"alert":             alert,
	} {
		t.Run(name, func(t *testing.T) {
			got := errs.From(raw)
			if got.Code() != errs.CodeTLS || got.Key() != errs.KeyTLSCertificate {
				t.Errorf("classified as %q/%q, want %q/%q",
					got.Code(), got.Key(), errs.CodeTLS, errs.KeyTLSCertificate)
			}
			if got.Retryable() {
				t.Error("an untrusted certificate is not fixed by retrying")
			}
			if got.Detail() == "" {
				t.Error("the detail is empty, the interface would have nothing to log")
			}
			if strings.Contains(got.Detail(), "provider.example") {
				t.Errorf("detail %q leaks the requested host name", got.Detail())
			}
		})
	}
}

func TestFromNetworkDetailHidesTheAddress(t *testing.T) {
	raw := &net.OpError{
		Op:     "dial",
		Net:    "tcp",
		Source: &net.TCPAddr{IP: net.IPv4(198, 51, 100, 3), Port: 51000},
		Addr:   &net.TCPAddr{IP: net.IPv4(203, 0, 113, 7), Port: 443},
		Err:    syscall.ECONNREFUSED,
	}
	got := errs.From(raw)
	if got.Code() != errs.CodeUnavailable || got.Key() != errs.KeyConnectionRefused {
		t.Errorf("classified as %q/%q, want %q/%q",
			got.Code(), got.Key(), errs.CodeUnavailable, errs.KeyConnectionRefused)
	}
	for _, forbidden := range []string{"203.0.113.7", "198.51.100.3", "443", "51000"} {
		if strings.Contains(got.Detail(), forbidden) {
			t.Errorf("detail %q leaks the address part %q", got.Detail(), forbidden)
		}
	}
	if !strings.Contains(got.Detail(), "dial") {
		t.Errorf("detail %q lost the operation", got.Detail())
	}
}

func TestFromNetworkConditions(t *testing.T) {
	tests := []struct {
		name string
		raw  error
		want errs.Code
		key  errs.Key
	}{
		{"timeout", &net.OpError{Op: "dial", Err: timeoutError{}}, errs.CodeTimeout, errs.KeyNetworkTimeout},
		{"unreachable host", syscall.EHOSTUNREACH, errs.CodeUnavailable, errs.KeyNetworkFailed},
		{"unreachable network", syscall.ENETUNREACH, errs.CodeUnavailable, errs.KeyNetworkFailed},
		{"reset", syscall.ECONNRESET, errs.CodeUnavailable, errs.KeyNetworkFailed},
		{"truncated body", io.ErrUnexpectedEOF, errs.CodeUnavailable, errs.KeyNetworkFailed},
		{"closed connection", net.ErrClosed, errs.CodeUnavailable, errs.KeyNetworkFailed},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := errs.From(tt.raw)
			if got.Code() != tt.want || got.Key() != tt.key {
				t.Errorf("classified as %q/%q, want %q/%q", got.Code(), got.Key(), tt.want, tt.key)
			}
			if !got.Retryable() {
				t.Error("a transport failure is retryable")
			}
		})
	}
}

func TestFromFilesystemFailures(t *testing.T) {
	const path = `C:\Users\somebody\AppData\Local\Sora\secrets.vault`
	missing := errs.From(&fs.PathError{Op: "open", Path: path, Err: fs.ErrNotExist})
	if missing.Code() != errs.CodeNotFound || missing.Key() != errs.KeyNotFound {
		t.Errorf("classified as %q/%q, want %q/%q",
			missing.Code(), missing.Key(), errs.CodeNotFound, errs.KeyNotFound)
	}
	for _, forbidden := range []string{"somebody", "secrets.vault"} {
		if strings.Contains(missing.Detail(), forbidden) {
			t.Errorf("detail %q leaks the local path", missing.Detail())
		}
	}
	denied := errs.From(&fs.PathError{Op: "open", Path: path, Err: fs.ErrPermission})
	if denied.Code() != errs.CodePermissionDenied || denied.Key() != errs.KeyPermissionDenied {
		t.Errorf("classified as %q/%q, want %q/%q",
			denied.Code(), denied.Key(), errs.CodePermissionDenied, errs.KeyPermissionDenied)
	}
}

func TestFromUnknownAndCatalogErrors(t *testing.T) {
	if errs.From(nil) != nil {
		t.Error("From(nil) must be nil")
	}
	unknown := errs.From(errors.New("something nobody described"))
	if unknown.Code() != errs.CodeInternal || unknown.Key() != errs.KeyInternal {
		t.Errorf("classified as %q/%q, want %q/%q",
			unknown.Code(), unknown.Key(), errs.CodeInternal, errs.KeyInternal)
	}
	if unknown.Retryable() {
		t.Error("an undescribed failure is a defect and must not be retried blindly")
	}
	catalog := errs.New(errs.CodeResourceExhausted, errs.KeyRequestTooLarge, errors.New("too big"))
	if errs.From(catalog) != catalog {
		t.Error("From must return a catalog error unchanged")
	}
	if errs.From(errs.From(catalog)) != catalog {
		t.Error("classifying twice must be stable")
	}
}
