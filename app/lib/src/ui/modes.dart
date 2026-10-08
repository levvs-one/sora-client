import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../l10n/strings.dart';
import '../design/theme.dart';
import '../sora.dart';
import 'kit.dart';
import 'subscription_sheet.dart';

Future<void> showModes(BuildContext context) => showDialog<void>(context: context, builder: (_) => const _Modes());

Future<void> connectFromHome(BuildContext context) async {
  final sora = SoraScope.read(context);
  if (sora.phase == Phase.off && sora.servers.isEmpty && sora.selected != 'bypass') {
    final choice = await showDialog<String>(
      context: context,
      builder: (context) {
        final s = S.of(context), palette = Palette.of(context);
        return Dialog(
          backgroundColor: palette.raised,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PrimaryButton(label: s.addSubscription, onTap: () => Navigator.pop(context, 'subscription')),
                  if (sora.serverlessAvailable) ...[
                    const SizedBox(height: 8),
                    TextButton(onPressed: () => Navigator.pop(context, 'bypass'), child: Text(s.serverBypass)),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
    if (!context.mounted) return;
    if (choice == 'subscription') await showSubscriptionSheet(context);
    if (choice == 'bypass') {
      await sora.change(
        (x) => x
          ..server = 'bypass'
          ..tunnel = 'tun',
      );
      await sora.connect();
    }
    return;
  }
  await sora.toggle();
}

class ModeButton extends StatelessWidget {
  const ModeButton({super.key});
  @override
  Widget build(BuildContext context) {
    final sora = SoraScope.of(context), s = S.of(context), palette = Palette.of(context);
    final label = sora.selected == 'bypass'
        ? s.serverBypass
        : sora.settings.tunnel == 'tun'
        ? 'TUN'
        : s.proxyShort;
    return OutlinedButton(
      key: const ValueKey('mode-button'),
      onPressed: () => showModes(context),
      style: OutlinedButton.styleFrom(
        foregroundColor: palette.ink,
        side: BorderSide(color: palette.field),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(0, 36),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: Styles.secondary.copyWith(color: palette.ink)),
          const SizedBox(width: 8),
          Icon(Symbols.expand_more_rounded, size: 16, color: palette.ink3),
        ],
      ),
    );
  }
}

class _Modes extends StatelessWidget {
  const _Modes();
  @override
  Widget build(BuildContext context) {
    final sora = SoraScope.of(context), s = S.of(context), palette = Palette.of(context);
    final settings = sora.settings;
    final current = sora.selected == 'bypass' ? 'bypass' : settings.tunnel;
    Widget choice(String key, String title, String detail, bool selected, VoidCallback choose) => Tile(
      key: ValueKey(key),
      title: title,
      detail: detail,
      detailColor: palette.ink3,
      onTap: choose,
      trailing: SizedBox(width: 20, child: selected ? Icon(Symbols.check_rounded, size: 18, color: palette.ink) : null),
    );
    Future<void> mode(String value) => sora.change((x) {
      if (value == 'bypass') {
        x.server = 'bypass';
        x.tunnel = 'tun';
      } else {
        if (x.server == 'bypass') x.server = 'auto';
        x.tunnel = value;
      }
    });
    final routes = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (value, title, detail) in [
          ('tun', s.tunMode, s.tunExplanation),
          ('proxy', s.tunnelProxy, s.proxyExplanation),
          if (sora.serverlessAvailable) ('bypass', s.serverBypass, s.bypassExplanation),
        ])
          choice('mode-$value', title, detail, current == value, () => unawaited(mode(value))),
        const SizedBox(height: 12),
        SwitchTile(title: s.killSwitch, value: settings.killSwitch, onChanged: (v) => unawaited(sora.setKillSwitch(v))),
      ],
    );
    final engines = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Text(s.engine, style: Styles.bodyStrong.copyWith(color: palette.ink)),
        ),
        for (final (value, title, detail) in [
          ('', s.engineAuto, s.autoEngineExplanation),
          ('sing-box', 'sing-box', s.singboxExplanation),
          ('xray', 'Xray', s.xrayExplanation),
          ('mihomo', 'mihomo', s.mihomoExplanation),
        ])
          choice('engine-$value', title, detail, settings.engine == value, () async {
            if (value == 'sing-box' && !settings.controlPort) {
              if (!await confirm(
                context,
                question: s.controlPortQuestion('sing-box'),
                action: s.chooseEngine('sing-box'),
              )) {
                return;
              }
            }
            await sora.change(
              (x) => x
                ..engine = value
                ..controlPort = value == 'sing-box',
            );
          }),
      ],
    );
    return Dialog(
      key: const ValueKey('mode-panel'),
      backgroundColor: palette.raised,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 720, maxHeight: MediaQuery.sizeOf(context).height - 64),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(s.modes, style: Styles.heading.copyWith(color: palette.ink)),
                  ),
                  RoundButton(icon: Symbols.close_rounded, label: s.close, onTap: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (_, constraints) => constraints.maxWidth >= 600
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: routes),
                          const SizedBox(width: 24),
                          Expanded(child: engines),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [routes, const SizedBox(height: 16), engines],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
