//go:build !windows

package clashapi

import (
	"context"
	"errors"
	"net"
)

func dialPipe(context.Context, string) (net.Conn, error) {
	return nil, errors.New("clashapi: named pipes exist only on Windows")
}
