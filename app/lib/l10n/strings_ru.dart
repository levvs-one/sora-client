// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'strings.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class SRu extends S {
  SRu([String locale = 'ru']) : super(locale);

  @override
  String get stateOff => 'Не подключено';

  @override
  String get stateConnecting => 'Подключение';

  @override
  String get stateConnected => 'Подключено';

  @override
  String get stateReconnecting => 'Переподключение';

  @override
  String get stateDisconnecting => 'Отключение';

  @override
  String get stateFailed => 'Не подключено';

  @override
  String get coreMissing => 'Служба Sora не отвечает';

  @override
  String get serverAuto => 'Самый быстрый';

  @override
  String get serverBypass => 'Без сервера';

  @override
  String get addSubscription => 'Добавить подписку';

  @override
  String get servers => 'Серверы';

  @override
  String get settings => 'Настройки';

  @override
  String get subscription => 'Подписка';

  @override
  String get subscriptionLink => 'Ссылка на подписку';

  @override
  String get add => 'Добавить';

  @override
  String get refresh => 'Обновить';

  @override
  String get rename => 'Переименовать';

  @override
  String get delete => 'Удалить';

  @override
  String get cancel => 'Отмена';

  @override
  String get save => 'Сохранить';

  @override
  String get name => 'Название';

  @override
  String deleteSubscription(String name) {
    return 'Удалить «$name»?';
  }

  @override
  String get routes => 'Маршруты';

  @override
  String get presetGlobal => 'Всё через VPN';

  @override
  String get presetRu => 'Россия напрямую';

  @override
  String get presetIr => 'Иран напрямую';

  @override
  String get presetCn => 'Китай напрямую';

  @override
  String get blockAds => 'Блокировать рекламу';

  @override
  String get killSwitch => 'Интернет только через VPN';

  @override
  String get engine => 'Ядро';

  @override
  String get engineAuto => 'Авто';

  @override
  String get animations => 'Анимации';

  @override
  String get logs => 'Журнал';

  @override
  String get about => 'О приложении';

  @override
  String get logsAll => 'Все';

  @override
  String get logsImportant => 'Важное';

  @override
  String get logsErrors => 'Ошибки';

  @override
  String get search => 'Поиск';

  @override
  String get export => 'Сохранить в файл';

  @override
  String get clear => 'Очистить';

  @override
  String get logsEmpty => 'Здесь пусто';

  @override
  String appVersion(String version) {
    return 'Версия $version';
  }

  @override
  String get notInstalled => 'Не установлено';

  @override
  String get sourceCode => 'Исходный код';

  @override
  String get license => 'Лицензия';

  @override
  String usage(String used, String total) {
    return '$used из $total';
  }

  @override
  String until(String date) {
    return 'до $date';
  }

  @override
  String get expired => 'Срок истёк';

  @override
  String milliseconds(int n) {
    return '$n мс';
  }

  @override
  String bytesB(String n) {
    return '$n Б';
  }

  @override
  String bytesKB(String n) {
    return '$n КБ';
  }

  @override
  String bytesMB(String n) {
    return '$n МБ';
  }

  @override
  String bytesGB(String n) {
    return '$n ГБ';
  }

  @override
  String bytesTB(String n) {
    return '$n ТБ';
  }

  @override
  String get errGeneric => 'Что-то пошло не так';

  @override
  String get errCore => 'Служба Sora не отвечает';

  @override
  String get errAuth => 'Нет доступа к службе Sora';

  @override
  String get errVersion => 'Обновите Sora: приложение и служба разных версий';

  @override
  String get errBusy => 'Подождите, предыдущая команда ещё выполняется';

  @override
  String get errEngineMissing => 'Не найдено ядро для этого сервера';

  @override
  String get errEngineStart => 'Ядро не запустилось';

  @override
  String get errEngineStopped => 'Ядро остановилось';

  @override
  String get errTunnel => 'Нет прав на создание VPN-подключения';

  @override
  String get errServers => 'Сервер настроен с ошибкой';

  @override
  String get errNetwork => 'Нет связи с сервером';

  @override
  String get errTimeout => 'Сервер не ответил вовремя';

  @override
  String get errFirewall => 'Не удалось включить блокировку интернета без VPN';

  @override
  String get errSubFetch => 'Не удалось загрузить подписку';

  @override
  String get errSubFormat => 'Это не ссылка на подписку';

  @override
  String get errSubEmpty => 'В подписке нет серверов';

  @override
  String get errSubDuplicate => 'Эта подписка уже добавлена';

  @override
  String get errSubLimit => 'Слишком много подписок';

  @override
  String get errSubScheme => 'Нужна ссылка, начинающаяся с https://';

  @override
  String get errSecretStore => 'Хранилище Sora повреждено или недоступно';

  @override
  String get errNoServers => 'Добавьте подписку, чтобы подключиться';

  @override
  String get exportText => 'Текст';

  @override
  String get connections => 'Соединения';

  @override
  String get close => 'Закрыть';

  @override
  String get chainDirect => 'Напрямую';

  @override
  String get chainBlocked => 'Заблокировано';

  @override
  String get theme => 'Тема';

  @override
  String get themeSystem => 'Как в системе';

  @override
  String get themeLight => 'Светлая';

  @override
  String get themeDark => 'Тёмная';

  @override
  String get language => 'Язык';

  @override
  String get languageSystem => 'Как в системе';

  @override
  String get sectionConnection => 'Подключение';

  @override
  String get sectionNoServer => 'Без сервера';

  @override
  String get sectionPing => 'Пинг';

  @override
  String get sectionLog => 'Диагностика';

  @override
  String get ipv6 => 'IPv6';

  @override
  String get dns => 'DNS';

  @override
  String get dnsAuto => 'Авто';

  @override
  String get dnsHint => 'Адреса через запятую';

  @override
  String get fragment => 'Фрагментация TLS';

  @override
  String get fragmentPackets => 'Что дробить';

  @override
  String get fragmentLength => 'Размер частей';

  @override
  String get fragmentInterval => 'Пауза между частями';

  @override
  String get byDefault => 'По умолчанию';

  @override
  String get rangeHint => 'Например, 100-200';

  @override
  String get splitPos => 'Места разбиения';

  @override
  String get splitPosHint => 'Например, 1, midsld';

  @override
  String get disorder => 'Менять порядок частей';

  @override
  String get tlsRecord => 'Делить TLS-запись';

  @override
  String get tlsRecordNo => 'Нет';

  @override
  String get tlsRecordSni => 'По имени сайта';

  @override
  String get tlsRecordFirst => 'После первого байта';

  @override
  String get hostCase => 'Менять регистр Host';

  @override
  String get probeMethod => 'Способ';

  @override
  String get probeAuto => 'Авто';

  @override
  String get probeEngine => 'Через ядро';

  @override
  String get probeConnect => 'Только соединение';

  @override
  String get probeUrl => 'Адрес проверки';

  @override
  String get probeTimeout => 'Ожидание';

  @override
  String seconds(int n) {
    return '$n с';
  }

  @override
  String get subscriptions => 'Подписки';

  @override
  String get subscriptionSettings => 'Настройки';

  @override
  String get userAgent => 'User-Agent';

  @override
  String get autoUpdate => 'Обновлять автоматически';

  @override
  String get updateInterval => 'Как часто';

  @override
  String get intervalProvider => 'Как просит провайдер';

  @override
  String hours(int n) {
    return '$n ч';
  }

  @override
  String get updateNow => 'Обновить сейчас';

  @override
  String get logLevel => 'Что записывать';

  @override
  String get levelDebug => 'Всё';

  @override
  String get levelInfo => 'Обычное';

  @override
  String get levelWarning => 'Важное';

  @override
  String get levelError => 'Только ошибки';

  @override
  String get recordDestinations => 'Записывать адреса сайтов';

  @override
  String get reset => 'Сбросить настройки';

  @override
  String get resetConfirm => 'Сбросить все настройки?';

  @override
  String get resetAction => 'Сбросить';

  @override
  String get invalidValue => 'Такое значение не подойдёт';

  @override
  String get website => 'Сайт подписки';

  @override
  String get providerWebsite => 'Сайт провайдера';

  @override
  String get support => 'Поддержка';

  @override
  String controlPortQuestion(String engine) {
    return '$engine управляется через порт на этом компьютере. Другие программы смогут заметить, что VPN включён.';
  }

  @override
  String chooseEngine(String engine) {
    return 'Выбрать $engine';
  }

  @override
  String get rules => 'Свои правила';

  @override
  String get ruleAdd => 'Новое правило';

  @override
  String get ruleHint => 'Сайт, IP или программа';

  @override
  String get ruleDirect => 'Напрямую';

  @override
  String get ruleProxy => 'Через VPN';

  @override
  String get ruleBlock => 'Блокировать';

  @override
  String get failover => 'Переключаться при сбое';

  @override
  String get connectOnStart => 'Подключаться при запуске';

  @override
  String expiresIn(String name, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '# дней',
      few: '# дня',
      one: '# день',
      zero: 'несколько часов',
    );
    return '$name: подписка закончится через $_temp0';
  }

  @override
  String trafficLow(String name, String left) {
    return '$name: осталось $left';
  }

  @override
  String get ruleInvalid => 'Не похоже на сайт, IP или программу';

  @override
  String groupOrdered(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# серверов',
      few: '# сервера',
      one: '# сервер',
    );
    return '$_temp0, по очереди';
  }

  @override
  String groupBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# серверов',
      few: '# сервера',
      one: '# сервер',
    );
    return '$_temp0, самый быстрый';
  }

  @override
  String get tunnelMode => 'Режим';

  @override
  String get tunnelTun => 'Весь трафик';

  @override
  String get tunnelProxy => 'Системный прокси';

  @override
  String get proxyAddress => 'Адрес прокси';

  @override
  String get copied => 'Скопировано';

  @override
  String get launchAtLogin => 'Запускать вместе с системой';

  @override
  String get closeToTray => 'Сворачивать в трей при закрытии';

  @override
  String get notifications => 'Уведомления';

  @override
  String get trayOpen => 'Открыть Sora';

  @override
  String get trayConnect => 'Подключить';

  @override
  String get trayDisconnect => 'Отключить';

  @override
  String get trayServer => 'Сервер';

  @override
  String get trayQuit => 'Выйти из Sora';

  @override
  String trayTooltip(String state) {
    return 'Sora: $state';
  }

  @override
  String trayTooltipServer(String state, String server) {
    return 'Sora: $state, $server';
  }

  @override
  String get noticeInTray => 'Sora осталась в трее';

  @override
  String get noticeInTrayBody => 'Выйти можно из меню значка';

  @override
  String get noticeLost => 'Соединение прервалось';

  @override
  String get noticeLostBody => 'Sora переподключается';

  @override
  String get noticeRestored => 'Снова подключено';

  @override
  String get noticeFailed => 'Не удалось подключиться';

  @override
  String get noticeBackup => 'Основной сервер не ответил, работает запасной';

  @override
  String get noticeNext => 'Сервер не ответил, работает следующий';

  @override
  String get noticeMainBack => 'Основной сервер снова отвечает, трафик идёт через него';

  @override
  String get noticeSubscription => 'Подписка';

  @override
  String get importTitle => 'Добавить подписку?';

  @override
  String get importSealed =>
      'Эта ссылка зашифрована для Happ, прочитать её может только Happ. Попросите у провайдера обычную ссылку на подписку.';

  @override
  String get understood => 'Понятно';

  @override
  String get noAnswer => 'нет ответа';

  @override
  String get home => 'Главная';

  @override
  String get navRules => 'Правила';

  @override
  String get navConnections => 'Подключения';

  @override
  String get navLogs => 'Логи';

  @override
  String get navAbout => 'О приложении';

  @override
  String get sidebarToggle => 'Развернуть меню';

  @override
  String get more => 'Ещё';

  @override
  String get less => 'Свернуть';

  @override
  String get currentServer => 'Текущий сервер';

  @override
  String get trafficDown => 'Получено';

  @override
  String get trafficUp => 'Отправлено';

  @override
  String perSecond(String value) {
    return '$value/с';
  }

  @override
  String activeRules(int count) {
    return 'Активные правила: $count';
  }

  @override
  String get recentNotifications => 'Последние уведомления';

  @override
  String get notificationsEmpty => 'Здесь появятся события подключения и подписок';

  @override
  String get retryConnect => 'Подключиться снова';

  @override
  String get openLogs => 'Открыть логи';

  @override
  String get tourReplay => 'Показать гайд снова';

  @override
  String tourStep(int step) {
    return 'Шаг $step из 5';
  }

  @override
  String get tourBack => 'Назад';

  @override
  String get tourNext => 'Далее';

  @override
  String get tourSkip => 'Пропустить';

  @override
  String get tourFinish => 'Готово';

  @override
  String get tourAdd => 'Добавьте ссылку на подписку от провайдера.';

  @override
  String get tourServer => 'Выберите сервер. «Самый быстрый» подберёт его за вас.';

  @override
  String get tourConnect => 'Нажмите здесь, чтобы подключиться или отключиться.';

  @override
  String get tourMode => 'Выберите режим. Kill switch блокирует интернет при обрыве VPN.';

  @override
  String get tourSettings => 'Откройте настройки. Здесь можно показать гайд снова.';

  @override
  String get chooseProgram => 'Выбрать программу';

  @override
  String get installedApps => 'Установленные программы';

  @override
  String get runningProcesses => 'Запущенные процессы';

  @override
  String get programsFailed => 'Не удалось получить список программ';

  @override
  String get programsEmpty => 'Программы не найдены. Попробуйте другое имя.';

  @override
  String get selectExe => 'Выбрать файл .exe';

  @override
  String get trafficUnavailable => 'Счётчики пока недоступны';

  @override
  String get speedtest => 'Скорость';

  @override
  String get speedtestCheck => 'Проверить скорость';

  @override
  String get speedtestSearch => 'Найти сервис';

  @override
  String get speedtestEmpty => 'Ничего не найдено. Измените запрос.';

  @override
  String get speedtestBackToList => 'К списку сервисов';

  @override
  String get speedtestOpenBrowser => 'Открыть в браузере';

  @override
  String get speedtestUnavailable => 'Встроенный браузер не запустился. Откройте сервис в системном браузере.';

  @override
  String get speedtestPageFailed => 'Страница не загрузилась. Обновите её или откройте сервис в системном браузере.';

  @override
  String get speedtestExternalFailed => 'Системный браузер не открылся. Попробуйте ещё раз.';

  @override
  String get modes => 'Режимы';

  @override
  String get proxyShort => 'Прокси';

  @override
  String get tunMode => 'Весь трафик (TUN)';

  @override
  String get checkUpdates => 'Проверять обновления';

  @override
  String get updates => 'Обновления приложения';

  @override
  String updateAvailable(String version) {
    return 'Доступна версия $version';
  }

  @override
  String get updateOpenAbout => 'Посмотреть обновление';

  @override
  String updateNotes(String version) {
    return 'Что изменилось в $version';
  }

  @override
  String get updateCheck => 'Проверить обновления';

  @override
  String get updateChecking => 'Проверяем...';

  @override
  String get updateNoNotes => 'Автор релиза не добавил описание.';

  @override
  String get updateDropWarning =>
      'При обновлении Sora и ядра VPN-соединение прервётся на несколько секунд. Продолжить?';

  @override
  String get updateWaitConnection => 'Дождитесь завершения подключения и готовности службы Sora.';

  @override
  String get updateDownloading => 'Скачиваем и проверяем файлы...';

  @override
  String get updateInstalling => 'Подготовка обновления или ожидание пароля администратора...';

  @override
  String get updateNetworkError => 'Не удалось скачать обновление. Попробуйте ещё раз.';

  @override
  String get updateReleaseError => 'Данные релиза или нужные файлы отсутствуют либо некорректны.';

  @override
  String get updateChecksumError => 'Файл не совпадает с SHA256SUMS. Установка не запускалась.';

  @override
  String get updateInstallError => 'Обновление не завершилось. Возможно, запрос прав был отменён.';

  @override
  String get updateUnsupported =>
      'Этот файл приложения не принадлежит поддерживаемой паре пакетов Sora. Используйте инструкцию установки из описания релиза.';

  @override
  String get updateManual =>
      'Выполните команду в терминале для установки обоих проверенных пакетов, затем откройте Sora снова. Файлы сохранены в каталоге загрузки. VPN-соединение прервётся.';

  @override
  String get updateCopyCommand => 'Скопировать команду';

  @override
  String get updateChecksDisabled => 'Автоматические проверки отключены в настройках.';

  @override
  String get updateInstalled => 'Обновление установлено. Откройте Sora снова.';

  @override
  String get projectLinks => 'Проект';

  @override
  String get githubReleases => 'Релизы и загрузки';

  @override
  String get telegramChannel => 'Канал в Telegram';

  @override
  String get licenses => 'Лицензии';

  @override
  String get componentLicenses => 'Лицензии компонентов';

  @override
  String get appCopyright => '© 2026 levvs-one и участники проекта';

  @override
  String get collapseServers => 'Свернуть серверы';

  @override
  String get expandServers => 'Показать серверы';

  @override
  String get hideDescription => 'Скрыть описание';

  @override
  String get showDescription => 'Показать описание';

  @override
  String get pendingConnectionChanges => 'Чтобы применить изменения, переподключитесь.';

  @override
  String get reconnectNow => 'Применить и переподключить';

  @override
  String get bypassLimitations =>
      'Этот режим обходит DPI только для HTTP и TLS, не поддерживает UDP и не меняет IP. Для голоса Discord, звонков и заблокированных адресов Telegram используйте VPN-сервер.';

  @override
  String get errEngineUnsupported =>
      'Выбранное ядро не поддерживает этот профиль или настройки. Выберите «Авто» либо совместимое ядро.';

  @override
  String get errRestore => 'Не удалось полностью очистить подключение. Повторите отключение; подробности — в журнале.';

  @override
  String get errSessionEnded => 'Эта сессия уже завершена. Обновите состояние подключения.';

  @override
  String get retryDisconnect => 'Повторить отключение';

  @override
  String get tunStack => 'Стек TUN';

  @override
  String get modesInfo => 'Подробнее о режимах';

  @override
  String get modesGuideTitle => 'Режимы и ядра';

  @override
  String get modesGuide =>
      'Выбирайте «Авто», если не знаете, какое ядро нужно серверу. Sora сверяет поддержку профиля и настроек перед подключением. Само ядро не меняет скорость тарифа: результат зависит от сервера, маршрута, протокола и сети.\n\n## Режимы\n\n### Весь трафик (TUN)\n\nSora создаёт виртуальный сетевой интерфейс и направляет через него трафик приложений, включая TCP и UDP. Это подходящий режим для Telegram, игр и голосовой связи Discord. Правила могут отправлять отдельные сайты и программы напрямую или блокировать их. Для работы нужны права сетевой службы и сервер, поддерживающий нужный протокол.\n\n### Системный прокси\n\nSora задаёт локальный HTTP/SOCKS-прокси. Его используют приложения, которые учитывают системные настройки прокси. Программа со своим сетевым стеком может пройти напрямую; UDP и голосовые звонки обычно требуют TUN. Этот режим удобен для браузеров и приложений с поддержкой прокси.\n\n### Без сервера\n\nВ Linux Sora использует [zapret](https://github.com/bol-van/zapret): разбивает и меняет HTTP/TLS-запросы, чтобы обходить некоторые проверки DPI. Адрес IP остаётся вашим, соединение идёт к сайту напрямую. Результат зависит от провайдера и способа блокировки.\n\nТекущая интеграция использует tpws и обрабатывает TCP для HTTP и TLS. Она не обходит блокировку по IP, не пересылает UDP и не гарантирует работу Telegram с MTProto. Для голоса Discord, звонков Telegram и таких блокировок выберите VPN-сервер и TUN.\n\n## Ядра\n\n### Авто\n\nSora выбирает установленное ядро, которое поддерживает весь план подключения. Важно всё сразу: протоколы серверов, транспорт, группы, фрагментация и режим. Если выбранный вручную движок несовместим, новое подключение отклоняется до отключения текущего. Выберите «Авто» или другое ядро и примените настройки снова.\n\n### sing-box\n\nВ новых пакетах Sora используется [sing-box-lx](https://github.com/Leadaxe/sing-box-lx), форк [sing-box](https://github.com/SagerNet/sing-box). Он добавляет клиентский XHTTP и VLESS Encryption. Sora распознаёт сборку и её возможности; стандартный sing-box без XHTTP не получает эту возможность по одному лишь названию.\n\nПоддерживаются VLESS, VMess, Trojan, Shadowsocks, Hysteria2, TUIC, AnyTLS, WireGuard и параметры AmneziaWG 1.x/2.x, которые умеет импортировать Sora. Полные JSON-профили Xray требуют Xray. Новые параметры AWG 3.x ещё не импортируются. Управление sing-box использует защищённый паролем локальный порт; другие программы на компьютере могут заметить его наличие.\n\n### Xray\n\n[Xray-core](https://github.com/XTLS/Xray-core) подходит для VLESS, REALITY, XHTTP, VLESS Encryption и TLS-фрагментации. Он также запускает полные профили Xray от провайдера, сохраняя их маршрутизацию и группы. Профиль такого вида нельзя автоматически превратить в конфиг другого движка без изменения его поведения.\n\nВ поставляемом Xray удалён параметр отключения проверки TLS-сертификата (`allowInsecure`). Для таких обычных серверов «Авто» выбирает sing-box или mihomo. При ручном выборе Xray Sora сообщает о несовместимости до отключения текущего соединения. Для старого полного JSON-профиля нужен обновлённый профиль провайдера с проверяемым сертификатом или его отпечатком.\n\n### mihomo\n\n[mihomo](https://github.com/MetaCubeX/mihomo) поддерживает группы с последовательным резервом и балансировкой, а также XHTTP и AmneziaWG. Выбирайте его, если важен автоматический переход на запасной сервер. Фрагментация TLS из настроек Sora для этого ядра недоступна.\n\n## Совместимость в Sora\n\n| Возможность | sing-box-lx | Xray | mihomo |\n| --- | --- | --- | --- |\n| TUN и TCP/UDP в Linux | Да | Да | Да |\n| XHTTP | Да | Да | Да |\n| VLESS Encryption | Да | Да | Да |\n| Полный профиль Xray | Нет | Да | Нет |\n| TUIC / AnyTLS | Оба | Нет | TUIC |\n| TLS-фрагментация | Да | Да | Нет |\n| AmneziaWG 1.x/2.x | Да¹ | Нет | Да |\n| Группа с резервом | Нет | Нет² | Да |\n\n¹ Профили с J1/J2/J3/Itime направляются в mihomo; эти параметры нельзя молча отбрасывать. ² Для группы полных профилей Xray запасной профиль выбирает приложение. Точная поддержка зависит от установленной сборки. Её версию можно посмотреть в «О приложении».\n\n## Стек TUN\n\nСтек обрабатывает TCP и UDP внутри виртуального интерфейса. В панели режимов у Xray и mihomo можно выбрать gVisor, System, Mixed или MIPS. Выбор сохраняется отдельно для каждого ядра. В режиме системного прокси и «Без сервера» этот выбор не используется.\n\n- **Mixed** — TCP использует системный стек, UDP обрабатывает gVisor. Это вариант по умолчанию для mihomo.\n- **System** — использует системный стек. При проблемах с сетевыми программами попробуйте другой вариант.\n- **gVisor** — обрабатывает трафик в пользовательском пространстве.\n- **MIPS** — собственный IP-стек mihomo, доступный в поставляемой версии 1.19.32.\n\nУ Xray gVisor работает встроенно и выбран по умолчанию. System, Mixed и MIPS подключаются через TUN-движок mihomo: он передаёт TCP и UDP в Xray по защищённому локальному SOCKS. Протокол, профиль провайдера и маршрутизация остаются в Xray. Для этих трёх вариантов нужен установленный mihomo.\n\nСвязка запускает второй процесс. В трёх замерах без трафика она потребляла примерно на 32–36 МиБ больше физической памяти, чем встроенный TUN Xray. Это не оценка нагрузки при скачивании: расходы процессора и память зависят от соединений. Если другой стек не нужен, оставьте gVisor. Для sing-box переключатель не добавляется. Ни один вариант не гарантирует более высокую скорость во всех сетях. Смените стек и нажмите «Применить и переподключить», чтобы проверить результат в своей сети.\n\n## Когда применяются настройки\n\nВыбор режима, ядра, сервера, DNS и правил сохраняется сразу. Во время активного подключения Sora показывает предложение переподключиться. Нажмите «Применить и переподключить», чтобы запустить выбранный план. При перезапуске движка текущие загрузки и звонки могут прерваться. Повторные нажатия не запускают несколько подключений одновременно; отключение завершает смену и освобождает соединение.\n\n«Интернет только через VPN» блокирует прямой выход при обрыве туннеля. Это ограничение действует на всю машину, поэтому используйте его осознанно. При явном отключении Sora снимает свои правила. Если очистка не завершилась, повторите отключение и откройте журнал.\n\n## Документация проектов\n\n- [sing-box-lx: настройки и поддержка](https://github.com/Leadaxe/sing-box-lx/blob/lx/docs-lx/lx-config.ru.md)\n- [sing-box: документация](https://sing-box.sagernet.org/)\n- [Xray: документация](https://xtls.github.io/)\n- [mihomo: документация](https://wiki.metacubex.one/)\n- [zapret: описание и ограничения](https://github.com/bol-van/zapret/blob/master/docs/readme.md)\n';

  @override
  String get probeServers => 'Проверить серверы';
}
