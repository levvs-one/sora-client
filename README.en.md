# Sora

[Русский](README.md)

A VPN client for Windows and Linux. It opens regular subscriptions (VLESS, VMess, Trojan, Shadowsocks and others, plus Xray JSON subscriptions) and picks the engine for each connection on its own: sing-box, Xray or mihomo.

## Install

Windows 10 (1809 or later) and Windows 11, x64. In PowerShell:

```powershell
irm https://github.com/levvs-one/sora-client/releases/latest/download/install.ps1 | iex
```

Linux: Debian, Ubuntu, Fedora, openSUSE, Arch.

```sh
curl -fsSL https://github.com/levvs-one/sora-client/releases/latest/download/install.sh | sh
```

The scripts take the latest release, check the files against `SHA256SUMS` and install them. On Linux they go through apt, dnf, zypper or pacman, so Sora updates and uninstalls like any other package.

You can also download the Windows installer and the Linux packages from the [releases](https://github.com/levvs-one/sora-client/releases) page.

## Features

- Subscriptions by link: scheduled updates, traffic used, expiry date, provider announcements.
- Xray JSON subscriptions (Remnawave): each profile runs as written, with its own balancers and routing.
- Modes: all traffic through TUN, or the system proxy.
- Kill switch: nftables on Linux, WFP on Windows.
- Automatic fastest server and failover to a backup.
- Your own rules for sites, IP addresses and programs: direct, through the VPN, or blocked.
- DPI bypass without a server via zapret (on Linux).
- Tray icon, start with the system, notifications.
- `sora://`, `happ://add` and the links of v2rayN, Clash, Hiddify and sing-box open the subscription import.
- Log viewer and a list of active connections.
- Russian and English, light and dark theme.

Protocols: VLESS (REALITY, XTLS Vision), VMess, Trojan, Shadowsocks (including 2022), Hysteria2, TUIC, WireGuard, AmneziaWG, SOCKS5, HTTP(S). Transports: raw, ws, grpc, httpupgrade, xhttp.

## For providers

No special subscription format is needed: Sora opens the same link as Happ and other clients. Grouping is controlled through server names.

Servers of one subscription with the same name show up as one entry. Traffic goes through the fastest of them, and a server that failed the check is never picked.

If a name ends with a role, the main server is used first and the backup takes over when the main one stops answering.

| Name in the subscription | How Sora uses it |
| --- | --- |
| `Netherlands (main)` | entry "Netherlands", traffic goes here |
| `Netherlands (backup)` | used when the main one does not answer |
| `Germany`, `Germany` | entry "Germany", the faster of the two |

Main: `main`, `primary`, `основной`, `главный`. Backup: `backup`, `reserve`, `fallback`, `запасной`, `резерв`, `резервный`. Case does not matter; the role can be in brackets or follow a space, a hyphen or a colon. A server without a role in a group that has roles counts as a backup.

Role order is handled by the mihomo engine, which Sora picks for such groups automatically. If sing-box or Xray is pinned in the settings, only the main servers are used.

Other clients show these servers one by one, under the same names.

## Platforms

| System | What is available |
| --- | --- |
| Windows 10 1809+ and 11, x64 | app and service, installer |
| Linux x64 | app and service, .deb, .rpm and Arch packages |
| Linux ARM64 | service only (Flutter does not build the app for Linux ARM64) |
| Windows 7 SP1, x32 | the old client on the [`legacy`](https://github.com/levvs-one/sora-client/tree/legacy) branch |
| Android | in development |

## Building

You need Go 1.26 and Flutter 3.47.

```sh
cd core
go test ./...
go build -o sora-core ./cmd/sora-core

cd ../app
flutter pub get
flutter build linux --release
```

With engine builds at hand, the tests also push real traffic through them:

```sh
SORA_SINGBOX_BIN=... SORA_XRAY_BIN=... SORA_MIHOMO_BIN=... SORA_ENGINES_DIR=... go test ./...
```

Packaging is described in [packaging](packaging/README.md).

| Directory | Contents |
| --- | --- |
| [`core`](core/README.md) | the `sora-core` service in Go: engines, subscriptions, secret store, kill switch |
| [`app`](app/README.md) | the Flutter app |
| [`proto`](proto/README.md) | the gRPC contract between the app and the service |
| [`packaging`](packaging/README.md) | the Windows installer and Linux packages |
| [`service`](service) | the Windows service and the systemd unit |

Detailed documentation, in Russian: [docs](docs/README.md).

## Feedback

Report bugs and ideas in [issues](https://github.com/levvs-one/sora-client/issues). Report vulnerabilities privately, see [SECURITY.md](SECURITY.md). How to contribute: [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[GPL-3.0](LICENSE). Third-party components are listed in [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md).

Sora is not affiliated with OpenAI, the developers of Happ or other clients mentioned here.
