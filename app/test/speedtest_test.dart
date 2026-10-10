import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sora/main.dart';
import 'package:sora/src/settings.dart';
import 'package:sora/src/sora.dart';
import 'package:sora/src/speedtest_services.dart';
import 'package:sora/src/ui/speedtest.dart';
import 'package:sora/src/ui/shell.dart';
import 'package:webview_all_linux/webview_all_linux.dart';

import 'desktop_shell_test.dart' show section, size;
import 'fixtures/desktop_state.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
  });

  Future<DesktopState> start(WidgetTester tester, {double width = 1440}) async {
    size(tester, width, width < 720 ? 800 : 900);
    addTearDown(tester.view.reset);
    final settings = await Settings.load();
    await settings.completeTour();
    settings
      ..language = 'ru'
      ..animations = false;
    final sora = DesktopState(settings);
    addTearDown(sora.dispose);
    await tester.pumpWidget(SoraApp(sora: sora));
    await tester.pumpAndSettle();
    await section(tester, 7);
    return sora;
  }

  test('catalog starts with Ookla and Yandex and has unique HTTP URLs', () {
    expect(speedtestServices.take(2).map((s) => s.url), ['https://www.speedtest.net/', 'https://yandex.ru/internet']);
    expect(speedtestServices.length, greaterThanOrEqualTo(40));
    expect(speedtestServices.map((s) => s.url).toSet().length, speedtestServices.length);
    expect(speedtestServices.map((s) => s.url), isNot(contains('https://speed.cloudflare.com/')));
    expect(speedtestServices.map((s) => s.url), isNot(contains('https://www.verizon.com/speedtest/')));
    for (final service in speedtestServices) {
      expect(Uri.parse(service.url).scheme, 'https');
      expect(service.regions, isNotEmpty);
      expect(service.operator, isNotEmpty);
      expect(service.measures, isNotEmpty);
      expect(service.note, isNotEmpty);
    }
  });

  testWidgets('Ctrl+2 opens prioritized service panels and search selects the website', (tester) async {
    await start(tester);
    expect(find.byType(SpeedtestScreen), findsOneWidget);
    final ookla = find.byKey(const ValueKey('speedtest-service-https://www.speedtest.net/'));
    final yandex = find.byKey(const ValueKey('speedtest-service-https://yandex.ru/internet'));
    expect(tester.getTopLeft(ookla).dy, lessThan(tester.getTopLeft(yandex).dy));
    expect(find.byType(ChoiceChip), findsNothing);
    expect(find.text('Россия и СНГ'), findsNothing);
    expect(find.text('Мир'), findsNothing);
    expect(find.textContaining('Сервисов:'), findsNothing);
    final name = tester.widget<Text>(find.descendant(of: ookla, matching: find.byType(Text)));
    expect(name.textAlign, TextAlign.center);
    expect(name.style!.fontWeight, FontWeight.w600);
    await tester.enterText(find.byKey(const ValueKey('speedtest-search')), 'ростелеком');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('speedtest-service-https://www.rt.ru/checkup')), findsOneWidget);
    expect(yandex, findsNothing);
    await tester.enterText(find.byKey(const ValueKey('speedtest-search')), 'unknown-service');
    await tester.pumpAndSettle();
    expect(find.text('Ничего не найдено. Измените запрос.'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('speedtest-search')), 'fast.com');
    await tester.pumpAndSettle();
    final fast = find.byKey(const ValueKey('speedtest-service-https://fast.com/'));
    expect(fast, findsOneWidget);
    await tester.tap(fast);
    await tester.pumpAndSettle();
    expect(tester.widget<SpeedtestBrowser>(find.byType(SpeedtestBrowser)).service.url, 'https://fast.com/');
    final tile = tester.widget<Material>(find.ancestor(of: fast, matching: find.byType(Material)).first);
    expect((tile.shape! as RoundedRectangleBorder).side, BorderSide.none);
    expect(find.textContaining('Через VPN:'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('a saved removed service falls back to the first available service', (tester) async {
    final sora = await start(tester);
    await sora.settings.saveSpeedtestService('https://speed.cloudflare.com/');
    await section(tester, 1);
    await section(tester, 7);
    expect(tester.widget<SpeedtestBrowser>(find.byType(SpeedtestBrowser)).service.url, speedtestServices.first.url);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('last service survives a fresh Settings and app', (tester) async {
    final sora = await start(tester);
    await tester.tap(find.byKey(const ValueKey('speedtest-service-https://yandex.ru/internet')));
    await tester.pumpAndSettle();
    final settings = await Settings.load();
    expect(settings.speedtestService, 'https://yandex.ru/internet');
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    final restored = Sora(settings);
    addTearDown(restored.dispose);
    await tester.pumpWidget(SoraApp(sora: restored));
    await tester.pumpAndSettle();
    await section(tester, 7);
    expect(tester.widget<SpeedtestBrowser>(find.byType(SpeedtestBrowser)).service.url, settings.speedtestService);
    expect(sora.settings.speedtestService, settings.speedtestService);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('native startup failure shows a message and external browser action', (tester) async {
    LinuxWebViewPlatform.registerWith();
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const channel = MethodChannel('com.abandoft.webview_all_linux');
    var attempts = 0;
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'createWebView');
      attempts++;
      throw PlatformException(code: 'webkit_unavailable', message: 'No WebKitGTK runtime');
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    await start(tester);
    expect(find.text('Встроенный браузер не запустился. Откройте сервис в системном браузере.'), findsWidgets);
    expect(find.byKey(const ValueKey('speedtest-fallback')), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('speedtest-reload')));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  group('native browser ownership', () {
    const prefix = 'com.abandoft.webview_all_linux';
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    late List<MethodChannel> channels;
    late List<String> loads;
    late Map<int, int> disposals;
    late int created;
    Completer<int>? creation;
    Completer<void>? release;

    Future<void> flush(WidgetTester tester) async {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      for (var i = 0; i < 8; i++) {
        await tester.pump();
      }
    }

    Future<void> event(int id, Map<String, Object?> data) async {
      final done = Completer<void>();
      await messenger.handlePlatformMessage(
        '$prefix/$id/events',
        const StandardMethodCodec().encodeSuccessEnvelope(data),
        (_) => done.complete(),
      );
      await done.future;
    }

    setUp(() {
      LinuxWebViewPlatform.registerWith();
      created = 0;
      creation = null;
      release = null;
      channels = [];
      loads = [];
      disposals = {};
      const root = MethodChannel(prefix);
      channels.add(root);
      messenger.setMockMethodCallHandler(root, (call) async {
        expect(call.method, 'createWebView');
        final id = ++created;
        final channel = MethodChannel('$prefix/$id');
        final events = MethodChannel('$prefix/$id/events');
        channels.addAll([channel, events]);
        messenger.setMockMethodCallHandler(events, (_) async => null);
        messenger.setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'applySettings') expect((call.arguments as Map)['pageCacheEnabled'], false);
          if (call.method == 'loadRequest') loads.add((call.arguments as Map)['url'] as String);
          if (call.method == 'dispose') {
            disposals.update(id, (n) => n + 1, ifAbsent: () => 1);
            await release?.future;
          }
          return null;
        });
        return creation == null ? id : await creation!.future;
      });
    });

    tearDown(() {
      for (final channel in channels) {
        messenger.setMockMethodCallHandler(channel, null);
      }
    });

    testWidgets('40 service changes reuse one controller and leaving releases it once', (tester) async {
      await start(tester);
      for (var i = 0; i < 40; i++) {
        final service = speedtestServices[i % 2];
        await tester.tap(find.byKey(ValueKey('speedtest-service-${service.url}')));
        await tester.pump();
      }
      await tester.pumpAndSettle();
      expect(created, 1);
      expect(loads.last, speedtestServices[1].url);
      expect(disposals, isEmpty);
      await section(tester, 1);
      await flush(tester);
      expect(disposals, {1: 1});
      await section(tester, 7);
      expect(created, 2);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await flush(tester);
      expect(disposals, {1: 1, 2: 1});
      expect(tester.takeException(), isNull);
    });

    testWidgets('closing before native creation completes disposes the late controller', (tester) async {
      await start(tester);
      await section(tester, 1);
      await flush(tester);
      creation = Completer<int>();
      tester.widget<ShellScope>(find.byType(ShellScope)).select(6);
      await tester.pump();
      await tester.pump();
      expect(created, 2);
      await tester.pumpWidget(const SizedBox());
      creation!.complete(2);
      await tester.pumpAndSettle();
      await flush(tester);
      expect(disposals, {1: 1, 2: 1});
      expect(loads, hasLength(1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('stale and subresource errors are ignored, real errors release before retry', (tester) async {
      final sora = await start(tester);
      final old = speedtestServices[0].url, current = speedtestServices[1].url;
      await tester.tap(find.byKey(ValueKey('speedtest-service-$current')));
      await tester.pumpAndSettle();
      await event(1, {'type': 'pageStarted', 'url': current});
      await event(1, {
        'type': 'webResourceError',
        'url': old,
        'isForMainFrame': true,
        'description': 'late old failure',
      });
      await event(1, {
        'type': 'webResourceError',
        'url': current,
        'isForMainFrame': false,
        'description': 'asset failure',
      });
      await tester.pump();
      expect(disposals, isEmpty);
      final before = sora.history.length;
      release = Completer<void>();
      await event(1, {
        'type': 'webResourceError',
        'url': current,
        'isForMainFrame': true,
        'description': 'network failure',
      });
      await tester.pump();
      await flush(tester);
      expect(sora.history.length, before + 1);
      expect(disposals, {1: 1});
      await tester.tap(find.byKey(const ValueKey('speedtest-reload')));
      await tester.pump();
      expect(created, 1, reason: 'retry waits for native cleanup');
      release!.complete();
      release = null;
      await tester.pumpAndSettle();
      expect(created, 2);
      await event(2, {'type': 'pageStarted', 'url': current});
      await event(2, {'type': 'pageFinished', 'url': current});
      await tester.pump(const Duration(seconds: 46));
      expect(find.byKey(const ValueKey('speedtest-reload')), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await flush(tester);
      expect(disposals, {1: 1, 2: 1});
      expect(tester.takeException(), isNull);
    });

    testWidgets('a terminated process after page completion releases the browser and allows recovery', (tester) async {
      await start(tester);
      final url = speedtestServices[0].url;
      await event(1, {'type': 'pageStarted', 'url': url});
      await event(1, {'type': 'pageFinished', 'url': url});
      await event(1, {
        'type': 'webResourceError',
        'errorCode': 0,
        'errorType': 'webContentProcessTerminated',
        'isForMainFrame': true,
        'description': 'WebKit web process terminated',
      });
      await tester.pump();
      await flush(tester);
      expect(disposals, {1: 1});
      expect(find.byKey(const ValueKey('speedtest-reload')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('speedtest-reload')));
      await tester.pumpAndSettle();
      expect(created, 2);
      expect(loads.last, url);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await flush(tester);
      expect(disposals, {1: 1, 2: 1});
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('narrow list opens full pane, returns, and sidebar opens speed', (tester) async {
    final sora = await start(tester, width: 420);
    expect(find.byType(SpeedtestBrowser), findsNothing);
    await tester.tap(find.byKey(const ValueKey('speedtest-service-https://yandex.ru/internet')));
    await tester.pumpAndSettle();
    expect(find.byType(SpeedtestBrowser), findsOneWidget);
    expect(find.byKey(const ValueKey('speedtest-search')), findsNothing);
    expect(find.textContaining('Через VPN:'), findsNothing);
    sora.phase = Phase.off;
    sora.notifyListeners();
    await tester.pumpAndSettle();
    expect(find.text('Без VPN'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('speedtest-return')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('speedtest-search')), findsOneWidget);
    await section(tester, 1);
    await section(tester, 7);
    await tester.pumpAndSettle();
    expect(find.byType(SpeedtestScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('root dialogs and narrow navigation hide the native browser area', (tester) async {
    await start(tester);
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    final navigator = tester.widget<MaterialApp>(find.byType(MaterialApp)).navigatorKey!;
    final dialog = showDialog<void>(
      context: navigator.currentContext!,
      builder: (_) => const Dialog(child: Text('Import subscription')),
    );
    await tester.pumpAndSettle();
    expect(tester.widget<SpeedtestBrowser>(find.byType(SpeedtestBrowser)).visible, isFalse);
    navigator.currentState!.pop();
    await dialog;
    await tester.pumpAndSettle();
    expect(tester.widget<SpeedtestBrowser>(find.byType(SpeedtestBrowser)).visible, isTrue);
    size(tester, 420, 800);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('speedtest-service-https://www.speedtest.net/')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('speedtest-menu')));
    await tester.pumpAndSettle();
    expect(tester.widget<SpeedtestBrowser>(find.byType(SpeedtestBrowser)).visible, isFalse);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(tester.widget<SpeedtestBrowser>(find.byType(SpeedtestBrowser)).visible, isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('speed section light and dark screenshots', (tester) async {
    final output = '${Platform.environment['HOME']!}/.local/share/sora-dev/shots';
    await tester.runAsync(() async {
      await (FontLoader('Inter')
            ..addFont(Future.value(ByteData.sublistView(await File('assets/fonts/InterVariable.ttf').readAsBytes()))))
          .load();
      await (FontLoader(
        'packages/material_symbols_icons/MaterialSymbolsRounded',
      )..addFont(rootBundle.load('packages/material_symbols_icons/lib/fonts/MaterialSymbolsRounded.ttf'))).load();
      await Directory(output).create(recursive: true);
    });
    addTearDown(tester.view.reset);
    final capture = GlobalKey();
    for (final theme in ['light', 'dark']) {
      for (final (width, height) in [(1440.0, 900.0), (1000.0, 720.0), (420.0, 800.0)]) {
        SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
        final settings = await Settings.load();
        await settings.completeTour();
        settings
          ..language = 'ru'
          ..theme = theme
          ..animations = false;
        final sora = Sora(settings);
        size(tester, width, height);
        await tester.pumpWidget(
          RepaintBoundary(
            key: capture,
            child: SoraApp(sora: sora),
          ),
        );
        await tester.pumpAndSettle();
        await section(tester, 7);
        await tester.pump(const Duration(seconds: 6));
        await tester.pumpAndSettle();
        for (final pane in width == 420 ? ['list', 'browser'] : ['list-browser']) {
          if (pane == 'browser') {
            await tester.tap(find.byKey(const ValueKey('speedtest-service-https://www.speedtest.net/')));
            await tester.pumpAndSettle();
          }
          expect(tester.takeException(), isNull);
          final boundary = capture.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          await tester.runAsync(() async {
            final rendered = await boundary.toImage(pixelRatio: 1);
            final png = (await rendered.toByteData(format: ui.ImageByteFormat.png))!;
            final path = '$output/speedtest-$pane-${width.toInt()}x${height.toInt()}-$theme.png';
            await File(path).writeAsBytes(png.buffer.asUint8List());
            rendered.dispose();
            debugPrint(path);
          });
        }
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
        sora.dispose();
      }
    }
  }, skip: Platform.environment['SORA_SHOTS'] == null);
}
