//go:build linux

package main

import (
	"context"
	"errors"
	"fmt"
	"io"
	"net"
	"os"
	"strconv"
	"time"

	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/credentials/insecure"
	"google.golang.org/grpc/status"
)

func main() {
	if os.Args[1] == "dns-server" {
		dnsServer()
		return
	}
	if os.Args[1] == "dns" {
		dnsQuery(os.Args[2], os.Args[3], os.Args[4])
		return
	}
	seconds := 0
	if os.Args[2] == "hold" {
		var err error
		seconds, err = strconv.Atoi(os.Args[3])
		must(err)
	}
	ctx, cancel := context.WithTimeout(context.Background(), time.Duration(seconds)*time.Second+30*time.Second)
	defer cancel()
	conn, err := grpc.NewClient("passthrough:///core", grpc.WithTransportCredentials(insecure.NewCredentials()),
		grpc.WithContextDialer(func(ctx context.Context, _ string) (net.Conn, error) {
			return (&net.Dialer{}).DialContext(ctx, "unix", os.Args[1])
		}))
	must(err)
	defer conn.Close()
	c := corev1.NewCoreControlClient(conn)
	api := &corev1.ApiVersion{Major: 1, Minor: 5, MinSupportedMinor: 1}
	h, err := c.Handshake(ctx, &corev1.HandshakeRequest{ClientVersion: api})
	must(err)
	auth := h.GetControlAuthenticator()
	switch os.Args[2] {
	case "connect":
		// Xray JSON exercises provider-profile rendering, the owner's import path.
		payload := `vless://b831381d-6324-4d53-ad4f-8cda48b30811@198.51.100.2:10080?security=none&type=tcp#upstream`
		if os.Args[3] == "xray" {
			payload = `{"remarks":"upstream","outbounds":[{"tag":"proxy","protocol":"vless","settings":{"vnext":[{"address":"198.51.100.2","port":10080,"users":[{"id":"b831381d-6324-4d53-ad4f-8cda48b30811","encryption":"none"}]}]}}]}`
		}
		imported, err := c.ParseImport(ctx, &corev1.ParseImportRequest{ApiVersion: api, Payload: []byte(payload)})
		must(err)
		wire(imported.GetError())
		p := imported.GetSessionPlan()
		p.Engines = []string{os.Args[3]}
		p.NetworkControlAllowed = true
		p.TunnelMode = corev1.TunnelMode_TUNNEL_MODE_SYSTEM
		if os.Args[4] == "proxy" {
			p.TunnelMode = corev1.TunnelMode_TUNNEL_MODE_APPLICATION
		}
		p.Routing = &corev1.RoutingOptions{ProxyTarget: p.GetOutbounds()[0].GetId()}
		p.DnsPolicy = &corev1.DnsPolicy{Servers: []string{"192.168.0.1"}}
		r, err := c.Connect(ctx, &corev1.ConnectRequest{ApiVersion: api, ControlAuthenticator: auth, SessionPlan: p, KillSwitch: len(os.Args) > 5 && os.Args[5] == "kill"})
		must(err)
		wire(r.GetError())
		fmt.Println(r.GetStatus().GetConnection().GetValue())
	case "disconnect":
		r, err := c.Disconnect(ctx, &corev1.DisconnectRequest{ApiVersion: api, ControlAuthenticator: auth})
		must(err)
		wire(r.GetError())
	case "hold":
		start := time.Now()
		ticker := time.NewTicker(time.Second)
		defer ticker.Stop()
		for {
			r, err := c.GetStatus(ctx, &corev1.GetStatusRequest{ApiVersion: api})
			must(err)
			wire(r.GetError())
			if r.GetStatus().GetConnection().GetValue() != corev1.ConnectionStateValue_CONNECTION_STATE_VALUE_CONNECTED {
				panic(fmt.Sprint(r))
			}
			if time.Since(start) >= time.Duration(seconds)*time.Second {
				break
			}
			select {
			case <-ctx.Done():
				panic(ctx.Err())
			case <-ticker.C:
			}
		}
		// State events reveal a restart even if polling missed its short outage.
		watchCtx, stopWatch := context.WithTimeout(ctx, 2*time.Second)
		defer stopWatch()
		watchDeadline, _ := watchCtx.Deadline()
		events, err := c.WatchEvents(watchCtx, &corev1.WatchEventsRequest{ApiVersion: api})
		must(err)
		connected := false
		for {
			event, err := events.Recv()
			if err != nil {
				// The server can finish first at the same deadline and return
				// EOF before the client's context cancellation is scheduled.
				if watchCtx.Err() != nil || status.Code(err) == codes.DeadlineExceeded || errors.Is(err, io.EOF) && !time.Now().Before(watchDeadline) {
					break
				}
				must(err)
			}
			if state := event.GetStateChanged(); state != nil {
				value := state.GetState().GetValue()
				if connected && value != corev1.ConnectionStateValue_CONNECTION_STATE_VALUE_CONNECTED {
					panic(fmt.Sprint(event))
				}
				connected = connected || value == corev1.ConnectionStateValue_CONNECTION_STATE_VALUE_CONNECTED
			}
			if event.GetError() != nil {
				panic(fmt.Sprint(event))
			}
		}
		if !connected {
			panic("no connected event")
		}
		fmt.Printf("connected for %s\n", time.Since(start).Round(time.Second))
	case "logs":
		r, err := c.QueryLogs(ctx, &corev1.QueryLogsRequest{ApiVersion: api, ControlAuthenticator: auth, Limit: 1000})
		must(err)
		wire(r.GetError())
		for _, entry := range r.GetEntries() {
			fmt.Println(entry.GetLevel(), entry.GetSource(), entry.GetMessage())
		}
	}
}

func must(err error) {
	if err != nil {
		panic(err)
	}
}
func wire(err *corev1.SoraError) {
	if err != nil {
		panic(fmt.Sprint(err))
	}
}
