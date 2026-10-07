import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'strings_en.dart';
import 'strings_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of S
/// returned by `S.of(context)`.
///
/// Applications need to include `S.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/strings.dart';
///
/// return MaterialApp(
///   localizationsDelegates: S.localizationsDelegates,
///   supportedLocales: S.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the S.supportedLocales
/// property.
abstract class S {
  S(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static S of(BuildContext context) {
    return Localizations.of<S>(context, S)!;
  }

  static const LocalizationsDelegate<S> delegate = _SDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en'), Locale('ru')];

  /// No description provided for @stateOff.
  ///
  /// In ru, this message translates to:
  /// **'Не подключено'**
  String get stateOff;

  /// No description provided for @stateConnecting.
  ///
  /// In ru, this message translates to:
  /// **'Подключение'**
  String get stateConnecting;

  /// No description provided for @stateConnected.
  ///
  /// In ru, this message translates to:
  /// **'Подключено'**
  String get stateConnected;

  /// No description provided for @stateReconnecting.
  ///
  /// In ru, this message translates to:
  /// **'Переподключение'**
  String get stateReconnecting;

  /// No description provided for @stateDisconnecting.
  ///
  /// In ru, this message translates to:
  /// **'Отключение'**
  String get stateDisconnecting;

  /// No description provided for @stateFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не подключено'**
  String get stateFailed;

  /// No description provided for @coreMissing.
  ///
  /// In ru, this message translates to:
  /// **'Служба Sora не отвечает'**
  String get coreMissing;

  /// No description provided for @serverAuto.
  ///
  /// In ru, this message translates to:
  /// **'Самый быстрый'**
  String get serverAuto;

  /// No description provided for @serverBypass.
  ///
  /// In ru, this message translates to:
  /// **'Без сервера'**
  String get serverBypass;

  /// No description provided for @addSubscription.
  ///
  /// In ru, this message translates to:
  /// **'Добавить подписку'**
  String get addSubscription;

  /// No description provided for @servers.
  ///
  /// In ru, this message translates to:
  /// **'Серверы'**
  String get servers;

  /// No description provided for @settings.
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get settings;

  /// No description provided for @subscription.
  ///
  /// In ru, this message translates to:
  /// **'Подписка'**
  String get subscription;

  /// No description provided for @subscriptionLink.
  ///
  /// In ru, this message translates to:
  /// **'Ссылка на подписку'**
  String get subscriptionLink;

  /// No description provided for @add.
  ///
  /// In ru, this message translates to:
  /// **'Добавить'**
  String get add;

  /// No description provided for @refresh.
  ///
  /// In ru, this message translates to:
  /// **'Обновить'**
  String get refresh;

  /// No description provided for @rename.
  ///
  /// In ru, this message translates to:
  /// **'Переименовать'**
  String get rename;

  /// No description provided for @delete.
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get delete;

  /// No description provided for @cancel.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get save;

  /// No description provided for @name.
  ///
  /// In ru, this message translates to:
  /// **'Название'**
  String get name;

  /// No description provided for @deleteSubscription.
  ///
  /// In ru, this message translates to:
  /// **'Удалить «{name}»?'**
  String deleteSubscription(String name);

  /// No description provided for @routes.
  ///
  /// In ru, this message translates to:
  /// **'Маршруты'**
  String get routes;

  /// No description provided for @presetGlobal.
  ///
  /// In ru, this message translates to:
  /// **'Всё через VPN'**
  String get presetGlobal;

  /// No description provided for @presetRu.
  ///
  /// In ru, this message translates to:
  /// **'Россия напрямую'**
  String get presetRu;

  /// No description provided for @presetIr.
  ///
  /// In ru, this message translates to:
  /// **'Иран напрямую'**
  String get presetIr;

  /// No description provided for @presetCn.
  ///
  /// In ru, this message translates to:
  /// **'Китай напрямую'**
  String get presetCn;

  /// No description provided for @blockAds.
  ///
  /// In ru, this message translates to:
  /// **'Блокировать рекламу'**
  String get blockAds;

  /// No description provided for @killSwitch.
  ///
  /// In ru, this message translates to:
  /// **'Интернет только через VPN'**
  String get killSwitch;

  /// No description provided for @engine.
  ///
  /// In ru, this message translates to:
  /// **'Ядро'**
  String get engine;

  /// No description provided for @engineAuto.
  ///
  /// In ru, this message translates to:
  /// **'Авто'**
  String get engineAuto;

  /// No description provided for @animations.
  ///
  /// In ru, this message translates to:
  /// **'Анимации'**
  String get animations;

  /// No description provided for @logs.
  ///
  /// In ru, this message translates to:
  /// **'Журнал'**
  String get logs;

  /// No description provided for @about.
  ///
  /// In ru, this message translates to:
  /// **'О приложении'**
  String get about;

  /// No description provided for @logsAll.
  ///
  /// In ru, this message translates to:
  /// **'Все'**
  String get logsAll;

  /// No description provided for @logsImportant.
  ///
  /// In ru, this message translates to:
  /// **'Важное'**
  String get logsImportant;

  /// No description provided for @logsErrors.
  ///
  /// In ru, this message translates to:
  /// **'Ошибки'**
  String get logsErrors;

  /// No description provided for @search.
  ///
  /// In ru, this message translates to:
  /// **'Поиск'**
  String get search;

  /// No description provided for @export.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить в файл'**
  String get export;

  /// No description provided for @clear.
  ///
  /// In ru, this message translates to:
  /// **'Очистить'**
  String get clear;

  /// No description provided for @logsEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Здесь пусто'**
  String get logsEmpty;

  /// No description provided for @appVersion.
  ///
  /// In ru, this message translates to:
  /// **'Версия {version}'**
  String appVersion(String version);

  /// No description provided for @notInstalled.
  ///
  /// In ru, this message translates to:
  /// **'Не установлено'**
  String get notInstalled;

  /// No description provided for @sourceCode.
  ///
  /// In ru, this message translates to:
  /// **'Исходный код'**
  String get sourceCode;

  /// No description provided for @license.
  ///
  /// In ru, this message translates to:
  /// **'Лицензия'**
  String get license;

  /// No description provided for @usage.
  ///
  /// In ru, this message translates to:
  /// **'{used} из {total}'**
  String usage(String used, String total);

  /// No description provided for @until.
  ///
  /// In ru, this message translates to:
  /// **'до {date}'**
  String until(String date);

  /// No description provided for @expired.
  ///
  /// In ru, this message translates to:
  /// **'Срок истёк'**
  String get expired;

  /// No description provided for @milliseconds.
  ///
  /// In ru, this message translates to:
  /// **'{n} мс'**
  String milliseconds(int n);

  /// No description provided for @bytesB.
  ///
  /// In ru, this message translates to:
  /// **'{n} Б'**
  String bytesB(String n);

  /// No description provided for @bytesKB.
  ///
  /// In ru, this message translates to:
  /// **'{n} КБ'**
  String bytesKB(String n);

  /// No description provided for @bytesMB.
  ///
  /// In ru, this message translates to:
  /// **'{n} МБ'**
  String bytesMB(String n);

  /// No description provided for @bytesGB.
  ///
  /// In ru, this message translates to:
  /// **'{n} ГБ'**
  String bytesGB(String n);

  /// No description provided for @bytesTB.
  ///
  /// In ru, this message translates to:
  /// **'{n} ТБ'**
  String bytesTB(String n);

  /// No description provided for @errGeneric.
  ///
  /// In ru, this message translates to:
  /// **'Что-то пошло не так'**
  String get errGeneric;

  /// No description provided for @errCore.
  ///
  /// In ru, this message translates to:
  /// **'Служба Sora не отвечает'**
  String get errCore;

  /// No description provided for @errAuth.
  ///
  /// In ru, this message translates to:
  /// **'Нет доступа к службе Sora'**
  String get errAuth;

  /// No description provided for @errVersion.
  ///
  /// In ru, this message translates to:
  /// **'Обновите Sora: приложение и служба разных версий'**
  String get errVersion;

  /// No description provided for @errBusy.
  ///
  /// In ru, this message translates to:
  /// **'Подождите, предыдущая команда ещё выполняется'**
  String get errBusy;

  /// No description provided for @errEngineMissing.
  ///
  /// In ru, this message translates to:
  /// **'Не найдено ядро для этого сервера'**
  String get errEngineMissing;

  /// No description provided for @errEngineStart.
  ///
  /// In ru, this message translates to:
  /// **'Ядро не запустилось'**
  String get errEngineStart;

  /// No description provided for @errEngineStopped.
  ///
  /// In ru, this message translates to:
  /// **'Ядро остановилось'**
  String get errEngineStopped;

  /// No description provided for @errTunnel.
  ///
  /// In ru, this message translates to:
  /// **'Нет прав на создание VPN-подключения'**
  String get errTunnel;

  /// No description provided for @errServers.
  ///
  /// In ru, this message translates to:
  /// **'Сервер настроен с ошибкой'**
  String get errServers;

  /// No description provided for @errNetwork.
  ///
  /// In ru, this message translates to:
  /// **'Нет связи с сервером'**
  String get errNetwork;

  /// No description provided for @errTimeout.
  ///
  /// In ru, this message translates to:
  /// **'Сервер не ответил вовремя'**
  String get errTimeout;

  /// No description provided for @errFirewall.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось включить блокировку интернета без VPN'**
  String get errFirewall;

  /// No description provided for @errSubFetch.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить подписку'**
  String get errSubFetch;

  /// No description provided for @errSubFormat.
  ///
  /// In ru, this message translates to:
  /// **'Это не ссылка на подписку'**
  String get errSubFormat;

  /// No description provided for @errSubEmpty.
  ///
  /// In ru, this message translates to:
  /// **'В подписке нет серверов'**
  String get errSubEmpty;

  /// No description provided for @errSubDuplicate.
  ///
  /// In ru, this message translates to:
  /// **'Эта подписка уже добавлена'**
  String get errSubDuplicate;

  /// No description provided for @errSubLimit.
  ///
  /// In ru, this message translates to:
  /// **'Слишком много подписок'**
  String get errSubLimit;

  /// No description provided for @errSubScheme.
  ///
  /// In ru, this message translates to:
  /// **'Нужна ссылка, начинающаяся с https://'**
  String get errSubScheme;

  /// No description provided for @errSecretStore.
  ///
  /// In ru, this message translates to:
  /// **'Хранилище Sora повреждено или недоступно'**
  String get errSecretStore;

  /// No description provided for @errNoServers.
  ///
  /// In ru, this message translates to:
  /// **'Добавьте подписку, чтобы подключиться'**
  String get errNoServers;

  /// No description provided for @exportText.
  ///
  /// In ru, this message translates to:
  /// **'Текст'**
  String get exportText;

  /// No description provided for @connections.
  ///
  /// In ru, this message translates to:
  /// **'Соединения'**
  String get connections;

  /// No description provided for @close.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть'**
  String get close;

  /// No description provided for @chainDirect.
  ///
  /// In ru, this message translates to:
  /// **'Напрямую'**
  String get chainDirect;

  /// No description provided for @chainBlocked.
  ///
  /// In ru, this message translates to:
  /// **'Заблокировано'**
  String get chainBlocked;
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  Future<S> load(Locale locale) {
    return SynchronousFuture<S>(lookupS(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_SDelegate old) => false;
}

S lookupS(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return SEn();
    case 'ru':
      return SRu();
  }

  throw FlutterError(
    'S.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
