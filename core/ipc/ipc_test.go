package ipc_test

import (
	"context"
	"errors"
	"io"
	"net"
	"path/filepath"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/ipc"
)

// endpointAddress returns an address inside the temporary directory of the test, so
// a test never touches the real endpoint of a running core.
func endpointAddress(t *testing.T) string {
	t.Helper()
	if strings.HasPrefix(ipc.ListenAddress(), `\\.\pipe\`) {
		// A named pipe has no directory, so the name carries the test instead.
		return `\\.\pipe\sora-core-test-` + strings.ReplaceAll(t.Name(), "/", "-")
	}
	return filepath.Join(t.TempDir(), "core.sock")
}

// TestEndpointCarriesAConnection proves the transport works end to end on this
// platform: a listener, a client, a decision about the peer and the bytes.
func TestEndpointCarriesAConnection(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	address := endpointAddress(t)
	listener, err := ipc.Listen(ctx, ipc.Options{Address: address})
	if err != nil {
		t.Fatalf("Listen() error = %v", err)
	}
	if listener.Address() != address {
		t.Errorf("Address() = %q, want %q", listener.Address(), address)
	}

	const payload = "handshake"
	var served sync.WaitGroup
	servedErr := make(chan error, 1)
	served.Add(1)
	go func() {
		defer served.Done()
		servedErr <- listener.Serve(ctx, func(_ context.Context, connection net.Conn) error {
			_, _ = io.WriteString(connection, payload)
			return nil
		})
	}()

	connection, err := ipc.Dial(ctx, address)
	if err != nil {
		t.Fatalf("Dial() error = %v", err)
	}
	defer func() { _ = connection.Close() }()
	buffer := make([]byte, len(payload))
	if _, err := io.ReadFull(connection, buffer); err != nil {
		t.Fatalf("reading from the endpoint: %v", err)
	}
	if string(buffer) != payload {
		t.Errorf("the endpoint carried %q, want %q", buffer, payload)
	}
	cancel()
	// A cancelled serve ends with the context error, which is how a caller knows
	// the endpoint was closed on purpose rather than by a failure.
	if err := <-servedErr; !errors.Is(err, context.Canceled) {
		t.Errorf("Serve() = %v, want the cancellation", err)
	}
	served.Wait()
}

// TestRefusedPeerGetsNothing proves the rule is real: a caller that the allow
// function refuses is closed without a byte, because an answer of any kind tells it
// that a core is listening.
func TestRefusedPeerGetsNothing(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	address := endpointAddress(t)
	listener, err := ipc.Listen(ctx, ipc.Options{
		Address: address,
		Allow:   func(ipc.Peer) bool { return false },
	})
	if err != nil {
		t.Fatalf("Listen() error = %v", err)
	}
	go func() {
		_ = listener.Serve(ctx, func(_ context.Context, connection net.Conn) error {
			t.Error("a refused connection reached the handler")
			_ = connection.Close()
			return nil
		})
	}()

	connection, err := ipc.Dial(ctx, address)
	if err != nil {
		// The kernel may refuse the connection outright, which is the best outcome.
		return
	}
	defer func() { _ = connection.Close() }()
	_ = connection.SetReadDeadline(time.Now().Add(2 * time.Second))
	buffer := make([]byte, 8)
	if _, err := io.ReadFull(connection, buffer); err == nil {
		t.Errorf("a refused peer read %q from the endpoint", buffer)
	} else if !errors.Is(err, io.EOF) && !errors.Is(err, io.ErrUnexpectedEOF) {
		var netErr net.Error
		if !errors.As(err, &netErr) || !netErr.Timeout() {
			t.Errorf("a refused peer got %v, want an end of stream", err)
		}
	}
}

// TestDialFailsFastWhenNothingListens proves a client is told quickly rather than
// hanging on an endpoint that will never answer.
func TestDialFailsFastWhenNothingListens(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()
	if _, err := ipc.Dial(ctx, endpointAddress(t)); err == nil {
		t.Error("Dial() succeeded although nothing is listening")
	}
}
