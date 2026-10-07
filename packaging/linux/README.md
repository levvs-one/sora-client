# packaging/linux

Пакеты Sora для Linux: `.deb`, `.rpm` и пакет Arch Linux, собранные
[nfpm](https://github.com/goreleaser/nfpm). Их два:

- `sora-core` (`nfpm.yaml`) — служба ядра с движками и zapret;
- `sora` (`nfpm-app.yaml`) — приложение. Оно зависит от `sora-core` той же
  версии, так что человек ставит только `sora`, а ядро приходит само. Серверу без
  графики хватает `sora-core`.

## Что ставит пакет

| Путь | Что это |
| --- | --- |
| `/usr/bin/sora-core` | служба ядра |
| `/usr/lib/sora/engines/` | sing-box, Xray-core, mihomo, `geoip.dat`, `geosite.dat` |
| `/usr/lib/systemd/system/sora-core.service` | unit службы, см. [service/linux](../../service/linux/README.md) |
| `/usr/lib/sysusers.d/sora.conf` | пользователь и группа `sora` |
| `/usr/share/polkit-1/actions/io.github.levvs-one.sora.policy` | доступ к службе для активной локальной сессии |

Пакет `sora`:

| Путь | Что это |
| --- | --- |
| `/usr/lib/sora/app/` | приложение на Flutter |
| `/usr/bin/sora` | ссылка на него |
| `/usr/share/applications/io.github.levvs_one.sora.desktop` | ярлык в меню приложений |
| `/usr/share/icons/hicolor/scalable/apps/io.github.levvs_one.sora.svg` | значок |

Человеку не нужен терминал. Пакет открывается в центре приложений; после установки
скрипт создаёт пользователя службы, включает и запускает её. Интерфейс в активной
сессии получает доступ через polkit без пароля и без групп. Обновление
перезапускает службу на новой версии. Удаление останавливает службу и снимает
таблицу nftables `sora`, если служба не успела снять её сама.

## Движки

Версии и SHA-256 движков закреплены в [`engines.lock`](../engines/engines.lock).
[`fetch.sh`](../engines/fetch.sh) скачивает их по HTTPS и отказывается собирать
пакет, если сумма хоть одного файла не совпала. Базы geoip и geosite берутся из
архива Xray той же закреплённой версии.

## Сборка

```sh
cd core && CGO_ENABLED=0 GOARCH=amd64 go build -trimpath -ldflags '-s -w' -o ../dist/sora-core ./cmd/sora-core && cd ..
packaging/engines/fetch.sh amd64 dist/engines
SORA_ARCH=amd64 SORA_VERSION=0.3.0 nfpm package --config packaging/linux/nfpm.yaml --packager deb --target dist/
```

`--packager rpm` и `--packager archlinux` собирают остальные форматы. Пакет
приложения собирается после сборки самого приложения:

```sh
cd app && flutter build linux --release --dart-define=SORA_VERSION=0.3.0 && cd ..
SORA_ARCH=amd64 SORA_VERSION=0.3.0 nfpm package --config packaging/linux/nfpm-app.yaml --packager deb --target dist/
```

CI собирает все три формата в каждом pull request и прикладывает их к прогону:
`sora-core` для amd64 и arm64, `sora` для amd64. Flutter не выпускает SDK для
Linux на arm64, поэтому приложение для arm64 пока не собирается.

## Что не проверено

Установка пакетов на живой системе с запуском службы, tun и kill switch не
проверялась: для этого нужны права root. Проверены состав пакетов, зависимости,
скрипты установки и удаления, unit (`systemd-analyze verify`) и политика polkit.
