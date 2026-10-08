package subscription

import "testing"

func TestAFetchFromTheInternetNeverReachesALocalAddress(t *testing.T) {
	for _, address := range []string{"127.0.0.1:443", "[::1]:443", "10.0.0.5:443", "192.168.1.1:443", "169.254.169.254:80", "[fe80::1]:443", "0.0.0.0:443"} {
		if checkDial(false, address) == nil {
			t.Errorf("%s was dialled for a subscription on the internet", address)
		}
	}
	if err := checkDial(false, "93.184.216.34:443"); err != nil {
		t.Errorf("a public address was refused: %v", err)
	}
	if err := checkDial(true, "192.168.1.1:443"); err != nil {
		t.Errorf("a subscription on the local network could not reach it: %v", err)
	}
}

func TestALocalSubscriptionIsRecognised(t *testing.T) {
	ctx := t.Context()
	for host, want := range map[string]bool{"127.0.0.1": true, "192.168.0.10": true, "localhost": true, "93.184.216.34": false} {
		if got := isPrivateHost(ctx, host); got != want {
			t.Errorf("isPrivateHost(%q) = %v, want %v", host, got, want)
		}
	}
}
