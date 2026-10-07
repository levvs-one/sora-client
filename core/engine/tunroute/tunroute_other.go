//go:build !linux

package tunroute

import (
	"context"
	"errors"
)

func route(context.Context, string, int) error {
	return errors.New("tunroute: routing into an adapter is implemented for Linux only")
}

func unroute(context.Context) error { return nil }
