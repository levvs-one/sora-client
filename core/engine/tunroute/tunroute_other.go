//go:build !linux

package tunroute

import (
	"context"
	"errors"

	"github.com/levvs-one/sora-client/core/engine"
)

func route(context.Context, engine.Tun, int) error {
	return errors.New("tunroute: routing into an adapter is implemented for Linux only")
}

func unroute(context.Context) error { return nil }

func cleanup(context.Context, engine.Tun) error { return nil }
