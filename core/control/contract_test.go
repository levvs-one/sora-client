package control_test

import (
	"testing"

	"github.com/levvs-one/sora-client/core/control"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
	"google.golang.org/protobuf/reflect/protoreflect"
)

func TestNegotiate(t *testing.T) {
	tests := []struct {
		name    string
		client  *corev1.ApiVersion
		server  *corev1.ApiVersion
		want    uint32
		wantErr bool
	}{
		{"highest common minor", &corev1.ApiVersion{Major: 1, Minor: 4}, &corev1.ApiVersion{Major: 1, Minor: 3}, 3, false},
		{"minimum bounds", &corev1.ApiVersion{Major: 1, Minor: 4, MinSupportedMinor: 2}, &corev1.ApiVersion{Major: 1, Minor: 3, MinSupportedMinor: 1}, 3, false},
		{"no common minor", &corev1.ApiVersion{Major: 1, Minor: 1}, &corev1.ApiVersion{Major: 1, Minor: 3, MinSupportedMinor: 2}, 0, true},
		{"major mismatch", &corev1.ApiVersion{Major: 1}, &corev1.ApiVersion{Major: 2}, 0, true},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, err := control.Negotiate(tt.client, tt.server)
			if (err != nil) != tt.wantErr || got != tt.want {
				t.Fatalf("Negotiate() = (%d, %v), want (%d, error=%v)", got, err, tt.want, tt.wantErr)
			}
		})
	}
}

func TestCoreEventPayloadKinds(t *testing.T) {
	ones := []protoreflect.FieldNumber{4, 5, 6, 7, 8, 9}
	message := (&corev1.CoreEvent{}).ProtoReflect().Descriptor().Oneofs().Get(0)
	if message.Fields().Len() != len(ones) {
		t.Fatalf("payload has %d fields, want %d", message.Fields().Len(), len(ones))
	}
	for _, number := range ones {
		if message.Fields().ByNumber(number) == nil {
			t.Fatalf("payload field %d is missing", number)
		}
	}
}

func TestSoraErrorIsRedacted(t *testing.T) {
	fields := (&corev1.SoraError{}).ProtoReflect().Descriptor().Fields()
	for i := 0; i < fields.Len(); i++ {
		if fields.Get(i).Name() == "detail" || fields.Get(i).Name() == "raw_detail" {
			t.Fatalf("SoraError contains an unredacted detail field: %s", fields.Get(i).Name())
		}
	}
}
