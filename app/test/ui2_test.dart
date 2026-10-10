import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sora/main.dart';
import 'package:sora/src/core/link.dart';
import 'package:sora/src/generated/sora/core/v1/core_control.pb.dart';
import 'package:sora/src/notifications.dart';
import 'package:sora/src/settings.dart';
import 'package:sora/src/sora.dart';
import 'package:sora/src/ui/announcement.dart';
import 'package:sora/src/ui/home.dart';
import 'package:sora/src/ui/servers.dart';
import 'package:sora/src/ui/speedtest.dart';
import 'package:sora/src/ui/tour.dart';
import 'package:sora/src/ui/notifications_screen.dart';
import 'package:sora/src/ui/modes.dart';

import 'desktop_shell_test.dart' show section, size;
import 'fixtures/desktop_state.dart';

class _EmptySora extends Sora {
  _EmptySora(super.settings) {
    phase = Phase.off;
  }
  int connects = 0;
  @override
  Future<void> connect({bool retry = false}) async {
    connects++;
  }
}

void main() {
  setUp(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

  Future<Sora> start(WidgetTester tester, {bool empty = false, bool bypass = true, double width = 1440}) async {
    size(tester, width, width == 420 ? 800 : 900);
    addTearDown(tester.view.reset);
    final settings = await Settings.load();
    await settings.completeTour();
    settings
      ..language = 'ru'
      ..animations = false;
    final sora = empty ? _EmptySora(settings) : DesktopState(settings);
    sora.serverlessAvailable = bypass;
    addTearDown(sora.dispose);
    await tester.pumpWidget(SoraApp(sora: sora));
    await tester.pumpAndSettle();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
    return sora;
  }

  Future<AppNotification> message(
    WidgetTester tester,
    Sora sora, {
    String title = 'Событие',
    String action = '',
  }) async {
    final notice = AppNotification(time: DateTime.now(), title: title, body: 'Подробности события', action: action);
    await sora.recordNotification(notice);
    await tester.pumpAndSettle();
    return notice;
  }

  testWidgets('toasts stack at top right, expire in five seconds and keep history', (tester) async {
    final sora = await start(tester);
    final first = await message(tester, sora, title: 'Первое');
    final second = await message(tester, sora, title: 'Второе');
    final rect = tester.getRect(find.byKey(ObjectKey(second)));
    expect(rect.left, greaterThan(1000));
    expect(rect.top, lessThan(100));
    expect(tester.getTopLeft(find.byKey(ObjectKey(first))).dy, greaterThan(rect.top));
    await tester.pump(const Duration(seconds: 4));
    expect(find.byKey(ObjectKey(first)), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.byKey(ObjectKey(first)), findsNothing);
    expect(find.byKey(ObjectKey(second)), findsNothing);
    expect(sora.history.length, 5);
  });

  testWidgets('hover pauses remaining toast lifetime', (tester) async {
    final sora = await start(tester);
    final notice = await message(tester, sora);
    await tester.pump(const Duration(seconds: 2));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.byKey(ObjectKey(notice))));
    await tester.pump(const Duration(seconds: 8));
    expect(find.byKey(ObjectKey(notice)), findsOneWidget);
    await mouse.moveTo(Offset.zero);
    await tester.pump(const Duration(seconds: 2));
    expect(find.byKey(ObjectKey(notice)), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.byKey(ObjectKey(notice)), findsNothing);
    await mouse.removePointer();
  });

  testWidgets('toast uses an 80 pixel frame with equal text insets', (tester) async {
    final sora = await start(tester, empty: true);
    final notice = await message(tester, sora);
    final title = find.byKey(ObjectKey(notice));
    final card = find.ancestor(
      of: title,
      matching: find.byWidgetPredicate((w) => w is Container && w.constraints?.maxWidth == 360),
    );
    final frame = tester.getRect(card);
    final text = tester.getRect(title);
    final body = tester.getRect(find.text('Подробности события'));
    expect(frame.size, const Size(360, 80));
    expect(text.left - frame.left, 16);
    expect(body.top - text.bottom, closeTo(4, .01));
    expect(text.top - frame.top, closeTo(frame.bottom - body.bottom, .01));
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
  });

  testWidgets('notification dates use bold Inter on uniform cards', (tester) async {
    final sora = await start(tester);
    await section(tester, 5);
    expect(find.byIcon(Symbols.done_all_rounded), findsNothing);
    final rows = find.byType(NotificationRow);
    expect(rows, findsNWidgets(3));
    final dates = find.descendant(
      of: rows,
      matching: find.byWidgetPredicate(
        (w) =>
            w is Text &&
            w.style?.fontFamily == 'Inter' &&
            w.style?.fontWeight == FontWeight.w600 &&
            w.style?.fontSize == 12,
      ),
    );
    expect(dates, findsNWidgets(3));
    final styles = tester
        .widgetList<Text>(find.descendant(of: rows, matching: find.byType(Text)))
        .where((w) => sora.history.any((n) => n.title == w.data))
        .map((w) => w.style)
        .toSet();
    expect(styles, hasLength(1));
  });

  testWidgets('first launch has one subscription action and no premature service failure', (tester) async {
    final settings = await Settings.load();
    await settings.completeTour();
    settings
      ..language = 'ru'
      ..animations = false;
    final sora = Sora(settings);
    addTearDown(sora.dispose);
    size(tester, 1440);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(SoraApp(sora: sora));
    await tester.pumpAndSettle();
    expect(find.text('Добавить подписку'), findsOneWidget);
    expect(find.text('Служба Sora не отвечает'), findsNothing);
    expect(find.text('Не подключено'), findsOneWidget);
    sora.failure = CoreFailure.unavailable;
    sora.notifyListeners();
    await tester.pumpAndSettle();
    expect(find.text('Служба Sora не отвечает'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('toast supports right swipe, close and retry action', (tester) async {
    final sora = await start(tester, empty: true) as _EmptySora;
    final notice = await message(tester, sora);
    final toast = find.ancestor(of: find.byKey(ObjectKey(notice)), matching: find.byType(Dismissible));
    await tester.drag(toast, const Offset(-240, 0));
    await tester.pumpAndSettle();
    expect(find.byKey(ObjectKey(notice)), findsOneWidget);
    await tester.drag(toast, const Offset(420, 0));
    await tester.pumpAndSettle();
    expect(find.byKey(ObjectKey(notice)), findsNothing);
    final close = await message(tester, sora);
    final closeToast = find.ancestor(of: find.byKey(ObjectKey(close)), matching: find.byType(Dismissible));
    await tester.tap(find.descendant(of: closeToast, matching: find.byIcon(Symbols.close_rounded)));
    await tester.pumpAndSettle();
    expect(find.byKey(ObjectKey(close)), findsNothing);
    final retry = await message(tester, sora, action: 'connect');
    await tester.tap(find.byKey(ObjectKey(retry)));
    await tester.pumpAndSettle();
    expect(sora.connects, 1);
    expect(find.byKey(ObjectKey(retry)), findsNothing);
    expect(sora.history.length, 3);
  });

  for (final animations in [false, true]) {
    testWidgets('burst of notices is safe with animations: $animations', (tester) async {
      final sora = await start(tester, empty: true);
      await sora.change((s) => s.animations = animations, replan: false);
      await tester.pumpAndSettle();
      for (var i = 0; i < 25; i++) {
        await sora.recordNotification(AppNotification(time: DateTime.now(), title: 'Событие $i', body: 'Связь'));
      }
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Событие 24'), findsOneWidget);
      expect(sora.history.length, 25);
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();
      expect(find.byType(Dismissible), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('home failures use toast without moving controls or inline error', (tester) async {
    final sora = await start(tester);
    final before = tester.getRect(find.byKey(const ValueKey('current-server')));
    sora.failure = const CoreFailure('core.engine.start_failed');
    sora.reportFailure(sora.failure!);
    await tester.pumpAndSettle();
    final home = find.descendant(of: find.byType(HomeScreen), matching: find.byType(Text));
    expect(
      home.evaluate().map((e) => (e.widget as Text).data).whereType<String>(),
      isNot(contains('Движок не запустился')),
    );
    expect(tester.getRect(find.byKey(const ValueKey('current-server'))), before);
    expect(find.byType(Dismissible), findsOneWidget);
    expect(find.text('Подключение'), findsNothing);
    expect(find.text('Текущий сервер'), findsNothing);
    expect(find.text('Системный прокси'), findsNothing);
    expect(find.text('Без сервера'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('connection timer ticks locally and stops when disconnected', (tester) async {
    final sora = await start(tester);
    final elapsed = find.descendant(of: find.byKey(const ValueKey('elapsed')), matching: find.byType(Text));
    final before = tester.widget<Text>(elapsed);
    final serverName = find.descendant(of: find.byType(ServersScreen), matching: find.text('￼Нидерланды, Амстердам'));
    final serverBefore = tester.widget<Text>(serverName);
    var stateChanges = 0;
    sora.addListener(() => stateChanges++);

    // Elapsed time uses the wall clock; pumping advances only the test timer.
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 1100)));
    await tester.pump(const Duration(seconds: 1));
    expect(tester.widget<Text>(elapsed).data, isNot(before.data));
    expect(identical(tester.widget<Text>(serverName), serverBefore), isTrue);
    expect(stateChanges, 0);

    sora.phase = Phase.off;
    sora.notifyListeners();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('elapsed')), findsNothing);
    await tester.pump(const Duration(seconds: 2));
    expect(stateChanges, 1);
    expect(tester.takeException(), isNull);
  });

  test('protocol line preserves all parts and does not guess profile protocol', () {
    expect(
      protocolLine(
        OutboundSpec(protocol: 'xray-profile', displayProtocol: 'vless', transport: 'xhttp', security: 'reality'),
      ),
      'VLESS | XHTTP | REALITY | JSON',
    );
    expect(
      protocolLine(OutboundSpec(protocol: 'shadowsocks', transport: 'tcp', security: 'none')),
      'SHADOWSOCKS | TCP',
    );
    expect(protocolLine(OutboundSpec(protocol: 'xray-profile')), 'XRAY | JSON');
  });

  for (final width in [1440.0, 1000.0, 420.0]) {
    testWidgets('protocol text and latency grid at $width', (tester) async {
      await start(tester, width: width);
      final line = find.text('VLESS | XHTTP | REALITY | JSON');
      await tester.scrollUntilVisible(
        line,
        200,
        scrollable: find.descendant(of: find.byType(HomeScreen), matching: find.byType(Scrollable)).first,
      );
      await tester.ensureVisible(line);
      await tester.pumpAndSettle();
      final widget = tester.widget<Text>(line);
      expect(widget.maxLines, 1);
      expect(widget.overflow, TextOverflow.ellipsis);
      expect(widget.style!.fontSize, 12);
      final search = find.byType(ServersScreen).first;
      final latency = find.descendant(of: search, matching: find.text('42 мс'));
      expect(tester.getTopLeft(latency).dx, greaterThan(tester.getTopLeft(line).dx));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('modes change route, bypass, kill switch and all engine choices', (tester) async {
    final sora = await start(tester);
    await tester.tap(find.byKey(const ValueKey('mode-button')));
    await tester.pumpAndSettle();
    expect(find.text('Режимы'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('mode-proxy')));
    await tester.pumpAndSettle();
    expect(sora.settings.tunnel, 'proxy');
    await tester.tap(find.byKey(const ValueKey('mode-bypass')));
    await tester.pumpAndSettle();
    expect(sora.selected, 'bypass');
    expect(sora.settings.tunnel, 'tun');
    await tester.tap(find.text('Интернет только через VPN'));
    await tester.pumpAndSettle();
    expect(sora.settings.killSwitch, isTrue);
    for (final engine in ['xray', 'mihomo', '']) {
      await tester.tap(find.byKey(ValueKey('engine-$engine')));
      await tester.pumpAndSettle();
      expect(sora.settings.engine, engine);
    }
    await tester.tap(find.byKey(const ValueKey('engine-sing-box')));
    await tester.pumpAndSettle();
    expect(sora.settings.engine, '');
    await tester.tap(find.text('Выбрать sing-box'));
    await tester.pumpAndSettle();
    expect(sora.settings.engine, 'sing-box');
    expect(sora.settings.controlPort, isTrue);
    await tester.tap(find.byKey(const ValueKey('mode-tun')));
    await tester.pumpAndSettle();
    expect(sora.selected, 'auto');
  });

  for (final width in [1440.0, 420.0]) {
    testWidgets('TUN stack menus save each engine selection at $width', (tester) async {
      final sora = await start(tester, width: width);
      await tester.tap(find.byKey(const ValueKey('mode-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('engine-mihomo')));
      await tester.pumpAndSettle();
      final menu = find.byKey(const ValueKey('mihomo-tun-stack'));
      await tester.ensureVisible(menu);
      await tester.tap(find.descendant(of: menu, matching: find.text('Mixed')));
      await tester.pumpAndSettle();
      expect(find.byType(MenuItemButton), findsNWidgets(4));
      await tester.tap(find.text('MIPS'));
      await tester.pumpAndSettle();
      expect(sora.settings.mihomoTunStack, 'mips');
      expect((await Settings.load()).mihomoTunStack, 'mips');
      await tester.ensureVisible(find.byKey(const ValueKey('mode-proxy')));
      await tester.tap(find.byKey(const ValueKey('mode-proxy')));
      await tester.pumpAndSettle();
      expect(menu, findsNothing);
      expect(find.text('Стек TUN'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('mode-tun')));
      await tester.pumpAndSettle();
      expect(menu, findsOneWidget);
      await tester.ensureVisible(find.byKey(const ValueKey('engine-xray')));
      await tester.tap(find.byKey(const ValueKey('engine-xray')));
      await tester.pumpAndSettle();
      expect(menu, findsNothing);
      expect(find.text('gVisor'), findsOneWidget);
      final xrayMenu = find.byKey(const ValueKey('xray-tun-stack'));
      await tester.ensureVisible(xrayMenu);
      await tester.tap(find.descendant(of: xrayMenu, matching: find.text('gVisor')));
      await tester.pumpAndSettle();
      expect(find.byType(MenuItemButton), findsNWidgets(4));
      await tester.tap(find.text('System'));
      await tester.pumpAndSettle();
      expect(sora.settings.xrayTunStack, 'system');
      expect((await Settings.load()).xrayTunStack, 'system');
      await tester.tap(find.byKey(const ValueKey('engine-')));
      await tester.pumpAndSettle();
      expect(find.text('Стек TUN'), findsNothing);
      expect(sora.settings.mihomoTunStack, 'mips');
      expect(sora.settings.xrayTunStack, 'system');
      expect(tester.takeException(), isNull);
    });

    testWidgets('mode details open as a page and return safely at $width', (tester) async {
      await start(tester, width: width);
      await tester.tap(find.byKey(const ValueKey('mode-button')));
      await tester.pumpAndSettle();
      expect(find.text('Все приложения через VPN'), findsNothing);
      expect(find.text('Ядро подбирает совместимый движок'), findsNothing);
      expect(find.textContaining('sing-box не поддерживает XHTTP'), findsNothing);
      final info = find.byKey(const ValueKey('modes-info'));
      await tester.ensureVisible(info);
      await tester.tap(info);
      await tester.pumpAndSettle();
      expect(find.byType(ModesGuideScreen), findsOneWidget);
      expect(find.byKey(const ValueKey('mode-panel')), findsNothing);
      final body = tester.widget<MarkdownBody>(find.byType(MarkdownBody));
      expect(body.data, contains('sing-box-lx'));
      expect(body.data, contains('https://github.com/bol-van/zapret'));
      expect(body.onTapLink, isNotNull);
      expect(tester.takeException(), isNull);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(ModesGuideScreen), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  }

  for (final available in [false, true]) {
    testWidgets('empty connect offers subscription and supported bypass: $available', (tester) async {
      final sora = await start(tester, empty: true, bypass: available) as _EmptySora;
      await tester.tap(find.byKey(const ValueKey('mode-button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('mode-bypass')), available ? findsOneWidget : findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('connect-control')));
      await tester.pumpAndSettle();
      expect(find.descendant(of: find.byType(Dialog), matching: find.text('Добавить подписку')), findsOneWidget);
      expect(
        find.descendant(of: find.byType(Dialog), matching: find.text('Без сервера')),
        available ? findsOneWidget : findsNothing,
      );
      expect(sora.history, isEmpty);
      if (available) {
        await tester.tap(find.text('Без сервера'));
        await tester.pumpAndSettle();
        expect(sora.selected, 'bypass');
        expect(sora.connects, 1);
      } else {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async => call.method == 'Clipboard.getData' ? <String, String>{'text': ''} : null,
        );
        addTearDown(
          () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            null,
          ),
        );
        await tester.tap(find.descendant(of: find.byType(Dialog), matching: find.text('Добавить подписку')));
        await tester.pumpAndSettle();
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();
        expect(find.byType(TextField), findsOneWidget);
      }
    });
  }

  testWidgets('mode guide survives repeated desktop and compact layout changes', (tester) async {
    await start(tester);
    await tester.tap(find.byKey(const ValueKey('mode-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('modes-info')));
    await tester.pumpAndSettle();
    for (final width in [420.0, 1440.0, 1000.0, 420.0, 1440.0]) {
      size(tester, width, 900);
      await tester.pumpAndSettle();
      expect(find.byType(ModesGuideScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('mode information still opens after resizing the open dialog', (tester) async {
    await start(tester);
    await tester.tap(find.byKey(const ValueKey('mode-button')));
    await tester.pumpAndSettle();
    size(tester, 420, 900);
    await tester.pumpAndSettle();
    final info = find.byKey(const ValueKey('modes-info'));
    await tester.ensureVisible(info);
    await tester.tap(info);
    await tester.pumpAndSettle();
    expect(find.byType(ModesGuideScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('description starts fully open and toggles independently of server collapse', (tester) async {
    await start(tester);
    final announcement = find.byType(Announcement).first;
    final body = tester.widget<MarkdownBody>(find.descendant(of: announcement, matching: find.byType(MarkdownBody)));
    expect(body.data, contains('🌍'));
    expect(body.styleSheet!.textAlign, WrapAlignment.center);
    expect(body.styleSheet!.strong!.fontWeight, FontWeight.w600);
    expect(body.styleSheet!.em!.fontStyle, FontStyle.italic);
    expect(body.onTapLink, isNotNull);
    expect(find.descendant(of: announcement, matching: find.byType(RichText)), findsWidgets);
    expect(find.byKey(const ValueKey('announcement-preview')), findsNothing);
    expect(find.text('Ещё'), findsNothing);
    final toggle = find.byKey(const ValueKey('description-subscription-travel'));
    final servers = find.byKey(const ValueKey('collapse-subscription-travel'));
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(find.byType(Announcement), findsNothing);
    expect(find.text('￼Нидерланды, Амстердам'), findsNWidgets(2));
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(find.byType(Announcement), findsOneWidget);
    await tester.tap(servers);
    await tester.pumpAndSettle();
    expect(find.byType(Announcement), findsOneWidget);
    expect(find.text('￼Нидерланды, Амстердам'), findsOneWidget);
    await tester.tap(servers);
    await tester.pumpAndSettle();
    expect(find.text('￼Нидерланды, Амстердам'), findsNWidgets(2));
  });

  testWidgets('tour cutout uses circle and card radii', (tester) async {
    await start(tester);
    await section(tester, 6);
    await tester.scrollUntilVisible(find.text('Показать гайд снова'), 250);
    await tester.tap(find.text('Показать гайд снова'));
    await tester.pumpAndSettle();
    for (final radius in [18.0, 12.0, 88.0, 8.0, 8.0]) {
      final scrim = tester.widget<TourScrim>(find.byType(TourScrim));
      expect(scrim.radius, radius);
      if (radius == 88) expect(scrim.rect.size, const Size(176, 176));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
    }
  });

  testWidgets('native browser yields to toast and returns after timeout', (tester) async {
    final sora = await start(tester);
    await section(tester, 7);
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    final notice = await message(tester, sora);
    expect(tester.widget<SpeedtestBrowser>(find.byType(SpeedtestBrowser)).visible, isFalse);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.byKey(ObjectKey(notice))));
    await tester.pump(const Duration(seconds: 6));
    expect(find.byKey(ObjectKey(notice)), findsOneWidget);
    expect(tester.widget<SpeedtestBrowser>(find.byType(SpeedtestBrowser)).visible, isFalse);
    await mouse.moveTo(Offset.zero);
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    expect(find.byKey(ObjectKey(notice)), findsNothing);
    expect(tester.widget<SpeedtestBrowser>(find.byType(SpeedtestBrowser)).visible, isTrue);
    await mouse.removePointer();
  });
}
