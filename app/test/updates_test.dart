import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sora/main.dart';
import 'package:sora/src/desktop/desktop.dart';
import 'package:sora/src/notifications.dart';
import 'package:sora/src/settings.dart';
import 'package:sora/src/sora.dart';
import 'package:sora/src/ui/about.dart';
import 'package:sora/src/ui/kit.dart';
import 'package:sora/src/ui/settings_screen.dart';
import 'package:sora/src/updates.dart';

import 'desktop_shell_test.dart' show section, size;

final recorded = File('test/fixtures/releases/latest.json').readAsStringSync();
final release = SoraRelease.parse(recorded);
const executable = '/usr/lib/sora/app/sora';

Future<ProcessResult> packageQuery(String manager, String exe, List<String> args) async {
  final answer = switch ((manager, exe, args.first)) {
    ('deb', 'dpkg-query', '-S') => 'sora: $executable\n',
    ('deb', 'dpkg-query', '-W') => 'sora\tinstalled\nsora-core\tinstalled\n',
    ('rpm', 'rpm', '-qf') || ('zypper', 'rpm', '-qf') => 'sora\n',
    ('rpm', 'rpm', '-q') || ('zypper', 'rpm', '-q') => 'sora\nsora-core\n',
    ('rpm', 'dnf', '--version') => '4.21.1\n',
    ('zypper', 'zypper', '--version') => 'zypper 1.14.78\n',
    ('arch', 'pacman', '-Qoq') => 'sora\n',
    ('arch', 'pacman', '-Qq') => 'sora\nsora-core\n',
    _ => null,
  };
  return ProcessResult(1, answer == null ? 1 : 0, answer ?? '', '');
}

class UpdateSora extends Sora {
  UpdateSora(super.settings, {String? response, this.current = '1.0.4'}) : response = response ?? recorded;
  final String response;
  final String current;
  int requests = 0;
  @override
  AppUpdater get updates => _updates;
  late final AppUpdater _updates = AppUpdater(
    settings,
    version: current,
    connection: () => phase == Phase.connected
        ? UpdateConnection.connected
        : phase == Phase.off
        ? UpdateConnection.idle
        : UpdateConnection.changing,
    client: () => MockClient((request) async {
      requests++;
      expect(request.url.path, '/repos/levvs-one/sora-client/releases/latest');
      return http.Response(response, 200, headers: {'content-type': 'application/json; charset=utf-8'});
    }),
    available: (release) => recordNotification(
      AppNotification(
        time: DateTime.now(),
        title: strings.updateAvailable(release.version),
        body: strings.updateOpenAbout,
        action: 'update',
      ),
    ),
  )..addListener(notifyListeners);
}

class RecordingDesktop extends Desktop {
  RecordingDesktop(Sora sora) : super(sora, GlobalKey<NavigatorState>());
  @override
  Future<void> launchUpdate(File installer) async => throw StateError('UI test must not launch an installer');
  @override
  Future<void> restartAfterUpdate() async => throw StateError('UI test must not restart');
  @override
  Future<void> quit({bool disconnect = true}) async => throw StateError('UI test must not quit');
}

Future<void> finishCheck(WidgetTester tester, AppUpdater updater) async {
  for (var attempt = 0; attempt < 30 && updater.checking; attempt++) {
    // Stream timeout cancellation completes on the real event loop.
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
  }
  expect(updater.checking, isFalse);
}

void main() {
  setUp(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

  test('release comparison uses numeric semver and ignores build metadata', () {
    for (final (next, current, newer) in [
      ('v1.10.0', '1.9.9', true),
      ('2.0.0', '1.999.999', true),
      ('1.0.5', '1.0.5+6', false),
      ('1.0.4', '1.0.5', false),
      ('1.0.5', '1.0.5-rc.2', true),
      ('1.0.6-beta.1', '1.0.5', false),
      ('1.0.5', 'dev', false),
      ('garbage', '1.0.5', false),
    ]) {
      expect(newerRelease(next, current), newer, reason: '$next / $current');
    }
  });

  test('recorded published release parses notes and complete platform assets', () {
    expect(release.version, '1.0.5');
    expect(release.notes, contains('## Что нового'));
    expect(release.asset('SHA256SUMS').size, greaterThan(0));
    for (final format in PackageFormat.values) {
      for (final name in LinuxInstallation(format, '').filenames(release.version)) {
        expect(release.asset(name).url.host, 'github.com');
      }
    }
    expect(release.asset('Sora-Setup-1.0.5-x64.exe').url.scheme, 'https');
  });

  test('reject drafts, prereleases, malformed fields, duplicates and foreign URLs', () {
    final original = jsonDecode(recorded) as Map<String, dynamic>;
    for (final field in ['draft', 'prerelease']) {
      expect(() => SoraRelease.parse(jsonEncode({...original, field: true})), throwsA(isA<UpdateFailure>()));
    }
    for (final tag in ['v1.0.6-rc.1', '../../oops', '1.0', 'v01.2.3']) {
      expect(() => SoraRelease.parse(jsonEncode({...original, 'tag_name': tag})), throwsA(isA<UpdateFailure>()));
    }
    final assets = original['assets'] as List;
    expect(
      () => SoraRelease.parse(
        jsonEncode({
          ...original,
          'assets': [...assets, assets.first],
        }),
      ),
      throwsA(isA<UpdateFailure>()),
    );
    expect(
      () => SoraRelease.parse(
        jsonEncode({
          ...original,
          'assets': [
            {...assets.first as Map, 'browser_download_url': 'https://example.org/setup.exe'},
          ],
        }),
      ),
      throwsA(isA<UpdateFailure>()),
    );
    expect(() => SoraRelease.parse('{}'), throwsA(isA<UpdateFailure>()));
    expect(() => SoraRelease.parse('not json'), throwsA(isA<UpdateFailure>()));
  });

  test('recorded release script matches SHA256SUMS, corruption and ambiguity fail', () async {
    final sums = File('test/fixtures/releases/SHA256SUMS').readAsStringSync();
    final script = File('test/fixtures/releases/install.sh');
    await verifyUpdateFile(script, sums, 'install.sh');
    expect(
      expectedHash(
        sums.replaceAll('  install.sh', ' *install.sh').toUpperCase().replaceAll('INSTALL.SH', 'install.sh'),
        'install.sh',
      ),
      expectedHash(sums, 'install.sh'),
    );
    final work = await Directory.systemTemp.createTemp('sora-hash-test-');
    addTearDown(() => work.delete(recursive: true));
    final changed = await File('${work.path}/install.sh').writeAsString('${script.readAsStringSync()}corrupted');
    await expectLater(verifyUpdateFile(changed, sums, 'install.sh'), throwsA(isA<UpdateFailure>()));
    expect(() => expectedHash(sums, 'missing'), throwsA(isA<UpdateFailure>()));
    expect(
      () => expectedHash('$sums${expectedHash(sums, 'install.sh')}  install.sh\n', 'install.sh'),
      throwsA(isA<UpdateFailure>()),
    );
  });

  for (final (manager, format) in [
    ('deb', PackageFormat.deb),
    ('rpm', PackageFormat.rpm),
    ('zypper', PackageFormat.rpm),
    ('arch', PackageFormat.arch),
  ]) {
    test('detect installed executable ownership with $manager', () async {
      final detected = await LinuxInstallation.detect((exe, args) => packageQuery(manager, exe, args), executable);
      expect(detected!.format, format);
      expect(detected.filenames(release.version).length, 2);
      expect(detected.manager, switch (manager) {
        'deb' => 'apt-get',
        'rpm' => 'dnf',
        'arch' => 'pacman',
        _ => manager,
      });
    });
  }

  test('unowned executable and missing core never select a package manager', () async {
    expect(await LinuxInstallation.detect((exe, args) async => ProcessResult(1, 1, '', ''), executable), isNull);
    expect(
      await LinuxInstallation.detect((exe, args) async {
        if (exe == 'pacman' && args.first == '-Qoq') return ProcessResult(1, 0, 'sora\n', '');
        if (exe == 'pacman' && args.first == '-Qq') return ProcessResult(1, 0, 'sora\n', '');
        return ProcessResult(1, 1, '', '');
      }, executable),
      isNull,
    );
    expect(shellQuote("/tmp/a'b c"), "'/tmp/a'\\''b c'");
  });

  test('automatic failures stay quiet, explicit failures are visible', () async {
    final settings = await Settings.load();
    var notices = 0;
    final updater = AppUpdater(
      settings,
      connection: () => UpdateConnection.idle,
      available: (_) async {
        notices++;
      },
      client: () => MockClient((_) async => http.Response('{"message":"rate limit"}', 403)),
    );
    addTearDown(updater.dispose);
    await updater.check();
    expect(updater.error, isNull);
    expect(notices, 0);
    await updater.check(manual: true);
    expect(updater.error, UpdateError.network);
    expect(updater.checking, isFalse);
  });

  test('automatic success publishes the recorded release', () async {
    final settings = await Settings.load();
    var notices = 0;
    final updater = AppUpdater(
      settings,
      version: '1.0.4',
      connection: () => UpdateConnection.idle,
      available: (_) async {
        notices++;
      },
      client: () => MockClient((_) async => http.Response.bytes(utf8.encode(recorded), 200)),
    );
    addTearDown(updater.dispose);
    await updater.check(manual: true).timeout(const Duration(seconds: 2));
    expect(updater.error, isNull);
    expect(updater.latest, isNotNull);
    expect(notices, 1);
  });

  testWidgets('start and twelve-hour checks obey settings and persist one notice per version', (tester) async {
    final settings = await Settings.load();
    var checks = 0, notices = 0;
    final updater = AppUpdater(
      settings,
      version: '1.0.4',
      connection: () => UpdateConnection.idle,
      available: (_) async {
        notices++;
      },
      client: () => MockClient((_) async {
        checks++;
        return http.Response(recorded, 200, headers: {'content-type': 'application/json; charset=utf-8'});
      }),
    );
    updater.start();
    await finishCheck(tester, updater);
    expect(checks, 1);
    expect(notices, 1);
    await tester.pump(const Duration(hours: 12));
    await finishCheck(tester, updater);
    expect(checks, 2);
    expect(notices, 1);
    await updater.setChecking(false);
    await tester.pump(const Duration(hours: 24));
    expect(checks, 2);
    expect((await Settings.load()).checkUpdates, isFalse);
    await updater.setChecking(true);
    await finishCheck(tester, updater);
    expect(checks, 3);
    expect(notices, 1);
    updater.dispose();
    final reloaded = AppUpdater(
      await Settings.load(),
      version: '1.0.4',
      connection: () => UpdateConnection.idle,
      available: (_) async {
        notices++;
      },
      client: () => MockClient(
        (_) async => http.Response(recorded, 200, headers: {'content-type': 'application/json; charset=utf-8'}),
      ),
    );
    final checked = reloaded.check();
    await finishCheck(tester, reloaded);
    await checked;
    expect(notices, 1);
    reloaded.dispose();
  });

  for (final manager in ['deb', 'rpm', 'zypper', 'arch', 'windows']) {
    for (final scenario in ['success', 'hash', 'connecting', 'changed', 'cancel', 'manual', 'denied', 'missing']) {
      if (manager == 'windows' && ['manual', 'denied'].contains(scenario)) continue;
      test('$manager install: $scenario', () async {
        final settings = await Settings.load();
        var state = scenario == 'connecting' ? UpdateConnection.changing : UpdateConnection.connected;
        final order = <String>[];
        final requests = <String>[];
        String? downloadDirectory;
        final data = <String, List<int>>{};
        final names = manager == 'windows'
            ? ['Sora-Setup-1.0.5-x64.exe']
            : LinuxInstallation(
                manager == 'deb'
                    ? PackageFormat.deb
                    : manager == 'arch'
                    ? PackageFormat.arch
                    : PackageFormat.rpm,
                '',
              ).filenames('1.0.5');
        for (final name in names) {
          data[name] = utf8.encode('Test bytes for $name');
        }
        data['SHA256SUMS'] = utf8.encode([for (final name in names) '${sha256.convert(data[name]!)}  $name\n'].join());
        final assets = {
          for (final name in [...names, 'SHA256SUMS'])
            name: ReleaseAsset(name, release.asset(name).url, data[name]!.length),
        };
        if (scenario == 'missing') assets.remove(names.last);
        final updater = AppUpdater(
          settings,
          version: '1.0.4',
          executable: executable,
          windows: manager == 'windows',
          connection: () => state,
          available: (_) async {
            order.add('notice');
          },
          canElevate: () async => scenario != 'manual',
          client: () => MockClient((request) async {
            final name = request.url.pathSegments.last;
            requests.add(name);
            if (scenario == 'changed' && name == names.last) state = UpdateConnection.changing;
            final bytes = data[name]!;
            return http.Response.bytes(
              scenario == 'hash' && name == names.last ? List<int>.filled(bytes.length, 0) : bytes,
              200,
            );
          }),
          run: (exe, args) async {
            if (exe != '/usr/bin/pkexec') return packageQuery(manager, exe, args);
            order.add('install');
            downloadDirectory = args.last;
            expect(args.take(3), [
              updateHelper,
              manager == 'deb'
                  ? 'deb'
                  : manager == 'arch'
                  ? 'arch'
                  : 'rpm',
              '1.0.5',
            ]);
            for (final name in names) {
              await verifyUpdateFile(File('${args.last}/$name'), utf8.decode(data['SHA256SUMS']!), name);
            }
            expect(settings.resumeAfterUpdate, isTrue);
            return ProcessResult(1, scenario == 'denied' ? 126 : 0, '', '');
          },
        );
        addTearDown(updater.dispose);
        updater.latest = SoraRelease('1.0.5', release.notes, assets);
        await updater.install(
          confirmDrop: () async {
            order.add('warn');
            return scenario != 'cancel';
          },
          launchWindows: (file) async {
            order.add('install');
            downloadDirectory = file.parent.path;
            expect(await file.exists(), isTrue);
            expect(settings.resumeAfterUpdate, isTrue);
          },
          restartLinux: () async {
            order.add('restart');
          },
          quit: () async {
            order.add('quit');
          },
        );
        expect(updater.busy, isFalse);
        if (scenario == 'success') {
          expect(order, manager == 'windows' ? ['warn', 'install', 'quit'] : ['warn', 'install', 'restart', 'quit']);
          expect(updater.error, isNull);
        } else if (scenario == 'manual' || scenario == 'denied') {
          expect(updater.manualCommand, contains('sora-core'));
          expect(updater.manualCommand, contains(names.last));
          expect(order, scenario == 'manual' ? ['warn'] : ['warn', 'install']);
          expect(settings.resumeAfterUpdate, isFalse);
        } else {
          expect(order, scenario == 'cancel' ? ['warn'] : isEmpty);
          expect(updater.error, switch (scenario) {
            'hash' => UpdateError.checksum,
            'connecting' || 'changed' => UpdateError.connecting,
            'missing' => UpdateError.release,
            _ => null,
          });
          if (scenario == 'connecting' || scenario == 'missing') expect(requests, isEmpty);
          expect(settings.resumeAfterUpdate, isFalse);
        }
        // Test artifacts remain only when the product intentionally keeps a
        // downloaded installer or a manual-install pair.
        if (updater.manualCommand != null) {
          final core = RegExp("'([^']+/sora-core[^']+)'").firstMatch(updater.manualCommand!);
          downloadDirectory ??= File(core![1]!).parent.path;
        }
        if (downloadDirectory != null && Directory(downloadDirectory!).existsSync()) {
          await Directory(downloadDirectory!).delete(recursive: true);
        }
      });
    }
  }

  Future<UpdateSora> showApp(WidgetTester tester, {double width = 1440}) async {
    size(tester, width, 900);
    addTearDown(tester.view.reset);
    final settings = await Settings.load();
    await settings.completeTour();
    settings
      ..language = 'ru'
      ..animations = false;
    final sora = UpdateSora(settings)..phase = Phase.off;
    addTearDown(sora.dispose);
    await tester.pumpWidget(SoraApp(sora: sora, desktop: RecordingDesktop(sora)));
    await tester.pumpAndSettle();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
    return sora;
  }

  testWidgets('one update toast opens About with recorded markdown and navigation badge', (tester) async {
    final sora = await showApp(tester);
    final checked = sora.updates.check();
    await finishCheck(tester, sora.updates);
    await checked;
    await tester.pumpAndSettle();
    expect(find.text('Доступна версия 1.0.5'), findsOneWidget);
    expect(sora.history.single.action, 'update');
    final sidebar = find.byKey(const ValueKey('sidebar'));
    final badges = tester.widgetList<Badge>(find.descendant(of: sidebar, matching: find.byType(Badge)));
    expect(badges.where((b) => b.isLabelVisible).length, 2);
    final repeated = sora.updates.check();
    await finishCheck(tester, sora.updates);
    await repeated;
    await tester.pumpAndSettle();
    expect(sora.history.length, 1);
    await tester.tap(find.text('Доступна версия 1.0.5'));
    await tester.pumpAndSettle();
    expect(find.byType(AboutScreen), findsOneWidget);
    expect(find.text('Версия 1.0.4'), findsOneWidget);
    final markdown = tester.widget<MarkdownBody>(find.byKey(const ValueKey('release-notes')));
    expect(markdown.data, release.notes);
    expect(markdown.selectable, isTrue);
    expect(markdown.onTapLink, isNotNull);
    expect(tester.widget<PrimaryButton>(find.byKey(const ValueKey('install-update'))).onTap, isNotNull);
    sora.phase = Phase.connecting;
    sora.notifyListeners();
    await tester.pumpAndSettle();
    expect(tester.widget<PrimaryButton>(find.byKey(const ValueKey('install-update'))).onTap, isNull);
    expect(tester.takeException(), isNull);
  });

  for (final width in [1000.0, 420.0]) {
    testWidgets('About markdown fits at $width and settings persist update checks', (tester) async {
      final sora = await showApp(tester, width: width);
      final checked = sora.updates.check();
      await finishCheck(tester, sora.updates);
      await checked;
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();
      await section(tester, 7);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('install-update')),
        300,
        scrollable: find.descendant(of: find.byType(AboutScreen), matching: find.byType(Scrollable)).first,
      );
      expect(tester.takeException(), isNull);
      await section(tester, 6);
      await tester.scrollUntilVisible(
        find.text('Проверять обновления'),
        -300,
        scrollable: find.descendant(of: find.byType(SettingsScreen), matching: find.byType(Scrollable)).first,
      );
      await tester.tap(find.text('Проверять обновления'));
      await tester.pumpAndSettle();
      expect(sora.settings.checkUpdates, isFalse);
      expect((await Settings.load()).checkUpdates, isFalse);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
  }
}
