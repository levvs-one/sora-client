import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/strings.dart';
import '../core/link.dart';
import '../design/logo.dart';
import '../design/theme.dart';
import '../generated/sora/core/v1/core_control.pbgrpc.dart';
import '../sora.dart';
import 'kit.dart';

/// Stamped by a release build with --dart-define=SORA_VERSION; a build that
/// was not stamped says so rather than claiming a version.
const appVersion = String.fromEnvironment('SORA_VERSION', defaultValue: 'dev');

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  About? _about;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_load()));
  }

  Future<void> _load() async {
    final link = SoraScope.read(context).link;
    if (link == null) return;
    try {
      final answer = await link.stub.getAbout(GetAboutRequest(apiVersion: apiVersion));
      if (mounted && !answer.hasError()) setState(() => _about = answer.about);
    } catch (_) {
      // Without the core the screen still shows the app's own version.
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final palette = Palette.of(context);
    final about = _about;
    return Screen(
      title: s.about,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 32),
          child: Column(
            children: [
              SoraMark(size: 64, color: palette.ink),
              const SizedBox(height: 18),
              Text('Sora', style: Styles.title.copyWith(color: palette.ink)),
              const SizedBox(height: 4),
              Text(s.appVersion(appVersion), style: Styles.secondary.copyWith(color: palette.ink)),
            ],
          ),
        ),
        if (about != null) ...[
          Group(
            children: [
              Tile(title: s.engine, trailing: _value(context, 'Sora ${about.coreVersion}')),
              for (final e in about.engines)
                Tile(
                  title: switch (e.kind) {
                    'xray' => 'Xray',
                    _ => e.kind,
                  },
                  trailing: _value(context, e.installed ? e.version : s.notInstalled),
                ),
            ],
          ),
          Group(
            children: [
              if (about.sourceUrl.startsWith('https://'))
                LinkTile(title: s.sourceCode, onTap: () => unawaited(launchUrl(Uri.parse(about.sourceUrl)))),
              Tile(title: s.license, trailing: _value(context, about.license)),
            ],
          ),
        ],
      ],
    );
  }

  Widget _value(BuildContext context, String text) =>
      Text(text, style: Styles.secondary.copyWith(color: Palette.of(context).ink));
}
