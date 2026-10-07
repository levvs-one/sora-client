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

  static const _keys = {'format', 'server', 'preset', 'blockAds', 'killSwitch', 'engine', 'animations'};

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
}
