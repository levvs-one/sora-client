import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:pub_semver/pub_semver.dart';

import 'settings.dart';

const appVersion = String.fromEnvironment('SORA_VERSION', defaultValue: 'dev');
const releaseRepository = 'https://github.com/levvs-one/sora-client';
const updateHelper = '/usr/lib/sora/sora-update';
const updatePolicy = '/usr/share/polkit-1/actions/io.github.levvs-one.sora.update.policy';

enum UpdateConnection { idle, connected, changing, unknown }

enum UpdateError { network, release, checksum, installation, connecting, unsupported }

class UpdateFailure implements Exception {
  const UpdateFailure(this.reason);
  final UpdateError reason;
}

/// Build metadata does not describe a different installed release.
Version? releaseVersion(String text) {
  try {
    final version = Version.parse(text.replaceFirst(RegExp(r'^v'), ''));
    return Version(
      version.major,
      version.minor,
      version.patch,
      pre: version.preRelease.join('.').isEmpty ? null : version.preRelease.join('.'),
    );
  } on FormatException {
    return null;
  }
}

bool newerRelease(String candidate, String installed) {
  final next = releaseVersion(candidate), current = releaseVersion(installed);
  return next != null && !next.isPreRelease && current != null && next > current;
}

class ReleaseAsset {
  const ReleaseAsset(this.name, this.url, this.size);
  final String name;
  final Uri url;
  final int size;
}

class SoraRelease {
  const SoraRelease(this.version, this.notes, this.assets);
  final String version;
  final String notes;
  final Map<String, ReleaseAsset> assets;

  static SoraRelease parse(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final tag = json['tag_name'] as String;
      final version = tag.replaceFirst(RegExp(r'^v'), '');
      // Published Sora packages use a three-part stable version in filenames.
      if (json['draft'] != false ||
          json['prerelease'] != false ||
          !RegExp(r'^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$').hasMatch(version)) {
        throw const UpdateFailure(UpdateError.release);
      }
      final assets = <String, ReleaseAsset>{};
      for (final entry in json['assets'] as List) {
        final item = entry as Map<String, dynamic>;
        final name = item['name'] as String;
        final url = Uri.parse(item['browser_download_url'] as String);
        final size = item['size'] as int;
        final expected = Uri.parse('$releaseRepository/releases/download/$tag/$name');
        if (name.contains('/') || name.contains('\\') || size < 1 || assets.containsKey(name) || url != expected) {
          throw const UpdateFailure(UpdateError.release);
        }
        assets[name] = ReleaseAsset(name, url, size);
      }
      return SoraRelease(version, json['body'] as String? ?? '', Map.unmodifiable(assets));
    } on UpdateFailure {
      rethrow;
    } catch (_) {
      throw const UpdateFailure(UpdateError.release);
    }
  }

  ReleaseAsset asset(String name) => assets[name] ?? (throw const UpdateFailure(UpdateError.release));
}

String expectedHash(String manifest, String name) {
  final hashes = <String>[];
  for (final line in const LineSplitter().convert(manifest)) {
    final match = RegExp(r'^([a-fA-F0-9]{64}) [ *](.+)$').firstMatch(line);
    if (match != null && match[2] == name) hashes.add(match[1]!.toLowerCase());
  }
  if (hashes.length != 1) throw const UpdateFailure(UpdateError.checksum);
  return hashes.single;
}

Future<void> verifyUpdateFile(File file, String manifest, String name) async {
  final expected = expectedHash(manifest, name);
  final actual = await sha256.bind(file.openRead()).first;
  if (actual.toString() != expected) throw const UpdateFailure(UpdateError.checksum);
}

enum PackageFormat { deb, rpm, arch }

typedef UpdateProcess = Future<ProcessResult> Function(String executable, List<String> arguments);

class LinuxInstallation {
  const LinuxInstallation(this.format, this.manager);
  final PackageFormat format;
  final String manager;

  List<String> filenames(String version) => switch (format) {
    PackageFormat.deb => ['sora-core_${version}_amd64.deb', 'sora_${version}_amd64.deb'],
    PackageFormat.rpm => ['sora-core-$version-1.x86_64.rpm', 'sora-$version-1.x86_64.rpm'],
    PackageFormat.arch => ['sora-core-$version-1-x86_64.pkg.tar.zst', 'sora-$version-1-x86_64.pkg.tar.zst'],
  };

  List<String> installArguments(List<String> files) => switch (manager) {
    'apt-get' => ['install', '-y', ...files],
    'dnf' => ['install', '-y', ...files],
    'zypper' => ['--non-interactive', 'install', '--allow-unsigned-rpm', ...files],
    'pacman' => ['-U', '--noconfirm', ...files],
    _ => throw const UpdateFailure(UpdateError.unsupported),
  };

  String manualCommand(List<String> files) {
    final arguments = installArguments(files);
    final command = [
      'sudo',
      manager,
      ...arguments.take(arguments.length - files.length),
      ...files.map(shellQuote),
    ].join(' ');
    return manager == 'pacman' ? 'sudo pacman -S --needed gst-plugins-good && $command' : command;
  }

  /// Query ownership of this executable, not merely which managers are present.
  static Future<LinuxInstallation?> detect(UpdateProcess run, String executable) async {
    Future<String?> query(String command, List<String> args) async {
      try {
        final result = await run(command, args).timeout(const Duration(seconds: 5));
        return result.exitCode == 0 ? (result.stdout as String).trim() : null;
      } on Object {
        return null;
      }
    }

    final debOwner = await query('dpkg-query', ['-S', executable]);
    if (debOwner == 'sora: $executable' || debOwner == 'sora:amd64: $executable') {
      final status = await query('dpkg-query', ['-W', '-f=\${Package}\t\${db:Status-Status}\n', 'sora', 'sora-core']);
      if (status != null && status.split('\n').toSet().containsAll({'sora\tinstalled', 'sora-core\tinstalled'})) {
        return const LinuxInstallation(PackageFormat.deb, 'apt-get');
      }
    }
    if (await query('rpm', ['-qf', '--qf', '%{NAME}\n', executable]) == 'sora') {
      final names = await query('rpm', ['-q', '--qf', '%{NAME}\n', 'sora', 'sora-core']);
      if (names != null && names.split('\n').toSet().containsAll({'sora', 'sora-core'})) {
        for (final manager in ['dnf', 'zypper']) {
          if (await query(manager, ['--version']) != null) return LinuxInstallation(PackageFormat.rpm, manager);
        }
      }
    }
    if (await query('pacman', ['-Qoq', executable]) == 'sora') {
      final packages = await query('pacman', ['-Qq', 'sora', 'sora-core']);
      if (packages != null && packages.split('\n').toSet().containsAll({'sora', 'sora-core'})) {
        return const LinuxInstallation(PackageFormat.arch, 'pacman');
      }
    }
    return null;
  }
}

String shellQuote(String value) => "'${value.replaceAll("'", "'\\''")}'";

class AppUpdater extends ChangeNotifier {
  AppUpdater(
    this.settings, {
    required this.connection,
    required this.available,
    this.version = appVersion,
    http.Client Function()? client,
    UpdateProcess? run,
    String? executable,
    bool? windows,
    Future<bool> Function()? canElevate,
  }) : _client = client ?? (() => IOClient(HttpClient()..findProxy = HttpClient.findProxyFromEnvironment)),
       _run = run ?? ((exe, args) => Process.run(exe, args)),
       _executable = executable ?? Platform.resolvedExecutable,
       _windows = windows ?? Platform.isWindows,
       _canElevate =
           canElevate ??
           (() async =>
               await File(updateHelper).exists() &&
               await File(updatePolicy).exists() &&
               await File('/usr/bin/pkexec').exists());

  final Settings settings;
  final String version;
  final UpdateConnection Function() connection;
  final Future<void> Function(SoraRelease release) available;
  final http.Client Function() _client;
  final UpdateProcess _run;
  final String _executable;
  final bool _windows;
  final Future<bool> Function() _canElevate;
  Timer? _timer;
  bool _disposed = false;
  bool _started = false;
  bool checking = false;
  bool busy = false;
  bool installed = false;
  double? progress;
  UpdateError? error;
  SoraRelease? latest;
  String? manualCommand;
  Directory? _work;
  final _clients = <http.Client>{};
  bool get hasUpdate => !installed && latest != null && newerRelease(latest!.version, version);

  void start() {
    if (_started || _disposed) return;
    _started = true;
    _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    if (!settings.checkUpdates || !_started || _disposed) return;
    _timer = Timer.periodic(const Duration(hours: 12), (_) => unawaited(check()));
    unawaited(check());
  }

  Future<void> setChecking(bool enabled) async {
    await settings.saveCheckUpdates(enabled);
    if (_disposed) return;
    _schedule();
    notifyListeners();
  }

  Future<void> check({bool manual = false}) async {
    if (_disposed || checking || busy || (!manual && !settings.checkUpdates)) return;
    checking = true;
    if (manual) error = null;
    notifyListeners();
    try {
      final bytes = await _fetch(
        Uri.parse('https://api.github.com/repos/levvs-one/sora-client/releases/latest'),
        limit: 2 * 1024 * 1024,
      );
      final release = SoraRelease.parse(utf8.decode(bytes));
      if (_disposed || (!manual && !settings.checkUpdates)) return;
      latest = release;
      error = null;
      if (hasUpdate && settings.notifiedUpdate != release.version) {
        await settings.saveNotifiedUpdate(release.version);
        if (!_disposed) await available(release);
      }
    } catch (e) {
      if (manual) error = e is UpdateFailure ? e.reason : UpdateError.network;
    } finally {
      checking = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<List<int>> _fetch(Uri uri, {required int limit, File? target, int? size}) async {
    final client = _client();
    _clients.add(client);
    IOSink? sink;
    final bytes = <int>[];
    final abort = Completer<void>();
    final deadline = Timer(
      target == null ? const Duration(seconds: 20) : const Duration(minutes: 30),
      () => abort.complete(),
    );
    try {
      final request = http.AbortableRequest('GET', uri, abortTrigger: abort.future)
        ..headers.addAll({
          'Accept': uri.host == 'api.github.com' ? 'application/vnd.github+json' : 'application/octet-stream',
          'User-Agent': 'Sora/$version',
          'X-GitHub-Api-Version': '2022-11-28',
        });
      final response = await client.send(request);
      if (response.statusCode != 200 || (response.contentLength ?? 0) > limit) {
        throw const UpdateFailure(UpdateError.network);
      }
      sink = target?.openWrite();
      var received = 0;
      await for (final chunk in response.stream.timeout(const Duration(seconds: 30))) {
        if (_disposed) throw const UpdateFailure(UpdateError.network);
        received += chunk.length;
        if (received > limit) throw const UpdateFailure(UpdateError.network);
        if (sink == null) {
          bytes.addAll(chunk);
        } else {
          sink.add(chunk);
          // Flush each chunk to bound memory while fetching large core packages.
          await sink.flush();
          final next = size == null ? null : received / size;
          if (next != null && (progress == null || (next * 100).floor() != (progress! * 100).floor())) {
            progress = next;
            notifyListeners();
          }
        }
      }
      if (size != null && received != size) throw const UpdateFailure(UpdateError.network);
      return bytes;
    } on UpdateFailure {
      rethrow;
    } on Object {
      throw const UpdateFailure(UpdateError.network);
    } finally {
      deadline.cancel();
      client.close();
      _clients.remove(client);
      await sink?.close();
    }
  }

  void _guard() {
    if (_disposed || connection() == UpdateConnection.changing || connection() == UpdateConnection.unknown) {
      throw const UpdateFailure(UpdateError.connecting);
    }
  }

  /// The caller provides desktop launch/quit operations so tests never elevate.
  Future<void> install({
    required Future<bool> Function() confirmDrop,
    required Future<void> Function(File installer) launchWindows,
    required Future<void> Function() restartLinux,
    required Future<void> Function() quit,
  }) async {
    if (busy || !hasUpdate || _disposed) return;
    error = null;
    manualCommand = null;
    busy = true;
    progress = null;
    notifyListeners();
    bool handedOff = false;
    try {
      _guard();
      final release = latest!;
      final installation = _windows ? null : await LinuxInstallation.detect(_run, _executable);
      if (!_windows && installation == null) throw const UpdateFailure(UpdateError.unsupported);
      final names = _windows ? ['Sora-Setup-${release.version}-x64.exe'] : installation!.filenames(release.version);
      // Resolve the whole pair before downloading or invoking any installer.
      final assets = [for (final name in names) release.asset(name)];
      final sums = release.asset('SHA256SUMS');
      if (_work != null) await _work!.delete(recursive: true);
      final work = _work = await Directory.systemTemp.createTemp('sora-update-');
      final manifest = utf8.decode(await _fetch(sums.url, limit: 1024 * 1024, size: sums.size));
      for (final asset in assets) {
        expectedHash(manifest, asset.name);
      }
      await File('${work.path}/SHA256SUMS').writeAsString(manifest, flush: true);
      for (final asset in assets) {
        final file = File('${work.path}/${asset.name}');
        await _fetch(asset.url, limit: asset.size, target: file, size: asset.size);
        await verifyUpdateFile(file, manifest, asset.name);
      }
      _guard();
      if (connection() == UpdateConnection.connected && !await confirmDrop()) return;
      _guard();
      if (_windows) {
        await settings.saveResumeAfterUpdate(connection() == UpdateConnection.connected);
        _guard();
        await launchWindows(File('${work.path}/${names.single}'));
        handedOff = true;
        await quit();
      } else {
        final paths = [for (final name in names) '${work.path}/$name'];
        if (!await _canElevate()) {
          manualCommand = installation!.manualCommand(paths);
          return;
        }
        _guard();
        await settings.saveResumeAfterUpdate(connection() == UpdateConnection.connected);
        _guard();
        final result = await _run('/usr/bin/pkexec', [
          updateHelper,
          installation!.format.name,
          release.version,
          work.path,
        ]);
        if (result.exitCode != 0) {
          manualCommand = installation.manualCommand(paths);
          throw const UpdateFailure(UpdateError.installation);
        }
        installed = true;
        await restartLinux();
        await quit();
      }
    } catch (e) {
      error = e is UpdateFailure ? e.reason : UpdateError.installation;
    } finally {
      busy = false;
      progress = null;
      if (!handedOff && !installed) await settings.saveResumeAfterUpdate(false);
      // Keep verified files for the manual command or a launched Windows setup.
      if (!handedOff && manualCommand == null && _work != null) {
        await _work!.delete(recursive: true);
        _work = null;
      }
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    for (final client in _clients.toList()) {
      client.close();
    }
    super.dispose();
  }
}
