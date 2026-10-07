// Package tunroute sends the traffic of the machine into a tun adapter that an
// engine created without routes of its own.
//
// Everything not sent by the engine's account goes through a table of its own
// whose default route is the adapter, so the engine's connections to its
// servers keep the main table and never loop back into the tunnel. Routes of
// the main table more specific than the default, the local network among them,
// still win. DNS queries go into the tunnel even when the resolver sits on the
// local network, because the router answering them would see every name.
package tunroute

import "context"

// Route sends everything not sent by uid into device. It replaces whatever an
// earlier call left, so it runs again after the engine restarts and recreates
// its adapter.
func Route(ctx context.Context, device string, uid int) error { return route(ctx, device, uid) }

// Unroute removes the rules and the table; calling it with nothing in place
// succeeds.
func Unroute(ctx context.Context) error { return unroute(ctx) }
