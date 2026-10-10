import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:sora/main.dart';
import 'package:sora/src/notifications.dart';
import 'package:sora/src/core/link.dart';
import 'package:sora/src/generated/sora/core/v1/core_control.pb.dart';
import 'package:sora/src/desktop/programs.dart';
import 'package:sora/src/rules.dart';
import 'package:sora/src/settings.dart';
import 'package:sora/src/sora.dart';
import 'package:sora/src/ui/kit.dart';
import 'package:sora/src/ui/about.dart';
import 'package:sora/src/ui/tour.dart';

import 'fixtures/desktop_state.dart';

Future<void> section(WidgetTester tester, int number) async {
  final key = [
    LogicalKeyboardKey.digit1,
    LogicalKeyboardKey.digit2,
    LogicalKeyboardKey.digit3,
    LogicalKeyboardKey.digit4,
    LogicalKeyboardKey.digit5,
    LogicalKeyboardKey.digit6,
    LogicalKeyboardKey.digit7,
    LogicalKeyboardKey.digit8,
  ][const [0, 3, 7, 4, 2, 5, 1, 6][number - 1]];
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(key);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pumpAndSettle();
}

void size(WidgetTester tester, double width, [double height = 900]) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, height);
}

class _SubscriptionsSora extends DesktopState {
  _SubscriptionsSora(super.settings);
  final refreshed = <String>[];
  final second = SubscriptionState(
    settings: SubscriptionSettings(id: 'work', name: 'Work'),
    displayName: 'Work',
    outbounds: [OutboundSpec(id: 'work-nl', displayName: 'Нидерланды, работа', protocol: 'vless')],
  );

  @override
  List<SubscriptionState> get subscriptions => [subscription, second];
  @override
  List<OutboundSpec> get servers => subscriptions.expand((s) => s.outbounds).toList();
  @override
  Future<CoreFailure?> refreshSubscription(String id) async {
    refreshed.add(id);
    return null;
  }
}

void main() {
  setUp(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

  testWidgets('matching subscriptions retain independent refresh buttons during search and updates', (tester) async {
    size(tester, 1440);
    addTearDown(tester.view.reset);
    final settings = await Settings.load();
    await settings.completeTour();
    settings.animations = false;
    final sora = _SubscriptionsSora(settings);
    addTearDown(sora.dispose);
    await tester.pumpWidget(SoraApp(sora: sora));
    await tester.pumpAndSettle();
    final travelCollapse = find.byKey(const ValueKey('collapse-subscription-travel'));
    await tester.tap(travelCollapse);
    await tester.pumpAndSettle();
    expect(find.text('Нидерланды, работа'), findsOneWidget);
    expect(find.text('🇩🇪 Германия, Франкфурт'), findsNothing);
    await tester.tap(travelCollapse);
    await tester.pumpAndSettle();
    expect(find.text('🇩🇪 Германия, Франкфурт'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('server-search')), 'Нидерланды');
    await tester.pumpAndSettle();
    final travel = find.byKey(const ValueKey('refresh-subscription-travel'));
    final work = find.byKey(const ValueKey('refresh-subscription-work'));
    expect(travel, findsOneWidget);
    expect(work, findsOneWidget);
    await tester.tap(travel);
    await tester.pumpAndSettle();
    expect(sora.refreshed, ['travel']);
    sora.subscription.updating = true;
    sora.notifyListeners();
    await tester.pump();
    expect(find.descendant(of: travel, matching: find.byType(RoundButton)), findsNothing);
    await tester.tap(work);
    await tester.pump();
    expect(sora.refreshed, ['travel', 'work']);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('last navigation item opens About with project links and bundled license texts', (tester) async {
    size(tester, 1440);
    addTearDown(tester.view.reset);
    final settings = await Settings.load();
    await settings.completeTour();
    settings
      ..language = 'ru'
      ..animations = false
      ..sidebarExpanded = true;
    final sora = Sora(settings);
    addTearDown(sora.dispose);
    const channel = MethodChannel('plugins.flutter.io/url_launcher');
    final opened = <String>[];
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'launch');
      opened.add((call.arguments as Map)['url'] as String);
      return true;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    await tester.pumpWidget(SoraApp(sora: sora));
    await tester.pumpAndSettle();
    final sidebar = find.byKey(const ValueKey('sidebar'));
    final navigation = find.descendant(of: sidebar, matching: find.byType(Text));
    expect(navigation.evaluate().map((e) => (e.widget as Text).data).whereType<String>().toList(), [
      'Sora',
      'Главная',
      'Скорость',
      'Уведомления',
      'Правила',
      'Логи',
      'Настройки',
      'О приложении',
    ]);
    expect(tester.getSize(find.byKey(const ValueKey('sidebar-toggle'))), const Size(36, 36));
    await section(tester, 8);
    expect(find.byType(AboutScreen), findsOneWidget);
    for (final title in ['Релизы и загрузки', 'Канал в Telegram', 'Исходный код']) {
      await tester.tap(find.text(title));
      await tester.pumpAndSettle();
    }
    expect(opened, [
      'https://github.com/levvs-one/sora-client/releases',
      'https://t.me/sora_client',
      'https://github.com/levvs-one/sora-client',
    ]);
    expect(find.text('GPL-3.0-only'), findsOneWidget);
    final licenses = await tester.runAsync(() => LicenseRegistry.licenses.toList());
    for (final package in [
      'Sora',
      'Inter',
      'Noto Sans Mono',
      'sing-box',
      'mihomo',
      'Xray',
      'zapret',
      'Go',
      'google.golang.org/grpc',
    ]) {
      final entries = licenses!.where((entry) => entry.packages.contains(package)).toList();
      expect(entries, hasLength(1), reason: package);
      expect(entries.single.paragraphs, isNotEmpty);
    }
    await tester.tap(find.text('Лицензии компонентов'));
    await tester.pump();
    expect(find.byType(LicensePage), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  for (final (width, layout, sidebar) in [
    (719.0, 'compact-layout', false),
    (720.0, 'medium-layout', true),
    (999.0, 'medium-layout', true),
    (1000.0, 'wide-layout', true),
  ]) {
    testWidgets('layout at $width pixels', (tester) async {
      size(tester, width);
      addTearDown(tester.view.reset);
      final settings = await Settings.load();
      await settings.completeTour();
      settings.animations = false;
      final sora = DesktopState(settings);
      addTearDown(sora.dispose);
      await tester.pumpWidget(SoraApp(sora: sora));
      await tester.pumpAndSettle();
      expect(find.byKey(ValueKey(layout)), findsOneWidget);
      expect(find.byKey(const ValueKey('sidebar')), sidebar ? findsOneWidget : findsNothing);
      expect(find.byKey(const ValueKey('drawer-button')), sidebar ? findsNothing : findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
  }

  testWidgets('sidebar expands, collapses and persists after reload', (tester) async {
    size(tester, 1440);
    addTearDown(tester.view.reset);
    final settings = await Settings.load();
    await settings.completeTour();
    settings.animations = false;
    final sora = Sora(settings);
    addTearDown(sora.dispose);
    await tester.pumpWidget(SoraApp(sora: sora));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byKey(const ValueKey('sidebar'))).width, 56);
    await tester.tap(find.byKey(const ValueKey('sidebar-toggle')));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byKey(const ValueKey('sidebar'))).width, 224);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byKey(const ValueKey('sidebar'))).width, 56);
    await tester.runAsync(() async => await Future<void>.delayed(Duration.zero));
    final reloaded = await Settings.load();
    expect(reloaded.sidebarExpanded, isFalse);
    await tester.tap(find.byKey(const ValueKey('sidebar-toggle')));
    await tester.pumpAndSettle();
    await tester.runAsync(() async => await Future<void>.delayed(Duration.zero));
    expect((await Settings.load()).sidebarExpanded, isTrue);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('history records notices, survives reload and clears read count', (tester) async {
    size(tester, 1440);
    addTearDown(tester.view.reset);
    final settings = await Settings.load();
    await settings.completeTour();
    settings.language = 'ru';
    settings.animations = false;
    settings.notifications = false;
    final sora = Sora(settings);
    addTearDown(sora.dispose);
    await tester.pumpWidget(SoraApp(sora: sora));
    await tester.pumpAndSettle();
    for (final notice in [
      const ConnectionLost(),
      const ConnectionRestored(),
      const ServerSwitched('Амстердам', backup: true),
      const ServerReturned('Амстердам'),
    ]) {
      await sora.recordNotification(sora.notificationFor(notice));
    }
    await section(tester, 5);
    expect(sora.unreadCount, 4);
    expect(find.text('Соединение прервалось'), findsNWidgets(2));
    final second = Sora(await Settings.load());
    addTearDown(second.dispose);
    expect(second.history.length, 4);
    expect(second.history.first.body, contains('снова отвечает'));
    expect(second.unreadCount, 4);
    await sora.markNotificationsRead();
    await tester.pumpAndSettle();
    expect(sora.unreadCount, 0);
    expect((await Settings.load()).notificationHistory.every((n) => n.read), isTrue);
    for (var i = 0; i < 101; i++) {
      await sora.recordNotification(AppNotification(time: DateTime.now(), title: '$i', body: 'Событие подключения'));
    }
    expect(sora.history.length, 100);
    expect(sora.history.first.title, '100');
    expect((await Settings.load()).notificationHistory.length, 100);
    await sora.clearNotifications();
    await tester.pumpAndSettle();
    expect((await Settings.load()).notificationHistory, isEmpty);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('tour starts on fresh install, resizes, skips and stays done', (tester) async {
    size(tester, 1440);
    addTearDown(tester.view.reset);
    final settings = await Settings.load();
    expect(settings.tourDone, isFalse);
    settings.language = 'ru';
    settings.animations = false;
    final sora = Sora(settings);
    addTearDown(sora.dispose);
    await tester.pumpWidget(SoraApp(sora: sora));
    await tester.pumpAndSettle();
    expect(ShowcaseView.getNamed('sora-tour').isShowcaseRunning, isTrue);
    expect(find.text('Шаг 1 из 5'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(find.text('Шаг 2 из 5'), findsOneWidget);
    size(tester, 420, 800);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(find.text('Шаг 1 из 5'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(ShowcaseView.getNamed('sora-tour').isShowcaseRunning, isFalse);
    expect((await Settings.load()).tourDone, isTrue);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('upgrade does not start tour and settings can replay it', (tester) async {
    await SharedPreferencesAsync().setString('theme', 'dark');
    final settings = await Settings.load();
    expect(settings.tourDone, isTrue);
    expect(settings.theme, 'dark');
    settings.language = 'ru';
    settings.animations = false;
    size(tester, 1440);
    addTearDown(tester.view.reset);
    final sora = Sora(settings);
    addTearDown(sora.dispose);
    await tester.pumpWidget(SoraApp(sora: sora));
    await tester.pumpAndSettle();
    expect(ShowcaseView.getNamed('sora-tour').isShowcaseRunning, isFalse);
    await section(tester, 6);
    await tester.scrollUntilVisible(find.text('Показать гайд снова'), 250);
    await tester.tap(find.text('Показать гайд снова'));
    await tester.pumpAndSettle();
    expect(find.text('Шаг 1 из 5'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('all tour steps remain positioned when crossing breakpoints with motion', (tester) async {
    size(tester, 1440);
    addTearDown(tester.view.reset);
    final settings = await Settings.load();
    settings.language = 'ru';
    final sora = Sora(settings);
    addTearDown(sora.dispose);
    await tester.pumpWidget(SoraApp(sora: sora));
    await tester.pumpAndSettle();
    for (var step = 1; step <= 5; step++) {
      expect(find.text('Шаг $step из 5'), findsOneWidget);
      size(tester, step.isEven ? 420 : 1000, step.isEven ? 800 : 720);
      await tester.pumpAndSettle();
      final scrim = tester.widget<TourScrim>(find.byType(TourScrim));
      expect(scrim.rect.isEmpty, isFalse);
      expect(scrim.duration, const Duration(milliseconds: 220));
      expect(scrim.rect.right, lessThanOrEqualTo(tester.view.physicalSize.width));
      expect(scrim.rect.bottom, lessThanOrEqualTo(tester.view.physicalSize.height));
      final scope = tester.widget<TourScope>(find.byType(TourScope).first);
      final target = tester.getRect(
        find.byWidgetPredicate((w) => w is Showcase && w.showcaseKey == scope.keys[step - 1]),
      );
      expect(scrim.rect.left, closeTo(target.left, 1));
      expect(scrim.rect.top, closeTo(target.top.clamp(0, tester.view.physicalSize.height), 1));
      expect(tester.takeException(), isNull);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
    }
    expect(ShowcaseView.getNamed('sora-tour').isShowcaseRunning, isFalse);
    expect((await Settings.load()).tourDone, isTrue);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('system reduced motion disables tour and sidebar animation', (tester) async {
    size(tester, 1440);
    addTearDown(tester.view.reset);
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final settings = await Settings.load();
    final sora = Sora(settings);
    addTearDown(sora.dispose);
    await tester.pumpWidget(SoraApp(sora: sora));
    await tester.pumpAndSettle();
    expect(tester.widget<TourScrim>(find.byType(TourScrim)).duration, Duration.zero);
    expect(tester.widget<AnimatedContainer>(find.byKey(const ValueKey('sidebar'))).duration, Duration.zero);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('nested server screen and Escape keep the desktop shell', (tester) async {
    size(tester, 1440);
    addTearDown(tester.view.reset);
    final settings = await Settings.load();
    await settings.completeTour();
    settings.animations = false;
    final sora = DesktopState(settings);
    addTearDown(sora.dispose);
    await tester.pumpWidget(SoraApp(sora: sora));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('current-server')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('wide-layout')), findsNothing);
    expect(find.byKey(const ValueKey('sidebar')), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('wide-layout')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('program picker searches real desktop applications and saves the binary', (tester) async {
    size(tester, 1000, 720);
    addTearDown(tester.view.reset);
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const icons = MethodChannel('xdg_icons'), events = MethodChannel('xdg_icons/events');
    messenger.setMockMethodCallHandler(icons, (_) async => null);
    messenger.setMockMethodCallHandler(events, (_) async => null);
    addTearDown(() {
      messenger.setMockMethodCallHandler(icons, null);
      messenger.setMockMethodCallHandler(events, null);
    });
    final programs = await tester.runAsync(installedPrograms);
    expect(programs, isNotEmpty);
    final program = programs!.first;
    expect(program.binary, isNot(contains('/')));
    final processes = await tester.runAsync(runningPrograms);
    expect(processes, isNotEmpty);
    final settings = await Settings.load();
    await settings.completeTour();
    settings.language = 'ru';
    settings.animations = false;
    final sora = Sora(settings);
    addTearDown(sora.dispose);
    await tester.pumpWidget(SoraApp(sora: sora));
    await tester.pumpAndSettle();
    await section(tester, 2);
    await tester.tap(find.text('Новое правило'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Выбрать программу'));
    for (var attempt = 0; attempt < 100; attempt++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump();
      if (find.byType(CircularProgressIndicator).evaluate().isEmpty) break;
    }
    await tester.pumpAndSettle();
    final search = find.descendant(of: find.byType(Dialog), matching: find.byType(TextField));
    await tester.enterText(search, program.binary);
    await tester.pumpAndSettle();
    await tester.tap(find.text(program.name).first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(PrimaryButton, 'Добавить'));
    await tester.pumpAndSettle();
    expect(settings.rules, ['direct process:${program.binary}']);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  }, skip: !Platform.isLinux);

  testWidgets('rule sheet closes safely with motion and respects theme motion preference', (tester) async {
    size(tester, 1000, 720);
    addTearDown(tester.view.reset);
    final settings = await Settings.load();
    await settings.completeTour();
    settings.language = 'ru';
    final sora = Sora(settings);
    addTearDown(sora.dispose);
    await tester.pumpWidget(SoraApp(sora: sora));
    await tester.pumpAndSettle();
    await section(tester, 2);
    await tester.tap(find.text('Новое правило'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '例子.中国');
    await tester.tap(find.widgetWithText(PrimaryButton, 'Добавить'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await sora.change((s) => s.animations = false, replan: false);
    await tester.pumpAndSettle();
    expect(tester.widget<MaterialApp>(find.byType(MaterialApp)).themeAnimationDuration, Duration.zero);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('new rule sheet accepts Unicode and sends Unicode in the plan', (tester) async {
    size(tester, 1440);
    addTearDown(tester.view.reset);
    final settings = await Settings.load();
    await settings.completeTour();
    settings.language = 'ru';
    settings.animations = false;
    final sora = Sora(settings);
    addTearDown(sora.dispose);
    await tester.pumpWidget(SoraApp(sora: sora));
    await tester.pumpAndSettle();
    await section(tester, 2);
    await tester.tap(find.text('Новое правило'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'гоыыыыс.рф');
    await tester.pump();
    await tester.tap(find.widgetWithText(PrimaryButton, 'Добавить'));
    await tester.pumpAndSettle();
    expect(settings.rules, ['direct domain:гоыыыыс.рф']);
    final plan = buildPlan(servers: [], choice: 'bypass', settings: settings);
    expect(plan.routes.single.destination, 'domain:гоыыыыс.рф');
    expect(find.text('гоыыыыс.рф'), findsOneWidget);
    expect(UserRule.destinationOf('例子.中国'), 'domain:例子.中国');
    for (final invalid in ['-bad.ru', 'bad-.ru', 'a..ru', 'bad_host.ru', '${'a' * 64}.ru']) {
      expect(UserRule.destinationOf(invalid), isNull);
    }
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
