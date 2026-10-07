import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/strings.dart';
import '../sora.dart';
import 'about.dart';
import 'kit.dart';
import 'logs.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sora = SoraScope.of(context);
    final settings = sora.settings;
    final s = S.of(context);
    return Screen(
      title: s.settings,
      children: [
        Group(
          children: [
            ChoiceTile<String>(
              title: s.routes,
              value: settings.preset,
              choices: {'global': s.presetGlobal, 'ru': s.presetRu, 'ir': s.presetIr, 'cn': s.presetCn},
              onChanged: (v) => unawaited(sora.setPreset(v)),
            ),
            SwitchTile(title: s.blockAds, value: settings.blockAds, onChanged: (v) => unawaited(sora.setBlockAds(v))),
            SwitchTile(
              title: s.killSwitch,
              value: settings.killSwitch,
              onChanged: (v) => unawaited(sora.setKillSwitch(v)),
            ),
          ],
        ),
        Group(
          children: [
            ChoiceTile<String>(
              title: s.engine,
              value: settings.engine,
              choices: {'': s.engineAuto, 'sing-box': 'sing-box', 'xray': 'Xray', 'mihomo': 'mihomo'},
              onChanged: (v) => unawaited(sora.setEngine(v)),
            ),
            SwitchTile(title: s.animations, value: settings.animations, onChanged: sora.setAnimations),
          ],
        ),
        Group(
          children: [
            LinkTile(title: s.logs, onTap: () => push<void>(context, const LogsScreen())),
            LinkTile(title: s.about, onTap: () => push<void>(context, const AboutScreen())),
          ],
        ),
      ],
    );
  }
}
