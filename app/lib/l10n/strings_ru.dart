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
  String get navAbout => 'О программе';

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
  String get markAllRead => 'Прочитать все';

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
  String get speedtestSearch => 'Сервис, страна или оператор';

  @override
  String get speedtestAll => 'Все';

  @override
  String get speedtestCis => 'Россия и СНГ';

  @override
  String get speedtestWorld => 'Мир';

  @override
  String speedtestCount(int count) {
    return 'Сервисов: $count';
  }

  @override
  String get speedtestEmpty => 'Ничего не найдено. Измените запрос или фильтр.';

  @override
  String get speedtestBackToList => 'К списку сервисов';

  @override
  String get speedtestBack => 'Назад по странице';

  @override
  String get speedtestOpenBrowser => 'Открыть в браузере';

  @override
  String speedtestViaVpn(String server) {
    return 'Через VPN: $server';
  }

  @override
  String get speedtestNoVpn => 'Без VPN';

  @override
  String get speedtestStarting => 'Запускаем встроенный браузер...';

  @override
  String get speedtestLoading => 'Загрузка страницы...';

  @override
  String get speedtestUnavailable => 'Встроенный браузер не запустился. Откройте сервис в системном браузере.';

  @override
  String get speedtestPageFailed => 'Страница не загрузилась. Обновите её или откройте сервис в системном браузере.';

  @override
  String get speedtestExternalFailed => 'Системный браузер не открылся. Попробуйте ещё раз.';

  @override
  String get speedtestRoutingNote => 'Маршрут зависит от правил Sora';

  @override
  String get modes => 'Режимы';

  @override
  String get proxyShort => 'Прокси';

  @override
  String get tunMode => 'Весь трафик (TUN)';

  @override
  String get tunExplanation => 'Все приложения через VPN';

  @override
  String get proxyExplanation => 'Трафик приложений с прокси';

  @override
  String get bypassExplanation => 'Обход DPI через zapret, без VPN';

  @override
  String get autoEngineExplanation => 'Ядро подбирает совместимый движок';

  @override
  String get singboxExplanation => 'Гибкая маршрутизация и TUN';

  @override
  String get xrayExplanation => 'VLESS, REALITY и TLS-фрагментация';

  @override
  String get mihomoExplanation => 'Группы серверов и авторезерв';

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
  String get updateCheck => 'Проверить сейчас';

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
}
