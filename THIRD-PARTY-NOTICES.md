# Сторонние компоненты

Что Sora ставит вместе с собой. Движки скачиваются с выпусков их авторов и
сверяются по SHA-256 из [`packaging/engines/engines.lock`](packaging/engines/engines.lock);
Sora их не изменяет.

## Движки

| Компонент | Версия | Где | Лицензия | Исходный код |
| --- | --- | --- | --- | --- |
| sing-box | 1.14.2 | Linux, Windows | GPL-3.0-or-later с условием автора о названии | https://github.com/SagerNet/sing-box/tree/v1.14.2 |
| Xray-core | 26.3.27 | Linux, Windows | MPL-2.0 | https://github.com/XTLS/Xray-core/tree/v26.3.27 |
| mihomo | 1.19.32 | Linux, Windows (сборка compatible) | GPL-3.0 | https://github.com/MetaCubeX/mihomo/tree/v1.19.32 |
| zapret (tpws, nfqws) | 72.1 | Linux | MIT, © bol-van | [`third_party/zapret`](third_party/zapret) |

## Приложение

| Компонент | Версия | Лицензия |
| --- | --- | --- |
| Flutter и Dart | 3.47.6 | BSD-3-Clause |
| Inter | 4.1 | SIL Open Font License 1.1 |
| grpc | 5.1.0 | Apache-2.0 |
| retry | 3.1.2 | Apache-2.0 |
| cupertino_icons | 2.0.0 | MIT |
| protobuf, fixnum, http2, intl, ffi | 6.1.0, 1.1.1, 2.3.1, 0.20.3, 2.2.0 | BSD-3-Clause |
| shared_preferences, file_selector, url_launcher | 2.5.6, 1.1.0, 6.3.3 | BSD-3-Clause |
| win32 | 6.4.0 | BSD-3-Clause |

Тексты лицензий: GPL-3.0 — файл `LICENSE` рядом с этим; Inter — `Inter-LICENSE.txt`;
zapret — `zapret-LICENSE.txt` в пакете ядра для Linux. Остальные лежат в исходном
коде компонентов по ссылкам выше и на pub.dev.
