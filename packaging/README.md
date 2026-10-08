# packaging

| Каталог | Что собирается |
| --- | --- |
| [`windows`](windows/README.md) | установщик для Windows x64 (Inno Setup) |
| [`linux`](linux/README.md) | пакеты .deb, .rpm и для Arch (nfpm) |
| [`engines`](engines) | список сборок sing-box, Xray и mihomo с контрольными суммами и скрипт загрузки |
| [`zapret`](zapret) | сборка tpws и nfqws |
| [`install`](install) | установка одной командой: `install.sh` для Linux, `install.ps1` для Windows |

В релизах всё это собирает CI по тегу `v*`, вместе с файлом `SHA256SUMS`. Установщик и пакеты пока не подписаны.
