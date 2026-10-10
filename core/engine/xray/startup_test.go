package xray

import (
	"net"
	"testing"

	"github.com/levvs-one/sora-client/core/engine/supervise"
)

func TestPrivateTunWaitsForAdapter(t *testing.T) {
	d := &driver{}
	if _, err := d.Handshake(t.Context(), supervise.Runtime{TunDevice: "sora-missing"}); err == nil {
		t.Fatal("private TUN reported ready before its adapter exists")
	}
	interfaces, err := net.Interfaces()
	if err != nil {
		t.Fatal(err)
	}
	for _, iface := range interfaces {
		if iface.Flags&net.FlagLoopback != 0 {
			if _, err := d.Handshake(t.Context(), supervise.Runtime{TunDevice: iface.Name}); err != nil {
				t.Fatal(err)
			}
			return
		}
	}
	t.Fatal("no loopback interface")
}
