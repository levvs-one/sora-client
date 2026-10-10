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

  /// No description provided for @theme.
  ///
  /// In ru, this message translates to:
  /// **'Тема'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In ru, this message translates to:
  /// **'Как в системе'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In ru, this message translates to:
  /// **'Светлая'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In ru, this message translates to:
  /// **'Тёмная'**
  String get themeDark;

  /// No description provided for @language.
  ///
  /// In ru, this message translates to:
  /// **'Язык'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In ru, this message translates to:
  /// **'Как в системе'**
  String get languageSystem;

  /// No description provided for @sectionConnection.
  ///
  /// In ru, this message translates to:
  /// **'Подключение'**
  String get sectionConnection;

  /// No description provided for @sectionNoServer.
  ///
  /// In ru, this message translates to:
  /// **'Без сервера'**
  String get sectionNoServer;

  /// No description provided for @sectionPing.
  ///
  /// In ru, this message translates to:
  /// **'Пинг'**
  String get sectionPing;

  /// No description provided for @sectionLog.
  ///
  /// In ru, this message translates to:
  /// **'Диагностика'**
  String get sectionLog;

  /// No description provided for @ipv6.
  ///
  /// In ru, this message translates to:
  /// **'IPv6'**
  String get ipv6;

  /// No description provided for @dns.
  ///
  /// In ru, this message translates to:
  /// **'DNS'**
  String get dns;

  /// No description provided for @dnsAuto.
  ///
  /// In ru, this message translates to:
  /// **'Авто'**
  String get dnsAuto;

  /// No description provided for @dnsHint.
  ///
  /// In ru, this message translates to:
  /// **'Адреса через запятую'**
  String get dnsHint;

  /// No description provided for @fragment.
  ///
  /// In ru, this message translates to:
  /// **'Фрагментация TLS'**
  String get fragment;

  /// No description provided for @fragmentPackets.
  ///
  /// In ru, this message translates to:
  /// **'Что дробить'**
  String get fragmentPackets;

  /// No description provided for @fragmentLength.
  ///
  /// In ru, this message translates to:
  /// **'Размер частей'**
  String get fragmentLength;

  /// No description provided for @fragmentInterval.
  ///
  /// In ru, this message translates to:
  /// **'Пауза между частями'**
  String get fragmentInterval;

  /// No description provided for @byDefault.
  ///
  /// In ru, this message translates to:
  /// **'По умолчанию'**
  String get byDefault;

  /// No description provided for @rangeHint.
  ///
  /// In ru, this message translates to:
  /// **'Например, 100-200'**
  String get rangeHint;

  /// No description provided for @splitPos.
  ///
  /// In ru, this message translates to:
  /// **'Места разбиения'**
  String get splitPos;

  /// No description provided for @splitPosHint.
  ///
  /// In ru, this message translates to:
  /// **'Например, 1, midsld'**
  String get splitPosHint;

  /// No description provided for @disorder.
  ///
  /// In ru, this message translates to:
  /// **'Менять порядок частей'**
  String get disorder;

  /// No description provided for @tlsRecord.
  ///
  /// In ru, this message translates to:
  /// **'Делить TLS-запись'**
  String get tlsRecord;

  /// No description provided for @tlsRecordNo.
  ///
  /// In ru, this message translates to:
  /// **'Нет'**
  String get tlsRecordNo;

  /// No description provided for @tlsRecordSni.
  ///
  /// In ru, this message translates to:
  /// **'По имени сайта'**
  String get tlsRecordSni;

  /// No description provided for @tlsRecordFirst.
  ///
  /// In ru, this message translates to:
  /// **'После первого байта'**
  String get tlsRecordFirst;

  /// No description provided for @hostCase.
  ///
  /// In ru, this message translates to:
  /// **'Менять регистр Host'**
  String get hostCase;

  /// No description provided for @probeMethod.
  ///
  /// In ru, this message translates to:
  /// **'Способ'**
  String get probeMethod;

  /// No description provided for @probeAuto.
  ///
  /// In ru, this message translates to:
  /// **'Авто'**
  String get probeAuto;

  /// No description provided for @probeEngine.
  ///
  /// In ru, this message translates to:
  /// **'Через ядро'**
  String get probeEngine;

  /// No description provided for @probeConnect.
  ///
  /// In ru, this message translates to:
  /// **'Только соединение'**
  String get probeConnect;

  /// No description provided for @probeUrl.
  ///
  /// In ru, this message translates to:
  /// **'Адрес проверки'**
  String get probeUrl;

  /// No description provided for @probeTimeout.
  ///
  /// In ru, this message translates to:
  /// **'Ожидание'**
  String get probeTimeout;

  /// No description provided for @seconds.
  ///
  /// In ru, this message translates to:
  /// **'{n} с'**
  String seconds(int n);

  /// No description provided for @subscriptions.
  ///
  /// In ru, this message translates to:
  /// **'Подписки'**
  String get subscriptions;

  /// No description provided for @subscriptionSettings.
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get subscriptionSettings;

  /// No description provided for @userAgent.
  ///
  /// In ru, this message translates to:
  /// **'User-Agent'**
  String get userAgent;

  /// No description provided for @autoUpdate.
  ///
  /// In ru, this message translates to:
  /// **'Обновлять автоматически'**
  String get autoUpdate;

  /// No description provided for @updateInterval.
  ///
  /// In ru, this message translates to:
  /// **'Как часто'**
  String get updateInterval;

  /// No description provided for @intervalProvider.
  ///
  /// In ru, this message translates to:
  /// **'Как просит провайдер'**
  String get intervalProvider;

  /// No description provided for @hours.
  ///
  /// In ru, this message translates to:
  /// **'{n} ч'**
  String hours(int n);

  /// No description provided for @updateNow.
  ///
  /// In ru, this message translates to:
  /// **'Обновить сейчас'**
  String get updateNow;

  /// No description provided for @logLevel.
  ///
  /// In ru, this message translates to:
  /// **'Что записывать'**
  String get logLevel;

  /// No description provided for @levelDebug.
  ///
  /// In ru, this message translates to:
  /// **'Всё'**
  String get levelDebug;

  /// No description provided for @levelInfo.
  ///
  /// In ru, this message translates to:
  /// **'Обычное'**
  String get levelInfo;

  /// No description provided for @levelWarning.
  ///
  /// In ru, this message translates to:
  /// **'Важное'**
  String get levelWarning;

  /// No description provided for @levelError.
  ///
  /// In ru, this message translates to:
  /// **'Только ошибки'**
  String get levelError;

  /// No description provided for @recordDestinations.
  ///
  /// In ru, this message translates to:
  /// **'Записывать адреса сайтов'**
  String get recordDestinations;

  /// No description provided for @reset.
  ///
  /// In ru, this message translates to:
  /// **'Сбросить настройки'**
  String get reset;

  /// No description provided for @resetConfirm.
  ///
  /// In ru, this message translates to:
  /// **'Сбросить все настройки?'**
  String get resetConfirm;

  /// No description provided for @resetAction.
  ///
  /// In ru, this message translates to:
  /// **'Сбросить'**
  String get resetAction;

  /// No description provided for @invalidValue.
  ///
  /// In ru, this message translates to:
  /// **'Такое значение не подойдёт'**
  String get invalidValue;

  /// No description provided for @website.
  ///
  /// In ru, this message translates to:
  /// **'Сайт подписки'**
  String get website;

  /// No description provided for @providerWebsite.
  ///
  /// In ru, this message translates to:
  /// **'Сайт провайдера'**
  String get providerWebsite;

  /// No description provided for @support.
  ///
  /// In ru, this message translates to:
  /// **'Поддержка'**
  String get support;

  /// No description provided for @controlPortQuestion.
  ///
  /// In ru, this message translates to:
  /// **'{engine} управляется через порт на этом компьютере. Другие программы смогут заметить, что VPN включён.'**
  String controlPortQuestion(String engine);

  /// No description provided for @chooseEngine.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать {engine}'**
  String chooseEngine(String engine);

  /// No description provided for @rules.
  ///
  /// In ru, this message translates to:
  /// **'Свои правила'**
  String get rules;

  /// No description provided for @ruleAdd.
  ///
  /// In ru, this message translates to:
  /// **'Новое правило'**
  String get ruleAdd;

  /// No description provided for @ruleHint.
  ///
  /// In ru, this message translates to:
  /// **'Сайт, IP или программа'**
  String get ruleHint;

  /// No description provided for @ruleDirect.
  ///
  /// In ru, this message translates to:
  /// **'Напрямую'**
  String get ruleDirect;

  /// No description provided for @ruleProxy.
  ///
  /// In ru, this message translates to:
  /// **'Через VPN'**
  String get ruleProxy;

  /// No description provided for @ruleBlock.
  ///
  /// In ru, this message translates to:
  /// **'Блокировать'**
  String get ruleBlock;

  /// No description provided for @failover.
  ///
  /// In ru, this message translates to:
  /// **'Переключаться при сбое'**
  String get failover;

  /// No description provided for @connectOnStart.
  ///
  /// In ru, this message translates to:
  /// **'Подключаться при запуске'**
  String get connectOnStart;

  /// No description provided for @expiresIn.
  ///
  /// In ru, this message translates to:
  /// **'{name}: подписка закончится через {days, plural, =0{несколько часов} one{# день} few{# дня} other{# дней}}'**
  String expiresIn(String name, int days);

  /// No description provided for @trafficLow.
  ///
  /// In ru, this message translates to:
  /// **'{name}: осталось {left}'**
  String trafficLow(String name, String left);

  /// No description provided for @ruleInvalid.
  ///
  /// In ru, this message translates to:
  /// **'Не похоже на сайт, IP или программу'**
  String get ruleInvalid;

  /// No description provided for @groupOrdered.
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, one{# сервер} few{# сервера} other{# серверов}}, по очереди'**
  String groupOrdered(int count);

  /// No description provided for @groupBest.
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, one{# сервер} few{# сервера} other{# серверов}}, самый быстрый'**
  String groupBest(int count);

  /// No description provided for @tunnelMode.
  ///
  /// In ru, this message translates to:
  /// **'Режим'**
  String get tunnelMode;

  /// No description provided for @tunnelTun.
  ///
  /// In ru, this message translates to:
  /// **'Весь трафик'**
  String get tunnelTun;

  /// No description provided for @tunnelProxy.
  ///
  /// In ru, this message translates to:
  /// **'Системный прокси'**
  String get tunnelProxy;

  /// No description provided for @proxyAddress.
  ///
  /// In ru, this message translates to:
  /// **'Адрес прокси'**
  String get proxyAddress;

  /// No description provided for @copied.
  ///
  /// In ru, this message translates to:
  /// **'Скопировано'**
  String get copied;

  /// No description provided for @launchAtLogin.
  ///
  /// In ru, this message translates to:
  /// **'Запускать вместе с системой'**
  String get launchAtLogin;

  /// No description provided for @closeToTray.
  ///
  /// In ru, this message translates to:
  /// **'Сворачивать в трей при закрытии'**
  String get closeToTray;

  /// No description provided for @notifications.
  ///
  /// In ru, this message translates to:
  /// **'Уведомления'**
  String get notifications;

  /// No description provided for @trayOpen.
  ///
  /// In ru, this message translates to:
  /// **'Открыть Sora'**
  String get trayOpen;

  /// No description provided for @trayConnect.
  ///
  /// In ru, this message translates to:
  /// **'Подключить'**
  String get trayConnect;

  /// No description provided for @trayDisconnect.
  ///
  /// In ru, this message translates to:
  /// **'Отключить'**
  String get trayDisconnect;

  /// No description provided for @trayServer.
  ///
  /// In ru, this message translates to:
  /// **'Сервер'**
  String get trayServer;

  /// No description provided for @trayQuit.
  ///
  /// In ru, this message translates to:
  /// **'Выйти из Sora'**
  String get trayQuit;

  /// No description provided for @trayTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Sora: {state}'**
  String trayTooltip(String state);

  /// No description provided for @trayTooltipServer.
  ///
  /// In ru, this message translates to:
  /// **'Sora: {state}, {server}'**
  String trayTooltipServer(String state, String server);

  /// No description provided for @noticeInTray.
  ///
  /// In ru, this message translates to:
  /// **'Sora осталась в трее'**
  String get noticeInTray;

  /// No description provided for @noticeInTrayBody.
  ///
  /// In ru, this message translates to:
  /// **'Выйти можно из меню значка'**
  String get noticeInTrayBody;

  /// No description provided for @noticeLost.
  ///
  /// In ru, this message translates to:
  /// **'Соединение прервалось'**
  String get noticeLost;

  /// No description provided for @noticeLostBody.
  ///
  /// In ru, this message translates to:
  /// **'Sora переподключается'**
  String get noticeLostBody;

  /// No description provided for @noticeRestored.
  ///
  /// In ru, this message translates to:
  /// **'Снова подключено'**
  String get noticeRestored;

  /// No description provided for @noticeFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось подключиться'**
  String get noticeFailed;

  /// No description provided for @noticeBackup.
  ///
  /// In ru, this message translates to:
  /// **'Основной сервер не ответил, работает запасной'**
  String get noticeBackup;

  /// No description provided for @noticeNext.
  ///
  /// In ru, this message translates to:
  /// **'Сервер не ответил, работает следующий'**
  String get noticeNext;

  /// No description provided for @noticeMainBack.
  ///
  /// In ru, this message translates to:
  /// **'Основной сервер снова отвечает, трафик идёт через него'**
  String get noticeMainBack;

  /// No description provided for @noticeSubscription.
  ///
  /// In ru, this message translates to:
  /// **'Подписка'**
  String get noticeSubscription;

  /// No description provided for @importTitle.
  ///
  /// In ru, this message translates to:
  /// **'Добавить подписку?'**
  String get importTitle;

  /// No description provided for @importSealed.
  ///
  /// In ru, this message translates to:
  /// **'Эта ссылка зашифрована для Happ, прочитать её может только Happ. Попросите у провайдера обычную ссылку на подписку.'**
  String get importSealed;

  /// No description provided for @understood.
  ///
  /// In ru, this message translates to:
  /// **'Понятно'**
  String get understood;

  /// No description provided for @noAnswer.
  ///
  /// In ru, this message translates to:
  /// **'нет ответа'**
  String get noAnswer;

  /// No description provided for @home.
  ///
  /// In ru, this message translates to:
  /// **'Главная'**
  String get home;

  /// No description provided for @navRules.
  ///
  /// In ru, this message translates to:
  /// **'Правила'**
  String get navRules;

  /// No description provided for @navConnections.
  ///
  /// In ru, this message translates to:
  /// **'Подключения'**
  String get navConnections;

  /// No description provided for @navLogs.
  ///
  /// In ru, this message translates to:
  /// **'Логи'**
  String get navLogs;

  /// No description provided for @navAbout.
  ///
  /// In ru, this message translates to:
  /// **'О приложении'**
  String get navAbout;

  /// No description provided for @sidebarToggle.
  ///
  /// In ru, this message translates to:
  /// **'Развернуть меню'**
  String get sidebarToggle;

  /// No description provided for @more.
  ///
  /// In ru, this message translates to:
  /// **'Ещё'**
  String get more;

  /// No description provided for @less.
  ///
  /// In ru, this message translates to:
  /// **'Свернуть'**
  String get less;

  /// No description provided for @currentServer.
  ///
  /// In ru, this message translates to:
  /// **'Текущий сервер'**
  String get currentServer;

  /// No description provided for @trafficDown.
  ///
  /// In ru, this message translates to:
  /// **'Получено'**
  String get trafficDown;

  /// No description provided for @trafficUp.
  ///
  /// In ru, this message translates to:
  /// **'Отправлено'**
  String get trafficUp;

  /// No description provided for @perSecond.
  ///
  /// In ru, this message translates to:
  /// **'{value}/с'**
  String perSecond(String value);

  /// No description provided for @activeRules.
  ///
  /// In ru, this message translates to:
  /// **'Активные правила: {count}'**
  String activeRules(int count);

  /// No description provided for @recentNotifications.
  ///
  /// In ru, this message translates to:
  /// **'Последние уведомления'**
  String get recentNotifications;

  /// No description provided for @notificationsEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Здесь появятся события подключения и подписок'**
  String get notificationsEmpty;

  /// No description provided for @retryConnect.
  ///
  /// In ru, this message translates to:
  /// **'Подключиться снова'**
  String get retryConnect;

  /// No description provided for @openLogs.
  ///
  /// In ru, this message translates to:
  /// **'Открыть логи'**
  String get openLogs;

  /// No description provided for @tourReplay.
  ///
  /// In ru, this message translates to:
  /// **'Показать гайд снова'**
  String get tourReplay;

  /// No description provided for @tourStep.
  ///
  /// In ru, this message translates to:
  /// **'Шаг {step} из 5'**
  String tourStep(int step);

  /// No description provided for @tourBack.
  ///
  /// In ru, this message translates to:
  /// **'Назад'**
  String get tourBack;

  /// No description provided for @tourNext.
  ///
  /// In ru, this message translates to:
  /// **'Далее'**
  String get tourNext;

  /// No description provided for @tourSkip.
  ///
  /// In ru, this message translates to:
  /// **'Пропустить'**
  String get tourSkip;

  /// No description provided for @tourFinish.
  ///
  /// In ru, this message translates to:
  /// **'Готово'**
  String get tourFinish;

  /// No description provided for @tourAdd.
  ///
  /// In ru, this message translates to:
  /// **'Добавьте ссылку на подписку от провайдера.'**
  String get tourAdd;

  /// No description provided for @tourServer.
  ///
  /// In ru, this message translates to:
  /// **'Выберите сервер. «Самый быстрый» подберёт его за вас.'**
  String get tourServer;

  /// No description provided for @tourConnect.
  ///
  /// In ru, this message translates to:
  /// **'Нажмите здесь, чтобы подключиться или отключиться.'**
  String get tourConnect;

  /// No description provided for @tourMode.
  ///
  /// In ru, this message translates to:
  /// **'Выберите режим. Kill switch блокирует интернет при обрыве VPN.'**
  String get tourMode;

  /// No description provided for @tourSettings.
  ///
  /// In ru, this message translates to:
  /// **'Откройте настройки. Здесь можно показать гайд снова.'**
  String get tourSettings;

  /// No description provided for @chooseProgram.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать программу'**
  String get chooseProgram;

  /// No description provided for @installedApps.
  ///
  /// In ru, this message translates to:
  /// **'Установленные программы'**
  String get installedApps;

  /// No description provided for @runningProcesses.
  ///
  /// In ru, this message translates to:
  /// **'Запущенные процессы'**
  String get runningProcesses;

  /// No description provided for @programsFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось получить список программ'**
  String get programsFailed;

  /// No description provided for @programsEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Программы не найдены. Попробуйте другое имя.'**
  String get programsEmpty;

  /// No description provided for @selectExe.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать файл .exe'**
  String get selectExe;

  /// No description provided for @trafficUnavailable.
  ///
  /// In ru, this message translates to:
  /// **'Счётчики пока недоступны'**
  String get trafficUnavailable;

  /// No description provided for @speedtest.
  ///
  /// In ru, this message translates to:
  /// **'Скорость'**
  String get speedtest;

  /// No description provided for @speedtestCheck.
  ///
  /// In ru, this message translates to:
  /// **'Проверить скорость'**
  String get speedtestCheck;

  /// No description provided for @speedtestSearch.
  ///
  /// In ru, this message translates to:
  /// **'Найти сервис'**
  String get speedtestSearch;

  /// No description provided for @speedtestEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Ничего не найдено. Измените запрос.'**
  String get speedtestEmpty;

  /// No description provided for @speedtestBackToList.
  ///
  /// In ru, this message translates to:
  /// **'К списку сервисов'**
  String get speedtestBackToList;

  /// No description provided for @speedtestOpenBrowser.
  ///
  /// In ru, this message translates to:
  /// **'Открыть в браузере'**
  String get speedtestOpenBrowser;

  /// No description provided for @speedtestUnavailable.
  ///
  /// In ru, this message translates to:
  /// **'Встроенный браузер не запустился. Откройте сервис в системном браузере.'**
  String get speedtestUnavailable;

  /// No description provided for @speedtestPageFailed.
  ///
  /// In ru, this message translates to:
  /// **'Страница не загрузилась. Обновите её или откройте сервис в системном браузере.'**
  String get speedtestPageFailed;

  /// No description provided for @speedtestExternalFailed.
  ///
  /// In ru, this message translates to:
  /// **'Системный браузер не открылся. Попробуйте ещё раз.'**
  String get speedtestExternalFailed;

  /// No description provided for @modes.
  ///
  /// In ru, this message translates to:
  /// **'Режимы'**
  String get modes;

  /// No description provided for @proxyShort.
  ///
  /// In ru, this message translates to:
  /// **'Прокси'**
  String get proxyShort;

  /// No description provided for @tunMode.
  ///
  /// In ru, this message translates to:
  /// **'Весь трафик (TUN)'**
  String get tunMode;

  /// No description provided for @checkUpdates.
  ///
  /// In ru, this message translates to:
  /// **'Проверять обновления'**
  String get checkUpdates;

  /// No description provided for @updates.
  ///
  /// In ru, this message translates to:
  /// **'Обновления приложения'**
  String get updates;

  /// No description provided for @updateAvailable.
  ///
  /// In ru, this message translates to:
  /// **'Доступна версия {version}'**
  String updateAvailable(String version);

  /// No description provided for @updateOpenAbout.
  ///
  /// In ru, this message translates to:
  /// **'Посмотреть обновление'**
  String get updateOpenAbout;

  /// No description provided for @updateNotes.
  ///
  /// In ru, this message translates to:
  /// **'Что изменилось в {version}'**
  String updateNotes(String version);

  /// No description provided for @updateCheck.
  ///
  /// In ru, this message translates to:
  /// **'Проверить обновления'**
  String get updateCheck;

  /// No description provided for @updateChecking.
  ///
  /// In ru, this message translates to:
  /// **'Проверяем...'**
  String get updateChecking;

  /// No description provided for @updateNoNotes.
  ///
  /// In ru, this message translates to:
  /// **'Автор релиза не добавил описание.'**
  String get updateNoNotes;

  /// No description provided for @updateDropWarning.
  ///
  /// In ru, this message translates to:
  /// **'При обновлении Sora и ядра VPN-соединение прервётся на несколько секунд. Продолжить?'**
  String get updateDropWarning;

  /// No description provided for @updateWaitConnection.
  ///
  /// In ru, this message translates to:
  /// **'Дождитесь завершения подключения и готовности службы Sora.'**
  String get updateWaitConnection;

  /// No description provided for @updateDownloading.
  ///
  /// In ru, this message translates to:
  /// **'Скачиваем и проверяем файлы...'**
  String get updateDownloading;

  /// No description provided for @updateInstalling.
  ///
  /// In ru, this message translates to:
  /// **'Подготовка обновления или ожидание пароля администратора...'**
  String get updateInstalling;

  /// No description provided for @updateNetworkError.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось скачать обновление. Попробуйте ещё раз.'**
  String get updateNetworkError;

  /// No description provided for @updateReleaseError.
  ///
  /// In ru, this message translates to:
  /// **'Данные релиза или нужные файлы отсутствуют либо некорректны.'**
  String get updateReleaseError;

  /// No description provided for @updateChecksumError.
  ///
  /// In ru, this message translates to:
  /// **'Файл не совпадает с SHA256SUMS. Установка не запускалась.'**
  String get updateChecksumError;

  /// No description provided for @updateInstallError.
  ///
  /// In ru, this message translates to:
  /// **'Обновление не завершилось. Возможно, запрос прав был отменён.'**
  String get updateInstallError;

  /// No description provided for @updateUnsupported.
  ///
  /// In ru, this message translates to:
  /// **'Этот файл приложения не принадлежит поддерживаемой паре пакетов Sora. Используйте инструкцию установки из описания релиза.'**
  String get updateUnsupported;

  /// No description provided for @updateManual.
  ///
  /// In ru, this message translates to:
  /// **'Выполните команду в терминале для установки обоих проверенных пакетов, затем откройте Sora снова. Файлы сохранены в каталоге загрузки. VPN-соединение прервётся.'**
  String get updateManual;

  /// No description provided for @updateCopyCommand.
  ///
  /// In ru, this message translates to:
  /// **'Скопировать команду'**
  String get updateCopyCommand;

  /// No description provided for @updateChecksDisabled.
  ///
  /// In ru, this message translates to:
  /// **'Автоматические проверки отключены в настройках.'**
  String get updateChecksDisabled;

  /// No description provided for @updateInstalled.
  ///
  /// In ru, this message translates to:
  /// **'Обновление установлено. Откройте Sora снова.'**
  String get updateInstalled;

  /// No description provided for @projectLinks.
  ///
  /// In ru, this message translates to:
  /// **'Проект'**
  String get projectLinks;

  /// No description provided for @githubReleases.
  ///
  /// In ru, this message translates to:
  /// **'Релизы и загрузки'**
  String get githubReleases;

  /// No description provided for @telegramChannel.
  ///
  /// In ru, this message translates to:
  /// **'Канал в Telegram'**
  String get telegramChannel;

  /// No description provided for @licenses.
  ///
  /// In ru, this message translates to:
  /// **'Лицензии'**
  String get licenses;

  /// No description provided for @componentLicenses.
  ///
  /// In ru, this message translates to:
  /// **'Лицензии компонентов'**
  String get componentLicenses;

  /// No description provided for @appCopyright.
  ///
  /// In ru, this message translates to:
  /// **'© 2026 levvs-one и участники проекта'**
  String get appCopyright;

  /// No description provided for @collapseServers.
  ///
  /// In ru, this message translates to:
  /// **'Свернуть серверы'**
  String get collapseServers;

  /// No description provided for @expandServers.
  ///
  /// In ru, this message translates to:
  /// **'Показать серверы'**
  String get expandServers;

  /// No description provided for @hideDescription.
  ///
  /// In ru, this message translates to:
  /// **'Скрыть описание'**
  String get hideDescription;

  /// No description provided for @showDescription.
  ///
  /// In ru, this message translates to:
  /// **'Показать описание'**
  String get showDescription;

  /// No description provided for @pendingConnectionChanges.
  ///
  /// In ru, this message translates to:
  /// **'Чтобы применить изменения, переподключитесь.'**
  String get pendingConnectionChanges;

  /// No description provided for @reconnectNow.
  ///
  /// In ru, this message translates to:
  /// **'Применить и переподключить'**
  String get reconnectNow;

  /// No description provided for @bypassLimitations.
  ///
  /// In ru, this message translates to:
  /// **'Этот режим обходит DPI только для HTTP и TLS, не поддерживает UDP и не меняет IP. Для голоса Discord, звонков и заблокированных адресов Telegram используйте VPN-сервер.'**
  String get bypassLimitations;

  /// No description provided for @errEngineUnsupported.
  ///
  /// In ru, this message translates to:
  /// **'Выбранное ядро не поддерживает этот профиль или настройки. Выберите «Авто» либо совместимое ядро.'**
  String get errEngineUnsupported;

  /// No description provided for @errRestore.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось полностью очистить подключение. Повторите отключение; подробности — в журнале.'**
  String get errRestore;

  /// No description provided for @errSessionEnded.
  ///
  /// In ru, this message translates to:
  /// **'Эта сессия уже завершена. Обновите состояние подключения.'**
  String get errSessionEnded;

  /// No description provided for @retryDisconnect.
  ///
  /// In ru, this message translates to:
  /// **'Повторить отключение'**
  String get retryDisconnect;

  /// No description provided for @tunStack.
  ///
  /// In ru, this message translates to:
  /// **'Стек TUN'**
  String get tunStack;

  /// No description provided for @modesInfo.
  ///
  /// In ru, this message translates to:
  /// **'Подробнее о режимах'**
  String get modesInfo;

  /// No description provided for @modesGuideTitle.
  ///
  /// In ru, this message translates to:
  /// **'Режимы и ядра'**
  String get modesGuideTitle;

  /// No description provided for @modesGuide.
  ///
  /// In ru, this message translates to:
  /// **'Выбирайте «Авто», если не знаете, какое ядро нужно серверу. Sora сверяет поддержку профиля и настроек перед подключением. Само ядро не меняет скорость тарифа: результат зависит от сервера, маршрута, протокола и сети.\n\n## Режимы\n\n### Весь трафик (TUN)\n\nSora создаёт виртуальный сетевой интерфейс и направляет через него трафик приложений, включая TCP и UDP. Это подходящий режим для Telegram, игр и голосовой связи Discord. Правила могут отправлять отдельные сайты и программы напрямую или блокировать их. Для работы нужны права сетевой службы и сервер, поддерживающий нужный протокол.\n\n### Системный прокси\n\nSora задаёт локальный HTTP/SOCKS-прокси. Его используют приложения, которые учитывают системные настройки прокси. Программа со своим сетевым стеком может пройти напрямую; UDP и голосовые звонки обычно требуют TUN. Этот режим удобен для браузеров и приложений с поддержкой прокси.\n\n### Без сервера\n\nВ Linux Sora использует [zapret](https://github.com/bol-van/zapret): разбивает и меняет HTTP/TLS-запросы, чтобы обходить некоторые проверки DPI. Адрес IP остаётся вашим, соединение идёт к сайту напрямую. Результат зависит от провайдера и способа блокировки.\n\nТекущая интеграция использует tpws и обрабатывает TCP для HTTP и TLS. Она не обходит блокировку по IP, не пересылает UDP и не гарантирует работу Telegram с MTProto. Для голоса Discord, звонков Telegram и таких блокировок выберите VPN-сервер и TUN.\n\n## Ядра\n\n### Авто\n\nSora выбирает установленное ядро, которое поддерживает весь план подключения. Важно всё сразу: протоколы серверов, транспорт, группы, фрагментация и режим. Если выбранный вручную движок несовместим, новое подключение отклоняется до отключения текущего. Выберите «Авто» или другое ядро и примените настройки снова.\n\n### sing-box\n\nВ новых пакетах Sora используется [sing-box-lx](https://github.com/Leadaxe/sing-box-lx), форк [sing-box](https://github.com/SagerNet/sing-box). Он добавляет клиентский XHTTP и VLESS Encryption. Sora распознаёт сборку и её возможности; стандартный sing-box без XHTTP не получает эту возможность по одному лишь названию.\n\nПоддерживаются VLESS, VMess, Trojan, Shadowsocks, Hysteria2, TUIC, AnyTLS, WireGuard и параметры AmneziaWG 1.x/2.x, которые умеет импортировать Sora. Полные JSON-профили Xray требуют Xray. Новые параметры AWG 3.x ещё не импортируются. Управление sing-box использует защищённый паролем локальный порт; другие программы на компьютере могут заметить его наличие.\n\n### Xray\n\n[Xray-core](https://github.com/XTLS/Xray-core) подходит для VLESS, REALITY, XHTTP, VLESS Encryption и TLS-фрагментации. Он также запускает полные профили Xray от провайдера, сохраняя их маршрутизацию и группы. Профиль такого вида нельзя автоматически превратить в конфиг другого движка без изменения его поведения.\n\nВ поставляемом Xray удалён параметр отключения проверки TLS-сертификата (`allowInsecure`). Для таких обычных серверов «Авто» выбирает sing-box или mihomo. При ручном выборе Xray Sora сообщает о несовместимости до отключения текущего соединения. Для старого полного JSON-профиля нужен обновлённый профиль провайдера с проверяемым сертификатом или его отпечатком.\n\n### mihomo\n\n[mihomo](https://github.com/MetaCubeX/mihomo) поддерживает группы с последовательным резервом и балансировкой, а также XHTTP и AmneziaWG. Выбирайте его, если важен автоматический переход на запасной сервер. Фрагментация TLS из настроек Sora для этого ядра недоступна.\n\n## Совместимость в Sora\n\n| Возможность | sing-box-lx | Xray | mihomo |\n| --- | --- | --- | --- |\n| TUN и TCP/UDP в Linux | Да | Да | Да |\n| XHTTP | Да | Да | Да |\n| VLESS Encryption | Да | Да | Да |\n| Полный профиль Xray | Нет | Да | Нет |\n| TUIC / AnyTLS | Оба | Нет | TUIC |\n| TLS-фрагментация | Да | Да | Нет |\n| AmneziaWG 1.x/2.x | Да¹ | Нет | Да |\n| Группа с резервом | Нет | Нет² | Да |\n\n¹ Профили с J1/J2/J3/Itime направляются в mihomo; эти параметры нельзя молча отбрасывать. ² Для группы полных профилей Xray запасной профиль выбирает приложение. Точная поддержка зависит от установленной сборки. Её версию можно посмотреть в «О приложении».\n\n## Стек TUN\n\nСтек обрабатывает TCP и UDP внутри виртуального интерфейса. В панели режимов у Xray и mihomo можно выбрать gVisor, System, Mixed или MIPS. Выбор сохраняется отдельно для каждого ядра. В режиме системного прокси и «Без сервера» этот выбор не используется.\n\n- **Mixed** — TCP использует системный стек, UDP обрабатывает gVisor. Это вариант по умолчанию для mihomo.\n- **System** — использует системный стек. При проблемах с сетевыми программами попробуйте другой вариант.\n- **gVisor** — обрабатывает трафик в пользовательском пространстве.\n- **MIPS** — собственный IP-стек mihomo, доступный в поставляемой версии 1.19.32.\n\nУ Xray gVisor работает встроенно и выбран по умолчанию. System, Mixed и MIPS подключаются через TUN-движок mihomo: он передаёт TCP и UDP в Xray по защищённому локальному SOCKS. Протокол, профиль провайдера и маршрутизация остаются в Xray. Для этих трёх вариантов нужен установленный mihomo.\n\nСвязка запускает второй процесс. В трёх замерах без трафика она потребляла примерно на 32–36 МиБ больше физической памяти, чем встроенный TUN Xray. Это не оценка нагрузки при скачивании: расходы процессора и память зависят от соединений. Если другой стек не нужен, оставьте gVisor. Для sing-box переключатель не добавляется. Ни один вариант не гарантирует более высокую скорость во всех сетях. Смените стек и нажмите «Применить и переподключить», чтобы проверить результат в своей сети.\n\n## Когда применяются настройки\n\nВыбор режима, ядра, сервера, DNS и правил сохраняется сразу. Во время активного подключения Sora показывает предложение переподключиться. Нажмите «Применить и переподключить», чтобы запустить выбранный план. При перезапуске движка текущие загрузки и звонки могут прерваться. Повторные нажатия не запускают несколько подключений одновременно; отключение завершает смену и освобождает соединение.\n\n«Интернет только через VPN» блокирует прямой выход при обрыве туннеля. Это ограничение действует на всю машину, поэтому используйте его осознанно. При явном отключении Sora снимает свои правила. Если очистка не завершилась, повторите отключение и откройте журнал.\n\n## Документация проектов\n\n- [sing-box-lx: настройки и поддержка](https://github.com/Leadaxe/sing-box-lx/blob/lx/docs-lx/lx-config.ru.md)\n- [sing-box: документация](https://sing-box.sagernet.org/)\n- [Xray: документация](https://xtls.github.io/)\n- [mihomo: документация](https://wiki.metacubex.one/)\n- [zapret: описание и ограничения](https://github.com/bol-van/zapret/blob/master/docs/readme.md)\n'**
  String get modesGuide;

  /// No description provided for @probeServers.
  ///
  /// In ru, this message translates to:
  /// **'Проверить серверы'**
  String get probeServers;
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
