# Happ Desktop / Happ Mobile: разбор функциональности для Sora

Дата проверки: **01.10.2026**. Источники — только первичные: GitHub API и файлы
`github.com/Happ-proxy/*`, страницы магазинов (Google Play, App Store), официальные сайты
`happ.su` / `happ.info`. Всё, что подтвердить не удалось, помечено **«не подтверждено»**.

## 0. Важное про домены (это меняет план проверки)

- **`happ.app` к Happ отношения не имеет**: страница отдаёт «For Sale Domain: happ.app … Buy Now
  €25,571.93» (Dynadot) — домен продается. Ссылка на `happ.app` в постановке задачи нерелевантна.
  <https://happ.app>
- **`docs.happ.app` не резолвится** («Unable to connect»), `docs.happ.su` — тоже,
  `https://happ.su/docs` и `https://happ.info/docs` → 404.
  Документация реально доступна только из меню сайта (модалка «User Docs» / «Technical Docs»),
  прямой URL в снятом HTML не отображается. **Содержимое документации — не подтверждено.**
- Рабочие официальные точки: `https://happ.su` (EN / 中文 / Русский / фарси) и
  `https://happ.info` (зеркало, есть `/ru`). Трекер багов — отдельный сервис
  `https://issues.happ.su/` (указан в README вместо GitHub Issues).

## 1. Профиль проекта

| Параметр | Значение | Источник |
|---|---|---|
| Позиционирование | «Cross-platform application designed for convenient work with proxy servers, **built on the powerful Xray core**» | <https://happ.su> (01.10.2026) |
| Юрлицо | «© 2024-2026 Happ. All rights reserved. **Flyfrog LLC**»; в Google Play: «FLYFROG LTD, 20-22 Wenlock Road, LONDON N1 7GU, United Kingdom» | <https://happ.su>, <https://play.google.com/store/apps/details?id=com.happproxy> |
| Платформы | «Available for **Desktop, Mobile and TV** Platforms» | <https://happ.su> |
| Девиз ядра | App Store: «New level of security by **Xray**»; Google Play: «Advanced level of security by Xray» | <https://apps.apple.com/us/app/happ-proxy-utility/id6504287215> |
| Модель | «Happ does not provide VPN services for purchase. Users are responsible for acquiring or setting up their own servers» | Google Play / README |

## 2. Движок

- **Xray — подтверждено** в трёх независимых первичных местах (сайт, описание в Google Play, README
  репозитория happ-desktop). В описании Google Play движок подписан прямо по протоколам:
  «VLESS(Reality) **(Xray-core)** / VMess **(V2ray)** / Trojan / Shadowsocks / Socks / Hysteria2».
- **sing-box / mihomo в составе Happ — не подтверждено.** Ни в README, ни в описаниях магазинов,
  ни в списке репозиториев организации упоминаний нет. Косвенно: в организации есть форки
  `Happ-proxy/Xray-core`, `Happ-proxy/3x-ui`, `Happ-proxy/Marzban`, `Happ-proxy/Xray-docs-next` —
  то есть команда живёт в экосистеме Xray, а не clash/mihomo.
  <https://github.com/orgs/Happ-proxy/repositories>
- Никакого публичного «control API» ядра у Happ из первичных источников не видно; есть только
  «Technical Docs — Specifications, API, details for developers» (содержимое недоступно).

## 3. Платформы и присутствие в сторах

| Платформа | Каналы | Комментарий |
|---|---|---|
| iOS | App Store Global `id6504287215`; **отдельное приложение «Happ Lite» только для RU** `id6799917773`; два TestFlight-линка (Global и RU) | README: <https://raw.githubusercontent.com/Happ-proxy/happ-desktop/main/README.md> |
| Android | Google Play `com.happproxy`; **APK + Beta APK прямо из GitHub Releases** | <https://github.com/Happ-proxy/happ-android/releases> |
| Windows | `setup-Happ.x64.exe`, `setup-Happ.arm64.exe` + зеркала `files-hub.com` | релиз 4.3.0 |
| macOS | `Happ.macOS.universal.dmg` (arm64+intel) | релиз 4.3.0 |
| Linux | `.deb` и `.rpm` (x64, arm64), Arch `.pkg.tar.zst` (x64, arm64) | релиз 4.3.0 |
| TV | заявлено на сайте как отдельная категория платформ | деталей в снятом HTML нет — **не подтверждено** |

Факты о релизах (GitHub API):

| | Desktop | Android |
|---|---|---|
| Последний релиз | `4.3.0`, опубликован **2026-09-15T15:27:48Z** | `4.6.1`, опубликован **2026-09-30T10:49:48Z** |
| Тело релиза | 4 пункта (см. §7) | «Minor UX improvements» |
| Скачиваний главного артефакта | `setup-Happ.x64.exe` — **403 595** | `Happ.apk` — **24 971** |
| Размер | 118 932 528 байт (x64 setup) | 62 331 518 байт (APK) |
| Версия в сторе | — | Google Play: «Updated on **Sep 25, 2026**» |

Аудитория: Google Play — «**10M+ Downloads**», рейтинг 4.1 (54.6K отзывов), PEGI 3;
App Store — 4.6 (16K оценок), «#13 в MZGenre.Utilities», 360.2 MB, iPhone/iPad/Mac,
«Languages: English and 4 more» (EN, китайский, персидский, русский), возрастной рейтинг 10+.

## 4. Протоколы

Дословный список из Google Play (самый свежий первичный источник, 01.10.2026):

| Протокол | Статус |
|---|---|
| VLESS (Reality) — Xray-core | подтверждено |
| VMess — V2ray | подтверждено |
| Trojan | подтверждено |
| Shadowsocks | подтверждено |
| Socks | подтверждено |
| Hysteria2 | подтверждено (есть только в Google Play-описании; в README desktop его нет) |
| WireGuard, TUIC, Snell, AnyTLS, SSR, SSH | **не подтверждено** (в описаниях отсутствуют) |

## 5. Подписки

| Фича | Статус / формулировка источника |
|---|---|
| Конфигурация прокси на базе правил | «Configuration of proxies based on rules» (Google Play, README) |
| **Скрытые подписки** | «Hidden subscriptions» (Google Play) |
| **Шифрованные подписки** | «Encrypted subscriptions» (Google Play) |
| Индивидуальные параметры каждой подписки | релиз Desktop 4.3.0: «Added a Settings page to each subscription's menu for setting **that subscription's own User-Agent**, replacing the single global User-Agent option» |
| Стабильность хранения и автообновления подписок | changelog Android: «Major update of subscriptions' individual parameter management», «Stability improvements for auto-updates», «Improving the stability of the subscription storage» |
| Groups/providers как в clash-модели (proxy-providers) | **не подтверждено** — публичной модели «provider» у Happ нет, формат описан только в недоступных Technical Docs |
| Fragment / fallback-url | changelog Android: «Added support of 'fallback-url' in URL's fragment» |

## 6. Роутинг и пресеты

- Есть генератор профилей маршрутизации: `Happ-proxy/routing_generator` — «Этот репозиторий содержит
  исходный код веб-сайта, который позволяет **генерировать профиль роутинга** для приложения Happ»
  (PHP, 15 звёзд, последняя активность 2025-03-18).
  <https://raw.githubusercontent.com/Happ-proxy/routing_generator/master/README.md>
- Состав пресетов, форматы правил и источники geo-данных — **не подтверждено** (документация
  недоступна, содержимое генератора не разбиралось).
- Косвенное подтверждение «правила привязаны к соединению»: отзыв пользователя от 2026-09-03
  (см. §12) — «теперь роутинг должен применяться к конкретному подключению».

## 7. TUN / per-app / kill switch / DNS / диагностика — честная таблица

| Возможность Happ | Статус | Первичное подтверждение |
|---|---|---|
| TUN / «VPN tunnel» на десктопе | **подтверждено** | релиз Desktop 4.3.0: «Fixed the **VPN tunnel** being lost after putting a Linux or macOS computer to sleep» |
| Системный сервис на Windows | **подтверждено** | релиз Desktop 4.3.0: «Improved connecting on Windows when the **Happ service** is slow to start, and showing a clear reinstall message if the service can't start at all» |
| Per-app proxy (выбор приложений) | **не подтверждено** | в описаниях и changelog'ах нет |
| Kill switch / lock mode | **не подтверждено** | |
| Управление DNS (свои серверы, DoH, anti-leak) | **не подтверждено** | |
| Экспорт логов / диагностика | **не подтверждено** | публичный канал — внешний трекер `issues.happ.su` + «AI-бот / платная поддержка» на сайте |
| Темы/оформление | **не подтверждено** | |
| Локализация интерфейса | **подтверждено**: App Store — «English and 4 more» (EN, китайский, персидский, русский); сайт — EN / 中文 / Русский / фарси | App Store, happ.su |
| Автообновление приложения | **подтверждено** (механизм — см. §8) | файл `release` в репозитории + changelog'и |


## 8. Релизный цикл и механизм auto-update (первичные данные)

- Desktop: `4.3.0` (2026-09-15). Android: `4.6.1` (2026-09-30) — **мобильная ветка минимум на три
  минорные версии впереди десктопной**; десктоп обновляется заметно реже.
- В корне `happ-desktop` лежит файл `release` (1896 байт) — JSON-манифест автообновления:

  ```json
  { "app": "happ_desktop", "filenum": 51,
    "windows": {
      "block": ["2.5.2","2.4.0","2.2.0", "...", "0.2.6"],
      "stable":     { "version": "4.3.0", "link": ".../setup-Happ.x64.exe",
                      "update": { "warnalways": "0.3.2", "updateonly": "1.0.1" } },
      "stable_arm": { "version": "4.3.0", "link": ".../setup-Happ.arm64.exe" } } }
  ```

  То есть у Happ есть: (а) серверный указатель stable/beta по платформам и архитектурам
  (`windows`, `windows_beta`, `windows_stable_arm`, …), (б) **список `block` из 36 устаревших версий
  Windows** — принудительный запрет старых клиентов, (в) пороги `warnalways` / `updateonly` для
  «предупредить» vs «обновить обязательно».
  <https://raw.githubusercontent.com/Happ-proxy/happ-desktop/main/release>
- Это сильная сторона (централизованный контроль автообновления), но она же — источник жалоб:
  обновление, меняющее модель роутинга без миграции, ломает рабочий конфиг (§12).

## 9. Open-source статус (главный вывод для конкурентного анализа)

| Репозиторий | Что внутри | Лицензия | Вывод |
|---|---|---|---|
| `Happ-proxy/happ-desktop` | **только 2 файла**: `README.md` (4963 Б) и `release` (1896 Б); размер репозитория 32 КБ; `language: null`; `license: null`; 1880 звёзд, 88 форков, создан 2025-01-23, push 2026-09-28 | **нет** | исходников клиента **нет** |
| `Happ-proxy/happ-android` | 191 КБ, `language: null`, `license: null`, 779 звёзд; в релизах только `Happ.apk` / `Happ_beta.apk` | **нет** | исходников нет |
| `Happ-proxy/happ-ios` | **один файл** `README.md` (2405 Б); активность остановлена 2025-01-28 | **нет** | исходников нет |
| `Happ-proxy/.github`, `app_domain`, `Web-Dashboard`, `happ_update_test` | служебные | — | — |
| `Happ-proxy/routing_generator` | PHP-сайт генератора профилей роутинга | — | единственный «настоящий» код |
| Форки `Xray-core` (MPL-2.0), `3x-ui` (GPL-3.0), `Marzban` (AGPL-3.0), `Xray-docs-next` (CC-BY-SA-4.0) | серверная экосистема | upstream | к клиенту отношения не имеют |

Источники: <https://api.github.com/repos/Happ-proxy/happ-desktop>,
<https://api.github.com/repos/Happ-proxy/happ-desktop/contents?ref=main>,
<https://api.github.com/repos/Happ-proxy/happ-ios/contents?ref=main>,
<https://github.com/orgs/Happ-proxy/repositories>.

- **Публичный трекер багов закрыт**: у `happ-desktop` и `happ-android` `has_issues: false`, страница
  Issues показывает «Issue creation is restricted in this repository» и пустую выдачу по `is:issue`
  (<https://github.com/Happ-proxy/happ-desktop/issues>); обратная связь вынесена на закрытый
  `https://issues.happ.su/`.
- Итог: **Happ — проприетарный клиент с открытой только периферией**. В материалах нет слова
  «open source»; есть «We are an independent project». Формально репозитории без LICENSE означают
  «все права защищены», то есть даже README нельзя повторно использовать без разрешения.

## 10. Приватность: что обещано и что заявлено в сторах

| Тезис | Формулировка источника |
|---|---|
| Позиция разработчика | «Happ ensures your network activity remains private by **not collecting any data**; your information remains solely on your device without being sent to external servers» (Google Play, App Store, README) |
| Google Play «Data safety» | «**No data shared with third parties**»; «This app may collect these data types: **App info and performance**»; «Data is encrypted in transit»; «**Data can't be deleted**» |
| Дисклеймер | «Happ does not sell or provide VPN services. Beware of scammers claiming to offer "official Happ VPNs"» (App Store, «Important Notice») |
| Документы | ссылки «Privacy Policy» / «Terms of Services» на happ.su; юрлицо FLYFROG LTD (Лондон) |

Замечание для Sora: расхождение между «не собираем ничего» и обязательным полем Play
«App info and performance» + «Data can't be deleted» — это то место, где GPL-клиент может выиграть
прозрачностью (публичная политика + воспроизводимая сборка).

## 11. Ценообразование / платный тир

| Факт | Источник |
|---|---|
| App Store: **Free**, возрастной рейтинг 10+ | App Store |
| Google Play: в описании нет ни in-app purchases, ни подписки | Google Play |
| Монетизация на сайте — **донаты**: банковские карты (в т. ч. карты МИР, рубли, VISA/MasterCard в EUR/USD) и крипта (USDT Arbitrum/BSC BEP-20/ETH/POL, SOL, BTC, TRC-20, LTC, TON) | happ.su |
| Платная **поддержка**, а не платная версия: «resolve your issue quickly and for free using our AI bot, or contact customer service for **paid assistance**» | happ.su |
| Наличие premium-тира / Happ Pass | **не подтверждено** ни в одном первичном источнике |


## 12. Системные жалобы пользователей

Публичный GitHub-трекер Happ закрыт (§9), поэтому жалобы живут в магазинах. Ниже — дословно
подтверждённые отзывы с датами; темы, которых в первичных источниках нет, помечены отдельно.

| Тема | Дословно / суть | Откуда |
|---|---|---|
| **Ломка настроек после обновления** | «Terrible ux! I had general routing settings and it worked fine. After update it stopped working… Now routing must be applied to specific connection. **No info about this change, no setting migration**, nothing. App should not break after update» (8 «полезно», Artyom Summer, **2026-09-03**) | Google Play |
| **Пинг без живой сортировки + нет автоочистки мёртвых узлов** | «when the pinging operation starts, the configurations are **not sorted during the work** and you have to wait until the end… there is **no option to automatically delete invalid configurations**, and they have to be deleted manually one by one» (BehnamGharjeloo, **2026-09-10**); второй отзыв (2026-06-17): «…would not working when you have a subscription with **1000 configs**» | App Store |
| **Нестабильность подписок/автообновлений (самопризнание)** | changelog Android: «Stability improvements for auto-updates», «Improving the stability of the subscription storage» | GitHub Releases |
| **Потеря туннеля после сна (Linux/macOS), медленный старт службы (Windows)** | релиз 4.3.0: «Fixed the VPN tunnel being lost after putting a Linux or macOS computer to sleep»; «Improved connecting on Windows when the Happ service is slow to start» | GitHub Releases |
| Хвалят | «connection is quick, stable and reliable» (2026-09-11); «on a business trip in Russia… lifesaver» (2026-07-30, 18 «полезно»); «very good for your kid… to watch cartoons in Iran» (App Store) | Play / App Store |
| Жалобы на **DNS-утечки, battery drain, «confusing UI», отсутствие протоколов** | **не подтверждено**: публичных issue нет (трекер закрыт), в снятых фрагментах описаний магазинов таких тем нет | — |

## 13. Итог по Happ в одном абзаце

Happ — это Xray-клиент с очень сильным дистрибутивом (10M+ загрузок в Play, 4.1★; 4.6★ в App Store,
#13 в Utilities), пятью платформами, TV-веткой, собственным серверным механизмом автообновления
с блокировкой старых версий и полностью закрытой кодовой базой (репозитории-витрины без кода и без
LICENSE, issue-трекер закрыт, документация недоступна по внешним URL). Функционально он покрывает
«прокси + правила + подписки (в том числе скрытые и шифрованные) + TUN на десктопе + сервис на
Windows», но по подтверждённым первичным источникам **не демонстрирует** per-app proxy, kill switch,
управление DNS, экспорт логов, темы и clash-подобные группы/провайдеры. Системные боли — поломка
роутинга после обновления без миграции и неудобный массовый тест узлов на больших подписках.


## 14. Таблица «что должно быть в Sora, чтобы быть впереди Happ»

Ранжирование: **Ценность** — влияние на пользователя (XL/L/M), **Стоимость** — трудоёмкость в Sora
(с учётом того, что Sora — GPL-3.0 desktop-клиент с TUN-интеграцией, диагностикой и поддержкой
Windows 7 x86; см. `NOTICE.md` в репозитории).

| # | Возможность | Чем бьёт Happ (подтверждённый факт) | Ценность | Стоимость | Комментарий |
|---|---|---|---|---|---|
| 1 | **Мигрируемые конфиги: ни одно обновление не ломает рабочий роутинг** + миграция старых схем и changelog «что изменилось в поведении» | жалоба 2026-09-03: роутинг сломался после апдейта, миграции не было | XL | Средняя | Дешевле всего — версия схемы конфига + миграции при старте; окупается сразу |
| 2 | **Массовый тест узлов по-человечески**: постепенная сортировка по задержке прямо во время прогона, пометка мёртвых узлов, пакетное удаление/скрытие недоступных | две жалобы в App Store (2026-06-17, 2026-09-10) про 1000-узловые подписки | XL | Низкая→Средняя | У mihomo есть `PUT /proxies/{name}` и `/proxies/{name}/delay?url&timeout` — данные уже есть, нужен UI-слой |
| 3 | **Подписки как proxy-providers**: `url` + `interval` + `filter`/`exclude-filter` + `override` (переименование, udp, skip-cert-verify) + `health-check` + `payload`-фолбэк | у Happ публичной модели provider нет; «hidden/encrypted subscriptions» — только заявка | XL | Средняя | Ядро делает основную работу; Sora хранит только URL и состояние |
| 4 | **Настоящий открытый код + публичный issue-трекер** | `happ-desktop` = README + манифест; `has_issues: false`, «Issue creation is restricted» | L→XL (доверие, сообщество, аудит безопасности) | Низкая | У Sora уже есть; это дифференциатор, который надо **явно** заявить в README |
| 5 | **Диагностический пакет одной кнопкой**: логи ядра (WS `/logs?format=structured`) + `/version` + снимок `/configs` + версия TUN-стека + тест DNS-утечки | у Happ экспорт логов не подтверждён, поддержка — AI-бот/платный чат | L | Низкая | mihomo отдаёт структурированные логи «из коробки» |
| 6 | **Kill switch (network lock)** с внятной семантикой при падении ядра | у Happ не подтверждён ни в одном первичном источнике | L | Средняя | Требует аккуратной реализации на Windows (см. §5.5 второго документа) |
| 7 | **Anti-leak TUN**: выбор стека (`system`/`gvisor`/`mixed`/`mips`), `strict-route`, `dns-hijack` + проверка перехвата | Happ чинил «туннель теряется после сна» — тема хрупкости TUN реальна | L | Высокая | Windows-требования (Wintun) у mihomo **не подтверждены** — проверять до обещаний |
| 8 | **Per-app routing** (Android `tun.include-package`; desktop — `PROCESS-NAME`/`PROCESS-PATH` правила) | у Happ не подтверждено | L | Средняя→Высокая | mihomo умеет и то и другое; на десктопе нужен сборщик имён/путей процессов |
| 9 | **Прозрачная телеметрия**: политика «собираем X» вместо «ничего не собираем» + возможность удалить данные | Play-карточка Happ: «No data shared» рядом с «App info and performance» и «Data can't be deleted» | M | Низкая | Формальный, но заметный контраст |
| 10 | **Локализация на 4+ языка** на parity с Happ | Happ: 4 языка на сайте, 5 в App Store | M | Низкая | Частично уже есть в Sora |
| 11 | **Авто-обновление без серверной блокировки старых версий**: semver, каналы stable/beta, возможность откатиться | `release`-манифест Happ содержит `block` из 36 версий Windows | M | Средняя | Модель «block-списка» конвертирует пользователей в недовольные отзывы |
| 12 | **Второй движок (Xray) «на каждый outbound»** — ради нативного VLESS/Reality и независимости от одного ядра | Happ целиком сидит на Xray | M | **Высокая** | Отложить: сначала довести mihomo-ветку до стабильности (§6 и §7 второго документа) |
| 13 | Мобильные приложения и TV-ветка | Happ присутствует на iOS/Android/TV | — | Вне скоупа | Sora — desktop; не пытаться догонять «всего лишь» на этом фронте |

**Как читать таблицу.** Позиции 1–5 дают максимум воспринимаемого преимущества при минимальном риске
и почти полностью опираются на то, что mihomo уже умеет через REST API (§3 второго документа): тесты
задержки, выбор узлов, провайдеры, структурированные логи, версия. Позиции 6–8 — настоящие
конкурентные фичи, но они же упираются в самые непрозрачные места платформы (TUN-требования Windows,
права процесса, kill switch), поэтому требуют предварительной проверки «живым прогоном» (§7 второго
документа).

## 15. Открытые вопросы по Happ (не подтверждено извне)

1. Содержание «User Docs» и «Technical Docs» (какие поля формат подписки поддерживает, есть ли
   правила уровня geo/protocol, есть ли DNS-секция).
2. Реализация «Hidden subscriptions» и «Encrypted subscriptions» (шифрование на устройстве или
   на стороне провайдера).
3. Является ли «Happ Lite» (App Store, RU-only) функционально урезанной версией — предположение
   о цензурно-ориентированной сборке **не подтверждено**.
4. Наличие premium-тира / Happ Pass.
5. Состав пресетов роутинга, генерируемых `routing_generator`.

