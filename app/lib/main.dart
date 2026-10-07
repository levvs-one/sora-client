import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/strings.dart';
import 'src/design/theme.dart';
import 'src/desktop/desktop.dart';
import 'src/settings.dart';
import 'src/sora.dart';
import 'src/ui/home.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  final sora = Sora(await Settings.load());
  unawaited(sora.run());
  final navigator = GlobalKey<NavigatorState>();
  final desktop = Platform.isLinux || Platform.isWindows ? Desktop(sora, navigator) : null;
  await desktop?.start(hidden: args.contains('--hidden'));
  runApp(SoraApp(sora: sora, navigator: navigator, desktop: desktop));
}

class SoraApp extends StatefulWidget {
  const SoraApp({super.key, required this.sora, this.navigator, this.desktop});

  final Sora sora;
  final GlobalKey<NavigatorState>? navigator;
  final Desktop? desktop;

  @override
  State<SoraApp> createState() => _SoraAppState();
}

class _SoraAppState extends State<SoraApp> {
  late final _navigator = widget.navigator ?? GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    final sora = widget.sora;
    final desktop = widget.desktop;
    final app = SoraScope(
      sora: sora,
      child: ListenableBuilder(
        listenable: sora,
        builder: (context, _) => MotionScope(
          enabled: sora.settings.animations,
          child: MaterialApp(
            title: 'Sora',
            debugShowCheckedModeBanner: false,
            theme: buildTheme(Brightness.light),
            darkTheme: buildTheme(Brightness.dark),
            themeMode: switch (sora.settings.theme) {
              'light' => ThemeMode.light,
              'dark' => ThemeMode.dark,
              _ => ThemeMode.system,
            },
            locale: sora.settings.language == 'system' ? null : Locale(sora.settings.language),
            themeAnimationDuration: const Duration(milliseconds: 300),
            localizationsDelegates: const [
              S.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: S.supportedLocales,
            navigatorKey: _navigator,
            // Escape steps back from any screen, as it does on a Mac.
            builder: (context, child) => CallbackShortcuts(
              bindings: {
                const SingleActivator(LogicalKeyboardKey.escape): () => unawaited(_navigator.currentState?.maybePop()),
              },
              child: child!,
            ),
            home: const HomeScreen(),
          ),
        ),
      ),
    );
    return desktop == null ? app : DesktopScope(desktop: desktop, child: app);
  }
}
