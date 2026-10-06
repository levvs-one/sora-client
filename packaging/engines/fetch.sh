#!/usr/bin/env bash
# Downloads the engine builds of engines.lock for one architecture, refuses any
# file whose SHA-256 differs from the lock, and lays them out as the core looks
# for them: sing-box, xray, mihomo, geoip.dat and geosite.dat in one directory.
# The geo databases come from the Xray archive, which is pinned like the rest.
#
#   packaging/engines/fetch.sh amd64|arm64 <destination>
set -euo pipefail

arch=${1:?architecture: amd64 or arm64}
dest=${2:?destination directory}
lock="$(dirname "$0")/engines.lock"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir -p "$dest"

found=0
while read -r engine line_arch digest url; do
	[[ -z "$engine" || "$engine" == \#* || "$line_arch" != "$arch" ]] && continue
	found=$((found + 1))
	file="$work/$(basename "$url")"
	curl --fail --location --silent --show-error --retry 3 --proto '=https' --output "$file" "$url"
	echo "$digest  $file" | sha256sum --check --quiet --strict
	case "$engine" in
	sing-box)
		tar --extract --gzip --file "$file" --directory "$work" --wildcards '*/sing-box'
		install -m 0755 "$work"/sing-box-*/sing-box "$dest/sing-box"
		;;
	xray)
		unzip -o -q "$file" xray geoip.dat geosite.dat -d "$work/xray"
		install -m 0755 "$work/xray/xray" "$dest/xray"
		install -m 0644 "$work/xray/geoip.dat" "$work/xray/geosite.dat" "$dest/"
		;;
	mihomo)
		gunzip --stdout "$file" >"$work/mihomo"
		install -m 0755 "$work/mihomo" "$dest/mihomo"
		;;
	*)
		echo "engines.lock: unknown engine $engine" >&2
		exit 1
		;;
	esac
	echo "$engine $arch: verified"
done <"$lock"

if [[ "$found" -ne 3 ]]; then
	echo "engines.lock has $found engines for $arch, expected 3" >&2
	exit 1
fi
