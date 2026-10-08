// Package tunroute routes non-engine traffic through an engine-created TUN.
// Engine UID traffic stays in the main table to avoid loops; more-specific main
// routes still win. DNS enters TUN even for local resolvers to prevent leaking
// queried names.
package tunroute

import (
	"context"

	"github.com/levvs-one/sora-client/core/engine"
)

// Route sends traffic outside uid through device, replacing earlier routes
// after adapter recreation.
func Route(ctx context.Context, tun engine.Tun, uid int) error { return route(ctx, tun, uid) }

// Unroute removes routing rules and the table. It succeeds when nothing is
// installed.
func Unroute(ctx context.Context) error { return unroute(ctx) }
