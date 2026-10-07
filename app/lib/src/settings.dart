import 'dart:ui' show PlatformDispatcher;

import 'package:shared_preferences/shared_preferences.dart';

/// What the person chose, kept on this machine. Subscriptions and their
/// servers are not here: the core keeps them, encrypted, and updates them
/// while the window is closed.
class Settings {
  Settings._(this._store);

  /// The layout of the stored values. A change of layout raises it and adds a
  /// step to [_migrate], so a stored file from any earlier release still reads.
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
    final stored = _store.getInt('format') ?? 0;
    if (stored > format) {
      // Written by a newer release: values it added are ignored, and the
      // shared ones keep their meaning, because a step never reuses a key.
      return;
    }
    if (stored == 0 && !_store.containsKey('preset')) {
      // A first start. People in Russia, Iran and China most often need their
      // own sites to open directly, so the preset follows the system language.
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

  /// "auto", "bypass" or the id of a server.
  String get server => _store.getString('server') ?? 'auto';
  set server(String value) => _store.setString('server', value);

  /// A routing preset id from the core: global, ru, ir or cn.
  String get preset => _store.getString('preset') ?? 'global';
  set preset(String value) => _store.setString('preset', value);

  bool get blockAds => _store.getBool('blockAds') ?? true;
  set blockAds(bool value) => _store.setBool('blockAds', value);

  bool get killSwitch => _store.getBool('killSwitch') ?? false;
  set killSwitch(bool value) => _store.setBool('killSwitch', value);

  /// An engine kind to pin, or empty to let the core choose.
  String get engine => _store.getString('engine') ?? '';
  set engine(String value) => _store.setString('engine', value);

  bool get animations => _store.getBool('animations') ?? true;
  set animations(bool value) => _store.setBool('animations', value);

  /// system, light or dark.
  String get theme => _store.getString('theme') ?? 'system';
  set theme(String value) => _store.setString('theme', value);

  /// system, or a language code the interface has strings for.
  String get language => _store.getString('language') ?? 'system';
  set language(String value) => _store.setString('language', value);

  /// Splits the TLS ClientHello of proxy connections; empty values take the
  /// core defaults (tlshello, segment lengths and pauses of its choice).
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

  /// Resolvers of the session; empty takes the core defaults.
  List<String> get dns => _store.getStringList('dns') ?? const [];
  set dns(List<String> value) => _store.setStringList('dns', value);

  /// auto (through an engine where one carries the server), engine or connect.
  String get probeMethod => _store.getString('probeMethod') ?? 'auto';
  set probeMethod(String value) => _store.setString('probeMethod', value);

  /// Empty takes the core's test address.
  String get probeUrl => _store.getString('probeUrl') ?? '';
  set probeUrl(String value) => _store.setString('probeUrl', value);

  /// Milliseconds; zero takes the core default.
  int get probeTimeout => _store.getInt('probeTimeout') ?? 0;
  set probeTimeout(int value) => _store.setInt('probeTimeout', value);

  /// zapret's handshake reshaping for "no server". The defaults are the
  /// strategy the interop test runs real traffic through.
  List<String> get splitPos => _store.getStringList('splitPos') ?? const ['1', 'midsld'];
  set splitPos(List<String> value) => _store.setStringList('splitPos', value);
  bool get disorder => _store.getBool('disorder') ?? true;
  set disorder(bool value) => _store.setBool('disorder', value);

  /// Where to split the TLS ClientHello into two records; empty does not split.
  String get tlsRecord => _store.getString('tlsRecord') ?? '';
  set tlsRecord(String value) => _store.setString('tlsRecord', value);
  bool get hostCase => _store.getBool('hostCase') ?? true;
  set hostCase(bool value) => _store.setBool('hostCase', value);

  /// Lets an engine be controlled over a loopback port. sing-box has no
  /// other way, and with it no connection center or counters; the port is
  /// one other programs can find, so it is off until the person agrees.
  bool get controlPort => _store.getBool('controlPort') ?? false;
  set controlPort(bool value) => _store.setBool('controlPort', value);

  /// The person's own rules, each "target destination" where target is
  /// direct, proxy or block and destination is in the contract's form, for
  /// example "direct domain:bank.ru" or "proxy process:telegram-desktop".
  List<String> get rules => _store.getStringList('rules') ?? const [];
  set rules(List<String> value) => _store.setStringList('rules', value);

  /// When the picked server stops answering, the fastest other one carries
  /// the traffic until it comes back.
  bool get failover => _store.getBool('failover') ?? true;
  set failover(bool value) => _store.setBool('failover', value);

  bool get connectOnStart => _store.getBool('connectOnStart') ?? false;
  set connectOnStart(bool value) => _store.setBool('connectOnStart', value);

  /// tun carries every program through the adapter; proxy points the system
  /// proxy at the core and carries the programs that honour it.
  String get tunnel => _store.getString('tunnel') ?? 'tun';
  set tunnel(String value) => _store.setString('tunnel', value);

  /// Sora starts with the system, in the tray.
  bool get launchAtLogin => _store.getBool('launchAtLogin') ?? true;
  set launchAtLogin(bool value) => _store.setBool('launchAtLogin', value);

  /// Closing the window keeps Sora in the tray instead of quitting.
  bool get closeToTray => _store.getBool('closeToTray') ?? true;
  set closeToTray(bool value) => _store.setBool('closeToTray', value);

  /// Notices of what happened while the window was out of sight.
  bool get notifications => _store.getBool('notifications') ?? true;
  set notifications(bool value) => _store.setBool('notifications', value);

  /// The system proxy as it was before Sora pointed it at the core, kept
  /// until it is put back, so a crash in between cannot lose it.
  String get proxySnapshot => _store.getString('proxySnapshot') ?? '';
  set proxySnapshot(String value) => _store.setString('proxySnapshot', value);

  /// The first close to the tray says where Sora went; later ones do not.
  bool get trayHintShown => _store.getBool('trayHintShown') ?? false;
  set trayHintShown(bool value) => _store.setBool('trayHintShown', value);

  /// Forgets every choice; the next read gives the defaults again.
  Future<void> reset() async {
    // The saved system proxy is the machine's, not a choice: it survives, or
    // the next disconnect could not put it back.
    final snapshot = proxySnapshot;
    await _store.clear();
    if (snapshot.isNotEmpty) proxySnapshot = snapshot;
    await _migrate();
  }
}
