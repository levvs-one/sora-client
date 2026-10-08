package engine

import "encoding/json"

// profileKeys are the fields of an Xray configuration that carry credentials.
var profileKeys = map[string]bool{
	"id": true, "password": true, "pass": true, "user": true, "publicKey": true, "privateKey": true,
	"shortId": true, "preSharedKey": true, "secretKey": true, "spiderX": true, "seed": true,
}

// profileSecrets extracts profile credentials for redacting engine output.
func profileSecrets(raw json.RawMessage) []string {
	if len(raw) == 0 {
		return nil
	}
	var v any
	if json.Unmarshal(raw, &v) != nil {
		return nil
	}
	var out []string
	var walk func(any)
	walk = func(v any) {
		switch x := v.(type) {
		case map[string]any:
			for k, value := range x {
				if s, ok := value.(string); ok && profileKeys[k] {
					out = append(out, s)
					continue
				}
				walk(value)
			}
		case []any:
			for _, value := range x {
				walk(value)
			}
		}
	}
	walk(v)
	return out
}
