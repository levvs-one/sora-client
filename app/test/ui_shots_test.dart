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
import 'package:sora/src/core/link.dart';
import 'package:sora/src/ui/servers.dart';
import 'package:sora/src/ui/home.dart';

import 'desktop_shell_test.dart' show section, size;
import 'fixtures/desktop_state.dart';

void main() {
  testWidgets('desktop section screenshots', (tester) async {
    final output = '${Platform.environment['HOME']!}/.local/share/sora-dev/shots';
    await tester.runAsync(() async {
      final inter = FontLoader('Inter')
        ..addFont(Future.value(ByteData.sublistView(await File('assets/fonts/InterVariable.ttf').readAsBytes())));
      await inter.load();
      final emoji = FontLoader('Noto Color Emoji')
        ..addFont(
          Future.value(ByteData.sublistView(await File('/usr/share/fonts/noto/NotoColorEmoji.ttf').readAsBytes())),
        );
      await emoji.load();
      final symbols = FontLoader('packages/material_symbols_icons/MaterialSymbolsRounded')
        ..addFont(rootBundle.load('packages/material_symbols_icons/lib/fonts/MaterialSymbolsRounded.ttf'));
      await symbols.load();
      await (FontLoader(
        'packages/cupertino_icons/CupertinoIcons',
      )..addFont(rootBundle.load('packages/cupertino_icons/assets/CupertinoIcons.ttf'))).load();
      await Directory(output).create(recursive: true);
    });
    final capture = GlobalKey();
    Future<void> save(String path) async {
      await tester.runAsync(() async {
        for (final element in find.byType(Image).evaluate()) {
          await precacheImage((element.widget as Image).image, element);
        }
      });
      await tester.pumpAndSettle();
      final boundary = capture.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final rendered = await boundary.toImage(pixelRatio: 1);
        final png = (await rendered.toByteData(format: ui.ImageByteFormat.png))!;
        await File(path).writeAsBytes(png.buffer.asUint8List());
        rendered.dispose();
      });
      debugPrint(path);
    }

    addTearDown(tester.view.reset);
    const names = ['home', 'rules', 'connections', 'logs', 'notifications', 'settings', 'about'];
    for (final theme in ['light', 'dark']) {
      for (final (width, height) in [(1440.0, 900.0), (1000.0, 720.0), (420.0, 800.0)]) {
        SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
        final settings = await Settings.load();
        await settings.completeTour();
        settings
          ..language = 'ru'
          ..theme = theme
          ..animations = false;
        final sora = DesktopState(settings);
        size(tester, width, height);
        await tester.pumpWidget(
          RepaintBoundary(
            key: capture,
            child: SoraApp(sora: sora),
          ),
        );
        await tester.pumpAndSettle();
        for (var index = 0; index < names.length; index++) {
          await section(tester, index == 6 ? 8 : index + 1);
          await tester.pump(const Duration(seconds: 6));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: '${names[index]} $theme $width');
          final path = '$output/${names[index]}-${width.toInt()}x${height.toInt()}-$theme.png';
          await save(path);
        }
        await section(tester, 1);
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('description-subscription-travel')),
          180,
          scrollable: width == 420
              ? find.descendant(of: find.byType(HomeScreen), matching: find.byType(Scrollable)).first
              : find.descendant(of: find.byType(ServersScreen), matching: find.byType(Scrollable)).first,
        );
        await save('$output/announcement-expanded-${width.toInt()}x${height.toInt()}-$theme.png');
        await tester.tap(find.byKey(const ValueKey('description-subscription-travel')));
        await tester.pumpAndSettle();
        if (width == 420) {
          await tester.scrollUntilVisible(
            find.text('VLESS | XHTTP | REALITY | JSON'),
            180,
            scrollable: find.descendant(of: find.byType(HomeScreen), matching: find.byType(Scrollable)).first,
          );
          await save('$output/servers-${width.toInt()}x${height.toInt()}-$theme.png');
          await section(tester, 2);
          await section(tester, 1);
        }
        if (width >= 1000) {
          await tester.tap(find.byKey(const ValueKey('sidebar-toggle')));
          await tester.pumpAndSettle();
          await save('$output/sidebar-expanded-${width.toInt()}x${height.toInt()}-$theme.png');
          await tester.tap(find.byKey(const ValueKey('sidebar-toggle')));
          await tester.pumpAndSettle();
        } else if (width == 420) {
          await tester.tap(find.byKey(const ValueKey('drawer-button')));
          await tester.pumpAndSettle();
          await save('$output/sidebar-expanded-${width.toInt()}x${height.toInt()}-$theme.png');
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          await tester.pumpAndSettle();
        }
        await tester.tap(find.byKey(const ValueKey('mode-button')));
        await tester.pumpAndSettle();
        await save('$output/modes-${width.toInt()}x${height.toInt()}-$theme.png');
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        for (final notice in [
          const ConnectionLost(),
          const ConnectionFailed(CoreFailure('core.engine.start_failed')),
        ]) {
          await sora.recordNotification(sora.notificationFor(notice));
        }
        await tester.pumpAndSettle();
        await save('$output/toast-${width.toInt()}x${height.toInt()}-$theme.png');
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
        sora.dispose();
      }
    }
    for (final theme in ['light', 'dark']) {
      for (final (width, height) in [(1440.0, 900.0), (1000.0, 720.0), (420.0, 800.0)]) {
        SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
        final settings = await Settings.load();
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
        for (var step = 1; step <= 5; step++) {
          expect(find.text('Шаг $step из 5'), findsOneWidget);
          expect(tester.takeException(), isNull);
          await save('$output/tour-$step-${width.toInt()}x${height.toInt()}-$theme.png');
          await tester.tap(find.text(step == 5 ? 'Готово' : 'Далее'));
          await tester.pumpAndSettle();
        }
        sora.phase = Phase.off;
        sora.serverlessAvailable = true;
        sora.notifyListeners();
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('connect-control')));
        await tester.pumpAndSettle();
        expect(find.byType(Dialog), findsOneWidget);
        await save('$output/empty-connect-${width.toInt()}x${height.toInt()}-$theme.png');
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
        sora.dispose();
      }
    }
  }, skip: Platform.environment['SORA_SHOTS'] == null);
}
