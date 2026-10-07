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
}
