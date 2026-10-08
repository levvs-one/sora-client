// Package ipc carries the control API over account-restricted local pipes or
// Unix sockets, with no network ports. Tokens further restrict same-account
// processes. It exposes listeners and connections independently of gRPC so
// transport security and API contracts evolve separately.
package ipc

import (
	"context"
	"net"
	"time"
)

const (
	// handshakeTimeout bounds silent connections before introduction.
	handshakeTimeout = 10 * time.Second
	// dialTimeout bounds a client that cannot reach the endpoint at all.
	dialTimeout = 5 * time.Second
)

// Peer describes the process on the other end of a connection, as far as the
// platform can tell.
type Peer struct {
	// UID is the numeric user that opened the connection. It is zero where
	// the
	// platform has no such concept.
	UID int
	// PID is the process that opened the connection, zero where unknown.
	PID int
	// Verified indicates kernel-confirmed identity. If false, endpoint
	// permissions enforce the transport boundary.
	Verified bool
	// Detail is a short description for a log line, never a user name.
	Detail string
	// Present indicates a Windows peer in the active session or with
	// administrator rights.
	Present bool
}

// Options configures an endpoint.
type Options struct {
	// Address selects the endpoint. Empty uses the platform's standard
	// installation address.
	Address string
	// Group is the unix group allowed to connect, where the platform has
	// one.
	// Empty means the group the core itself runs in.
	Group string
	// Allow selects admitted peers. Nil uses the core user and Group on
	// Unix, or the pipe access list on Windows.
	Allow func(Peer) bool
	// HandshakeTimeout bounds a connection that has not introduced itself.
	HandshakeTimeout time.Duration
}

// Listener is the local endpoint the control plane is served on.
type Listener struct {
	net.Listener
	address string
	options Options
	allow   func(Peer) bool
}

// Listen opens a context-owned endpoint. Cancellation closes the listener even
// when handed directly to a server without a Serve loop.
func Listen(ctx context.Context, opts Options) (*Listener, error) {
	address := opts.Address
	if address == "" {
		address = ListenAddress()
	}
	inner, err := listenLocal(address, opts)
	if err != nil {
		return nil, err
	}
	allow := opts.Allow
	if allow == nil {
		allow = defaultAllow(opts)
	}
	listener := &Listener{
		Listener: inner,
		address:  address,
		options:  opts,
		allow:    allow,
	}
	if ctx != nil && ctx.Done() != nil {
		go func() {
			<-ctx.Done()
			_ = listener.Close()
		}()
	}
	return listener, nil
}

// Address returns the endpoint address for clients and diagnostics.
func (l *Listener) Address() string { return l.address }

// Accept returns the next authorized connection. Checking peers here also
// protects gRPC servers using the listener directly.
func (l *Listener) Accept() (net.Conn, error) {
	for {
		connection, err := l.Listener.Accept()
		if err != nil {
			return nil, err
		}
		if l.allow != nil && !l.allow(peerOf(connection)) {
			// Close unauthorized connections without replying to
			// avoid revealing the core endpoint.
			_ = connection.Close()
			continue
		}
		return connection, nil
	}
}

// Serve runs a handler per admitted connection until cancellation closes the
// endpoint. Direct listener users inherit the same checks through Accept.
func (l *Listener) Serve(ctx context.Context, handle func(context.Context, net.Conn) error) error {
	go func() {
		<-ctx.Done()
		_ = l.Close()
	}()
	for {
		connection, err := l.Accept()
		if err != nil {
			// Intentional listener closure returns cancellation
			// instead of a service failure.
			if ctx.Err() != nil {
				return ctx.Err()
			}
			return err
		}
		go l.dispatch(ctx, connection, handle)
	}
}

// dispatch gives one connection its own context and its introduction budget.
func (l *Listener) dispatch(ctx context.Context, connection net.Conn, handle func(context.Context, net.Conn) error) {
	connectionCtx, cancel := context.WithCancel(ctx)
	defer cancel()
	defer func() { _ = connection.Close() }()
	timeout := l.options.HandshakeTimeout
	if timeout <= 0 {
		timeout = handshakeTimeout
	}
	_ = connection.SetDeadline(time.Now().Add(timeout))
	// Clear the introduction deadline because the handler owns subsequent
	// long-lived streams.
	_ = connection.SetDeadline(time.Time{})
	_ = handle(connectionCtx, connection)
}

// Dial connects to a local endpoint for clients, service self-checks, and
// tests.
func Dial(ctx context.Context, address string) (net.Conn, error) {
	if address == "" {
		address = ListenAddress()
	}
	dialCtx, cancel := context.WithTimeout(ctx, dialTimeout)
	defer cancel()
	return dialLocal(dialCtx, address)
}
