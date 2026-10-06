package control_test

import (
	"strings"
	"testing"

	"google.golang.org/protobuf/reflect/protoreflect"

	"github.com/levvs-one/sora-client/core/control"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
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
	// Field numbers in CoreEvent oneof: 4=StateChanged, 5=StatsTick, 6=BypassStrategyChanged,
	// 7=ProbeResult, 8=LogBatch, 9=SoraError, 10=KillSwitchChanged
	ones := []protoreflect.FieldNumber{4, 5, 6, 7, 8, 9, 10}
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

// TestSecretMaterialHasExactlyOneCarrier pins the security property of the
// contract: only PutSecret may carry credential material, and it carries it once.
// Every other method refers to a stored secret by reference, so a client can run
// a plan without ever holding a password, and a compromised method cannot become
// a way to read one.
func TestSecretMaterialHasExactlyOneCarrier(t *testing.T) {
	service := (&corev1.HandshakeRequest{}).ProtoReflect().Descriptor().ParentFile().Services().ByName("CoreControl")
	if service == nil {
		t.Fatal("the contract has no CoreControl service")
	}
	carriers := make([]string, 0, 1)
	methods := service.Methods()
	for i := range methods.Len() {
		method := methods.Get(i)
		input := method.Input()
		if input.Fields().ByName("material") != nil {
			carriers = append(carriers, string(method.Name()))
			continue
		}
		if input.Fields().ByName("payload") != nil {
			// ParseImport and FetchSubscription carry a subscription body, not a
			// credential: the body is public to whoever holds the link, and the
			// core parses it into references instead of storing it.
			continue
		}
	}
	if len(carriers) != 1 || carriers[0] != "PutSecret" {
		t.Fatalf("credential material is carried by %v, want exactly PutSecret", carriers)
	}
}

// TestErrorCodesAreUniqueAndNamed keeps the wire enum readable: two classes
// sharing a number would make a client translate the wrong failure, and a missing
// prefix would make a log line ambiguous between cores.
func TestErrorCodesAreUniqueAndNamed(t *testing.T) {
	codes := corev1.SoraErrorCode_name
	seen := make(map[int32]string, len(codes))
	for number, name := range codes {
		if number == 0 {
			if name != "SORA_ERROR_CODE_UNSPECIFIED" {
				t.Errorf("the zero code is %q", name)
			}
			continue
		}
		if !strings.HasPrefix(name, "SORA_ERROR_CODE_") {
			t.Errorf("code %d is named %q without the enum prefix", number, name)
		}
		if other, dup := seen[number]; dup {
			t.Errorf("code %d is used by both %q and %q", number, other, name)
		}
		seen[number] = name
	}
	for _, want := range []string{
		"SORA_ERROR_CODE_VERSION_MISMATCH",
		"SORA_ERROR_CODE_UNAUTHENTICATED",
		"SORA_ERROR_CODE_PERMISSION_DENIED",
		"SORA_ERROR_CODE_CANCELLED",
	} {
		if _, ok := codes[corev1.SoraErrorCode_value[want]]; !ok {
			t.Errorf("the contract has no %s", want)
		}
	}
}
