# app

Приложение Sora на Flutter для Windows и Linux. Работает от имени пользователя и общается со службой `sora-core` через gRPC: unix-сокет на Linux, именованный канал на Windows. Подписки хранит служба, приложение хранит только настройки интерфейса.

## Запуск

```sh
flutter pub get
flutter test
flutter run -d linux
```

Служба из пакета слушает `/run/sora/core.sock`. Чтобы подключиться к службе, запущенной вручную, укажите её сокет:

```sh
sora-core -socket "$XDG_RUNTIME_DIR/sora-core.sock" -data-dir ~/.local/share/sora-dev/core
SORA_CORE_SOCKET="$XDG_RUNTIME_DIR/sora-core.sock" flutter run -d linux
```

Номер версии передаётся при сборке: `--dart-define=SORA_VERSION=1.0.3`. Без него в окне «О приложении» будет `dev`.

## Где что

| Путь | Что там |
| --- | --- |
| `lib/main.dart` | запуск, тема, язык |
| `lib/src/sora.dart` | состояние приложения и запросы к службе |
| `lib/src/core` | связь со службой, транспорт именованного канала для Windows |
| `lib/src/desktop` | трей, уведомления, системный прокси, ссылки `sora://` и `happ://` |
| `lib/src/ui` | экраны |
| `lib/src/design` | цвета, шрифт, анимации |
| `lib/l10n` | строки на русском и английском |
| `test` | тесты; `live_*` запускаются против настоящей службы |

Шрифт Inter 4.1 (OFL) лежит в `assets/fonts`.
