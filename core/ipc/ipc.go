// Package ipc carries the control plane between the privileged core and the
// interface on the same machine.
//
// The transport is local by construction: a named pipe on Windows, a unix domain
// socket on Linux and macOS. Neither has a port, neither is reachable from another
// machine, and both can be restricted to the accounts that may talk to a
// privileged process at all. On top of that the core still asks for a token,
// because a restriction by account is not a restriction by program: any process of
// that account may connect, and only the token tells the core that this caller is
// one it has spoken to before.
//
// Nothing here knows about gRPC. The transport is a listener and a connection, and
// the control plane is layered on top, so the security of the local boundary and
// the shape of the API can change independently.
package ipc

import (
	"context"
	"net"
	"time"
)

// Defaults of one endpoint.
const (
	// handshakeTimeout bounds a connection that has not introduced itself. It is
	// short because a real client connects and says something immediately, and a
	// silent connection is either a mistake or a probe.
	handshakeTimeout = 10 * time.Second
	// dialTimeout bounds a client that cannot reach the endpoint at all.
	dialTimeout = 5 * time.Second
)

// Peer describes the process on the other end of a connection, as far as the
// platform can tell.
type Peer struct {
	// UID is the numeric user that opened the connection. It is zero where the
	// platform has no such concept.
	UID int
	// PID is the process that opened the connection, zero where unknown.
	PID int
	// Verified reports whether the platform confirmed the identity from the kernel.
	// Where it is false, the boundary is the permission on the endpoint itself,
	// which is why this package is careful about that permission.
	Verified bool
	// Detail is a short description for a log line, never a user name.
	Detail string
	// Present reports, on Windows, that the peer is the person at the machine:
	// its process runs in the active session, or with administrator rights.
	Present bool
}

// Options configures an endpoint.
type Options struct {
	// Address is where the endpoint listens. Empty means the address of this
	// platform, which is the only value a normal installation uses.
	Address string
	// Group is the unix group allowed to connect, where the platform has one.
	// Empty means the group the core itself runs in.
	Group string
	// Allow decides which peers may connect. Empty means the platform default:
	// on unix the user of the core and the members of Group, on Windows the
	// access list of the pipe.
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

// Listen opens the local endpoint.
//
// The endpoint belongs to the context: when the service context ends the listener
// closes, whoever is serving it. A caller that hands the listener to a server
// instead of calling Serve has no serve loop of its own to watch the context, and
// an endpoint that outlives its service is an endpoint a stopped core still
// answers on.
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

// Address returns the address this endpoint listens on, which is what a client
// needs and what a diagnostics line should show.
func (l *Listener) Address() string { return l.address }

// Accept takes the next connection that is allowed to talk to this endpoint.
//
// The decision is made here rather than in a serve loop, because a serve loop is
// not the only consumer: a gRPC server takes the listener itself, and a boundary
// that only exists in one of the two paths is a boundary that will be bypassed.
func (l *Listener) Accept() (net.Conn, error) {
	for {
		connection, err := l.Listener.Accept()
		if err != nil {
			return nil, err
		}
		if l.allow != nil && !l.allow(peerOf(connection)) {
			// A refused connection is closed without a reply: an endpoint that
			// answers an unauthorised caller has already told it that a core is here.
			_ = connection.Close()
			continue
		}
		return connection, nil
	}
}

// Serve accepts connections until the context ends and then closes the endpoint.
// It is the simple shape, for a caller that wants a handler per connection; a gRPC
// server takes the listener itself and inherits the same peer rule through Accept.
func (l *Listener) Serve(ctx context.Context, handle func(context.Context, net.Conn) error) error {
	go func() {
		<-ctx.Done()
		_ = l.Close()
	}()
	for {
		connection, err := l.Accept()
		if err != nil {
			// An endpoint that was closed on purpose ends the serve loop with the
			// cancellation: a shutdown is not a failure.
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
	// The deadline covers only the introduction; the handler owns the connection
	// from here, and a long lived stream must not carry a stale deadline.
	_ = connection.SetDeadline(time.Time{})
	_ = handle(connectionCtx, connection)
}

// Dial opens a client connection to an endpoint. It is used by the interface, by
// the self test of the service and by the tests of this package.
func Dial(ctx context.Context, address string) (net.Conn, error) {
	if address == "" {
		address = ListenAddress()
	}
	dialCtx, cancel := context.WithTimeout(ctx, dialTimeout)
	defer cancel()
	return dialLocal(dialCtx, address)
}
