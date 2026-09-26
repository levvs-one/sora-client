# Sora

Открытый клиент подписок и защищенных подключений для Windows, Linux, Android и Android TV. Sora сама подбирает рабочий способ обхода блокировок в сети пользователя, понятно объясняет ошибки и возвращает систему в исходное состояние после любого завершения работы.

Новый клиент находится в разработке. Текущая стабильная сборка для Windows 7 SP1, 8.1, 10 и 11 называется Sora Legacy и лежит в каталоге [`legacy`](legacy/README.md). Она получает только исправления безопасности и критических ошибок.

## Структура репозитория

| Каталог | Что внутри |
| --- | --- |
| [`core`](core/README.md) | `libsora` на Go: сетевое ядро на sing-box и Xray-core, парсер подписок, проверки серверов, умный обход, каталог ошибок |
| [`proto`](proto/README.md) | Контракт `sora.core.v1` между приложением и ядром |
| [`app`](app/README.md) | Приложение на Flutter для Windows, Linux, Android и Android TV |
| [`app/android/tunnel`](app/android/tunnel/README.md) | Android-служба туннеля в отдельном процессе |
| [`service/windows`](service/windows/README.md) | Установка и жизненный цикл службы ядра Windows |
| [`service/linux`](service/linux/README.md) | Unit-файлы systemd, пользователи и права службы ядра Linux |
| [`packaging`](packaging/README.md) | Установщики и пакеты для всех платформ |
| [`legacy`](legacy/README.md) | Sora Legacy на WinForms для Windows 7 и 8.1 |

## Платформы

| Система | Версии | Архитектуры |
| --- | --- | --- |
| Windows | 10 версии 1809 и новее, 11 | x64, ARM64 |
| Linux | Debian 12+, Ubuntu 22.04+, Fedora 39+, openSUSE, AppImage | x64, ARM64 |
| Android | 8.0 и новее, Android TV | arm64-v8a, armeabi-v7a, x86_64 |

## Правила разработки

Как устроена работа с репозиторием, описано в [CONTRIBUTING.md](CONTRIBUTING.md). Об уязвимостях сообщайте по правилам из [SECURITY.md](SECURITY.md).

## Лицензия

Код распространяется по [GNU GPL-3.0](LICENSE). Уведомления о сторонних компонентах находятся в [NOTICE.md](NOTICE.md) и [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md).
