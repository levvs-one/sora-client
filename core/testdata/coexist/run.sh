#!/usr/bin/env bash
set -euo pipefail

# Reexec before any network changes. All listeners and routes live in private
# user, PID and network namespaces, including when CI invokes this as root.
if [[ ${1:-} != namespace ]]; then
    repo=$(cd "$(dirname "$0")/../../.." && pwd)
    engines=${SORA_ENGINES_DIR:?set SORA_ENGINES_DIR to installed engines}
    # SORA_COEXIST_WORK keeps artifacts somewhere that outlives a cleaned /tmp.
    base=${SORA_COEXIST_WORK:-${TMPDIR:-/tmp}}
    mkdir -p "$base"
    work=$(mktemp -d "$base/coexist-XXXXXX")
    chmod 755 "$work"
    export TMPDIR="$work"
    echo "Artifacts: $work"
    (cd "$repo/core" && go build -o "$work/sora-core" ./cmd/sora-core && go build -o "$work/probe" ./testdata/coexist)
    if [[ -n ${SORA_COEXIST_CORE:-} ]]; then cp "$SORA_COEXIST_CORE" "$work/sora-core"; fi
    cp "$0" "$work/run.sh"
    export SORA_COEXIST_HOST_NET=$(readlink /proc/self/ns/net)
    namespace_flags=(-np --mount-proc --fork)
    if [[ $(id -u) != 0 ]]; then namespace_flags+=(--map-auto --map-root-user); fi
    exec unshare "${namespace_flags[@]}" bash "$work/run.sh" namespace "$work" "$engines"
fi
work=$2
engines=$3
[[ $(readlink /proc/self/ns/net) != "${SORA_COEXIST_HOST_NET:?}" ]]
seconds=${SORA_COEXIST_SECONDS:-60}
pids=()
cleanup() {
    for pid in "${pids[@]}"; do kill -CONT "$pid" 2>/dev/null || true; kill "$pid" 2>/dev/null || true; done
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
ip link set uplink addrgenmode none
ip link set uplink up
nsenter -t "$server" -n ip link set lo up
nsenter -t "$server" -n ip addr add 192.168.0.1/24 dev peer
nsenter -t "$server" -n ip link set peer up
nsenter -t "$server" -n ip addr add 198.51.100.2/32 dev lo
nsenter -t "$server" -n ip addr add 203.0.113.80/32 dev lo
nsenter -t "$server" -n ip addr add 192.168.44.1/32 dev lo
ip route add 192.168.44.0/24 via 192.168.0.1 dev uplink
nsenter -t "$server" -n ip route add default via 192.168.0.64 dev peer
ip route add default via 192.168.0.1 dev uplink metric 600
# A foreign rule at our priorities must survive every cleanup.
for family in 4 6; do
    ip -"$family" rule add fwmark 0x7000 lookup 7000 priority 5333 protocol 99
done
# Strict reverse-path filtering on the fake uplink rejects replies when the
# main default points at Happ. Leave Sora's TUN filtering at kernel defaults.
sysctl -qw net.ipv4.conf.all.rp_filter=0 net.ipv4.conf.uplink.rp_filter=0
mkdir "$work/web"
cat /proc/sys/kernel/random/uuid > "$work/web/probe"
nsenter -t "$server" -n python3 -m http.server 8080 --bind 0.0.0.0 --directory "$work/web" > "$work/http.log" 2>&1 &
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
nsenter -t "$server" -n "$work/probe" dns-server > "$work/dns.log" 2>&1 &
pids+=("$!")
cat > "$work/happ.json" <<'JSON'
{"log":{"level":"debug"},"inbounds":[{"type":"tun","interface_name":"happ-xray","address":["172.19.0.1/30"],"auto_route":false,"stack":"mixed"}],"outbounds":[{"type":"direct","tag":"direct","bind_interface":"uplink"}],"route":{"final":"direct"}}
JSON

request() {
    local tag=$1
    shift
    setpriv --reuid 1000 --regid 1000 --clear-groups curl --noproxy '' -fsS --max-time 5 "$@" "http://203.0.113.80:8080/probe?$tag" > "$work/response" || return 1
    cmp "$work/web/probe" "$work/response" || return 1
    # Verify at the receiving server, not just at the client.
    for _ in {1..20}; do grep -qF "GET /probe?$tag " "$work/http.log" && return; sleep .1; done
    return 1
}

snapshot() {
    local prefix=$1
    for family in 4 6; do
        ip -"$family" rule > "$prefix-rules$family"
        ip -"$family" route show table all > "$prefix-routes$family"
    done
}
restored() {
    snapshot "$casework/after"
    for family in 4 6; do
        cmp "$casework/before-rules$family" "$casework/after-rules$family" || return 1
        cmp "$casework/before-routes$family" "$casework/after-routes$family" || return 1
    done
}
start_core() {
    rm -f "$casework/core.sock"
    "$work/sora-core" -socket "$casework/core.sock" -data-dir "$casework/data" -engines-dir "$engines" \
        -allow-file-keys -engine "$engine" -tunnel-port 18080 >> "$casework/core.log" 2>&1 &
    core=$!
    pids+=("$core")
    for _ in {1..100}; do [[ -S "$casework/core.sock" ]] && return; sleep .1; done
    return 1
}
# A receiver-side prerouting counter sees packets even when the destination
# has no listener. It cannot mistake a refused connection for a blocked leak.
observe() {
    local expression=$1
    nsenter -t "$server" -n nft delete table inet observe 2>/dev/null || true
    nsenter -t "$server" -n nft -f - <<NFT
 table inet observe {
    chain incoming { type filter hook prerouting priority filter; $expression counter comment "leak"; }
 }
NFT
}
no_leak() {
    nsenter -t "$server" -n nft list table inet observe | tee -a "$casework/packets"
    nsenter -t "$server" -n nft list table inet observe | grep -q 'counter packets 0 bytes 0'
}
regressions() {
    local engine=$1 other=$2 core children adapter peer fake result
    casework="$work/regression-$engine-$other"
    mkdir "$casework"
    snapshot "$casework/before"
    # Positive controls prove the same bound client reaches the receiver with
    # filtering off. TCP needs only a SYN, not a second DNS server.
    for transport in udp tcp; do
        observe "ip saddr 192.168.0.64 ip daddr 192.168.0.1 $transport sport 15353 $transport dport 53"
        setpriv --reuid 1000 --regid 1000 --clear-groups "$work/probe" dns "$transport" uplink "control-$engine-$other.example." > "$casework/control-$transport" 2>&1 || true
        nsenter -t "$server" -n nft list table inet observe > "$casework/control-packets-$transport"
        if grep -q 'counter packets 0 bytes 0' "$casework/control-packets-$transport"; then
            echo "Bound DNS positive control failed: $engine/$other/$transport"
            return 1
        fi
    done
    start_core
    probe=("$work/probe" "$casework/core.sock")
    "${probe[@]}" connect "$engine" tun kill > "$casework/connect.log"
    snapshot "$casework/connected"
    ip -j addr show dev sora0 > "$casework/connected-addresses"
    # A duplicate service and diagnostic invocations must leave live routing
    # and addresses intact, even with a distinct data directory.
    if [[ -z ${SORA_COEXIST_CORE:-} ]]; then
        if timeout 10 "$work/sora-core" -socket "$casework/core.sock" -data-dir "$casework/second-data" \
            -engines-dir "$engines" -allow-file-keys > "$casework/second-start.log" 2>&1; then
            echo "Second service start unexpectedly succeeded"
            return 1
        fi
        grep -q 'another instance owns' "$casework/second-start.log"
        for diagnostic in check version print-token; do
            "$work/sora-core" -"$diagnostic" -socket "$casework/core.sock" -data-dir "$casework/data" \
                -engines-dir "$engines" -allow-file-keys > /dev/null
        done
        snapshot "$casework/diagnosed"
        for family in 4 6; do
            cmp "$casework/connected-rules$family" "$casework/diagnosed-rules$family"
            cmp "$casework/connected-routes$family" "$casework/diagnosed-routes$family"
        done
        ip -j addr show dev sora0 > "$casework/diagnosed-addresses"
        cmp "$casework/connected-addresses" "$casework/diagnosed-addresses"
        if [[ $other == none ]]; then request "$engine-startup-preserved-$other"; fi
        printf '%s\tstartup-preserved\t%s\tPASS\n' "$engine" "$other" | tee -a "$work/results.tsv"
    fi
    nft list ruleset > "$casework/firewall"
    result=PASS
    for transport in udp tcp; do
        observe "ip saddr 192.168.0.64 ip daddr 192.168.0.1 $transport sport 15353 $transport dport 53"
        setpriv --reuid 1000 --regid 1000 --clear-groups "$work/probe" dns "$transport" uplink "bound-$engine-$other.example." > "$casework/dns-$transport" 2>&1 || true
        no_leak || result=FAIL
    done
    printf '%s\tbound-dns\t%s\t%s\n' "$engine" "$other" "$result" | tee -a "$work/results.tsv"
    adapter=$(ip -o -4 addr show dev sora0 | awk '{print $4}' | head -1)
    peer=$(python3 -c 'import ipaddress,sys; print(ipaddress.ip_interface(sys.argv[1]).ip+1)' "$adapter")
    fake=198.18.0.5
    [[ $adapter == 172.* ]] && fake="${adapter%.*.*}.0.5"
    printf 'adapter=%s peer=%s fake=%s\n' "$adapter" "$peer" "$fake" > "$casework/destinations"
    # Freeze only our core to keep the adapter down for the entire test,
    # including the supervisor restart delay.
    kill -STOP "$core"
    children=$(pgrep -P "$core")
    [[ -n $children ]]
    kill -KILL $children
    # A loaded machine can take several seconds to tear the adapter down.
    for _ in {1..150}; do ip link show sora0 > /dev/null 2>&1 || break; sleep .1; done
    result=PASS
    if ip link show sora0 > /dev/null 2>&1; then result=FAIL; fi
    observe "ip daddr { $fake, $peer, 172.19.0.5 }"
    for destination in "$fake" "$peer" 172.19.0.5; do
        setpriv --reuid 1000 --regid 1000 --clear-groups curl --noproxy '*' --max-time 1 "http://$destination:8080/" > /dev/null 2>&1 || true
        # Even the otherwise exempt engine UID must not release cached tunnel
        # destinations through the physical interface.
        curl --noproxy '*' --max-time 1 "http://$destination:8080/" > /dev/null 2>&1 || true
    done
    no_leak || result=FAIL
    printf '%s\tengine-crash\t%s\t%s\n' "$engine" "$other" "$result" | tee -a "$work/results.tsv"
    # Resume and disconnect to lift this session's firewall, then reproduce
    # a service crash without a kill switch to isolate stale route recovery.
    kill -CONT "$core"
    "${probe[@]}" disconnect
    kill "$core"
    wait "$core" || true
    restored || return 1
    start_core
    "${probe[@]}" connect "$engine" tun > "$casework/crash-connect.log"
    kill -STOP "$core"
    children=$(pgrep -P "$core")
    [[ -n $children ]]
    kill -KILL "$core" $children
    wait "$core" || true
    # A loaded machine can take several seconds to tear the adapter down.
    for _ in {1..150}; do ip link show sora0 > /dev/null 2>&1 || break; sleep .1; done
    if ip link show sora0 > /dev/null 2>&1; then echo "Crashed adapter still exists"; return 1; fi
    snapshot "$casework/crashed"
    start_core
    snapshot "$casework/restarted"
    "${probe[@]}" connect "$engine" proxy > "$casework/proxy-connect.log"
    local ready=false
    for attempt in {1..20}; do
        if request "$engine-proxy-restarted-$other-$attempt" --proxy socks5h://127.0.0.1:18080; then ready=true; break; fi
        sleep .1
    done
    [[ $ready == true ]]
    "${probe[@]}" disconnect
    result=PASS
    restored || result=FAIL
    printf '%s\tcore-crash\t%s\t%s\n' "$engine" "$other" "$result" | tee -a "$work/results.tsv"
    kill "$core"
    wait "$core" || true
    # Isolate later reproductions on the unfixed build too. These are exactly
    # Sora's reserved priorities/table, inside this disposable namespace.
    if [[ -n ${SORA_COEXIST_CORE:-} ]]; then
        for family in 4 6; do
            for priority in {5333..5339}; do
                for table in main 5340; do
                    while ip -"$family" rule del priority "$priority" table "$table" 2>/dev/null; do :; done
                done
            done
            ip -"$family" route flush table 5340 2>/dev/null || true
        done
    fi
}

printf 'engine\tmode\tother_vpn\tresult\n' > "$work/results.tsv"
if [[ -z ${SORA_COEXIST_CORE:-} ]]; then
    # Simulate an upgrade after an old core crash. Preserve a foreign address,
    # a foreign rule at the same priority, and another engine's table 2022.
    casework="$work/legacy-recovery"
    engine=sing-box
    mkdir "$casework"
    ip link add sora0 type dummy
    ip link set sora0 addrgenmode none
    ip link set sora0 up
    ip addr add 100.64.0.1/32 dev sora0
    ip route add 203.0.113.1/32 via 192.168.0.1 table 2022
    for family in 4 6; do
        ip -"$family" rule add fwmark 0x7000 oif uplink lookup main priority 5333 protocol 99
        ip -"$family" rule add fwmark 0x7001 oif lo lookup main priority 5333 protocol 2
        ip -"$family" rule add oif lo lookup main priority 5333 protocol 2
    done
    snapshot "$casework/before"
    ip addr add 172.20.0.1/30 dev sora0
    ip -6 addr add fdfe:dcba:9877::1/126 dev sora0 nodad
    for family in 4 6; do
        ip -"$family" rule add oif uplink lookup main priority 5333 protocol 2
        ip -"$family" rule add uidrange 0-0 lookup main priority 5336
        ip -"$family" rule add iif lo ipproto udp dport 53 lookup 5340 priority 5337
        ip -"$family" rule add iif lo lookup main suppress_prefixlength 0 priority 5338
        ip -"$family" rule add iif lo lookup 5340 priority 5339
        ip -"$family" route add default dev sora0 table 5340
    done
    ip -4 rule add from 172.19.0.1 lookup main priority 5334
    ip -4 rule add from 172.20.0.1 lookup 5340 priority 5335
    ip -6 rule add from fdfe:dcba:9877::1 lookup 5340 priority 5335
    ip -6 rule add oif sora0 lookup 2022 priority 32765
    start_core
    "$work/probe" "$casework/core.sock" connect "$engine" proxy > "$casework/connect.log"
    "$work/probe" "$casework/core.sock" disconnect
    restored
    kill "$core"
    wait "$core" || true
    ip link del sora0
    for family in 4 6; do
        ip -"$family" rule del fwmark 0x7000 oif uplink lookup main priority 5333 protocol 99
        ip -"$family" rule del fwmark 0x7001 oif lo lookup main priority 5333 protocol 2
        ip -"$family" rule del oif lo lookup main priority 5333 protocol 2
    done
    ip route del 203.0.113.1/32 table 2022
    printf 'sing-box\tlegacy-recovery\tnone\tPASS\n' | tee -a "$work/results.tsv"
fi
for other in ${SORA_COEXIST_VPNS:-none happ openvpn}; do
    case "$other" in none|happ|openvpn) ;; *) echo "Unknown VPN variant: $other"; exit 1 ;; esac
    if [[ $other != none ]]; then
        # A distinct VPN UID proves Sora's own UID exception is insufficient.
        setpriv --reuid 2000 --regid 2000 --clear-groups --inh-caps +net_admin,+net_raw --ambient-caps +net_admin,+net_raw \
            "$engines/sing-box" run -c stdin --disable-color < "$work/happ.json" > "$work/happ.log" 2>&1 &
        foreign=$!
        pids+=("$foreign")
        for _ in {1..50}; do ip -4 addr show dev happ-xray 2>/dev/null | grep -q 'inet 172.19.0.1/30' && break; sleep .1; done
        if [[ $other == happ ]]; then
            ip route add default dev happ-xray metric 1
        else
            ip route add 0.0.0.0/1 dev happ-xray
            ip route add 128.0.0.0/1 dev happ-xray
        fi
        request happ-before
    fi
    for engine in sing-box xray mihomo; do
        for mode in tun proxy; do
            casework="$work/$engine-$mode-$other"
            mkdir "$casework"
            snapshot "$casework/before"
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
            args=()
            [[ $mode == proxy ]] && args+=(--proxy socks5h://127.0.0.1:18080)
            # Controller readiness can precede the listener's first usable
            # outbound. Require a real response before timed sampling.
            ready=false
            for attempt in {1..20}; do
                if request "$engine-$mode-$other-ready-$attempt" "${args[@]}"; then ready=true; break; fi
                sleep .1
            done
            [[ $ready == true ]]
            if [[ $mode == tun && -z ${SORA_COEXIST_CORE:-} ]]; then
                "$work/sora-core" -check -socket "$casework/core.sock" -data-dir "$casework/data" \
                    -engines-dir "$engines" -allow-file-keys > "$casework/check.log"
            fi
            ip addr > "$casework/addresses"
            ip -4 rule > "$casework/rules4"
            ip -6 rule > "$casework/rules6"
            "${probe[@]}" hold "$seconds" > "$casework/hold.log" 2>&1 &
            hold=$!
            result=PASS
            for sample in 1 2 3 4 5 6; do
                upstream_before=$(grep -c 'proxy/vless/inbound: received request for tcp:203.0.113.80:8080' "$work/server.log" || true)
                request "$engine-$mode-$other-$sample" "${args[@]}" || result=FAIL
                upstream_after=$(grep -c 'proxy/vless/inbound: received request for tcp:203.0.113.80:8080' "$work/server.log" || true)
                if (( ${upstream_after:-0} <= ${upstream_before:-0} )); then result=FAIL; fi
                # Explicit LAN routes must win over both Sora and /1 VPN routes.
                request "$engine-$mode-lan-$other-$sample" --connect-to 203.0.113.80:8080:192.168.44.1:8080 || result=FAIL
                if [[ $other != none ]]; then
                    request "$engine-$mode-happ-$sample" --interface 172.19.0.1 || result=FAIL
                    # Happ's forwarded sockets also remain on their bound uplink.
                    request "$engine-$mode-uplink-$sample" --interface uplink || result=FAIL
                fi
                sleep "$(awk -v seconds="$seconds" 'BEGIN { print seconds / 6 }')"
            done
            wait "$hold" || result=FAIL
            "${probe[@]}" logs > "$casework/engine.log"
            "${probe[@]}" disconnect
            restored || result=FAIL
            ip -4 rule > "$casework/rules-after4"
            ip -6 rule > "$casework/rules-after6"
            ip -4 route show table main > "$casework/routes-after4"
            ip -6 route show table main > "$casework/routes-after6"
            for family in 4 6; do
                cmp "$casework/rules-before$family" "$casework/rules-after$family" || result=FAIL
                cmp "$casework/routes-before$family" "$casework/routes-after$family" || result=FAIL
            done
            if ip link show sora0 > /dev/null 2>&1; then result=FAIL; fi
            if [[ $other != none ]]; then request "$engine-$mode-happ-after" --interface 172.19.0.1 || result=FAIL; fi
            kill "$core"
            wait "$core" || true
            unset 'pids[-1]'
            printf '%s\t%s\t%s\t%s\n' "$engine" "$mode" "$other" "$result" | tee -a "$work/results.tsv"
        done
    done
    for engine in sing-box xray mihomo; do
        regressions "$engine" "$other"
    done
    if [[ $other != none ]]; then
        kill "$foreign"
        wait "$foreign" || true
    fi
done
! grep -q FAIL "$work/results.tsv"
