<p align="center">
  <img src="docs/images/sora-cover.png" alt="Sora" width="100%">
</p>

<h1 align="center">Sora</h1>

<p align="center">
  <strong>Прокси-клиент для Windows 7 SP1 x86.</strong><br>
  Один установщик, современный интерфейс и всё необходимое внутри.
</p>

<p align="center">
  <a href="https://github.com/levvs-one/sora-client/releases/download/v0.2.2/Sora-0.2.2-Win7-x86-Setup.exe"><strong>Скачать Sora 0.2.2</strong></a>
  ·
  <a href="https://github.com/levvs-one/sora-client/releases/download/v0.2.2/Sora-0.2.2-SHA256SUMS.txt">SHA-256</a>
  ·
  <a href="https://github.com/levvs-one/sora-client/releases/tag/v0.2.2">Что изменилось</a>
</p>

<p align="center">
  <img alt="Windows 7 SP1" src="https://img.shields.io/badge/Windows-7%20SP1-222222?style=flat-square">
  <img alt="x86" src="https://img.shields.io/badge/архитектура-x86-444444?style=flat-square">
  <a href="LICENSE"><img alt="GPL-3.0" src="https://img.shields.io/badge/лицензия-GPL--3.0-222222?style=flat-square"></a>
</p>

> [!NOTE]
> Sora — независимый проект сообщества на базе v2rayN. Он не связан с OpenAI или Happ. Техническое имя репозитория — `sora-client`.

## Быстрый старт

1. Скачай [`Sora-0.2.2-Win7-x86-Setup.exe`](https://github.com/levvs-one/sora-client/releases/download/v0.2.2/Sora-0.2.2-Win7-x86-Setup.exe).
2. Запусти установщик. Недостающие .NET Framework 4.8 и обновление SHA-2 установятся автоматически.
3. Открой Sora, нажми **«Добавить конфигурацию»** и вставь ссылку подписки или конфигурацию.

> [!WARNING]
> Установщик пока не подписан сертификатом. Windows может показать SmartScreen. Перед запуском сверь файл с [официальной контрольной суммой](https://github.com/levvs-one/sora-client/releases/download/v0.2.2/Sora-0.2.2-SHA256SUMS.txt).

## Что умеет

| | |
|---|---|
| **Подключение** | Системный прокси и TUN-режим |
| **Импорт** | HTTPS-подписки, Base64, VMess, VLESS, Trojan, Shadowsocks, SOCKS, SIP008 и Xray JSON |
| **Подписки** | Автоопределение формата, обновление без потери старых серверов, сохранение названий и эмодзи |
| **Проверка** | Прямой TCP-пинг до сервера и выбор лучшего измеренного профиля |
| **Диагностика** | Раздельные журналы и безопасный ZIP без ссылок подписок, UUID и учётных данных |
| **Комплект** | Xray, sing-box, tun2proxy, Wintun и системные компоненты в одном `.exe` |

![Главное окно Sora 0.2.2](docs/images/sora-main.png)

<details>
<summary><strong>Совместимость</strong></summary>

| Компонент | Версия | Архитектура |
|---|---:|---|
| Sora | 0.2.2 | Windows x86 |
| .NET Framework | 4.8 | x86/x64 runtime |
| Xray-core | 25.9.11 | windows/386 |
| sing-box | 1.12.12 legacy | windows/386 |
| tun2proxy | 0.7.16 | win7-i686 |
| Wintun | 0.14.1 | x86 |

Целевая система — **Windows 7 SP1 x86**. Для TUN нужен IPv4-адрес сервера. IPv6 в legacy-сборке намеренно не включён.

</details>

<details>
<summary><strong>Сборка из исходников</strong></summary>

Sora основана на [v2rayN 5.39](https://github.com/2dust/v2rayN/tree/529b6613e9193206277b2c2bfc3430ff17663f57) и собирается как `net48/win7-x86`.

Понадобятся Windows, .NET SDK 8, Inno Setup 7 и совместимые x86-компоненты из [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md).

```powershell
dotnet restore .\v2rayN\v2rayN\v2rayN.csproj --runtime win7-x86
dotnet build .\v2rayN\v2rayN\v2rayN.csproj --configuration Release --runtime win7-x86 --no-restore
```

`build/Stage-Release.ps1` собирает чистый каталог приложения, а `installer/Sora.iss` создаёт единый установщик.

</details>

<details>
<summary><strong>Безопасность и приватность</strong></summary>

- Не публикуй ссылки подписок, UUID, адреса серверов и необработанные журналы.
- Используй встроенный безопасный диагностический архив.
- Об уязвимостях сообщай по правилам из [SECURITY.md](SECURITY.md), а не через публичный issue.
- Проверяй SHA-256 установщика перед запуском.

</details>

## Проект

[Все релизы](https://github.com/levvs-one/sora-client/releases) · [История изменений](CHANGELOG.md) · [Предложить улучшение](https://github.com/levvs-one/sora-client/issues/new?template=02_feature_request.yml) · [Сообщить об ошибке](https://github.com/levvs-one/sora-client/issues/new?template=01_bug_report.yml) · [Участие в разработке](CONTRIBUTING.md)

## Происхождение и лицензия

Sora — изменённая версия v2rayN 5.39. Код распространяется по [GNU GPL-3.0](LICENSE), уведомления об авторах сохранены в [NOTICE.md](NOTICE.md), а лицензии и версии сторонних компонентов перечислены в [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md).

Исходный код каждой бинарной версии доступен в теге и архиве соответствующего релиза.
