<div align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="v2rayN/v2rayN/Assets/Sora/sora-logo-white.png">
    <source media="(prefers-color-scheme: light)" srcset="v2rayN/v2rayN/Assets/Sora/sora-logo-black.png">
    <img alt="Sora" src="v2rayN/v2rayN/Assets/Sora/sora-logo-black.png" width="96">
  </picture>

  # Sora

  Простой открытый прокси-клиент для Windows 7 SP1 x86

  [![Release](https://img.shields.io/github/v/release/levvs-one/sora-client?display_name=tag&style=flat-square)](https://github.com/levvs-one/sora-client/releases/latest)
  [![License](https://img.shields.io/github/license/levvs-one/sora-client?style=flat-square)](LICENSE)
  ![Platform](https://img.shields.io/badge/Windows-7%20SP1-111111?style=flat-square)
  ![Architecture](https://img.shields.io/badge/architecture-x86-555555?style=flat-square)
</div>

`sora-client` — техническое имя проекта. В интерфейсе и установщике используется название **Sora**.

Проект создан для сообщества пользователей устаревших 32-разрядных систем: один установщик, понятный интерфейс и необходимые компоненты в комплекте.

> [!IMPORTANT]
> Sora — независимый неофициальный проект. Он не связан с OpenAI, Flyfrog LLC, Happ Desktop или их владельцами. В проект не входят исходный код, логотипы и другие материалы Happ.

![Главное окно Sora](docs/images/sora-main.png)

## Возможности

- один установщик для 32-разрядной Windows 7 SP1;
- системный прокси и TUN-режим;
- единое окно импорта с автоопределением HTTPS-подписок, VMess, VLESS, Trojan, Shadowsocks, SOCKS, Base64, SIP008 и Xray JSON;
- подписки, маршрутизация и входящие подключения;
- проверка задержки и выбор лучшего измеренного сервера;
- реальные показатели текущего подключения;
- журналы приложения, ядра, TUN, AntiFilter, подписок и службы;
- диагностический ZIP без адресов серверов, UUID, ссылок подписок и учётных данных;
- автозапуск через параметр `--silent`;
- монохромный интерфейс Sora с собственными диалогами, меню и подтверждениями вместо системных экранов WinForms.

## Установка

1. Откройте [последний релиз](https://github.com/levvs-one/sora-client/releases/latest).
2. Скачайте `Sora-0.2.1-Win7-x86-Setup.exe`.
3. Сверьте SHA-256 с файлом `Sora-0.2.1-SHA256SUMS.txt`.
4. Запустите установщик.

Установщик добавляет .NET Framework 4.8 и обновление SHA-2 KB3033929 только при необходимости. Для TUN приложение запросит права администратора.

Установщик пока не подписан сертификатом. SmartScreen может показать предупреждение «неизвестный издатель» — это не заменяет проверку контрольной суммы.

Подробности выпусков: [Sora 0.2.1](docs/releases/0.2.1.md), [Sora 0.2.0](docs/releases/0.2.0.md) и [Sora 0.1.0](docs/releases/0.1.0.md).

## Совместимость

| Компонент | Версия | Архитектура |
|---|---:|---|
| Sora | 0.2.1 | Windows x86 |
| .NET Framework | 4.8 | x86/x64 runtime |
| Xray-core | 25.9.11 | windows/386 |
| sing-box | 1.12.12 legacy | windows/386 |
| tun2proxy | 0.7.16 | win7-i686 |
| Wintun | 0.14.1 | x86 |

Целевая система — Windows 7 SP1 x86. Для TUN нужен IPv4-адрес сервера. IPv6 в legacy-сборке намеренно не включён.

## Сборка из исходников

Проект основан на [v2rayN 5.39](https://github.com/2dust/v2rayN/tree/529b6613e9193206277b2c2bfc3430ff17663f57) и собирается как `net48/win7-x86`.

Требуются .NET SDK 8, Windows, Inno Setup 7 и совместимые x86-компоненты, перечисленные в [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md).

```powershell
dotnet restore .\v2rayN\v2rayN\v2rayN.csproj --runtime win7-x86
dotnet build .\v2rayN\v2rayN\v2rayN.csproj --configuration Release --runtime win7-x86 --no-restore
```

Скрипт `build/Stage-Release.ps1` формирует чистый каталог приложения. Сценарий `installer/Sora.iss` создаёт единый установщик.

## Безопасность

- Не публикуйте конфигурации, ссылки подписок, UUID и журналы с адресами серверов.
- Проверяйте SHA-256 файлов релиза.
- Уязвимости сообщайте по правилам из [SECURITY.md](SECURITY.md), а не через публичный issue.

## Происхождение и лицензии

Sora является изменённой версией v2rayN 5.39. Изменения проекта Sora начаты 29 августа 2026 года. Подробное уведомление приведено в [NOTICE.md](NOTICE.md).

Код приложения распространяется по [GNU GPL-3.0](LICENSE). Получатели бинарной сборки могут скачать соответствующий исходный код из тега того же релиза. Сторонние компоненты сохраняют собственные лицензии; версии, источники и контрольные суммы перечислены в [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md).

## Участие в разработке

Правила для изменений находятся в [CONTRIBUTING.md](CONTRIBUTING.md). История пользовательских изменений ведётся в [CHANGELOG.md](CHANGELOG.md).
