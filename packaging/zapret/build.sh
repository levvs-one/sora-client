#!/usr/bin/env bash
# Builds tpws and nfqws of the zapret copy in third_party/zapret (bol-van,
# MIT, vendored unchanged) and lays them out next to the engines, with the
# fake handshakes nfqws sends. The build runs in a scratch copy, so the vendored
# tree is never modified. Needs a C compiler, zlib and, for nfqws,
# libnetfilter_queue, libnfnetlink and libmnl headers.
#
#   packaging/zapret/build.sh <engines directory>
set -euo pipefail

dest=${1:?engines directory}
root=$(cd "$(dirname "$0")/../.." && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

cp -r "$root/third_party/zapret" "$work/zapret"
make -C "$work/zapret/tpws" --no-print-directory
make -C "$work/zapret/nfq" --no-print-directory

mkdir -p "$dest/zapret/fake"
install -m 0755 "$work/zapret/tpws/tpws" "$dest/tpws"
install -m 0755 "$work/zapret/nfq/nfqws" "$dest/nfqws"
install -m 0644 "$work/zapret/files/fake/"*.bin "$dest/zapret/fake/"
install -m 0644 "$root/third_party/zapret/docs/LICENSE.txt" "$dest/zapret/LICENSE.txt"
echo "zapret: tpws and nfqws built"
