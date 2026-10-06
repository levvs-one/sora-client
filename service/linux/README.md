# service/linux

Интеграция службы ядра `sora-core` с Linux. Код службы — в `core/cmd/sora-core`,
здесь системные файлы.

| Файл | Куда ставится | Что делает |
| --- | --- | --- |
| `sora-core.service` | `/usr/lib/systemd/system/` | служба ядра под пользователем `sora` с песочницей systemd |
| `sora.sysusers` | `/usr/lib/sysusers.d/sora.conf` | пользователь и группа `sora` |

## Как устроено

- Ядро работает от отдельного пользователя `sora`. Kill switch на nftables
  пропускает трафик движков по их uid, поэтому ядро и движки не должны делить
  учётную запись с человеком.
- Интерфейс подключается к `/run/sora/core.sock`. Сокет пускает пользователя
  `sora` и участников группы `sora`; остальные учётные записи получают отказ ещё до
  токена. Добавить себя в группу: `sudo usermod -aG sora $USER`, затем перелогиниться.
- Данные ядра — токен, шифрованное хранилище секретов, состояние движков — лежат в
  `/var/lib/sora` с правами 0700. Ключ хранилища защищён правами файла.
- Движки и базы geoip/geosite лежат в `/usr/lib/sora/engines`.
- Возможности ограничены `CAP_NET_ADMIN`, `CAP_NET_BIND_SERVICE` и `CAP_NET_RAW`:
  это tun, маршруты и nftables. Из устройств доступен только `/dev/net/tun`,
  файловая система только для чтения, кроме своих каталогов, домашние каталоги
  скрыты. `systemd-analyze security` оценивает службу в 4.0.

## Установка вручную

```sh
sudo install -Dm755 sora-core /usr/bin/sora-core
sudo install -Dm644 service/linux/sora-core.service /usr/lib/systemd/system/sora-core.service
sudo install -Dm644 service/linux/sora.sysusers /usr/lib/sysusers.d/sora.conf
sudo systemd-sysusers
sudo systemctl daemon-reload
sudo systemctl enable --now sora-core
```

При удалении пакет останавливает службу; ядро на остановке само снимает таблицу
nftables `sora`. Если служба была убита, таблицу снимает `sudo nft delete table inet sora`.
