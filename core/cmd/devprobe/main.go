package main

import (
	"context"
	"fmt"
	"net"
	"os"
	"time"

	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
)

func main() {
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()
	conn, err := grpc.NewClient("passthrough:///core", grpc.WithTransportCredentials(insecure.NewCredentials()),
		grpc.WithContextDialer(func(ctx context.Context, _ string) (net.Conn, error) {
			return (&net.Dialer{}).DialContext(ctx, "unix", os.Args[1])
		}))
	if err != nil {
		panic(err)
	}
	c := corev1.NewCoreControlClient(conn)
	v := &corev1.ApiVersion{Major: 1, Minor: 3, MinSupportedMinor: 3}
	h, err := c.Handshake(ctx, &corev1.HandshakeRequest{ClientVersion: v})
	if err != nil {
		panic(err)
	}
	q, err := c.QueryLogs(ctx, &corev1.QueryLogsRequest{ApiVersion: v, ControlAuthenticator: h.GetControlAuthenticator(),
		Filter: &corev1.LogFilter{Pattern: os.Args[2]}, Limit: 40})
	if err != nil {
		panic(err)
	}
	for i := len(q.GetEntries()) - 1; i >= 0; i-- {
		e := q.GetEntries()[i]
		fmt.Println(e.GetLevel(), e.GetSource(), e.GetMessage())
	}
	st, err := c.GetStatus(ctx, &corev1.GetStatusRequest{ApiVersion: v})
	fmt.Printf("status: %v err=%v\n", st.GetStatus().GetConnection(), err)
	if len(os.Args) > 3 && os.Args[3] == "conns" {
		lc, err := c.ListConnections(ctx, &corev1.ListConnectionsRequest{ApiVersion: v, ControlAuthenticator: h.GetControlAuthenticator(), SessionId: st.GetStatus().GetConnection().GetSessionId()})
		fmt.Println("conns err:", err, lc.GetError())
		for _, x := range lc.GetConnections() {
			fmt.Printf("  %s:%d rule=%q chain=%v\n", x.GetHost(), x.GetPort(), x.GetRule(), x.GetChain())
		}
	}
	if len(os.Args) > 3 && os.Args[3] == "connect-proxy" {
		subs, err := c.ListSubscriptions(ctx, &corev1.ListSubscriptionsRequest{ApiVersion: v, ControlAuthenticator: h.GetControlAuthenticator()})
		if err != nil {
			panic(err)
		}
		plan := &corev1.SessionPlan{TunnelMode: corev1.TunnelMode_TUNNEL_MODE_APPLICATION}
		for _, s := range subs.GetSubscriptions() {
			plan.Outbounds = append(plan.Outbounds, s.GetOutbounds()...)
		}
		plan.Routing = &corev1.RoutingOptions{ProxyTarget: plan.Outbounds[0].GetId()}
		r, err := c.Connect(ctx, &corev1.ConnectRequest{ApiVersion: v, ControlAuthenticator: h.GetControlAuthenticator(), SessionPlan: plan})
		fmt.Println("connect:", r.GetStatus().GetConnection().GetValue(), r.GetError(), err)
	}
	if len(os.Args) > 3 && os.Args[3] == "disconnect" {
		d, err := c.Disconnect(ctx, &corev1.DisconnectRequest{ApiVersion: v, ControlAuthenticator: h.GetControlAuthenticator()})
		fmt.Println("disconnect:", d.GetStatus().GetConnection().GetValue(), d.GetError(), err)
	}
}
