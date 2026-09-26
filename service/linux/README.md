# service/linux

Интеграция службы ядра `sora-core.service` с Linux. Код службы находится в `core/cmd/sora-core`, здесь лежат системные файлы.

## Что здесь будет

- Unit-файл systemd с возможностями `CAP_NET_ADMIN` и `CAP_NET_BIND_SERVICE` и строгой песочницей.
- Файлы sysusers и tmpfiles для группы `sora` и сокета `/run/sora/core.sock`.
- Сценарии пакетов, которые при удалении снимают таблицу nftables `sora` и возвращают DNS.
