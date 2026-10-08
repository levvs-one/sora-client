// Package control provides API version negotiation and sora/core/v1 contract
// types shared by the UI and core service.
package control

import (
	"fmt"

	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
)

// Negotiate selects the highest minor version supported by both peers.
func Negotiate(client, server *corev1.ApiVersion) (uint32, error) {
	if client == nil || server == nil || client.Major != server.Major {
		return 0, fmt.Errorf("api major version mismatch")
	}
	low := client.MinSupportedMinor
	if server.MinSupportedMinor > low {
		low = server.MinSupportedMinor
	}
	high := client.Minor
	if server.Minor < high {
		high = server.Minor
	}
	if low > high {
		return 0, fmt.Errorf("api minor version mismatch")
	}
	return high, nil
}
