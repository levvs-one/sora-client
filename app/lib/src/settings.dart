import 'dart:ui' show PlatformDispatcher;

import 'package:shared_preferences/shared_preferences.dart';

import 'notifications.dart';

/// Locally persisted app preferences. The core stores subscriptions and servers
/// encrypted and updates them while the UI is closed.
class Settings {
  Settings._(this._store);

  /// Storage schema version. Increment for layout changes and add a [_migrate]
  /// step to preserve compatibility with earlier releases.
  static const format = 1;

  static const _keys = {
    'format', 'server', 'preset', 'blockAds', 'killSwitch', 'engine', 'animations', 'theme', 'language', //
    'fragment', 'fragmentPackets', 'fragmentLength', 'fragmentInterval', 'ipv6', 'dns', //
    'probeMethod',
    'probeUrl',
    'probeTimeout',
    'splitPos',
    'disorder',
    'tlsRecord',
    'hostCase',
    'controlPort',
    'rules',
    'failover',
    'connectOnStart',
    'tunnel',
    'launchAtLogin',
    'closeToTray',
    'notifications',
    'proxySnapshot',
    'trayHintShown',
    'sidebarExpanded',
    'tourDone',
    'notificationHistory',
  };

  final SharedPreferencesWithCache _store;

  static Future<Settings> load() async {
    final store = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(allowList: _keys),
    );
    final settings = Settings._(store);
    await settings._migrate();
    return settings;
  }

  Future<void> _migrate() async {
    if (!_store.containsKey('tourDone')) {
      // Detect upgrades before migration writes its own defaults.
      final existing = _keys.where((key) => key != 'tourDone').any(_store.containsKey);
      await _store.setBool('tourDone', existing);
    }
    final stored = _store.getInt('format') ?? 0;
    if (stored > format) {
      // Ignore keys from newer releases. Existing keys retain their meaning
      // because migrations never reuse them.
      return;
    }
    if (stored == 0 && !_store.containsKey('preset')) {
      // Default to local-site bypass for Russian, Persian and Chinese locales,
      // where direct access to domestic sites is commonly needed.
      final language = PlatformDispatcher.instance.locale.languageCode;
      await _store.setString('preset', switch (language) {
        'ru' => 'ru',
        'fa' => 'ir',
        'zh' => 'cn',
        _ => 'global',
      });
    }
    await _store.setInt('format', format);
  }

  /// Server selection: "auto", "bypass" or a server ID.
  String get server => _store.getString('server') ?? 'auto';
  set server(String value) => _store.setString('server', value);

  /// Core routing preset: global, ru, ir or cn.
  String get preset => _store.getString('preset') ?? 'global';
  set preset(String value) => _store.setString('preset', value);

  bool get blockAds => _store.getBool('blockAds') ?? true;
  set blockAds(bool value) => _store.setBool('blockAds', value);

  bool get killSwitch => _store.getBool('killSwitch') ?? false;
  set killSwitch(bool value) => _store.setBool('killSwitch', value);

  /// Pinned engine kind; empty lets the core choose.
  String get engine => _store.getString('engine') ?? '';
  set engine(String value) => _store.setString('engine', value);

  bool get animations => _store.getBool('animations') ?? true;
  set animations(bool value) => _store.setBool('animations', value);

  /// Theme selection: system, light or dark.
  String get theme => _store.getString('theme') ?? 'light';
  set theme(String value) => _store.setString('theme', value);

  /// Language selection: system or a supported locale code.
  String get language => _store.getString('language') ?? 'system';
  set language(String value) => _store.setString('language', value);

  /// Enables TLS ClientHello fragmentation for proxy connections. Empty options
  /// use core defaults for packets (tlshello), segment lengths and delays.
  bool get fragment => _store.getBool('fragment') ?? false;
  set fragment(bool value) => _store.setBool('fragment', value);
  String get fragmentPackets => _store.getString('fragmentPackets') ?? '';
  set fragmentPackets(String value) => _store.setString('fragmentPackets', value);
  String get fragmentLength => _store.getString('fragmentLength') ?? '';
  set fragmentLength(String value) => _store.setString('fragmentLength', value);
  String get fragmentInterval => _store.getString('fragmentInterval') ?? '';
  set fragmentInterval(String value) => _store.setString('fragmentInterval', value);

  bool get ipv6 => _store.getBool('ipv6') ?? false;
  set ipv6(bool value) => _store.setBool('ipv6', value);

  /// Session DNS resolvers; empty uses core defaults.
  List<String> get dns => _store.getStringList('dns') ?? const [];
  set dns(List<String> value) => _store.setStringList('dns', value);

  /// Probe method: auto uses the server's engine when available; engine or
  /// connect pins the method.
  String get probeMethod => _store.getString('probeMethod') ?? 'auto';
  set probeMethod(String value) => _store.setString('probeMethod', value);

  /// Probe URL; empty uses the core's test address.
  String get probeUrl => _store.getString('probeUrl') ?? '';
  set probeUrl(String value) => _store.setString('probeUrl', value);

  /// Probe timeout in milliseconds; zero uses the core default.
  int get probeTimeout => _store.getInt('probeTimeout') ?? 0;
  set probeTimeout(int value) => _store.setInt('probeTimeout', value);

  /// zapret handshake splitting for bypass mode. Defaults match the strategy
  /// verified with real traffic by the interop test.
  List<String> get splitPos => _store.getStringList('splitPos') ?? const ['1', 'midsld'];
  set splitPos(List<String> value) => _store.setStringList('splitPos', value);
  bool get disorder => _store.getBool('disorder') ?? true;
  set disorder(bool value) => _store.setBool('disorder', value);

  /// TLS ClientHello record split position; empty disables splitting.
  String get tlsRecord => _store.getString('tlsRecord') ?? '';
  set tlsRecord(String value) => _store.setString('tlsRecord', value);
  bool get hostCase => _store.getBool('hostCase') ?? true;
  set hostCase(bool value) => _store.setBool('hostCase', value);

  /// Allows loopback engine control, required by sing-box, which lacks
  /// connection listing and counters. Other apps can discover the port, so
  /// enabling it requires consent.
  bool get controlPort => _store.getBool('controlPort') ?? false;
  set controlPort(bool value) => _store.setBool('controlPort', value);

  /// User rules in "target destination" format: target is direct, proxy or
  /// block; destination uses the core contract, e.g. "direct domain:bank.ru" or
  /// "proxy process:telegram-desktop".
  List<String> get rules => _store.getStringList('rules') ?? const [];
  set rules(List<String> value) => _store.setStringList('rules', value);

  /// Uses the fastest alternative while the selected server is unreachable,
  /// then returns to the selected server.
  bool get failover => _store.getBool('failover') ?? true;
  set failover(bool value) => _store.setBool('failover', value);

  bool get connectOnStart => _store.getBool('connectOnStart') ?? false;
  set connectOnStart(bool value) => _store.setBool('connectOnStart', value);

  /// Tunnel mode: tun routes all apps through the adapter; proxy configures the
  /// system proxy for apps that honour it.
  String get tunnel => _store.getString('tunnel') ?? 'tun';
  set tunnel(String value) => _store.setString('tunnel', value);

  /// Starts Sora in the tray at login.
  bool get launchAtLogin => _store.getBool('launchAtLogin') ?? true;
  set launchAtLogin(bool value) => _store.setBool('launchAtLogin', value);

  /// Keeps Sora in the tray when the window closes.
  bool get closeToTray => _store.getBool('closeToTray') ?? true;
  set closeToTray(bool value) => _store.setBool('closeToTray', value);

  /// Enables notifications for background events.
  bool get notifications => _store.getBool('notifications') ?? true;
  set notifications(bool value) => _store.setBool('notifications', value);

  /// Original system proxy settings and Sora's endpoint, retained until
  /// restoration. Saving is awaited before proxy changes to allow crash
  /// recovery.
  String get proxySnapshot => _store.getString('proxySnapshot') ?? '';
  Future<void> saveProxySnapshot(String value) => _store.setString('proxySnapshot', value);

  /// Whether the one-time close-to-tray hint has been shown.
  bool get trayHintShown => _store.getBool('trayHintShown') ?? false;
  set trayHintShown(bool value) => _store.setBool('trayHintShown', value);

  bool get sidebarExpanded => _store.getBool('sidebarExpanded') ?? false;
  set sidebarExpanded(bool value) => _store.setBool('sidebarExpanded', value);

  bool get tourDone => _store.getBool('tourDone') ?? false;
  Future<void> completeTour() => _store.setBool('tourDone', true);

  List<AppNotification> get notificationHistory => (_store.getStringList('notificationHistory') ?? const <String>[])
      .map(AppNotification.parse)
      .nonNulls
      .take(100)
      .toList();
  Future<void> saveNotificationHistory(List<AppNotification> history) =>
      _store.setStringList('notificationHistory', history.take(100).map((n) => n.stored).toList());

  /// Resets preferences to defaults while preserving the proxy snapshot.
  Future<void> reset() async {
    // Keep the proxy snapshot so the next disconnect can restore system
    // settings.
    final snapshot = proxySnapshot;
    final history = notificationHistory;
    await _store.clear();
    await completeTour();
    await saveNotificationHistory(history);
    if (snapshot.isNotEmpty) await saveProxySnapshot(snapshot);
    await _migrate();
  }
}
