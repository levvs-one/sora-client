# Установка, обновление и удаление

## Windows

Нужна 64-битная Windows 10 версии 1809 или новее, либо Windows 11.

Проще всего в PowerShell:

```powershell
irm https://github.com/levvs-one/sora-client/releases/latest/download/install.ps1 | iex
```

Скрипт скачает последний установщик, сверит его с `SHA256SUMS` из того же релиза и установит без вопросов. Windows один раз попросит права администратора: служба Sora ставится в систему.

Можно и вручную: скачайте `Sora-Setup-<версия>-x64.exe` со страницы [релизов](https://github.com/levvs-one/sora-client/releases) и запустите. Установщик спросит про ярлык на рабочем столе и про ссылки `happ://`. Второй пункт появляется, только если ссылки Happ ещё никто не открывает, поэтому установленный Happ Sora не трогает.

Что ставится:

| Где | Что |
| --- | --- |
| `C:\Program Files\Sora` | приложение |
| `C:\Program Files\Sora\core` | служба `sora-core.exe` и ядра sing-box, Xray, mihomo |
| `C:\ProgramData\Sora` | данные службы: подписки и ключи в зашифрованном виде |
| служба `SoraCore` | запускается вместе с Windows, перезапускается после сбоя |

Установщик не подписан сертификатом, поэтому SmartScreen при первом запуске покажет предупреждение. Подлинность файла можно проверить по `SHA256SUMS`:

```powershell
Get-FileHash .\Sora-Setup-1.0.5-x64.exe
```

Обновление: запустите установщик новой версии поверх старой или ещё раз выполните команду из начала раздела. Подписки и настройки сохранятся.

Удаление: «Параметры», «Приложения», Sora. Служба удаляется вместе с программой. Данные в `C:\ProgramData\Sora` остаются, их можно удалить вручную.

Windows 7 новой версией не поддерживается, для неё есть старый клиент в ветке [`legacy`](https://github.com/levvs-one/sora-client/tree/legacy).

## Linux

Пакеты собираются для Debian и Ubuntu (.deb), Fedora и openSUSE (.rpm) и Arch (.pkg.tar.zst).

```sh
curl -fsSL https://github.com/levvs-one/sora-client/releases/latest/download/install.sh | sh
```

Скрипт определит менеджер пакетов (apt, dnf, zypper или pacman), скачает два пакета, сверит их с `SHA256SUMS` и установит через `sudo`. Если хотя бы одна сумма не совпала, ничего не ставится.

Пакетов два:

- `sora-core`: служба, ядра sing-box, Xray и mihomo, zapret;
- `sora`: приложение, зависит от `sora-core` той же версии.

На ARM64 собирается только `sora-core`, приложение для этой архитектуры Flutter не собирает.

Вручную, например на Arch:

```sh
sha256sum -c SHA256SUMS --ignore-missing
sudo pacman -U sora-core-1.0.5-1-x86_64.pkg.tar.zst sora-1.0.5-1-x86_64.pkg.tar.zst
```

На Debian и Ubuntu:

```sh
sudo apt install ./sora-core_1.0.5_amd64.deb ./sora_1.0.5_amd64.deb
```

Что ставится:

| Где | Что |
| --- | --- |
| `/usr/bin/sora` | приложение (сами файлы в `/usr/lib/sora/app`) |
| `/usr/bin/sora-core` | служба |
| `/usr/lib/sora/engines` | ядра и базы geoip, geosite |
| `/usr/lib/systemd/system/sora-core.service` | служба systemd |
| `/var/lib/sora` | данные службы |
| `/run/sora/core.sock` | сокет, через который приложение говорит со службой |

После установки пакет сам создаёт пользователя `sora` и запускает службу. Приложение подключается к ней без пароля, если вы сидите за компьютером (это проверяет polkit). На машине без polkit добавьте себя в группу `sora`:

```sh
sudo usermod -aG sora $USER
```

Обновление: снова выполните команду установки или поставьте новые пакеты. Удаление: `sudo apt remove sora sora-core`, `sudo dnf remove sora sora-core` или `sudo pacman -R sora sora-core`.

Значок в трее появляется на панелях, которые поддерживают StatusNotifierItem: KDE, GNOME с расширением AppIndicator, Waybar с модулем `tray`, XFCE и другие. Если трея нет, закрытие окна закрывает только интерфейс, подключение продолжает работать в службе.
