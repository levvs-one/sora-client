# core

The `sora-core` service in Go. It runs the engines (sing-box, Xray, mihomo), keeps subscriptions and credentials encrypted, manages the kill switch and serves the gRPC API from `proto/sora/core/v1` to the app over a unix socket or a named pipe.

## Packages

| Package | Purpose |
| --- | --- |
| `cmd/sora-core` | the service entry point, Windows service install |
| `control` | the gRPC API |
| `ipc` | unix socket and named pipe, peer checks |
| `session` | session state, event journal, network change handling |
| `engine` | plan, engine capabilities and selection |
| `engine/singbox`, `engine/xray`, `engine/mihomo` | config rendering per engine |
| `engine/supervise` | engine processes: start, restart, stop |
| `engine/clashapi` | Clash API client for mihomo and sing-box |
| `engine/registry` | installed engines and which one runs a plan |
| `engine/tunroute` | policy routing for Xray TUN on Linux |
| `parser` | share links, subscriptions, Xray JSON |
| `subscription` | subscription downloads and scheduled updates |
| `secret` | encrypted storage (AES-256-GCM, DPAPI on Windows) |
| `guard` | kill switch: nftables on Linux, WFP on Windows |
| `probe` | server latency checks |
| `routing` | routing presets |
| `logs` | in-memory log store |
| `diagnostics` | diagnostic report with secrets masked |
| `errs` | error codes and message keys |

Tested engine builds: sing-box 1.14.2, Xray 26.3.27, mihomo 1.19.32. The exact files and checksums are in `packaging/engines/engines.lock`.

## Run

```sh
go run ./cmd/sora-core -data-dir ./data                      # start
go run ./cmd/sora-core -check                                # check that engines and permissions are in place
go run ./cmd/sora-core -socket /tmp/sora.sock -data-dir ./data   # listen on a custom socket
```

The app finds a custom socket through `SORA_CORE_SOCKET`.

On Windows the installer registers the core as the `SoraCore` service (`sora-core.exe -install-service`). On Linux the package ships the `sora-core.service` systemd unit.

## Test

```sh
go test -race ./...
golangci-lint run
go run golang.org/x/vuln/cmd/govulncheck@latest ./...
```

With engine binaries available the tests also check every rendered config with the engine itself and send real traffic through it:

```sh
SORA_SINGBOX_BIN=... SORA_XRAY_BIN=... SORA_MIHOMO_BIN=... SORA_ENGINES_DIR=... go test ./...
```

Code generated from the proto contract lives in `gen/` and is committed. Regenerate it with `buf generate` in `proto/`.
