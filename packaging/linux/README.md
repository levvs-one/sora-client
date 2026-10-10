# packaging/linux

Пакеты .deb, .rpm и для Arch собираются [nfpm](https://github.com/goreleaser/nfpm) из двух описаний:

- `nfpm.yaml`: пакет `sora-core`, служба с ядрами и zapret;
- `nfpm-app.yaml`: пакет `sora`, приложение. Зависит от `sora-core` той же версии.

| Путь | Пакет | Что это |
| --- | --- | --- |
| `/usr/bin/sora-core` | sora-core | служба |
| `/usr/lib/sora/engines/` | sora-core | sing-box, Xray, mihomo, tpws, nfqws, geoip.dat, geosite.dat |
| `/usr/lib/systemd/system/sora-core.service` | sora-core | unit, см. [service/linux](../../service/linux/README.md) |
| `/usr/lib/sysusers.d/sora.conf` | sora-core | пользователь и группа `sora` |
| `/usr/share/polkit-1/actions/io.github.levvs-one.sora.policy` | sora-core | доступ к службе для активной сессии |
| `/usr/share/licenses/sora-core/` | sora-core | лицензии |
| `/usr/lib/sora/app/`, `/usr/bin/sora` | sora | приложение |
| `/usr/lib/sora/sora-update` | sora | helper установки проверенной пары пакетов |
| `/usr/share/polkit-1/actions/io.github.levvs-one.sora.update.policy` | sora | обновление с паролем администратора |
| `/usr/share/applications/io.github.levvs_one.sora.desktop` | sora | ярлык, обработчик ссылок `sora://` и `happ://` |
| `/usr/share/icons/hicolor/scalable/apps/io.github.levvs_one.sora.svg` | sora | значок |

Скрипты в `scripts/`: после установки создаётся пользователь `sora`, служба включается и запускается; перед удалением служба останавливается; после удаления снимается таблица nftables `sora`, если она осталась.

## Сборка

```sh
cd core && CGO_ENABLED=0 go build -trimpath -ldflags '-s -w' -o ../dist/sora-core ./cmd/sora-core && cd ..
packaging/engines/fetch.sh amd64 dist/engines
packaging/zapret/build.sh dist/engines
SORA_ARCH=amd64 SORA_VERSION=1.0.6 nfpm package --config packaging/linux/nfpm.yaml --packager deb --target dist/

cd app && flutter build linux --release --dart-define=SORA_VERSION=1.0.6 && cd ..
SORA_ARCH=amd64 SORA_VERSION=1.0.6 nfpm package --config packaging/linux/nfpm-app.yaml --packager deb --target dist/
```

`--packager rpm` и `--packager archlinux` собирают остальные форматы. Для arm64 собирается только `sora-core`.

CI собирает все форматы в каждом pull request и проверяет установку через `install.sh` на Ubuntu, Fedora и Arch.

Обновление в приложении использует GitHub Releases и SHA256SUMS. Helper копирует оба пакета в закрытый root-каталог, повторно проверяет хеши, имена и версии пакетов и передаёт всю пару одному вызову пакетного менеджера. Действие polkit требует `auth_admin` в любой сессии, без сохранения разрешения. Если helper или pkexec отсутствует либо авторизация отклонена, приложение сохраняет проверенные загрузки и показывает команду для терминала. Первая установка новой функции поверх старого пакета без helper использует этот ручной путь.

Без установки пакетов и обращения к установленной службе helper проверяется командой `python3 packaging/linux/test_update.py -v`. Нужен bubblewrap с доступными user namespaces; в тесте пакетные менеджеры заменены регистраторами аргументов, файловая система хоста доступна только для чтения, `/run` изолирован.
