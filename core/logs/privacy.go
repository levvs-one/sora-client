package logs

import "regexp"

// Match hosts and IPv4/IPv6 addresses with optional ports. Require three IPv6
// colons to exclude timestamps such as 15:02:43.
var destinationPatterns = []*regexp.Regexp{
	regexp.MustCompile(`\[[0-9A-Fa-f:.]+\](?::\d{1,5})?`),
	regexp.MustCompile(`\b(?:[0-9A-Fa-f]{1,4}:){3,7}[0-9A-Fa-f]{1,4}\b`),
	regexp.MustCompile(`\b\d{1,3}(?:\.\d{1,3}){3}(?::\d{1,5})?\b`),
	regexp.MustCompile(`(?i)\b(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,63}\b(?::\d{1,5})?`),
}

// Destination replaces a hidden host or address.
const Destination = "[destination]"

// HideDestinations masks hosts and addresses unless destination recording is
// enabled.
func HideDestinations(s string) string {
	for _, p := range destinationPatterns {
		s = p.ReplaceAllString(s, Destination)
	}
	return s
}
