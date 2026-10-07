package subscription

import (
	"encoding/base64"
	"net/http"
	"testing"
	"time"
)

func TestBodyHeadersFillWhatTheResponseLeftOut(t *testing.T) {
	body := "#profile-title: Body Title\n#profile-update-interval: 6\n//support-url: tg://resolve?domain=help\n" +
		"#subscription-userinfo: upload=1; download=2; total=0; expire=0\nvless://x@h:1#a\n"
	encoded := []byte(base64.StdEncoding.EncodeToString([]byte(body)))
	header := http.Header{}
	header.Set("profile-update-interval", "24")
	info := parseInfo(header, encoded)
	if info.Title != "Body Title" || info.UpdateInterval != 24*time.Hour || info.SupportURL != "tg://resolve?domain=help" {
		t.Fatalf("info = %+v: the header wins, the body fills the rest", info)
	}
	if !info.HasUsage || info.Total != 0 || !info.Expire.IsZero() {
		t.Fatalf("total=0 and expire=0 mean unlimited and never: %+v", info)
	}
}

func TestInfoLimitsWhatAProviderControls(t *testing.T) {
	header := http.Header{}
	header.Set("profile-update-interval", "0")
	header.Set("content-disposition", `attachment; filename="Provider Name.txt"`)
	header.Set("announce", "base64:"+base64.StdEncoding.EncodeToString([]byte("line one\nline two\x07")))
	info := parseInfo(header, []byte("ss://x"))
	if info.UpdateInterval != 0 {
		t.Errorf("an interval of zero hours must be ignored, got %s", info.UpdateInterval)
	}
	if info.Title != "Provider Name" {
		t.Errorf("the file name is the fallback title, got %q", info.Title)
	}
	if info.Announce != "line one\nline two" {
		t.Errorf("announce keeps line breaks and drops control characters, got %q", info.Announce)
	}
	if info.HasUsage {
		t.Error("no usage header means no usage")
	}
}
