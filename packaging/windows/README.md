# packaging/windows

Установщик Sora для Windows 10 (1809) и 11, x64: приложение, ядро с движками и
служба `SoraCore`. Собирается [Inno Setup 6.7](https://jrsoftware.org/isinfo.php) или новее
из `sora.iss`.

- Ядро регистрирует себя службой само (`sora-core.exe -install-service`):
  автозапуск, перезапуск после сбоя, данные в `%ProgramData%\Sora`. Повторная
  установка обновляет службу на месте; удаление программы её снимает.
- Приложение говорит с ядром через именованный канал `\\.\pipe\sora-core-v1`.
  В канал пускает только систему, администраторов и того, кто сидит за
  компьютером; токен выдаёт `Handshake`.
- Движки — сборки для `windows-amd64` из
  [`engines.lock`](../engines/engines.lock), проверенные по SHA-256.

## Сборка

```powershell
cd core; go build -trimpath -ldflags '-s -w' -o ..\dist\windows\sora-core.exe .\cmd\sora-core; cd ..
bash packaging/engines/fetch.sh windows-amd64 dist/windows/engines
cd app; flutter build windows --release --dart-define=SORA_VERSION=0.3.0; cd ..
iscc /DAppVersion=0.3.0 packaging\windows\sora.iss
```

CI делает то же в каждом pull request, ставит установщик молча, проверяет, что
служба запущена, подключается к ней из приложения через канал и удаляет.

## Чего пока нет

- Kill switch на WFP: на Windows переключатель «Интернет только через VPN» не
  блокирует трафик.
- Подпись кода: установщик и программа не подписаны, SmartScreen предупредит.
- Обход без сервера: zapret для Windows (`winws`, WinDivert) не встроен.
