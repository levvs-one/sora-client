# Sora

[English](README.en.md)

VPN-клиент для Windows и Linux. Открывает обычные подписки (VLESS, VMess, Trojan, Shadowsocks и другие, а также JSON-подписки Xray) и сам выбирает, каким ядром вести подключение: sing-box, Xray или mihomo.

## Установка

Windows 10 (1809 и новее) и Windows 11, x64. В PowerShell:

```powershell
irm https://github.com/levvs-one/sora-client/releases/latest/download/install.ps1 | iex
```

Linux: Debian, Ubuntu, Fedora, openSUSE, Arch.

```sh
curl -fsSL https://github.com/levvs-one/sora-client/releases/latest/download/install.sh | sh
```

Скрипты берут последний релиз, сверяют файлы с `SHA256SUMS` и ставят их. На Linux установка идёт через apt, dnf, zypper или pacman, поэтому обновлять и удалять Sora можно как обычный пакет.

Установщик для Windows и пакеты для Linux можно скачать и вручную со страницы [релизов](https://github.com/levvs-one/sora-client/releases).

## Возможности

- Подписки по ссылке: обновление по расписанию, расход трафика, срок действия, объявления провайдера.
- JSON-подписки Xray (Remnawave): профиль работает целиком, со своими балансировщиками и маршрутами.
- Режимы: весь трафик через TUN или системный прокси.
- Kill switch: nftables на Linux, WFP на Windows.
- Автовыбор самого быстрого сервера и переход на запасной при сбое.
- Свои правила для сайтов, IP-адресов и программ: напрямую, через VPN или блокировать.
- Обход DPI без сервера через zapret (на Linux).
- Значок в трее, запуск вместе с системой, уведомления.
- Ссылки `sora://`, `happ://add` и ссылки v2rayN, Clash, Hiddify, sing-box открывают добавление подписки.
- Журнал и список активных соединений.
- Русский и английский интерфейс, светлая и тёмная тема.

Протоколы: VLESS (REALITY, XTLS Vision), VMess, Trojan, Shadowsocks (в том числе 2022), Hysteria2, TUIC, WireGuard, AmneziaWG, SOCKS5, HTTP(S). Транспорты: raw, ws, grpc, httpupgrade, xhttp.

## Провайдерам

Отдельный формат подписки не нужен, Sora открывает ту же ссылку, что Happ и другие клиенты. Управлять группировкой можно через названия серверов.

Серверы одной подписки с одинаковым названием показываются одной строкой. Трафик идёт через самый быстрый из них, сервер, который не ответил на проверку, не выбирается.

Если в конце названия указана роль, сначала используется основной сервер, а запасной включается, когда основной не отвечает.

| Название в подписке | Как работает в Sora |
| --- | --- |
| `Нидерланды (основной)` | строка «Нидерланды», трафик идёт сюда |
| `Нидерланды (запасной)` | включается, если основной не отвечает |
| `Германия`, `Германия` | строка «Германия», самый быстрый из двух |

Основной: `основной`, `главный`, `main`, `primary`. Запасной: `запасной`, `резерв`, `резервный`, `backup`, `reserve`, `fallback`. Регистр не важен, роль можно взять в скобки или отделить пробелом, дефисом или двоеточием. Сервер без роли в группе, где роли указаны, считается запасным.

Порядок по ролям работает на ядре mihomo, Sora выбирает его для таких групп сама. Если в настройках вручную закреплено ядро sing-box или Xray, используются только основные серверы.

В других клиентах эти серверы будут видны по отдельности, с теми же названиями.

## Платформы

| Система | Что есть |
| --- | --- |
| Windows 10 1809+ и 11, x64 | приложение и служба, установщик |
| Linux x64 | приложение и служба, пакеты .deb, .rpm и для Arch |
| Linux ARM64 | только служба (Flutter не собирает приложение под Linux ARM64) |
| Windows 7 SP1, x32 | старый клиент в ветке [`legacy`](https://github.com/levvs-one/sora-client/tree/legacy) |
| Android | в разработке |

## Сборка

Нужны Go 1.26 и Flutter 3.47.

```sh
cd core
go test ./...
go build -o sora-core ./cmd/sora-core

cd ../app
flutter pub get
flutter build linux --release
```

Если положить рядом собранные ядра, тесты дополнительно прогонят через них настоящий трафик:

```sh
SORA_SINGBOX_BIN=... SORA_XRAY_BIN=... SORA_MIHOMO_BIN=... SORA_ENGINES_DIR=... go test ./...
```

Сборка пакетов описана в [packaging](packaging/README.md).

| Каталог | Что там |
| --- | --- |
| [`core`](core/README.md) | служба `sora-core` на Go: ядра, подписки, хранилище, kill switch |
| [`app`](app/README.md) | приложение на Flutter |
| [`proto`](proto/README.md) | gRPC-контракт между приложением и службой |
| [`packaging`](packaging/README.md) | установщик для Windows и пакеты для Linux |
| [`service`](service) | службы для Windows и systemd |

Подробная документация: [docs](docs/README.md).

- [Установка, обновление и удаление](docs/install.md)
- [Как пользоваться](docs/usage.md)
- [Для провайдеров](docs/providers.md)
- [Если что-то не работает](docs/troubleshooting.md)
- [Как устроена Sora](docs/architecture.md)
- [Разработка и сборка](docs/development.md)

## Обратная связь

Ошибки и предложения пишите в [issues](https://github.com/levvs-one/sora-client/issues). Об уязвимостях сообщайте закрыто, см. [SECURITY.md](SECURITY.md). Как предложить изменения, описано в [CONTRIBUTING.md](CONTRIBUTING.md).

## Лицензия

[GPL-3.0](LICENSE). Сторонние компоненты перечислены в [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md).

Sora не связана с OpenAI, разработчиками Happ и других упомянутых клиентов.
