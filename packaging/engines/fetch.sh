#!/usr/bin/env bash
# Downloads the engine builds of engines.lock for one architecture, refuses any
# file whose SHA-256 differs from the lock, and lays them out as the core looks
# for them: sing-box, xray, mihomo, geoip.dat and geosite.dat in one directory.
# The geo databases come from the Xray archive, which is pinned like the rest.
#
#   packaging/engines/fetch.sh amd64|arm64 <destination>
set -euo pipefail

arch=${1:?architecture: amd64, arm64, windows-amd64 or win7-386}
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
	if [[ "$arch" == windows-* || "$arch" == win7-* ]]; then
		# Every Windows build is a zip with one executable named after its
		# engine; Xray's also carries the geo databases.
		unzip -o -q "$file" -d "$work/$engine"
		exe=$(find "$work/$engine" -iname "${engine}*.exe" ! -iname 'wxray.exe' | head -1)
		[[ -n "$exe" ]] || { echo "engines.lock: no executable in $(basename "$url")" >&2; exit 1; }
		install -m 0755 "$exe" "$dest/$engine.exe"
		if [[ "$engine" == xray ]]; then
			install -m 0644 "$work/xray/geoip.dat" "$work/xray/geosite.dat" "$dest/"
		fi
		echo "$engine $arch: verified"
		continue
	fi
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
