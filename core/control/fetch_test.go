package control_test

import (
	"context"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/control"
	"github.com/levvs-one/sora-client/core/engine"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
	"github.com/levvs-one/sora-client/core/secret"
	"github.com/levvs-one/sora-client/core/session"
	"github.com/levvs-one/sora-client/core/subscription"
)

type recordingFetcher struct{ agent string }

func (f *recordingFetcher) Fetch(_ context.Context, _ string, opts subscription.FetchOptions) (subscription.Result, error) {
	f.agent = opts.UserAgent
	return subscription.Result{
		Body: []byte("vless://b831381d-6324-4d53-ad4f-8cda48b30811@edge.example.com:443?security=none#Edge"),
		Info: subscription.Info{Title: "Provider", UpdateInterval: 12 * time.Hour, HasUsage: true,
			Download: 2048, Total: 4096, Expire: time.Unix(1798761600, 0), SupportURL: "https://t.me/help"},
	}, nil
}

func TestFetchSubscriptionCarriesTheUserAgentAndThePanelInfo(t *testing.T) {
	store, err := secret.Open(t.TempDir(), secret.Options{Protector: secret.FileProtector{}})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = store.Close() })
	auth, err := control.NewAuthenticator(testToken)
	if err != nil {
		t.Fatal(err)
	}
	fetcher := &recordingFetcher{}
	server, err := control.New(control.Config{
		Version: control.Version{Major: 1, Minor: 2, MinSupportedMinor: 1}, Authenticator: auth, Secrets: store, Fetcher: fetcher,
		Sessions: session.NewManager(session.ManagerConfig{
			Factory: func(context.Context, *engine.Plan) (engine.Engine, error) { return newStubEngine(), nil },
		}),
	})
	if err != nil {
		t.Fatal(err)
	}
	got, err := server.FetchSubscription(context.Background(), &corev1.FetchSubscriptionRequest{
		ApiVersion: clientVersion(), Reference: "https://panel.example/sub/token", UserAgent: "Happ/3.2.1",
	})
	if err != nil || got.GetError() != nil {
		t.Fatalf("FetchSubscription = %v, %v", got.GetError(), err)
	}
	if fetcher.agent != "Happ/3.2.1" {
		t.Errorf("user agent = %q", fetcher.agent)
	}
	info := got.GetInfo()
	if len(got.GetOutbounds()) != 1 || info.GetTitle() != "Provider" || info.GetUpdateInterval().AsDuration() != 12*time.Hour ||
		info.GetTotalBytes() != 4096 || info.GetExpire().AsTime().Year() != 2027 || info.GetSupportUrl() != "https://t.me/help" {
		t.Fatalf("response = %v", got)
	}
}
