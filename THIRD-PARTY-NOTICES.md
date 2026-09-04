# Сторонние компоненты

| Компонент | Версия | Лицензия | Исходный выпуск | SHA-256 исполняемого файла |
|---|---:|---|---|---|
| v2rayN | 5.39 | GPL-3.0 | https://github.com/2dust/v2rayN/tree/529b6613e9193206277b2c2bfc3430ff17663f57 | — |
| Xray-core | 25.9.11 win7-32 | MPL-2.0 | https://github.com/XTLS/Xray-core/releases/tag/v25.9.11 | `0F611E1DEB746BB295DE2344A3D1E668F39FDB1818515F631277B1425CE51AB1` |
| Xray-core release archive | 25.9.11 win7-32 | MPL-2.0 | тот же выпуск | `B23ACCCC3F9BD2591911C31EDB994C117F43C661F4A0CA06CBEEED4465D9C38A` |
| sing-box | 1.12.12 legacy win7-386 | GPL-3.0-or-later | https://github.com/SagerNet/sing-box/releases/tag/v1.12.12 | `E9FDD8B543D494B41923D5D4660E65AC380A14DDDD4D45E7379BE4CCED92D0E1` |
| tun2proxy | 0.7.16 win7-i686 | MIT | https://github.com/tun2proxy/tun2proxy/releases/tag/v0.7.16 | `DD769D0AC9BD0826B0BFB52C44E8DA87CBDCFB5B1AD9CD45D1B1691D1743D011` |
| tun2proxy DLL | 0.7.16 win7-i686 | MIT | тот же выпуск | `97001928B30F627C00AD1B128B4EA3F5E0500B2A701E18A4431CE19BAFAAE409` |
| tun2proxy udpgw | 0.7.16 win7-i686 | MIT | тот же выпуск | `203CDF3E78A277B37685E77B02AC04593B52473F8F485532B1312F9121FAC56C` |
| Wintun | 0.14.1 x86 | собственная лицензия WireGuard LLC | https://www.wintun.net/ | `D694FA46AB4CFEBCB2632D094C7AA97278EEF2F8052438621766D863AE98A931` |
| .NET Framework Runtime | 4.8 offline | Microsoft | https://dotnet.microsoft.com/download/dotnet-framework/net48 | `0A3A390C47E639D0F7FC65B21195FEE6B7F65B066F80F70C60FAB191D14B7E40` |
| Windows 7 SHA-2 update | KB3033929 x86 | Microsoft | https://www.microsoft.com/download/details.aspx?id=46078 | `246C300A6AE6DCA99453F6839745AC0015953528A7065BED1B015F91B80CF64D` |
| Phosphor Icons | Core, Bold | MIT | https://github.com/phosphor-icons/core | PNG-ресурсы в `Assets/Phosphor` |
| Country Flags | svg-country-flags 1.2.10 | Public Domain | https://github.com/hampusborgos/country-flags | PNG-ресурсы в `Assets/Flags`; архив `2576650B4568C8EE1A2A6DDAA45C0246BE16735F229BB40B1A0A6F40424E5213` |
| Markdig | 1.3.2 | BSD-2-Clause | https://github.com/xoofx/markdig/releases/tag/1.3.2 | NuGet-зависимость для безопасного разбора Markdown |
| NetSparkle | 3.1.0 | MIT | https://github.com/NetSparkleUpdater/NetSparkle/tree/3.1.0 | Проверка подписанных обновлений в Sora Update |
| NetSparkleUpdater.Chaos.NaCl | 0.9.4 | MIT, Public Domain | https://github.com/NetSparkleUpdater/Chaos.NaCl/tree/918eeb5ce31f1ac6cf041fbd4e6e83708bd461b1 | Проверка Ed25519; атрибуция в `licenses/nuget/Chaos.NaCl.txt` |
| libXray | 26.7.28 | MIT | https://github.com/XTLS/libXray/releases/tag/v26.7.28 | Android AAR и Linux x64 SO загружаются сборкой с проверкой SHA-256 |
| Compose Multiplatform | 1.11.1 | Apache-2.0 | https://github.com/JetBrains/compose-multiplatform | Общий интерфейс Android и Linux |
| JNA | 5.17.0 | Apache-2.0 или LGPL-2.1-or-later | https://github.com/java-native-access/jna/releases/tag/5.17.0 | Вызов C API libXray в Linux |
| Inter | Variable | OFL-1.1 | https://github.com/rsms/inter | Шрифт общего интерфейса; текст лицензии в `licenses/fonts` |
| multiplatform-markdown-renderer | 0.41.0 | Apache-2.0 | https://github.com/mikepenz/multiplatform-markdown-renderer/releases/tag/v0.41.0 | Разбор и отображение описаний подписок; последняя версия, совместимая с Android SDK 36 |

Тексты лицензий Xray, sing-box, tun2proxy, Wintun, Phosphor Icons и распространяемых NuGet-зависимостей устанавливаются в каталог `licenses`. Уведомление об источнике флагов распространяется вместе с ресурсами в `Assets/Flags/NOTICE.txt`. Точное соответствие NuGet-пакетов лицензиям находится в `licenses/nuget/ATTRIBUTIONS.md`.
