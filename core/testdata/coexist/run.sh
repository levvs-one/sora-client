#!/usr/bin/env bash
set -euo pipefail

# Reexec before any network changes. All listeners and routes live in private
# user, PID and network namespaces, including when CI invokes this as root.
if [[ ${1:-} != namespace ]]; then
    repo=$(cd "$(dirname "$0")/../../.." && pwd)
    engines=${SORA_ENGINES_DIR:?set SORA_ENGINES_DIR to installed engines}
    mkdir -p /tmp/claude-1000
    work=$(mktemp -d /tmp/claude-1000/coexist-XXXXXX)
    chmod 755 "$work"
    echo "Artifacts: $work"
    (cd "$repo/core" && go build -o "$work/sora-core" ./cmd/sora-core && go build -o "$work/probe" ./testdata/coexist/probe.go)
    export SORA_COEXIST_HOST_NET=$(readlink /proc/self/ns/net)
    namespace_flags=(-np --mount-proc --fork)
    if [[ $(id -u) != 0 ]]; then namespace_flags+=(--map-auto --map-root-user); fi
    exec unshare "${namespace_flags[@]}" bash "$0" namespace "$work" "$engines"
fi
work=$2
engines=$3
[[ $(readlink /proc/self/ns/net) != "${SORA_COEXIST_HOST_NET:?}" ]]
pids=()
cleanup() {
    for pid in "${pids[@]}"; do kill "$pid" 2>/dev/null || true; done
    wait || true
}
trap cleanup EXIT
ip link set lo up
unshare -n bash -c 'echo $$ > "$1"; exec sleep 3600' _ "$work/server.pid" &
pids+=("$!")
while [[ ! -s "$work/server.pid" ]]; do sleep .1; done
server=$(cat "$work/server.pid")
ip link add uplink type veth peer name peer
ip link set peer netns "$server"
ip addr add 192.168.0.64/24 dev uplink
ip link set uplink up
nsenter -t "$server" -n ip link set lo up
nsenter -t "$server" -n ip addr add 192.168.0.1/24 dev peer
nsenter -t "$server" -n ip link set peer up
nsenter -t "$server" -n ip addr add 198.51.100.2/32 dev lo
nsenter -t "$server" -n ip addr add 203.0.113.80/32 dev lo
nsenter -t "$server" -n ip route add default via 192.168.0.64 dev peer
ip route add default via 192.168.0.1 dev uplink metric 600
# Strict reverse-path filtering on the fake uplink rejects replies when the
# main default points at Happ. Leave Sora's TUN filtering at kernel defaults.
sysctl -qw net.ipv4.conf.all.rp_filter=0 net.ipv4.conf.uplink.rp_filter=0
mkdir "$work/web"
cat /proc/sys/kernel/random/uuid > "$work/web/probe"
nsenter -t "$server" -n python3 -m http.server 8080 --bind 203.0.113.80 --directory "$work/web" > "$work/http.log" 2>&1 &
pids+=("$!")
cat > "$work/server.json" <<'JSON'
{"log":{"loglevel":"debug"},"inbounds":[{"listen":"198.51.100.2","port":10080,"protocol":"vless","settings":{"clients":[{"id":"b831381d-6324-4d53-ad4f-8cda48b30811"}],"decryption":"none"}}],"outbounds":[{"protocol":"freedom"}]}
JSON
nsenter -t "$server" -n "$engines/xray" run -c "$work/server.json" > "$work/server.log" 2>&1 &
pids+=("$!")
for _ in {1..50}; do
    if nsenter -t "$server" -n curl --noproxy '*' -fsS --max-time 1 http://203.0.113.80:8080/probe > /dev/null 2>&1; then break; fi
    sleep .1
 done
cat > "$work/happ.json" <<'JSON'
{"log":{"level":"debug"},"inbounds":[{"type":"tun","interface_name":"happ-xray","address":["172.19.0.1/30"],"auto_route":false,"stack":"mixed"}],"outbounds":[{"type":"direct","tag":"direct","bind_interface":"uplink"}],"route":{"final":"direct"}}
JSON

request() {
    local tag=$1
    shift
    setpriv --reuid 1000 --regid 1000 --clear-groups curl --noproxy '' -fsS --max-time 5 "$@" "http://203.0.113.80:8080/probe?$tag" > "$work/response"
    cmp "$work/web/probe" "$work/response"
    # Verify at the receiving server, not just at the client.
    for _ in {1..20}; do grep -qF "GET /probe?$tag " "$work/http.log" && return; sleep .1; done
    return 1
}

printf 'engine\tmode\tother_vpn\tresult\n' > "$work/results.tsv"
for other in 0 1; do
    if [[ $other == 1 ]]; then
        # A distinct VPN UID proves Sora's own UID exception is insufficient.
        setpriv --reuid 2000 --regid 2000 --clear-groups --inh-caps +net_admin,+net_raw --ambient-caps +net_admin,+net_raw \
            "$engines/sing-box" run -c stdin --disable-color < "$work/happ.json" > "$work/happ.log" 2>&1 &
        pids+=("$!")
        for _ in {1..50}; do ip -4 addr show dev happ-xray 2>/dev/null | grep -q 'inet 172.19.0.1/30' && break; sleep .1; done
        ip route add default dev happ-xray metric 1
        request happ-before
    fi
    for engine in sing-box xray mihomo; do
        for mode in tun proxy; do
            casework="$work/$engine-$mode-$other"
            mkdir "$casework"
            ip -4 rule > "$casework/rules-before4"
            ip -6 rule > "$casework/rules-before6"
            ip -4 route show table main > "$casework/routes-before4"
            ip -6 route show table main > "$casework/routes-before6"
            "$work/sora-core" -socket "$casework/core.sock" -data-dir "$casework/data" -engines-dir "$engines" \
                -allow-file-keys -engine "$engine" -tunnel-port 18080 > "$casework/core.log" 2>&1 &
            core=$!
            pids+=("$core")
            for _ in {1..100}; do [[ -S "$casework/core.sock" ]] && break; sleep .1; done
            probe=("$work/probe" "$casework/core.sock")
            "${probe[@]}" connect "$engine" "$mode" > "$casework/connect.log"
            ip addr > "$casework/addresses"
            ip -4 rule > "$casework/rules4"
            ip -6 rule > "$casework/rules6"
            "${probe[@]}" hold 60 > "$casework/hold.log" 2>&1 &
            hold=$!
            args=()
            [[ $mode == proxy ]] && args+=(--proxy socks5h://127.0.0.1:18080)
            result=PASS
            for sample in {1..6}; do
                upstream_before=$(grep -c 'proxy/vless/inbound: received request for tcp:203.0.113.80:8080' "$work/server.log" || true)
                request "$engine-$mode-$other-$sample" "${args[@]}" || result=FAIL
                upstream_after=$(grep -c 'proxy/vless/inbound: received request for tcp:203.0.113.80:8080' "$work/server.log" || true)
                if (( ${upstream_after:-0} <= ${upstream_before:-0} )); then result=FAIL; fi
                if [[ $other == 1 ]]; then
                    request "$engine-$mode-happ-$sample" --interface 172.19.0.1 || result=FAIL
                    # Happ's forwarded sockets also remain on their bound uplink.
                    request "$engine-$mode-uplink-$sample" --interface uplink || result=FAIL
                fi
                sleep 10
            done
            wait "$hold" || result=FAIL
            "${probe[@]}" logs > "$casework/engine.log"
            "${probe[@]}" disconnect
            ip -4 rule > "$casework/rules-after4"
            ip -6 rule > "$casework/rules-after6"
            ip -4 route show table main > "$casework/routes-after4"
            ip -6 route show table main > "$casework/routes-after6"
            for family in 4 6; do
                cmp "$casework/rules-before$family" "$casework/rules-after$family" || result=FAIL
                cmp "$casework/routes-before$family" "$casework/routes-after$family" || result=FAIL
            done
            if ip link show sora0 > /dev/null 2>&1; then result=FAIL; fi
            if [[ $other == 1 ]]; then request "$engine-$mode-happ-after" --interface 172.19.0.1 || result=FAIL; fi
            kill "$core"
            wait "$core" || true
            unset 'pids[-1]'
            printf '%s\t%s\t%s\t%s\n' "$engine" "$mode" "$other" "$result" | tee -a "$work/results.tsv"
        done
    done
done
! grep -q FAIL "$work/results.tsv"
