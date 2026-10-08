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
      await Directory(output).create(recursive: true);
    });
    final capture = GlobalKey();
    Future<void> save(String path) async {
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
          await section(tester, index + 1);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: '${names[index]} $theme $width');
          final path = '$output/${names[index]}-${width.toInt()}x${height.toInt()}-$theme.png';
          await save(path);
        }
        await tester.pumpWidget(const SizedBox());
        sora.dispose();
      }
    }
    for (final (width, height) in [(1440.0, 900.0), (420.0, 800.0)]) {
      SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
      final settings = await Settings.load();
      settings
        ..language = 'ru'
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
        await save('$output/tour-$step-${width.toInt()}x${height.toInt()}-light.png');
        await tester.tap(find.text(step == 5 ? 'Готово' : 'Далее'));
        await tester.pumpAndSettle();
      }
      await tester.pumpWidget(const SizedBox());
      sora.dispose();
    }
  }, skip: Platform.environment['SORA_SHOTS'] == null);
}
