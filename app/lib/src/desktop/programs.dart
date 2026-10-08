import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:ffi/ffi.dart';

typedef Program = ({String name, String binary, String icon, bool running});

Future<List<Program>> installedPrograms() => Isolate.run(() {
  if (!Platform.isLinux) return <Program>[];
  final home = Platform.environment['HOME'];
  final directories = ['/usr/share/applications', if (home != null) '$home/.local/share/applications'];
  final gio = _DesktopEntries();
  final entries = <String, Program>{};
  for (final path in directories) {
    final dir = Directory(path);
    if (!dir.existsSync()) continue;
    for (final file in dir.listSync().whereType<File>().where((f) => f.path.endsWith('.desktop'))) {
      // A user's desktop file overrides the system entry with the same ID.
      final id = file.uri.pathSegments.last;
      entries.remove(id);
      final app = gio.read(file.path);
      if (app != null) entries[id] = app;
    }
  }
  return entries.values.toList()..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
});

Future<List<Program>> runningPrograms() async {
  final names = <String>{};
  if (Platform.isWindows) {
    final result = await Process.run('tasklist', ['/FO', 'CSV', '/NH']);
    if (result.exitCode != 0) throw const OSError('tasklist failed');
    for (final line in const LineSplitter().convert(result.stdout as String)) {
      final name = RegExp(r'^"([^"]+\.exe)"', caseSensitive: false).firstMatch(line)?.group(1);
      if (name != null) names.add(name);
    }
  } else if (Platform.isLinux) {
    await for (final dir in Directory('/proc').list()) {
      if (!RegExp(r'/\d+$').hasMatch(dir.path)) continue;
      try {
        final binary = await Link('${dir.path}/exe').target();
        names.add(binary.split('/').last.replaceFirst(RegExp(r' \(deleted\)$'), ''));
      } on FileSystemException {
        // Processes can exit mid-enumeration or belong to another user.
      }
    }
  }
  return [for (final name in names.toList()..sort()) (name: name, binary: name, icon: '', running: true)];
}

/// GIO implements the desktop-entry specification, including escapes and
/// localized names, and is part of the Linux GTK runtime already required.
class _DesktopEntries {
  final _gio = DynamicLibrary.open('libgio-2.0.so.0');
  final _glib = DynamicLibrary.open('libglib-2.0.so.0');
  final _object = DynamicLibrary.open('libgobject-2.0.so.0');
  late final _open = _gio.lookupFunction<Pointer<Void> Function(Pointer<Utf8>), Pointer<Void> Function(Pointer<Utf8>)>(
    'g_desktop_app_info_new_from_filename',
  );
  late final _name = _gio.lookupFunction<Pointer<Utf8> Function(Pointer<Void>), Pointer<Utf8> Function(Pointer<Void>)>(
    'g_app_info_get_name',
  );
  late final _get = _gio
      .lookupFunction<
        Pointer<Utf8> Function(Pointer<Void>, Pointer<Utf8>),
        Pointer<Utf8> Function(Pointer<Void>, Pointer<Utf8>)
      >('g_desktop_app_info_get_string');
  late final _hidden = _gio.lookupFunction<Int32 Function(Pointer<Void>), int Function(Pointer<Void>)>(
    'g_desktop_app_info_get_is_hidden',
  );
  late final _parse = _glib
      .lookupFunction<
        Int32 Function(Pointer<Utf8>, Pointer<Int32>, Pointer<Pointer<Pointer<Utf8>>>, Pointer<Void>),
        int Function(Pointer<Utf8>, Pointer<Int32>, Pointer<Pointer<Pointer<Utf8>>>, Pointer<Void>)
      >('g_shell_parse_argv');
  late final _freeArgs = _glib
      .lookupFunction<Void Function(Pointer<Pointer<Utf8>>), void Function(Pointer<Pointer<Utf8>>)>('g_strfreev');
  late final _free = _glib.lookupFunction<Void Function(Pointer<Void>), void Function(Pointer<Void>)>('g_free');
  late final _unref = _object.lookupFunction<Void Function(Pointer<Void>), void Function(Pointer<Void>)>(
    'g_object_unref',
  );

  Program? read(String path) => using((arena) {
    final app = _open(path.toNativeUtf8(allocator: arena));
    if (app == nullptr) return null;
    try {
      if (_hidden(app) != 0) return null;
      String get(String key) {
        final value = _get(app, key.toNativeUtf8(allocator: arena));
        if (value == nullptr) return '';
        try {
          return value.toDartString();
        } finally {
          _free(value.cast());
        }
      }

      final exec = get('Exec'), argc = arena<Int32>(), argv = arena<Pointer<Pointer<Utf8>>>();
      if (_parse(exec.toNativeUtf8(allocator: arena), argc, argv, nullptr) == 0) return null;
      try {
        final args = [for (var i = 0; i < argc.value; i++) argv.value[i].toDartString()];
        if (args.isEmpty) return null;
        var binary = args.first;
        if (binary.split('/').last == 'env') {
          binary = args.skip(1).where((a) => !a.startsWith('-') && !a.contains('=')).firstOrNull ?? '';
        }
        binary = binary.split('/').last;
        if (binary.isEmpty || binary.startsWith('%')) return null;
        final name = _name(app);
        return (
          name: name == nullptr ? binary : name.toDartString(),
          binary: binary,
          icon: get('Icon'),
          running: false,
        );
      } finally {
        _freeArgs(argv.value);
      }
    } finally {
      _unref(app);
    }
  });
}
