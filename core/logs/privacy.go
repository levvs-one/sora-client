package logs

import "regexp"

// Destination shapes found in engine messages: host names, IPv4 and IPv6
// addresses, each with an optional port. Times such as 15:02:43 have two
// colons and are not mistaken for IPv6, which needs three.
var destinationPatterns = []*regexp.Regexp{
	regexp.MustCompile(`\[[0-9A-Fa-f:.]+\](?::\d{1,5})?`),
	regexp.MustCompile(`\b(?:[0-9A-Fa-f]{1,4}:){3,7}[0-9A-Fa-f]{1,4}\b`),
	regexp.MustCompile(`\b\d{1,3}(?:\.\d{1,3}){3}(?::\d{1,5})?\b`),
	regexp.MustCompile(`(?i)\b(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,63}\b(?::\d{1,5})?`),
}

// Destination replaces a hidden host or address.
const Destination = "[destination]"

// HideDestinations replaces every host name and address in a message. It is
// applied to engine messages unless the user asked to record destinations.
func HideDestinations(s string) string {
	for _, p := range destinationPatterns {
		s = p.ReplaceAllString(s, Destination)
	}
	return s
}
