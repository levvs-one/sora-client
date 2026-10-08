import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

/// Controls the signed-in user's proxy in the UI process; the core service
/// would change its own account's settings. Persist [read] before pointing at
/// the core, then pass that snapshot to [restore], including after a crash.
abstract interface class SystemProxy {
  /// Returns a proxy controller for Windows, GNOME-like desktops or KDE.
  /// Returns null elsewhere; other Linux desktops use per-app proxy settings.
  static SystemProxy? forThisDesktop() {
    if (Platform.isWindows) return _WinInet();
    if (!Platform.isLinux) return null;
    // Match Chromium's desktop detection for system proxy settings.
    final desktop = (Platform.environment['XDG_CURRENT_DESKTOP'] ?? '').toUpperCase().split(':');
    if (desktop.contains('KDE')) return _Kde();
    const gnomeLike = {'GNOME', 'UNITY', 'CINNAMON', 'X-CINNAMON', 'BUDGIE', 'PANTHEON'};
    if (desktop.any(gnomeLike.contains)) return _Gnome();
    return null;
  }

  /// Reads a proxy snapshot accepted by [restore].
  Future<String> read();

  /// Points the system proxy at [host]:[port].
  Future<void> point(String host, int port);

  /// Checks whether the proxy still matches [host]:[port] before restoration,
  /// preserving changes made by the user or another app.
  Future<bool> pointsAt(String host, int port);

  /// Restores the snapshot returned by [read].
  Future<void> restore(String snapshot);
}

/// Local and private-network destinations excluded from proxying.
final _bypass = ['localhost', '127.*', '10.*', for (var i = 16; i < 32; i++) '172.$i.*', '192.168.*', '<local>'];

/// Uses WinINet per-connection options, like Windows Settings, to notify
/// running apps of proxy changes as well as updating settings.
final class _WinInet implements SystemProxy {
  static final _dll = DynamicLibrary.open('wininet.dll');
  static final _set = _dll
      .lookupFunction<
        Int32 Function(Pointer<Void>, Uint32, Pointer<Void>, Uint32),
        int Function(Pointer<Void>, int, Pointer<Void>, int)
      >('InternetSetOptionW');
  static final _query = _dll
      .lookupFunction<
        Int32 Function(Pointer<Void>, Uint32, Pointer<Void>, Pointer<Uint32>),
        int Function(Pointer<Void>, int, Pointer<Void>, Pointer<Uint32>)
      >('InternetQueryOptionW');
  static final _globalFree = DynamicLibrary.open('kernel32.dll')
      .lookupFunction<Pointer<Void> Function(Pointer<Void>), Pointer<Void> Function(Pointer<Void>)>('GlobalFree');

  static const _perConnectionOption = 75;
  static const _settingsChanged = 39;
  static const _refresh = 37;
  static const _flags = 1, _server = 2, _bypassList = 3, _autoConfigUrl = 4;
  static const _direct = 1, _proxy = 2;

  @override
  Future<String> read() async => jsonEncode(_read());

  @override
  Future<void> point(String host, int port) async =>
      _write(flags: _direct | _proxy, server: '$host:$port', bypass: _bypass.join(';'), autoConfigUrl: '');

  @override
  Future<bool> pointsAt(String host, int port) async {
    final now = _read();
    return (now['flags']! as int) & _proxy != 0 && now['server'] == '$host:$port';
  }

  @override
  Future<void> restore(String snapshot) async {
    final before = jsonDecode(snapshot) as Map<String, dynamic>;
    _write(
      flags: before['flags'] as int,
      server: before['server'] as String,
      bypass: before['bypass'] as String,
      autoConfigUrl: before['autoConfigUrl'] as String,
    );
  }

  Map<String, Object> _read() => using((arena) {
    final options = arena<_Option>(4);
    for (final (i, id) in [_flags, _server, _bypassList, _autoConfigUrl].indexed) {
      options[i].option = id;
    }
    final list = _list(arena, options, 4);
    final size = arena<Uint32>()..value = sizeOf<_OptionList>();
    if (_query(nullptr, _perConnectionOption, list.cast(), size) == 0) {
      throw const OSError('the system proxy cannot be read');
    }
    String take(int i) {
      final text = options[i].value.string;
      if (text == nullptr) return '';
      final value = text.toDartString();
      _globalFree(text.cast());
      return value;
    }

    return {'flags': options[0].value.dword, 'server': take(1), 'bypass': take(2), 'autoConfigUrl': take(3)};
  });

  void _write({required int flags, required String server, required String bypass, required String autoConfigUrl}) {
    using((arena) {
      final options = arena<_Option>(4);
      options[0]
        ..option = _flags
        ..value.dword = flags;
      options[1]
        ..option = _server
        ..value.string = server.toNativeUtf16(allocator: arena);
      options[2]
        ..option = _bypassList
        ..value.string = bypass.toNativeUtf16(allocator: arena);
      options[3]
        ..option = _autoConfigUrl
        ..value.string = autoConfigUrl.toNativeUtf16(allocator: arena);
      final list = _list(arena, options, 4);
      if (_set(nullptr, _perConnectionOption, list.cast(), sizeOf<_OptionList>()) == 0) {
        throw const OSError('the system proxy cannot be set');
      }
    });
    _set(nullptr, _settingsChanged, nullptr, 0);
    _set(nullptr, _refresh, nullptr, 0);
  }

  static Pointer<_OptionList> _list(Arena arena, Pointer<_Option> options, int count) => arena<_OptionList>()
    ..ref.size = sizeOf<_OptionList>()
    // A null connection selects LAN settings, inherited by connections without
    // their own settings.
    ..ref.connection = nullptr
    ..ref.count = count
    ..ref.error = 0
    ..ref.options = options;
}

final class _Value extends Union {
  @Uint32()
  external int dword;
  external Pointer<Utf16> string;
  @Uint64()
  external int filetime;
}

final class _Option extends Struct {
  @Uint32()
  external int option;
  external _Value value;
}

final class _OptionList extends Struct {
  @Uint32()
  external int size;
  external Pointer<Utf16> connection;
  @Uint32()
  external int count;
  @Uint32()
  external int error;
  external Pointer<_Option> options;
}

/// Proxy settings for GNOME and compatible desktops.
final class _Gnome implements SystemProxy {
  static const _keys = [
    ('org.gnome.system.proxy', 'mode'),
    ('org.gnome.system.proxy', 'ignore-hosts'),
    ('org.gnome.system.proxy.http', 'host'),
    ('org.gnome.system.proxy.http', 'port'),
    ('org.gnome.system.proxy.https', 'host'),
    ('org.gnome.system.proxy.https', 'port'),
    ('org.gnome.system.proxy.socks', 'host'),
    ('org.gnome.system.proxy.socks', 'port'),
  ];

  @override
  Future<String> read() async {
    final before = <String, String>{};
    for (final (schema, key) in _keys) {
      before['$schema $key'] = await _gsettings(['get', schema, key]);
    }
    return jsonEncode(before);
  }

  @override
  Future<bool> pointsAt(String host, int port) async =>
      await _gsettings(['get', 'org.gnome.system.proxy', 'mode']) == "'manual'" &&
      await _gsettings(['get', 'org.gnome.system.proxy.http', 'host']) == "'$host'" &&
      await _gsettings(['get', 'org.gnome.system.proxy.http', 'port']) == '$port';

  @override
  Future<void> point(String host, int port) async {
    final hosts = "['localhost', '127.0.0.0/8', '::1', '10.0.0.0/8', '172.16.0.0/12', '192.168.0.0/16']";
    for (final schema in ['http', 'https', 'socks']) {
      await _gsettings(['set', 'org.gnome.system.proxy.$schema', 'host', host]);
      await _gsettings(['set', 'org.gnome.system.proxy.$schema', 'port', '$port']);
    }
    await _gsettings(['set', 'org.gnome.system.proxy', 'ignore-hosts', hosts]);
    await _gsettings(['set', 'org.gnome.system.proxy', 'mode', 'manual']);
  }

  @override
  Future<void> restore(String snapshot) async {
    final before = (jsonDecode(snapshot) as Map<String, dynamic>).cast<String, String>();
    // Restore the mode last to avoid enabling partially restored proxy
    // settings.
    for (final (schema, key) in _keys.reversed) {
      final value = before['$schema $key'];
      if (value != null) await _gsettings(['set', schema, key, value]);
    }
  }

  static Future<String> _gsettings(List<String> args) async {
    final result = await Process.run('gsettings', args);
    if (result.exitCode != 0) throw OSError('gsettings: ${result.stderr}'.trim());
    return (result.stdout as String).trim();
  }
}

/// KIO proxy settings used by KDE Plasma apps and Chromium.
final class _Kde implements SystemProxy {
  static const _keys = ['ProxyType', 'httpProxy', 'httpsProxy', 'socksProxy', 'NoProxyFor'];

  @override
  Future<String> read() async => jsonEncode({for (final key in _keys) key: await _read(key)});

  @override
  Future<bool> pointsAt(String host, int port) async =>
      await _read('ProxyType') == '1' && await _read('httpProxy') == 'http://$host $port';

  @override
  Future<void> point(String host, int port) async {
    await _write('httpProxy', 'http://$host $port');
    await _write('httpsProxy', 'http://$host $port');
    await _write('socksProxy', 'socks://$host $port');
    await _write('NoProxyFor', 'localhost,127.0.0.0/8,::1,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16');
    await _write('ProxyType', '1');
    await _announce();
  }

  @override
  Future<void> restore(String snapshot) async {
    final before = (jsonDecode(snapshot) as Map<String, dynamic>).cast<String, String>();
    for (final key in _keys.reversed) {
      await _write(key, before[key] ?? '');
    }
    await _announce();
  }

  static String get _tool => File('/usr/bin/kwriteconfig6').existsSync() ? '6' : '5';

  static Future<String> _read(String key) async {
    final result = await Process.run('kreadconfig$_tool', [
      '--file',
      'kioslaverc',
      '--group',
      'Proxy Settings',
      '--key',
      key,
    ]);
    return (result.stdout as String).trim();
  }

  static Future<void> _write(String key, String value) async {
    final result = await Process.run('kwriteconfig$_tool', [
      '--file',
      'kioslaverc',
      '--group',
      'Proxy Settings',
      '--key',
      key,
      value,
    ]);
    if (result.exitCode != 0) throw OSError('kwriteconfig: ${result.stderr}'.trim());
  }

  /// Signals running KIO apps to reload their proxy configuration.
  static Future<void> _announce() => Process.run('dbus-send', [
    '--type=signal',
    '/KIO/Scheduler',
    'org.kde.KIO.Scheduler.reparseSlaveConfiguration',
    'string:',
  ]);
}
