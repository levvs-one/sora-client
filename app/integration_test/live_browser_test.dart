import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sora/main.dart';
import 'package:sora/src/settings.dart';
import 'package:sora/src/sora.dart';
import 'package:webview_all/webview_all.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('real websites survive repeated service changes and browser reopening', (tester) async {
    Future<Set<int>> browserProcesses() async {
      final processes = await Process.run('powershell.exe', [
        '-NoProfile',
        '-Command',
        "ConvertTo-Json -Compress -InputObject @(Get-Process msedgewebview2 -ErrorAction SilentlyContinue | Select-Object Id,WorkingSet64)",
      ]);
      expect(processes.exitCode, 0);
      final values = jsonDecode('${processes.stdout}') as List;
      debugPrint('WebView2 processes: $values');
      return values.map((value) => (value as Map)['Id'] as int).toSet();
    }

    final baseline = Platform.isWindows ? await browserProcesses() : <int>{};
    final settings = await Settings.load();
    await settings.completeTour();
    settings.animations = false;
    final sora = Sora(settings);
    try {
      await tester.pumpWidget(SoraApp(sora: sora));
      for (var reopen = 0; reopen < 3; reopen++) {
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.pump();
        Object? previous;
        for (final url in ['https://www.speedtest.net/', 'https://yandex.ru/internet']) {
          await tester.tap(find.byKey(ValueKey('speedtest-service-$url')));
          var loaded = false;
          final deadline = Stopwatch()..start();
          while (deadline.elapsed < const Duration(seconds: 90)) {
            await tester.pump(const Duration(milliseconds: 250));
            final views = find.byType(WebViewWidget);
            if (views.evaluate().isEmpty) continue;
            final controller = tester.widget<WebViewWidget>(views.first).platform.params.controller;
            try {
              final result = await controller
                  .runJavaScriptReturningResult(
                    "location.href !== 'about:blank' && document.readyState === 'complete' && document.body.innerText.length > 40",
                  )
                  .timeout(const Duration(seconds: 5));
              final current = await controller.currentUrl();
              if ((result == true || result == 'true') && Uri.tryParse(current ?? '')?.host == Uri.parse(url).host) {
                if (previous != null) expect(identical(controller, previous), isTrue);
                previous = controller;
                final title = await controller.getTitle();
                debugPrint('Browser cycle $reopen: $current — $title');
                loaded = true;
                break;
              }
            } catch (error) {
              debugPrint('Waiting for the website: $error');
            }
          }
          expect(loaded, isTrue, reason: '$url must load without a manual refresh');
        }
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.pump(const Duration(seconds: 2));
        expect(find.byType(WebViewWidget), findsNothing);
        if (Platform.isWindows) {
          final deadline = Stopwatch()..start();
          var remaining = await browserProcesses();
          while (remaining.difference(baseline).isNotEmpty && deadline.elapsed < const Duration(seconds: 20)) {
            await tester.pump(const Duration(milliseconds: 250));
            remaining = await browserProcesses();
          }
          expect(remaining.difference(baseline), isEmpty, reason: 'Closing the browser must release its processes.');
        }
      }
    } finally {
      await tester.pumpWidget(const SizedBox());
      sora.dispose();
    }
  }, timeout: const Timeout(Duration(minutes: 12)));
}
