# mihomo как управляемое ядро клиента Sora

Дата проверки: **01.10.2026**. Все утверждения ниже взяты из первичных источников (репозиторий
`MetaCubeX/mihomo` на пине релизного тега и официальная документация `wiki.metacubex.one`).
Там, где первичного подтверждения нет, стоит пометка **«не подтверждено»**.

## 0. Методика и одна важная оговорка про состояние источников

- Проверка исходников выполнена по **релизному тегу `v1.19.32`**, а не по ветке `main`/`master`.
  Причина: в снимке GitHub на 01.10.2026 объект репозитория `MetaCubeX/mihomo` на уровне
  ветки отдаёт содержимое стороннего Python-проекта (описание «A simple Python Pydantic model for
  Honkai: Star Rail…», `language: Python`, автоопределённая лицензия `MIT`, файл `LICENSE` 1049 байт
  «Copyright 2023 KT»): <https://api.github.com/repos/MetaCubeX/mihomo>,
  <https://raw.githubusercontent.com/MetaCubeX/mihomo/main/LICENSE>.
  Дерево того же репозитория по тегу `v1.19.32` — это реальный Go-движок (`main.go`, `hub/`, `config/`,
  `tunnel/`, `transport/`, `Dockerfile`) с `LICENSE` 35149 байт (GPL-3.0):
  <https://api.github.com/repos/MetaCubeX/mihomo/contents?ref=v1.19.32>.
- Практический вывод для Sora: **фиксировать ядро нужно по тегу + SHA blob файла**, а не по
  «последнему коммиту в main», и перепроверять `LICENSE` по этому же SHA. Иначе есть риск поставить
  в сборку артефакт/метаданные с другим лицензионным статусом.
- Релизный тег на дату проверки: **`v1.19.32`**, опубликован **2026-09-30T17:09:36Z**
  (`published_at`, автор `github-actions[bot]`, `prerelease: false`):
  <https://api.github.com/repos/MetaCubeX/mihomo/releases/latest>.
  Рядом висит prerelease `Alpha v1.19.31`. Ассеты идут по всем платформам в `.gz`
  (например `mihomo-android-386-v1.19.32.gz`, `mihomo-freebsd-amd64-compatible-v1.19.32.gz`,
  у каждого ассета указан `digest: sha256:...`).
- Документация: `https://wiki.metacubex.one` (en/ru/zh). Даты страниц сняты с футеров и указаны
  в каждой ссылке.

## 1. Лицензия и совместимость со GPL-3.0

| Вопрос | Факт | Источник |
|---|---|---|
| Файл `LICENSE` | Стандартный текст **GNU GPL v3** (заголовок `GNU GENERAL PUBLIC LICENSE / Version 3, 29 June 2007`), 35149 байт, blob sha `f288702d2fa16d3cdf0035b15a9fcbc552cd88e7`. Дополнительных пунктов после `END OF TERMS AND CONDITIONS` нет | <https://raw.githubusercontent.com/MetaCubeX/mihomo/v1.19.32/LICENSE> |
| Формулировка в README | «This software is released under the **GPL-3.0** license. **In addition, any downstream projects not affiliated with `MetaCubeX` shall not contain the word `mihomo` in their names.**» | <https://raw.githubusercontent.com/MetaCubeX/mihomo/v1.19.32/README.md> |
| Производные зависимости | `go.mod` модуля `github.com/metacubex/mihomo` зависит от форков `metacubex/sing-*` (sing-tun, sing-quic, sing-shadowsocks, sing-vmess, sing-wireguard, sing-mux), `metacubex/tailscale`, `metacubex/wireguard-go`, `metacubex/gvisor` | <https://raw.githubusercontent.com/MetaCubeX/mihomo/v1.19.32/go.mod> |
| sing-box (для сравнения) | `LICENSE` = GPL-3.0 + доп. пункт: «In addition, no derivative work may use the name or imply association with this application without prior consent» | <https://raw.githubusercontent.com/SagerNet/sing-box/testing/LICENSE> |
| Xray-core (для сравнения) | `Mozilla Public License 2.0` (по метаданным форка Happ-proxy) | <https://github.com/orgs/Happ-proxy/repositories> |

Совместимость с Sora (GPL-3.0, форк v2rayN 5.39, см. `NOTICE.md` в репозитории Sora):

- **GPL-3.0 → GPL-3.0: совместимо.** mihomo распространяется в составе GPL-3.0-приложения без конфликта
  лицензий. Текст лицензии: <https://www.gnu.org/licenses/gpl-3.0.html>.
- **Форма «дочерний процесс + REST-контроллер» не является линковкой.** Это «aggregate/work served
  on the same medium» в терминах §5 GPL-3.0: отдельная программа, запускаемая как отдельный бинарник.
  Обязательства всё равно возникают, потому что бинарник mihomo распространяется вместе с Sora.
- **Что обязательно при дистрибуции бинарника mihomo (unmodified):**
  1. accompanying **Complete Corresponding Source** для этой версии — по §6 допустимо сопровождать
     объектный код письменным предложением либо указывать официальный источник сборки (релизный тег
     `v1.19.32`); для Sora практически: в установщике/репозитории указать точный тег и положить `LICENSE`;
  2. сохранить **текст GPL-3.0** и все copyright-пометы в поставляемом артефакте;
  3. **заявить об изменениях**, если конфигурация/патчи/сборка отличаются от апстрима (§5a), и отметить,
     что Sora не аффилирована с MetaCubeX;
  4. записать в `THIRD-PARTY-NOTICES.md`: название, версия, лицензия GPL-3.0, URL исходников, хэш
     артефакта (`digest: sha256:...` есть у каждого ассета релиза — удобный якорь);
  5. если Sora когда-нибудь будет **слинкована** с mihomo как Go-библиотека — продукт становится одним
     произведением под GPL-3.0. Sora уже GPL-3.0, поэтому лицензия не ломается, но обязывает открыть
     весь код производного бинарника.
- **Риск-фактор по имени.** Оговорка в README запрещает неаффилированным downstream-проектам содержать
  слово `mihomo` **в названии проекта**. Формально это «additional restriction», и его применимость к
  производным по GPL §10 спорна — юридическую оценку должен давать юрист. Практическое решение для
  Sora: не называть никак внешние артефакты/классы/настройки «mihomo», а в `NOTICE.md` зафиксировать
  «Sora не связана с MetaCubeX» (тот же паттерн, что уже применён для OpenAI/Flyfrog/Happ).

## 2. Путь встраивания: библиотека Go или дочерний процесс + REST?

**Вывод: официального, документированного пути «mihomo как Go-библиотека» нет; штатный путь —
отдельный процесс, управляемый через external controller (REST/HTTP + WebSocket).**

Подтверждения:

- В списке возможностей README ядро прямо описано как having a «**Comprehensive HTTP RESTful API
  controller**»: <https://raw.githubusercontent.com/MetaCubeX/mihomo/v1.19.32/README.md>.
- Раздел «Внешний контроль (API)» документации:

  > «Внешний контроллер, с помощью которого можно управлять ядром через RESTful API.
  > Адрес прослушивания API; замените `127.0.0.1` на `0.0.0.0`, чтобы слушать все адреса»
  >
  > Источник (страница «通用配置 / General configuration», дата в футере 2026-07-08):
  > <https://wiki.metacubex.one/ru/config/general/> и <https://wiki.metacubex.one/en/config/general/>

  Дословные YAML-фрагменты страницы general (ключи — английский оригинал):

  ```yaml
  external-controller: 127.0.0.1:9090          # RESTful API
  external-controller-cors:
    allow-origins:
      - '*'
    allow-private-network: true
  external-controller-unix: mihomo.sock        # Unix socket; секрет НЕ проверяется
  external-controller-pipe: \\.\pipe\mihomo    # Windows named pipe; секрет НЕ проверяется
  external-controller-tls: 127.0.0.1:9443      # HTTPS-API; требует tls-секцию; external-controller тоже обязателен
  external-controller-routing-mark: 0          # только Linux
  external-doh-server: /dns-query              # DoH поверх API-порта; секрет НЕ проверяется
  secret: ""                                   # ключ доступа к API
  external-ui: /path/to/ui/folder              # отдаётся по http://<controller>/ui
  external-ui-name: xd
  external-ui-url: "https://github.com/MetaCubeX/metacubexd/archive/refs/heads/gh-pages.zip"
  ```

- Дословные оговорки документации (перевод + смысл оригинала):
  - `external-controller-unix` / `external-controller-pipe`: «при обращении к API из Unix-сокета /
    Windows named pipe **секрет не проверяется**, безопасность — на вашей стороне»;
  - `external-doh-server`: «этот URL **не проверяет secret**»;
  - `external-ui`: «может быть абсолютным путём или путём **относительно рабочей директории**»;
    «если путь вне рабочего каталога — добавьте его в переменную окружения `SAFE_PATHS`
    (разделитель `;` в Windows, `:` в других ОС)».
- Пример `config.yaml` того же тега подтверждает практические значения и уточнения:
  `external-controller: 0.0.0.0:9093`, `secret: "123456"  # Authorization:Bearer ${secret}`,
  «`external-controller-unix` — Windows-версия выше 17063 (то есть 1803/RS4) тоже поддерживает»,
  тест через `curl -v --unix-socket "mihomo.sock" http://localhost/`:
  <https://raw.githubusercontent.com/MetaCubeX/mihomo/v1.19.32/docs/config.yaml>.
- Про «библиотеку»: модуль называется `github.com/metacubex/mihomo`, точка входа `main.go` использует
  внутренние пакеты (`hub.Parse(configBytes, hub.WithExternalController(...), hub.WithSecret(...))`,
  `executor.Shutdown()`). Это **внутренние** API без гарантий стабильности; отдельной страницы/дока
  про «use as library» в документации нет; наличие публичного Go-API — **не подтверждено**
  (<https://raw.githubusercontent.com/MetaCubeX/mihomo/v1.19.32/main.go>).
  Для Sora это плюс: интеграция через REST не связывает нас с внутренностями ядра и не превращает
  Sora в единое произведение по GPL.

**Рекомендуемая архитектура для Sora** (вывод из перечисленных фактов, не цитата):

1. один экземпляр ядра на профиль/сессию, рабочий каталог = `--home-dir`-аналог (флаг `-d`);
2. контроллер только на loopback (`external-controller: 127.0.0.1:<порт из диапазона Sora>`),
   `secret` — случайный токен на запуск, передавать **через флаг `-secret`**, а не через файл;
3. `external-controller-unix`/`-pipe`/`external-doh-server` **не включать** (обходят secret);
4. handshake клиента: `GET /version` (см. §3) + сверка с `-v` баннером процесса;
5. конфиг передавать через `-config <base64>` или `-f -` (stdin) — см. §5, чтобы не писать секреты
   на диск и не зависеть от `SAFE_PATHS`.


## 3. REST / HTTP API внешнего контроллера

Источник: страница «APIs», <https://wiki.metacubex.one/en/api/> (дата в футере **2026-07-18**),
русская версия <https://wiki.metacubex.one/ru/api/> (2026-07-18), китайская
<https://wiki.metacubex.one/api/> (2026-07-03). Все тела ответов ниже — пересказ этой страницы;
дословные цитаты помечены кавычками.

Общий контракт доступа (дословно из страницы):

```
curl -H 'Authorization: Bearer ${secret}' http://${controller-api}/configs?force=true \
     -d '{"path": "", "payload": ""}' -X PUT
```

> «`${secret}` — ключ API, заданный в конфигурационном файле; `${controller-api}` — адрес
> прослушивания API; `?force=true` — параметр, который требуется для части запросов;
> `{"path": "", "payload": ""}` — данные обновляемого ресурса».
> «Если нужно передать путь **вне рабочего каталога mihomo**, добавьте его в `SAFE_PATHS`».

### 3.1 Рукопожатие и телеметрия

| Эндпоинт | Метод | Параметры | Ответ |
|---|---|---|---|
| `/version` | GET | — | `meta` (bool — «ядро Meta»), `version` (строка версии) |
| `/traffic` | GET **или WS** | — | раз в секунду: `up`, `down` (**байт/с**), `upTotal`, `downTotal` (**байт**) |
| `/memory` | GET **или WS** | — | раз в секунду: `inuse` (байт), `oslimit` (байт, «зафиксирован 0») |
| `/logs` | GET **или WS** | `?level=info|warning|error|debug`; `?format=structured` | стандарт: `{type, payload}` (по строке JSON за раз); structured: `{time (HH:MM:SS), level, message, fields[]}` |
| `/cache/fakeip/flush` | POST | — | 204, тела нет |
| `/cache/dns/flush` | POST | — | 204, тела нет |
| `/dns/query` | GET | `?name=example.com&type=A` | `Status`(Rcode), `Question[]`, `TC`, `RD`, `RA`, `AD`, `CD`, `Answer[]` (`name`,`type`,`TTL`,`data`), `Authority[]`, `Additional[]` |
| `/storage/{key}` | GET / PUT / DELETE | PUT — валидный JSON, **макс. 1 МБ** | GET — сохранённое JSON либо `null`; PUT/DELETE — 204 |
| `/debug/gc` | PUT | — | 204 (требует `log-level: debug` при запуске) |
| `/debug/pprof` | GET | `?raw=true` | сырой pprof (`heap`, `allocs`) |

### 3.2 Конфигурация, перезагрузка, обновления

| Эндпоинт | Метод | Параметры / тело | Ответ |
|---|---|---|---|
| `/configs` | GET | — | JSON рабочего конфига: «содержит поля `port`, `socks-port`, `mixed-port`, `mode`, `log-level`, `allow-lan`, `ipv6`, `tun` и т. д.» |
| `/configs` | **PUT** | `?force=true`; тело `{"path": "", "payload": ""}` | 204 — «перезагрузка базовой конфигурации» |
| `/configs` | **PATCH** | `{"mixed-port": 7890}` | 204 — частичное обновление без перезапуска |
| `/configs/geo` | POST | `{"path": "", "payload": ""}` | 204 — обновление GEO-баз |
| `/restart` | присутствует в оглавлении API; **точный HTTP-метод — не подтверждено** (тело раздела попало в обрезанный снимок страницы) | — | — |
| `/upgrade`, `/upgrade/ui`, `/upgrade/geo` | присутствуют в оглавлении; **семантика и методы — не подтверждено** | — | — |

Семантика `force=true`: документация описывает `?force=true` как параметр, «который требуется для
некоторых запросов», и показывает его именно на `PUT /configs` с телом `path`/`payload`. Точное
поведение без `force=true` в доках **не описано — не подтверждено**.

Профильные эндпоинты (`/profiles`, `PUT /profiles?name=`), которые встречаются в clash-ориентированных
клиентах, на странице API **отсутствуют**: в оглавлении их нет, вместо них описан `/storage/{key}`.
Статус: **не подтверждено** — не портировать вслепую.

### 3.3 Группы, прокси, тесты задержки

| Эндпоинт | Метод | Параметры / тело | Ответ |
|---|---|---|---|
| `/group`, `/group/{name}`, `/group/{name}/delay` | есть в оглавлении (алиасы к `/proxies*`); **поля и семантика — не подтверждено** | — | — |
| `/proxies` | GET | **параметр `lazy` — не подтверждён** (в полученном снимке страницы его нет) | словарь прокси и групп; у группы, кроме общих полей: `now` (текущий выбранный; у `LoadBalance` **нет** `now`), `all[]`, `testUrl`, `hidden`, `icon`, `emptyFallback`, `expectedStatus`, `fixed` (только `URLTest`/`Fallback`) |
| `/proxies/{name}` | GET | — | объект прокси/группы (те же поля) |
| `/proxies/{name}` | **PUT** | `{"name":"日本"}` | 204 — выбрать узел в группе |
| `/proxies/{name}` | **DELETE** | — | 204 — сброс `fixed` (кроме типа `Selector`) |
| `/proxies/{name}/delay` | GET | **`?url=xxx&timeout=5000`**; опционально `?expected=200/204` либо `200-299` | `{"delay": <мс, uint16>}` |

Единицы: `timeout` — **миллисекунды** (в примере `5000`), `delay` — **миллисекунды**; `expected`
поддерживает синтаксис `/` (список) и `-` (диапазон).


### 3.4 Proxy-провайдеры (наборы прокси)

| Эндпоинт | Метод | Ответ |
|---|---|---|
| `/providers/proxies` | GET | `providers` — объект, ключ = имя набора, значение = мета-информация + список прокси |
| `/providers/proxies/{name}` | GET | объект набора (конфиг + `proxies`) |
| `/providers/proxies/{name}` | **PUT** | 204 — обновить (перетянуть подписку) |
| `/providers/proxies/{name}/healthcheck` | GET | 204 — запустить health-check набора |
| `/providers/proxies/{name}/{proxy}` | GET | объект прокси |
| `/providers/proxies/{name}/{proxy}/healthcheck` | GET | `?url=xxx&timeout=5000` → `{"delay": мс}` |

### 3.5 Правила и наборы правил

| Эндпоинт | Метод | Ответ / тело |
|---|---|---|
| `/rules` | GET | `rules[]`: `index` (с 0), `type` (`DOMAIN`, `IP-CIDR`, `GEOIP`, …), `payload`, `proxy`, `size` (только `GEOIP`/`GEOSITE`, иначе `-1`), опц. `extra`: `disabled`, `hitCount`, `hitAt`, `missCount`, `missAt` |
| `/rules/disable` | **PATCH** | тело `{"0": false, "1": true}` → 204; «временная операция, **сбрасывается после перезапуска**» |
| `/providers/rules` | GET | `providers` — объект по именам наборов правил |
| `/providers/rules/{name}` | PUT | 204 — обновить набор правил |

### 3.6 Соединения

| Эндпоинт | Метод | Параметры | Ответ |
|---|---|---|---|
| `/connections` | GET **или WS** | `?interval=<мс>` (по умолчанию 1000) | `downloadTotal`, `uploadTotal` (байт), `memory` (байт), `connections[]`: `id`, `metadata` (адреса/протокол/имя процесса), `upload`, `download`, `start`, `chains[]`, `providerChains[]`, `rule`, `rulePayload` |
| `/connections` | DELETE | — | 204 — закрыть все |
| `/connections/{id}` | DELETE | — | 204 — закрыть одно |

### 3.7 Версионные различия (1.18.x против текущих)

- Актуальная стабильная ветка — **1.19.x** (`v1.19.32`, 2026-09-30). Строка `1.18.x` в доках ещё
  встречается как пример (в `proxy-providers` показан `User-Agent: "mihomo/1.18.3"`):
  <https://wiki.metacubex.one/en/config/proxy-providers/> (2026-08-16).
- В **релизных заметках 1.19.x** ломающих изменений REST API не найдено; там преимущественно фиксы и
  фичи протоколов/стаков. Примеры из `v1.19.32`: «feat: add load-balance `hash-key` to pin a session on
  the inbound user», «fix: default listener tun to mips stack», фиксы `anytls`, `sing-mux`,
  `hysteria2`, `trusttunnel`, `xhttp`, `OpenVPN`: <https://github.com/MetaCubeX/mihomo/releases/tag/v1.19.32>.
- Сигнал смены поведения: **авто-перезагрузка файлов сертификатов** работает «начиная с v1.19.18»
  (страница general, раздел TLS) — до 1.19.18 для смены сертификата API требовался перезапуск.
- Прямое сравнение маршрутов между 1.18 и 1.19 по первичному источнику **не подтверждено**
  (`.../contents/api?ref=v1.19.32` в текущем снимке GitHub отдаёт 404). Практический вывод: **пинить
  точную версию ядра**, делать handshake через `GET /version` и держать smoke-тест на каждый
  эндпоинт из этого раздела перед обновлением ядра (см. §7).


## 4. Ключи конфигурации, которые Sora должна уметь генерировать

### 4.1 Обязательное против опционального

Формальной JSON-схемы «минимального конфига» документация не публикует. Пометка **«Required»** в доках
стоит ровно на этих полях:

| Секция | Обязательные поля | Источник (дата страницы) |
|---|---|---|
| `proxies[]` | `name`, `type`, `server`, `port` | <https://wiki.metacubex.one/en/config/proxies/> (2026-05-14) |
| `proxy-groups[]` | `name`, `type` | <https://wiki.metacubex.one/en/config/proxy-groups/> (2026-08-16) |
| `proxy-providers` | `name`, `type` (`http`/`file`/`inline`); `url` — обязателен при `type: http` | <https://wiki.metacubex.one/en/config/proxy-providers/> (2026-08-16) |

Минимальный практически рабочий конфиг (вывод из примера `docs/config.yaml` той же версии, где
единственный незакомментированный вход — `mixed-port: 10801`): `mixed-port` + `proxies` и/или
`proxy-providers` + `proxy-groups` + `mode` + `rules`. Проверка — офлайн-флаг `-t` (§5.7).

### 4.2 Общие ключи (страница «General configuration», 2026-07-08)

| Ключ | Значения / единицы | Комментарий из доков |
|---|---|---|
| `mixed-port`, `port`, `socks-port`, `redir-port`, `tproxy-port` | int | верхнеуровневые входы; «подходят, когда нужен один фиксированный набор портов» (стр. inbound, 2026-07-18) |
| `listeners[]` | `name`, `type`, `port`, `listen`, `rule`, `proxy`, `udp` | несколько входов; «`listen: 0.0.0.0` слушает все интерфейсы; HTTP/SOCKS/Mixed без TLS нельзя выставлять в интернет» |
| `allow-lan` | bool | доступ других устройств к прокси-портам |
| `bind-address` | `"*"`, IPv4, `[IPv6]` | только при `allow-lan: true` |
| `lan-allowed-ips` / `lan-disallowed-ips` | CIDR-списки | дефолт белого списка `0.0.0.0/0` и `::/0`; **чёрный список приоритетнее** |
| `authentication`, `skip-auth-prefixes` | `user:pass`, CIDR | авторизация http/socks/mixed-входов |
| `mode` | `rule` / `global` / `direct` | дефолт `rule`; для `global` нужен выбор в группе `GLOBAL` |
| `log-level` | `silent`/`error`/`warning`/`info`/`debug` | вывод в консоль и в веб-панель |
| `ipv6` | bool, дефолт `true` | «выключение блокирует все IPv6-соединения и глушит AAAA-запросы» (комментарий в `docs/config.yaml`) |
| `keep-alive-interval`, `keep-alive-idle`, `disable-keep-alive` | сек/bool | «уменьшение расхода батареи на мобильных»; на Android keep-alive принудительно отключён |
| `find-process-mode` | `always` / `strict` (дефолт) / `off` | `off` рекомендован на роутерах |
| `unified-delay` | bool | считает RTT, убирает разницу рукопожатий разных типов узлов |
| `tcp-concurrent` | bool | коннект ко всем resolved IP, побеждает первый успешный |
| `interface-name`, `routing-mark` | строка/int | выходной интерфейс; fwmark (только Linux) |
| `profile.store-selected` | bool | «сохранять выбор группы из API, чтобы использовать при следующем старте» |
| `profile.store-fake-ip` | bool | сохранять таблицу соответствий fakeip |
| `geodata-mode` | bool, дефолт `false` | `true` = dat, иначе mmdb |
| `geodata-loader` | `standard` / `memconservative` (дефолт) | «для устройств с малой памятью» |
| `geo-auto-update`, `geo-update-interval` | bool / часы | автообновление GEO |
| `geox-url.{geoip,geosite,mmdb,asn}` | URL | кастомные зеркала GEO-файлов |
| `geosite-matcher` | `succinct` (дефолт) / `mph` | реализация матчера GeoSite (`docs/config.yaml`) |
| `global-ua` | строка, дефолт `clash.meta` | UA при скачивании внешних ресурсов |
| `etag-support` | bool, дефолт `true` | ETag для загрузки внешних ресурсов |
| `tls.{certificate,private-key,ech-key,custom-certifactes,client-auth-type,client-auth-cert}` | PEM/путь | «используется только для HTTPS API»; файлы сертификатов авто-перезагружаются **с v1.19.18** |
| `global-client-fingerprint` | — | **УСТАРЕЛО**: «глобальный TLS-отпечаток deprecated — ставьте `client-fingerprint` внутри proxy» |
| `experimental.{quic-go-disable-gso,quic-go-disable-ecn,dialer-ip4p-convert}` | bool | **весь** раздел experimental в доках (2026-07-18) ограничивается этими тремя ключами |
| `external-controller-cors.{allow-origins,allow-private-network}` | списки/bool | CORS для API |

Важная поправка к типичным шаблонам клиентов: ключей `experimental.cache-file` и
`experimental.sniff` в текущей документации **нет** — вместо первого документирован
`profile.store-selected`, а сниффинг вынесен в отдельный раздел «Domain sniffing»
(<https://wiki.metacubex.one/en/config/experimental/>, 2026-07-18). Актуальные имена этих ключей —
**не подтверждено** (нужен обход страницы sniffing).


### 4.3 TUN (`tun:`)

Источник: <https://wiki.metacubex.one/config/inbound/tun/> и <https://wiki.metacubex.one/en/config/inbound/tun/>
(обе 2026-09-14).

| Ключ | Значения | Комментарий из доков |
|---|---|---|
| `stack` | `system` / `gvisor` / `mixed` / `mips`, **дефолт `gvisor`** | «если нет проблем со стеком — используйте `mixed`»; `system` — системный стек (стабильнее/полнее, потребление памяти ниже остальных); `gvisor` — userspace-стек (изоляция); `mixed` — TCP идёт через system, UDP через gvisor; `mips` — собственный IP-стек mihomo |
| `enable`, `device`, `mtu` (дефолт 9000), `udp-timeout` (дефолт 300 с) | — | `device`: «на MacOS возможны только имена с префиксом `utun`» |
| `auto-route`, `auto-redirect`, `auto-detect-interface` | bool | `auto-redirect` — **только Linux** (iptables/nftables), требует `auto-route` |
| `dns-hijack` | `any:53`, `tcp://any:53` | «на MacOS/Windows нельзя автоматически перехватить DNS-запросы, уходящие в LAN; на Android при включённом Private DNS перехват не работает» |
| `strict-route` | bool | Linux: «не даёт непривязанным сетям достучаться, предотвращает утечки адресов, включает DNS-hijack на Android»; Windows: «добавляет правила брандмауэра против утечки DNS из-за многоадресного DNS-разрешения Windows; может сломать VirtualBox» |
| `gso`, `gso-max-size` | bool/int | только Linux |
| `inet6-address` | CIDR | при старте проверяется IPv6 на других интерфейсах; форс — `SKIP_SYSTEM_IPV6_CHECK=1` + `ipv6: true` |
| `route-address`, `route-exclude-address` (+ legacy `inet4-route-*`) | CIDR | кастомные маршруты при `auto-route` |
| `route-address-set`, `route-exclude-address-set` | имена rule-set | **только Linux + nftables + `auto-route` + `auto-redirect`; конфликтует с `routing-mark`** |
| `include-interface` / `exclude-interface` | список | взаимоисключающие |
| `include-uid[-range]`, `exclude-uid[-range]`, `include-mac-address`, `exclude-mac-address` | — | только Linux; UID требует `auto-route`, MAC требует `auto-route` + `auto-redirect` |
| `include-android-user`, `include-package`, `exclude-package` | UID / имена пакетов | **per-app routing на Android**; требует `auto-route` |
| `iproute2-table-index` (2022), `iproute2-rule-index` (9000), `endpoint-independent-nat` | — | тонкая настройка Linux |

### 4.4 Типы прокси (секция `proxies:`)

Общие поля (все подтверждены, стр. 2026-05-14): `name`, `type`, `server`, `port`, `ip-version`
(`dual`/`ipv4`/`ipv6`/`ipv4-prefer`/`ipv6-prefer`, дефолт `dual`), `udp` (дефолт `false`; включается
авто для UDP-протоколов и типов `direct`/`dns`), `interface-name`, `routing-mark`, `tfo`, `mptcp`,
`dialer-proxy`, `smux.*` (`enabled`, `protocol`: `smux`/`yamux`/`h2mux`, `max-connections`,
`min-streams`, `max-streams`, `statistic`, `only-tcp`, `padding`, `brutal-opts.{enabled,up,down}`).

Разделы «outbound proxy» официальной документации (en-навигация, страница 2026-05-14 и соседние):

```
HTTP, SOCKS, Shadowsocks, ShadowsocksR, Snell, VMess, VLESS, Trojan, AnyTLS, Mieru, Sudoku,
Hysteria, Hysteria2, TUIC, ShadowQUIC, WireGuard, EasyTier, Tailscale, SSH, MASQUE, TrustTunnel,
ZeroTier, OpenVPN
```

плюс «встроенные исходящие политики»: `DIRECT`, `DNS`, `Rematch`.

Что подтверждено дословно и что нет:

| Запрошенный Sora тип | Статус | Комментарий |
|---|---|---|
| `ss` (Shadowsocks) | **подтверждено**, `type: ss` | пример в str. common fields и в `payload` примера proxy-providers |
| `ssr` (ShadowsocksR) | страница есть («ShadowsocksR»); **точная строка значения — не подтверждена** | в `exclude-type` доки используют имена из Adapter Type (`Shadowsocks|Http`, `ss|http`) |
| `vmess`, `vless` (+Reality), `trojan`, `hysteria2`, `tuic`, `snell`, `wireguard`, `ssh`, `anytls`, `direct` | страницы есть; написание `ss` подтверждено, остальные — **не подтверждены посимвольно** | `anytls`, `hysteria2`, `trusttunnel`, `mieru`, `xhttp`, `openvpn`, `masque` встречаются в релизных заметках v1.19.32 |
| `reject` | частично | как цель правила встречается в примере `rules` (`DOMAIN,ad.com,REJECT`); отдельной страницы outbound-прокси нет → **не подтверждено** как значение `type:` |
| `source` | **не подтверждено** | в навигации раздела outbound отсутствует |
| `tuic v4/v5`, `hysteria2 realm` | подтверждено как **типы listener'ов** (входящие), str. inbound 2026-07-18 | это не исходящие |

Практический вывод: перед генерацией конфига Sora обязан получить точный список значений `type:`
живым прогоном `mihomo -t` на синтетическом конфиге (или вычитать из `docs/config.yaml` версии ядра,
которая у нас в сборке) — выдуманное написание типа приведёт к отказу парсинга.


### 4.5 Группы прокси (`proxy-groups:`)

Общие поля (страница «proxy-groups configuration», 2026-08-16):

| Ключ | Единицы/значение | Примечание из доков |
|---|---|---|
| `name`, `type` | обязательно | «при спецсимволах имя берётся в кавычки» |
| `proxies[]`, `use[]` | имена | ссылки на выходы и на наборы прокси |
| `url` | URL | адрес health-check; «проверяются только узлы из `proxies`, узлы из подключённых через `use` наборов **не** проверяются» |
| `interval` | **секунды** | если ≠ 0 — периодическая проверка включена |
| `lazy` | bool, дефолт `true` | «если группа не выбрана, проверки не выполняются» |
| `default-selected` | имя | если пусто/нет такого узла — берётся первый в группе |
| `empty-fallback` | имя, дефолт `COMPATIBLE` | узел-заглушка, когда группа пуста; **группа сюда не подходит** |
| `timeout` | **миллисекунды** | таймаут health-check |
| `max-failed-times` | int, дефолт 5 | после N неудач — принудительная проверка |
| `disable-udp` | bool | отключает UDP для группы |
| `interface-name`, `routing-mark` | — | **deprecated в группе**; приоритет: узел > политика > глобально |
| `include-all`, `include-all-proxies`, `include-all-providers` | bool | «включить все выходы/наборы, сортировка по имени»; в `include-all` группы не попадают |
| `filter`, `exclude-filter` | regex | несколько регулярок разделяются обратным апострофом `` ` `` |
| `exclude-type` | `Тип1|Тип2` | регулярки не поддерживаются, регистр игнорируется |
| `expected-status` | дефолт `*` | синтаксис: `200/302`, `400-503`, миксы |
| `hidden`, `icon` | bool/URL | отдаются в API, требуют адаптации фронта |

Типы групп по навигации доков: **Select (ручной выбор), Url-Test (автовыбор), Fallback (автооткат),
Load-Balance (балансировка), Relay (цепочка)**. Поля конкретных типов (`tolerance`,
`url-est-tolerance`, `salt`/`seed`, `relay`-фильтры и т. п.) находятся на отдельных страницах типов и
в этом обзоре **не подтверждены**. Подтверждено из API-страницы: у `LoadBalance` в ответе нет поля
`now`; `fixed` есть только у `URLTest` и `Fallback`; `expectedStatus` нет у `Selector`.
Из релизных заметок `v1.19.32`: у `load-balance` добавлен `hash-key` («pin a session on the inbound
user»).

### 4.6 Proxy-провайдеры (`proxy-providers:`) — подписки

Полный набор ключей (страница 2026-08-16):

| Ключ | Примечание |
|---|---|
| `type: http` / `file` / `inline` | обязательно |
| `url` | обязателен при `type: http` |
| `path` | файл набора; в примере `./proxy_providers/provider1.yaml` (путь относительно домашнего каталога) |
| `interval` | секунды (пример `3600`) |
| `proxy` | через какой узел скачивать (пример `DIRECT`) |
| `size-limit` | лимит размера файла набора |
| `age-secret-key` | ключ `age` для дешифрования подписки |
| `header` | заголовки запроса, напр. `User-Agent: ["mihomo/1.18.3"]`, `Authorization`, `X-Age-Public-Key` |
| `health-check.{enable,url,interval,timeout,lazy,expected-status}` | health-check набора |
| `override.{tfo,mptcp,udp,udp-over-tcp,down,up,skip-cert-verify,name-cert-verify,dialer-proxy,interface-name,routing-mark,ip-version}` | массовая правка узлов |
| `override.additional-prefix`, `override.additional-suffix` | префикс/суффикс имён узлов |
| `override.proxy-name[{pattern,target}]` | регулярковая замена имён |
| `override.override-expr` | подмножество языка `yq v4` (`.name = ...`, `del()`, `select()`, `map()`, `upcase` и др.) — для программной трансформации подписки |
| `filter`, `exclude-filter`, `exclude-type` | отбор узлов (`exclude-type: "ss|http"`) |
| `payload` | встроенный список узлов; используется и как **фолбэк**, когда `http`/`file` не распарсились |

Ключи `format`, `encoding`, `keep-old`, `no-hot-load`, `proxy-names-policy`, обычно припоминаемые из
старых клиентов, на этой странице **не приведены** — **не подтверждено**.


### 4.7 DNS (`dns:`)

Источник: <https://wiki.metacubex.one/en/config/dns/> (2026-07-18).

| Ключ | Значения | Примечание из доков |
|---|---|---|
| `enable` | bool | «если `false` — используется системное разрешение» |
| `cache-algorithm` | `lru` (дефолт) / `arc` | алгоритм кэша |
| `prefer-h3` | bool | DOH предпочитает HTTP/3 |
| `use-hosts`, `use-system-hosts`, `respect-rules` | bool | |
| `listen` | `0.0.0.0:1053` в примере | встроенный DNS-сервер (UDP и TCP) |
| `ipv6` | bool | «если `false` — пустой ответ на AAAA» |
| `enhanced-mode` | `fake-ip` / `redir-host` (**дефолт `redir-host`**) | режим обработки DNS |
| `fake-ip-range` | `198.18.0.1/16` в примере | «адрес TUN по умолчанию тоже ориентируется на это значение» |
| `fake-ip-range6`, `fake-ip-ttl`, `fake-ip-filter-mode` (`blacklist`), `fake-ip-filter` | — | фильтр вида `- '*.lan'` |
| `default-nameserver` | `223.5.5.5` в примере | разрешает имена самих DNS-серверов |
| `nameserver[]`, `fallback[]` | DoT/DoH/UDP | «fallback — резервные (обычно зарубежные) серверы» |
| `nameserver-policy` | ключ → серверы | поддержка префиксов (`+.arpa`) и **`rule-set:cn`** как ключа |
| `proxy-server-nameserver`, `proxy-server-nameserver-policy` | | разрешение имён узлов (лечит «курицу и яйцо») |
| `direct-nameserver`, `direct-nameserver-follow-policy` | | напр. `system` |
| `fallback-filter.{geoip,geoip-code,geosite,ipcidr,domain}` | `geoip-code` дефолт `CN` | «после настройки `fallback` фильтр включается по умолчанию»; `geosite` **deprecated — использовать `nameserver-policy`** |
| `fallback-lazy-query` | bool, дефолт `false` | |
| суффиксы URL сервера | `#proxy`, `&ecs=1.1.1.1/24`, `&ecs-override=true`, `&h3`, `&skip-cert-verify`, `&name-cert-verify`, `&disable-ipv4`, `&disable-ipv6`, `&disable-qtype-65`, `#RULES` | «`#RULES` — разрешать согласно правилам маршрутизации, эквивалент `respect-rules`» |

Ключ `policy/default/server-group` внутри `nameserver` (политики «прокси/прямые» для DNS-серверов) на
этой странице в явном виде не показан — **не подтверждено**; подтверждён механизм `#RULES` и
`direct-nameserver-follow-policy`.

### 4.8 Правила (`rules:`)

Источник: <https://wiki.metacubex.one/en/config/rules/> (2026-07-08). Приоритет — сверху вниз.

`DOMAIN`, `DOMAIN-SUFFIX`, `DOMAIN-KEYWORD`, `DOMAIN-WILDCARD` (`*`, `?`), `DOMAIN-REGEX`,
`GEOSITE`, `IP-CIDR`, `IP-CIDR6` (алиас), `IP-SUFFIX`, `IP-ASN`, `GEOIP`, `SRC-GEOIP`, `SRC-IP-ASN`,
`SRC-IP-CIDR`, `SRC-IP-SUFFIX`, `DST-PORT`, `SRC-PORT`, `IN-PORT`, `IN-TYPE`, `IN-USER`, `IN-NAME`,
`REMATCH-NAME`, `PROCESS-PATH`, `PROCESS-PATH-WILDCARD`, `PROCESS-PATH-REGEX`, `PROCESS-NAME`,
`PROCESS-NAME-WILDCARD`, `PROCESS-NAME-REGEX`, `UID`, `NETWORK`, `DSCP`, `RULE-SET`,
логические `AND`/`OR`/`NOT` (`AND,((DOMAIN,baidu.com),(NETWORK,UDP)),DIRECT`), `SUB-RULE`, `MATCH`.

Доп. параметры правила: `no-resolve` («только для правил по целевому IP; пропустить DNS-разрешение»),
`src` («превратить сопоставление по целевому IP в сопоставление по исходному IP»).
На Android `PROCESS-NAME*` матчит имена пакетов. Диалект wildcard'ов в `*-WILDCARD`
**отличается** от остального конфига — это отдельная ловушка для генератора.


### 4.9 Где ядро хранит состояние

| Факт | Статус |
|---|---|
| Домашний каталог задаётся флагом `-d` (или `CLASH_HOME_DIR`); относительный путь разрешается **относительно текущей директории процесса** (`filepath.Join(cwd, homeDir)`), затем `C.SetHomeDir` | подтверждено: `main.go` |
| Путь к конфиг-файлу по умолчанию = `<HomeDir>/<C.Path.Config()>`; абсолютный путь к `-f` разрешается относительно CWD | подтверждено: `main.go` |
| `profile.store-selected` хранит выбор групп между запусками; `profile.store-fake-ip` — таблицу fakeip | подтверждено: general 2026-07-08 |
| Файлы наборов прокси пишутся по `proxy-providers.<name>.path`, напр. `./proxy_providers/provider1.yaml` (относительно домашнего каталога) | подтверждено: proxy-providers 2026-08-16 |
| GEO-файлы скачиваются по `geox-url` и обновляются по `geo-auto-update`/`geo-update-interval`; для загрузки файлов вне рабочего каталога нужен `SAFE_PATHS` | подтверждено: general + api |
| Имена конкретных файлов состояния (`cache.db`, `Country.mmdb`, `geoip.db` и т. п.) | **не подтверждено**: `.gitignore` теговой версии содержит только `test/config/cache*`; нужен прогон ядра в чистой папке и снимок файлового дерева |

## 5. Интеграция как дочернего процесса: флаги и подводные камни

### 5.1 Точный набор флагов (v1.19.32)

Дословно из `init()` в `main.go`
(<https://raw.githubusercontent.com/MetaCubeX/mihomo/v1.19.32/main.go>):

| Флаг | Env-дублирует | Назначение (дословный usage-текст) |
|---|---|---|
| `-d` | `CLASH_HOME_DIR` | `set configuration directory` |
| `-f` | `CLASH_CONFIG_FILE` | `specify configuration file`; **особое значение `-` = чтение конфига из stdin** |
| `-config` | `CLASH_CONFIG_STRING` | `specify base64-encoded configuration string` |
| `-age-secret-key` | `CLASH_AGE_SECRET_KEY` | `specify age secret key to decrypt configuration` |
| `-ext-ui` | `CLASH_OVERRIDE_EXTERNAL_UI_DIR` | `override external ui directory` |
| `-ext-ctl` | `CLASH_OVERRIDE_EXTERNAL_CONTROLLER` | `override external controller address` |
| `-ext-ctl-tls` | `CLASH_OVERRIDE_EXTERNAL_CONTROLLER_TLS` | `override external controller tls address` |
| `-ext-ctl-unix` | `CLASH_OVERRIDE_EXTERNAL_CONTROLLER_UNIX` | `override external controller unix address` |
| `-ext-ctl-pipe` | `CLASH_OVERRIDE_EXTERNAL_CONTROLLER_PIPE` | `override external controller pipe address` |
| `-ext-ctl-routing-mark` | `CLASH_OVERRIDE_EXTERNAL_CONTROLLER_ROUTING_MARK` | `override external controller routing mark` |
| `-secret` | `CLASH_OVERRIDE_SECRET` | `override secret for RESTful API` |
| `-post-up`, `-post-down` | `CLASH_POST_UP`, `CLASH_POST_DOWN` | shell-скрипты, выполняемые после подъёма/перед падением |
| `-m` | — | `set geodata mode` |
| `-v` | — | `show current version of mihomo` |
| `-t` | — | `test configuration and exit` |

Отдельные подкоманды (без флагов, первые аргументы argv): `convert-ruleset`, `generate`, `age`.

**Важно: длинной опции `--home-dir` в v1.19.32 нет** — есть только `-d`. Ожидание «`--home-dir`»
из типичных шпаргалок по clash в этой версии не подтверждено.

Формат баннера `-v`: `Mihomo Meta <version> <GOOS> <GOARCH> with <go version> <buildTime>` и, если
есть, строка `Use tags: ...` — удобная перекрёстная проверка с `GET /version`.

### 5.2 Рабочий каталог и путь конфига

- `-d` и `-f` **подхватывают CWD**, если путь относительный → Sora обязана либо выставлять CWD
  процесса на домашний каталог профиля, либо передавать только абсолютные пути. Иначе файлы уедут
  в текущую папку GUI-процесса (`Program Files`/`System32` при запуске из службы).
- Передача конфига: `-config <base64>` (или stdin при `-f -`) позволяет **не писать конфиг с секретами
  на диск** и снимает проблему `SAFE_PATHS`. Если файл всё же пишется — он должен лежать в домашнем
  каталоге ядра.
- `-t` с `-config`/`-f -` проверяет конфиг из памяти: при успехе печатает
  `configuration file <path> test is successful` и выходит с кодом 0, при провале печатает
  `configuration test failed` / `configuration file <path> test failed` и делает `os.Exit(1)` —
  готовый **офлайн-валидатор конфигурации** (см. §5.7).


### 5.3 Сигналы и graceful shutdown (подтверждено по `main.go`)

- `SIGINT` / `SIGTERM` → выход из основного цикла; `defer executor.Shutdown()` выполняется → ядро
  закрывает слушатели/TUN и корректно освобождает ресурсы. Для Sora на Windows это означает:
  штатный `TerminateProcess` **не** даёт отработки `defer` — нужно либо дёргать `SIGINT`-эквивалент
  (Windows-консольные события CTRL_C/CTRL_CLOSE), либо предусмотреть таймаут и только потом `kill`.
  Точного описания Windows-обработки сигналов в доках нет — **не подтверждено**.
- `SIGHUP` → **повторный разбор того же конфига** (`hub.Parse(configBytes, options...)`) без выхода
  процесса. То есть «горячий reload» есть и через сигнал, и через `PUT /configs?force=true`.
- Логи уровня `debug` нужны для `/debug/pprof` (см. §3.1) — полезно держать отключаемый debug-режим
  в диагностике Sora.

### 5.4 Порты, LAN и секрет

- Порты: `mixed-port` + адрес контроллера (`external-controller`) — два ресурса, которые Sora обязана
  выбирать из свободного диапазона и переиспользовать между запусками (иначе каждый старт = новый
  firewall-rule и новый брандмауэрный промпт). Подтверждённых «рекомендованных» портов в доках нет;
  значения в примерах (`10801`, `9090`, `9093`, `9443`, `1053`) — просто примеры.
- Секрет: `Authorization: Bearer ${secret}`; задавать **флагом `-secret`**, чтобы не светить в файле.
  Требование «обязателен начиная с версии X» в документации **не подтверждено** — в general
  показано `secret: ""`, а в `docs/config.yaml` пример закомментирован, то есть пустой секрет
  допустим. **Вывод для Sora: secret включаем сами, всегда.**
- Обход секрета: `external-controller-unix`, `external-controller-pipe`, `external-doh-server`
  («этот URL не проверяет secret») → в Sora не включать; если очень нужен локальный IPC, только pipe
  с ACL на уровне ОС и без публичных путей.
- LAN: `allow-lan` + `bind-address` + `lan-allowed-ips`/`lan-disallowed-ips`. Не путать:
  `bind-address` работает **только** при `allow-lan: true`.

### 5.5 TUN: привилегии, драйверы, стек

- `stack: system`/`mixed` **ломаются при включённом брандмауэре**: документация прямо пишет «если
  включён файрвол, стеки `system` и `mixed` использовать нельзя» и даёт инструкцию разрешения ядра:
  Windows — «Параметры → Безопасность Windows → Разрешить приложение через брандмауэр → отметить
  ядро»; macOS — «обычно не требуется»; Linux — «обычно не требуется», при необходимости
  `sudo iptables -A OUTPUT -o <TUN> -j ACCEPT`.
- Linux: маршрутизация (`auto-route`), `auto-redirect` (iptables/nftables), `gso`, UID/MAC-правила,
  `route-*-set` (nftables) — всё это требует привилегированного запуска. Дословного упоминания
  `CAP_NET_ADMIN` в доках нет → **не подтверждено** как явное требование; практически — root или
  эквивалентные capabilities.
- macOS: `device` обязан быть с префиксом `utun`.
- **Windows Wintun/wireguard-go драйвер**: requirement для `stack: system` в полученных страницах
  документации **не упоминается → не подтверждено**. Проверять на живой машине по фактическому
  поведению собранного бинарника (и по ассетам релиза) перед тем, как обещать TUN-system в Sora.
- `strict-route` на Windows добавляет правила брандмауэра против утечки DNS и «может сломать
  VirtualBox»; на Linux — «предотвращает утечки адресов и включает DNS-hijack на Android».
  Для Sora это означает: strict-route = отдельный переключатель с предупреждением, а не по умолчанию.
- `dns-hijack` на macOS/Windows не перехватывает LAN-DNS, а на Android при включённом Private DNS
  перехват не работает → в диагностике Sora нужен явный тест DNS-утечки, а не молчаливая вера в hijack.

### 5.6 IPv6

- Верхний рубильник `ipv6: false` «блокирует все IPv6-соединения и глушит AAAA-запросы».
- Для TUN-адреса IPv6 нужно одновременно: `tun.inet6-address` + `ipv6: true`, иначе включается
  «проверка наличия IPv6 на других интерфейсах», которую можно обойти только
  `SKIP_SYSTEM_IPV6_CHECK=1`.
- `fake-ip-range6` — отдельный диапазон для v6-fakeip.

### 5.7 Офлайн-валидация конфига (рекомендуемый конвейер Sora)

1. собрать YAML в памяти;
2. `mihomo -d <home> -config <base64> -t` (или `-f -` + stdin) → код возврата 0 = валидно;
   текст ошибки идёт в stderr/stdout (`configuration test failed`);
3. только после успешной проверки запускать процесс боем;
4. ошибки парсинга при живом запуске дают `Parse config error: ...` и `log.Fatalln`
   (то есть процесс умирает сразу — Sora обязана показать пользователю stderr дочернего процесса).

### 5.8 Windows-специфика

- Именованный канал как контроллер: `-ext-ctl-pipe` / `external-controller-pipe: \\.\pipe\mihomo`
  (секрет не проверяется); Unix-сокет доступен в Windows-сборках «версии выше 17063 (1803/RS4)».
- Запуск как служба Windows / Session 0: **в документации mihomo раздела про службу Windows
  подтверждения нет** (в навигации есть страница «Создание сервиса», её содержимое получить не
  удалось — 404 на перепроверенных URL). Факт из стора: у Happ Desktop есть «Happ service»,
  и в релизе 4.3.0 они «улучшили подключение на Windows, когда служба Happ запускается медленно,
  и выводят понятное сообщение при невозможности запуска службы»
  (<https://github.com/Happ-proxy/happ-desktop/releases/tag/4.3.0>). Для Sora это сигнал, что
  Service Control Manager + задержка старта контроллера — реальный класс проблем; конкретные
  требования Session 0 — **не подтверждено**.


## 6. Матрица движков: mihomo vs sing-box vs Xray-core

Источники: список outbound/inbound sing-box
(<https://sing-box.sagernet.org/configuration/outbound/>, навигация той же страницы),
разделы outbound/inbound mihomo (§4.4), лицензии (§1), поддержка протоколов Happ/Xray
(<https://play.google.com/store/apps/details?id=com.happproxy>).

| Возможность | mihomo 1.19.32 | sing-box | Xray-core (MPL-2.0) |
|---|---|---|---|
| Лицензия | GPL-3.0 + оговорка про имя в README | GPL-3.0 + «no derivative work may use the name or imply association…» | MPL-2.0 |
| ss / ssr | `ss` подтверждено; `ShadowsocksR` — страница есть | `shadowsocks` есть; **ssr в списке outbound отсутствует** | ss есть; ssr — **не подтверждено** |
| vmess | есть | `vmess` | есть |
| vless (+Reality) | есть (страница VLESS) | `vless` есть; Reality — через TLS-настройку, точное имя ключа **не подтверждено** | есть (это «родной» протокол Xray) |
| trojan | есть | `trojan` | есть |
| hysteria / hysteria2 | есть обе (Hysteria, Hysteria2 + Realm как inbound) | `hysteria`, `hysteria2` | Hysteria2 заявлен у Happ поверх Xray |
| tuic (v4/v5) | есть (v4/v5 — как listeners) | `tuic` | **не подтверждено** |
| snell | есть | `snell` | нет |
| anytls | есть (str. inbound и outbound) | `anytls` | **не подтверждено** |
| wireguard | есть | `wireguard` (+ endpoint, tailscale) | **не подтверждено** |
| ssh | есть (страница SSH) | `ssh` | нет |
| direct / reject | `DIRECT` подтверждён; `REJECT` — как цель правила | `direct`, `block` | direct/block есть |
| tor, shadowtls, naive, bridge, tailcat | **не подтверждено** (в навигации outbound нет) | `tor`, `shadowtls`, `naive`, `bridge`, `tailcat` — подтверждены списком outbound | — |
| masque / openvpn / zerotier / tailscale / easytier / trusttunnel / sudoku / shadowquic / mieru | **есть страницы outbound** (MASQUE, OpenVPN, ZeroTier, Tailscale, EasyTier, TrustTunnel, Sudoku, ShadowQUIC, Mieru) | OpenVPN/OpenConnect/Tailscale/MASQUE есть в навигации (endpoint/service) | нет |
| proxy-providers (подписки, фильтр, override, yq-выражения, age-шифрование) | **есть, богато** (§4.6) | нет аналогичной секции; есть «Rule Set Source» и `experimental.cache-file` | нет |
| Правила | 40+ типов, включая `PROCESS-*`, `SRC-*`, `SUB-RULE`, `AND/OR/NOT`, `DSCP`, `IN-*` (§4.8) | `route` + rule actions + rule_set (свой формат) + «Headless Rule» | policy routing, домен-листы |
| GEO-экосистема | `geoip`/`geosite` (dat или mmdb), зеркала `geox-url`, автообновление, `meta-rules-dat` | GeoIP/Geosite + rule_set + V2Ray-совместимые источники | geo-источники свои |
| Группы/health-check/lazy/empty-fallback | есть, управляются из API | `selector`, `urltest` (без provider-экосистемы) | нет |
| Удалённое управление | **полный REST + WS контроллер** (§3), external-ui, DoH-эндпоинт | «Clash API» и «V2Ray API» как service (совместимость ограничена) | API xray (gRPC) — **не подтверждено** |
| TUN-стеки | `system` / `gvisor` / `mixed` / `mips` | `tun` inbound + `system`/`gvisor` (детали — **не подтверждено**) | tun через внешние механизмы |
| Per-app | Android: `tun.include-package`/`exclude-package`/`include-android-user` | правила маршрутизации по UID/пакетам — **не подтверждено** | нет |
| Экспортируемое состояние | `profile.store-selected`, `store-fake-ip`, `/storage/{key}` (≤1 МБ) | `experimental.cache-file` | нет |

Практический вывод для Sora (движок на каждый outbound не обязателен, но полезен):

- **mihomo** — когда нужен «клиент с подписками»: proxy-providers + filter/override + группы с
  health-check + 40+ типов правил + REST-наблюдаемость + PROCESS-правила.
- **sing-box** — когда нужен узкий современный набор (vless/trojan/ss/hysteria2/tuic/anytls/wireguard)
  с userspace-стеком и минимальной поверхностью; но подписки, группы и провайдеры придётся строить
  в самой Sora, а интеграция снова упирается в GPL-3.0 + ограничение на имя/ассоциацию.
- **Xray-core** — единственная «референсная» реализация VLESS/Reality, лицензия MPL-2.0 (наиболее
  дружелюбна к Proprietary-связыванию), но нет ни provider-экосистемы, ни REST-контроллера такого же
  уровня. Happ выбрала именно его — см. второй документ.

## 7. Что Sora обязана проверить живым прогоном (не подтверждено по докам)

1. Точные строки значений `type:` для ssr/anytls/hysteria2/tuic/snell/wireguard/ssh/source/reject —
   прогоном `mihomo -t` на синтетическом конфиге.
2. Существование и поведение `GET /proxies?lazy=true`, алиасов `/group*`, методов `/restart` и
   `/upgrade*`, а также эндпоинтов `/profiles` — на живом ядре v1.19.32.
3. Имена и расположение файлов состояния (cache/профиль/mmdb) — снимок файлового дерева домашнего
   каталога до/после работы.
4. Требование Wintun/драйвера для `tun.stack: system` на Windows и поведение при его отсутствии.
5. Обработка `SIGTERM`/CTRL_CLOSE в Windows-сборке и время до реального освобождения портов.
6. Актуальные ключи sniffing'а (страница «Domain sniffing») и «server policy» внутри `dns.nameserver`.
7. Содержимое страницы «Создание сервиса» (systemd/Windows service) — в текущем снимке недоступна.
8. Поведение `PUT /configs` без `force=true` и с `path` вне `SAFE_PATHS` (ожидаем отказ — проверить).

