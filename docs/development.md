# Разработка и сборка

## Что нужно

| Инструмент | Версия | Зачем |
| --- | --- | --- |
| Go | 1.26 | служба |
| Flutter | 3.47.6 | приложение |
| buf | 1.50 | контракт, генерация кода |
| protoc-gen-go, protoc-gen-go-grpc | 1.36.5, 1.5.1 | Go-код контракта |
| protoc_plugin (Dart) | 25.1.0 | Dart-код контракта |
| golangci-lint | 2.14 | линтер Go |
| nfpm | 2.47 | пакеты Linux |
| Inno Setup | 6.7 | установщик Windows |

## Каталоги

| Каталог | Что там |
| --- | --- |
| `core` | служба на Go, см. [core/README.md](../core/README.md) |
| `app` | приложение на Flutter, см. [app/README.md](../app/README.md) |
| `proto` | контракт `sora.core.v1` |
| `packaging/engines` | `engines.lock` с версиями и суммами ядер, `fetch.sh` для загрузки |
| `packaging/linux`, `packaging/windows` | пакеты и установщик |
| `packaging/install` | `install.sh` и `install.ps1` |
| `service/linux` | unit systemd, sysusers, политика polkit |
| `third_party/zapret` | исходники zapret |

## Служба

```sh
cd core
go test -race ./...
golangci-lint run
GOOS=windows golangci-lint run
go build -o sora-core ./cmd/sora-core
```

Запуск без установки, на своём сокете и со своими данными:

```sh
packaging/engines/fetch.sh amd64 /tmp/sora-engines
go run ./cmd/sora-core -socket /tmp/sora.sock -data-dir /tmp/sora-data -engines-dir /tmp/sora-engines -allow-file-keys
```

Флаги `sora-core`:

| Флаг | Что делает |
| --- | --- |
| `-data-dir` | каталог данных |
| `-engines-dir` | где искать ядра |
| `-socket` | свой путь к сокету или каналу |
| `-engine` | закрепить ядро: `sing-box`, `xray` или `mihomo` |
| `-tunnel-port` | порт локального прокси, 0 выбирает свободный |
| `-bypass` | адреса через запятую, которые идут мимо туннеля |
| `-log-level` | `debug`, `info`, `warn`, `error` |
| `-check` | проверить ядра и права и выйти |
| `-allow-file-keys` | хранить ключ хранилища в файле, если системного хранилища ключей нет |
| `-version` | версия службы и контракта |
| `-print-token` | вывести токен управления |
| `-install-service`, `-uninstall-service` | Windows: зарегистрировать или удалить службу `SoraCore` |

Тесты с настоящими ядрами. Если указать пути к ядрам, каждая собранная конфигурация проверяется самим ядром и через каждое ядро идёт настоящий трафик до локального сервера Xray:

```sh
SORA_SINGBOX_BIN=/tmp/sora-engines/sing-box \
SORA_XRAY_BIN=/tmp/sora-engines/xray \
SORA_MIHOMO_BIN=/tmp/sora-engines/mihomo \
SORA_ENGINES_DIR=/tmp/sora-engines \
go test ./...
```

## Приложение

```sh
cd app
flutter pub get
flutter analyze
flutter test
SORA_CORE_SOCKET=/tmp/sora.sock flutter run -d linux
```

Живые тесты идут против запущенной службы и по умолчанию пропускаются:

- `test/live_core_test.dart` при `SORA_CORE_LIVE=1`: подключение к службе, токен, базовые вызовы;
- `test/live_tunnel_test.dart` при `SORA_TUNNEL_LIVE=vless://...` локального сервера и `SORA_TUNNEL_LOG` с путём к его журналу: настоящий трафик через TUN и через системный прокси. Нужны права на создание адаптера, поэтому в CI тест идёт на Windows с установленной службой.

## Контракт

Описание в `proto/sora/core/v1/core_control.proto`. После изменения:

```sh
cd proto
buf lint
buf breaking --against '../.git#branch=main,subdir=proto'
buf generate
cd ../app && dart format lib/src/generated
```

Go-код попадает в `core/gen`, Dart-код в `app/lib/src/generated`, оба коммитятся. Новое поле помечается комментарием «Since 1.N», а версия контракта поднимается в `core/cmd/sora-core/main.go` и `app/lib/src/core/link.dart`.

## Ядра

Версии и SHA-256 всех сборок записаны в `packaging/engines/engines.lock`. `fetch.sh` скачивает их и останавливается, если сумма не совпала. Чтобы обновить ядро, поменяйте ссылку и сумму в `engines.lock` и прогоните тесты с настоящими ядрами.

## Пакеты и установщик

Linux, после сборки службы, ядер, zapret и приложения:

```sh
SORA_ARCH=amd64 SORA_VERSION=1.0.4 nfpm package --config packaging/linux/nfpm.yaml --packager deb --target dist/
SORA_ARCH=amd64 SORA_VERSION=1.0.4 nfpm package --config packaging/linux/nfpm-app.yaml --packager deb --target dist/
```

`--packager rpm` и `--packager archlinux` дают остальные форматы.

Windows, из корня репозитория:

```powershell
cd core; go build -o ..\dist\windows\sora-core.exe .\cmd\sora-core; cd ..
bash packaging/engines/fetch.sh windows-amd64 dist/windows/engines
cd app; flutter build windows --release --dart-define=SORA_VERSION=1.0.4; cd ..
iscc /DAppVersion=1.0.4 packaging\windows\sora.iss
```

## CI

На каждый pull request:

- линт workflow, линт и проверка совместимости контракта;
- тесты и линтер Go, сборка под все платформы, CodeQL, govulncheck, проверка зависимостей, поиск секретов;
- анализ и тесты приложения, сборка под Linux;
- Windows: тесты Go на Windows, сборка установщика, снимки экрана установщика и приложения, установка через `install.ps1`, проверка службы, живые тесты подключения и трафика, удаление;
- пакеты Linux для amd64 и arm64; на amd64 пакеты ставятся через `install.sh` на Ubuntu и в контейнерах Fedora и Arch, и проверяется, что служба запустилась.

## Выпуск

1. Поднять версию в `app/pubspec.yaml` и запись в `CHANGELOG.md`.
2. После слияния в `main` поставить тег `vX.Y.Z` и отправить его.
3. CI соберёт всё с этой версией и создаст черновик релиза с пакетами, установщиком, `install.sh`, `install.ps1` и `SHA256SUMS`.
4. Написать текст релиза и опубликовать черновик.
