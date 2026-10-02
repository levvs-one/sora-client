// Package singbox runs sing-box as a supervised child process and implements
// engine.Engine on top of its HTTP REST API (compatible with Clash API).
package singbox

import (
	"crypto/rand"
	"encoding/hex"
	"net"
)

// FreePort asks the kernel for a free loopback port.
func FreePort() (int, error) {
	ln, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		return 0, err
	}
	port := ln.Addr().(*net.TCPAddr).Port
	_ = ln.Close()
	return port, nil
}

// RandomSecret generates a random secret for the controller API.
func RandomSecret() (string, error) {
	b := make([]byte, 16)
	if _, err := rand.Read(b); err != nil {
		return "", err
	}
	return hex.EncodeToString(b), nil
}
