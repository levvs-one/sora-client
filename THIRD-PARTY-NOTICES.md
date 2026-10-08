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
| tray_manager, window_manager, nativeapi | 0.7.0, 0.5.2, 0.3.0 | MIT |
| flutter_local_notifications | 22.3.1 | BSD-3-Clause |
| app_links | 7.2.2 | Apache-2.0 |
| webview_all, webview_all_linux, webview_all_windows | 1.4.4 | MIT, © 2021-2026 Abandoft |
| dbus | 0.7.15 | MPL-2.0 |

## Служба

| Компонент | Лицензия |
| --- | --- |
| gRPC, protobuf для Go | Apache-2.0, BSD-3-Clause |
| golang.org/x/sys | BSD-3-Clause |
| go-winio | MIT |
| tailscale/wf | BSD-3-Clause |

Тексты лицензий: GPL-3.0 в файле `LICENSE`, Inter в `Inter-LICENSE.txt`, zapret в `zapret-LICENSE.txt` пакета `sora-core`. Лицензии остальных компонентов лежат в их исходном коде по ссылкам выше и на pub.dev.

## WebView All

Исходный код: https://github.com/abandoft/webview_all/tree/1.4.4

Copyright 2021-2026 [Abandoft](https://github.com/abandoft)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
