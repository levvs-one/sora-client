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
    await section(tester, 8);
    return sora;
  }

  test('catalog starts with Ookla and Yandex and has unique HTTP URLs', () {
    expect(speedtestServices.take(2).map((s) => s.url), ['https://www.speedtest.net/', 'https://yandex.ru/internet']);
    expect(speedtestServices.length, greaterThanOrEqualTo(40));
    expect(speedtestServices.map((s) => s.url).toSet().length, speedtestServices.length);
    for (final service in speedtestServices) {
      expect(Uri.parse(service.url).scheme, 'https');
      expect(service.regions, isNotEmpty);
      expect(service.operator, isNotEmpty);
      expect(service.measures, isNotEmpty);
      expect(service.note, isNotEmpty);
    }
  });

  testWidgets('Ctrl+8, regional filter and search work together', (tester) async {
    await start(tester);
    expect(find.byType(SpeedtestScreen), findsOneWidget);
    final ookla = find.byKey(const ValueKey('speedtest-service-https://www.speedtest.net/'));
    final yandex = find.byKey(const ValueKey('speedtest-service-https://yandex.ru/internet'));
    expect(tester.getTopLeft(ookla).dy, lessThan(tester.getTopLeft(yandex).dy));
    await tester.tap(find.byKey(const ValueKey('speedtest-filter-cis')));
    await tester.pumpAndSettle();
    expect(ookla, findsNothing);
    expect(yandex, findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('speedtest-search')), 'ростелеком');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('speedtest-service-https://www.rt.ru/checkup')), findsOneWidget);
    expect(yandex, findsNothing);
    await tester.tap(find.byKey(const ValueKey('speedtest-filter-world')));
    await tester.pumpAndSettle();
    expect(find.text('Ничего не найдено. Измените запрос или фильтр.'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('speedtest-search')), 'cloudflare');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('speedtest-service-https://speed.cloudflare.com/')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('last service and filter survive a fresh Settings and app', (tester) async {
    final sora = await start(tester);
    await tester.tap(find.byKey(const ValueKey('speedtest-service-https://yandex.ru/internet')));
    await tester.tap(find.byKey(const ValueKey('speedtest-filter-cis')));
    await tester.pumpAndSettle();
    final settings = await Settings.load();
    expect(settings.speedtestService, 'https://yandex.ru/internet');
    expect(settings.speedtestFilter, 'cis');
    await tester.pumpWidget(const SizedBox());
    final restored = Sora(settings);
    addTearDown(restored.dispose);
    await tester.pumpWidget(SoraApp(sora: restored));
    await tester.pumpAndSettle();
    await section(tester, 8);
    expect(tester.widget<SpeedtestBrowser>(find.byType(SpeedtestBrowser)).service.url, settings.speedtestService);
    expect(tester.widget<ChoiceChip>(find.byKey(const ValueKey('speedtest-filter-cis'))).selected, isTrue);
    expect(sora.settings.speedtestService, settings.speedtestService);
    await tester.pumpWidget(const SizedBox());
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
    expect(find.text('Встроенный браузер не запустился. Откройте сервис в системном браузере.'), findsOneWidget);
    expect(find.byKey(const ValueKey('speedtest-external')), findsOneWidget);
    expect(find.byKey(const ValueKey('speedtest-fallback')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('speedtest-reload')));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('narrow list opens full pane, returns, and home link opens speed', (tester) async {
    final sora = await start(tester, width: 420);
    expect(find.byType(SpeedtestBrowser), findsNothing);
    await tester.tap(find.byKey(const ValueKey('speedtest-service-https://yandex.ru/internet')));
    await tester.pumpAndSettle();
    expect(find.byType(SpeedtestBrowser), findsOneWidget);
    expect(find.byKey(const ValueKey('speedtest-search')), findsNothing);
    expect(find.textContaining('Через VPN:'), findsOneWidget);
    sora.phase = Phase.off;
    sora.notifyListeners();
    await tester.pumpAndSettle();
    expect(find.text('Без VPN'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('speedtest-return')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('speedtest-search')), findsOneWidget);
    await section(tester, 1);
    await tester.ensureVisible(find.byKey(const ValueKey('check-speed')));
    await tester.tap(find.byKey(const ValueKey('check-speed')));
    await tester.pumpAndSettle();
    expect(find.byType(SpeedtestScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('root dialogs and narrow navigation hide the native browser area', (tester) async {
    await start(tester);
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
    await tester.tap(find.byKey(const ValueKey('speedtest-menu')));
    await tester.pumpAndSettle();
    expect(tester.widget<SpeedtestBrowser>(find.byType(SpeedtestBrowser)).visible, isFalse);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(tester.widget<SpeedtestBrowser>(find.byType(SpeedtestBrowser)).visible, isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
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
      for (final (width, height) in [(1440.0, 900.0), (420.0, 800.0)]) {
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
        await section(tester, 8);
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
        sora.dispose();
      }
    }
  }, skip: Platform.environment['SORA_SHOTS'] == null);
}
