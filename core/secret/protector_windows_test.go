//go:build windows

package secret

import (
	"bytes"
	"testing"
)

func TestDPAPIKeepsAKeyForThisAccount(t *testing.T) {
	key := bytes.Repeat([]byte{0x5a}, 32)
	wrapped, err := DPAPIProtector{}.Protect(key)
	if err != nil {
		t.Fatalf("protect: %v", err)
	}
	if bytes.Contains(wrapped, key) {
		t.Fatal("the wrapped form carries the key in the clear")
	}
	back, err := DPAPIProtector{}.Unprotect(wrapped)
	if err != nil {
		t.Fatalf("unprotect: %v", err)
	}
	if !bytes.Equal(back, key) {
		t.Fatal("the key came back different")
	}
	wrapped[len(wrapped)-1] ^= 0xff
	if _, err := (DPAPIProtector{}).Unprotect(wrapped); err == nil {
		t.Fatal("a damaged blob was accepted")
	}
}
