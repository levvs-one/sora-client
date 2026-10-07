import 'dart:async';

import 'package:fixnum/fixnum.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/strings.dart';
import '../core/link.dart';
import '../design/theme.dart';
import '../generated/sora/core/v1/core_control.pb.dart';
import '../sora.dart';
import 'kit.dart';
import 'subscription_sheet.dart';

/// Every server of every subscription, with the two choices that need none:
/// the fastest one, picked by the core, and no server at all.
class ServersScreen extends StatefulWidget {
  const ServersScreen({super.key});

  @override
  State<ServersScreen> createState() => _ServersScreenState();
}

class _ServersScreenState extends State<ServersScreen> {
  @override
  void initState() {
    super.initState();
    // Latency is what people choose by, so it is measured on arrival.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(SoraScope.read(context).probe());
    });
  }

  @override
  Widget build(BuildContext context) {
    final sora = SoraScope.of(context);
    final s = S.of(context);
    final palette = Palette.of(context);
    return Screen(
      title: s.servers,
      actions: [
        if (sora.probing)
          SizedBox.square(dimension: 36, child: CupertinoActivityIndicator(color: palette.ink2))
        else
          RoundButton(icon: CupertinoIcons.arrow_clockwise, label: s.refresh, onTap: sora.probe),
        const SizedBox(width: 4),
        RoundButton(icon: CupertinoIcons.plus, label: s.addSubscription, onTap: () => showSubscriptionSheet(context)),
      ],
      children: [
        Group(
          children: [
            _ServerRow(id: 'auto', name: s.serverAuto),
            _ServerRow(id: 'bypass', name: s.serverBypass),
          ],
        ),
        for (final subscription in sora.subscriptions) ...[
          _SubscriptionHeader(state: subscription),
          if (subscription.outbounds.isNotEmpty)
            Group(
              children: [for (final o in subscription.outbounds) _ServerRow(id: o.id, name: o.displayName)],
            )
          else
            const SizedBox(height: 20),
        ],
      ],
    );
  }
}

class _ServerRow extends StatelessWidget {
  const _ServerRow({required this.id, required this.name});

  final String id;
  final String name;

  @override
  Widget build(BuildContext context) {
    final sora = SoraScope.of(context);
    final palette = Palette.of(context);
    final s = S.of(context);
    final chosen = sora.selected == id;
    final measured = sora.latency.containsKey(id);
    final ms = sora.latency[id];
    return Tile(
      title: name,
      onTap: () => unawaited(sora.select(id)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: Motion.of(context, Motion.medium),
            child: Text(
              !measured ? '' : (ms == null ? '—' : s.milliseconds(ms)),
              key: ValueKey(ms ?? (measured ? -1 : -2)),
              style: Styles.figures(Styles.secondary).copyWith(color: palette.ink2),
            ),
          ),
          const SizedBox(width: 12),
          AnimatedScale(
            scale: chosen ? 1 : 0.4,
            duration: Motion.of(context, Motion.medium),
            curve: Motion.curve,
            child: AnimatedOpacity(
              opacity: chosen ? 1 : 0,
              duration: Motion.of(context, Motion.fast),
              child: Icon(CupertinoIcons.checkmark_alt, size: 20, color: palette.ink),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubscriptionHeader extends StatelessWidget {
  const _SubscriptionHeader({required this.state});

  final SubscriptionState state;

  @override
  Widget build(BuildContext context) {
    final sora = SoraScope.read(context);
    final palette = Palette.of(context);
    final s = S.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final info = state.info;
    final parts = <String>[];
    var alarm = false;
    if (info.hasUsage) {
      final used = formatBytes(s, info.uploadBytes + info.downloadBytes, locale);
      parts.add(info.totalBytes == Int64.ZERO ? used : s.usage(used, formatBytes(s, info.totalBytes, locale)));
    }
    if (info.hasExpire()) {
      final expire = info.expire.toDateTime().toLocal();
      if (expire.isBefore(DateTime.now())) {
        parts.add(s.expired);
        alarm = true;
      } else {
        parts.add(s.until(DateFormat.MMMMd(locale).format(expire)));
      }
    }
    final error = state.hasLastError() && state.lastError.userMessageKey.isNotEmpty;
    final detail = error ? describe(s, CoreFailure(state.lastError.userMessageKey)) : parts.join(' · ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 4, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Styles.bodyStrong.copyWith(color: palette.ink),
                ),
                if (detail.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      detail,
                      style: Styles.caption.copyWith(color: error || alarm ? palette.danger : palette.ink2),
                    ),
                  ),
              ],
            ),
          ),
          if (state.updating)
            SizedBox.square(dimension: 36, child: CupertinoActivityIndicator(color: palette.ink2))
          else
            MenuAnchor(
              alignmentOffset: const Offset(-150, 4),
              menuChildren: [
                _item(context, s.refresh, () => unawaited(sora.refreshSubscription(state.settings.id))),
                _item(
                  context,
                  s.rename,
                  () => unawaited(
                    showFieldSheet(
                      context,
                      title: s.rename,
                      hint: s.name,
                      action: s.save,
                      initial: state.settings.name.isEmpty ? state.displayName : state.settings.name,
                      submit: (name) => sora.renameSubscription(state, name),
                    ),
                  ),
                ),
                _item(context, s.delete, () => unawaited(_confirmDelete(context)), danger: true),
              ],
              builder: (context, controller, _) => RoundButton(
                icon: CupertinoIcons.ellipsis,
                label: state.displayName,
                onTap: () => controller.isOpen ? controller.close() : controller.open(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _item(BuildContext context, String label, VoidCallback onTap, {bool danger = false}) {
    final palette = Palette.of(context);
    return MenuItemButton(
      onPressed: onTap,
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(190, 40)),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(9))),
        overlayColor: WidgetStatePropertyAll(palette.hover),
        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 12)),
      ),
      child: Text(label, style: Styles.secondary.copyWith(color: danger ? palette.danger : palette.ink)),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final sora = SoraScope.read(context);
    final s = S.of(context);
    final palette = Palette.of(context);
    final yes = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: palette.scrim,
      transitionDuration: Motion.enabled(context) ? Motion.medium : Duration.zero,
      transitionBuilder: (context, animation, _, child) {
        final curved = CurvedAnimation(parent: animation, curve: Motion.curve);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(scale: Tween(begin: 0.94, end: 1.0).animate(curved), child: child),
        );
      },
      pageBuilder: (context, _, _) => Center(
        child: Material(
          color: palette.raised,
          elevation: 24,
          shadowColor: palette.shadow,
          borderRadius: BorderRadius.circular(26),
          child: SizedBox(
            width: 320,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    s.deleteSubscription(state.displayName),
                    textAlign: TextAlign.center,
                    style: Styles.bodyStrong.copyWith(color: palette.ink),
                  ),
                  const SizedBox(height: 20),
                  Pressable(
                    onTap: () => Navigator.of(context).pop(true),
                    radius: 26,
                    wash: false,
                    child: Container(
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: palette.danger, borderRadius: BorderRadius.circular(26)),
                      child: Text(s.delete, style: Styles.bodyStrong.copyWith(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Pressable(
                    onTap: () => Navigator.of(context).pop(false),
                    radius: 22,
                    child: SizedBox(
                      height: 44,
                      child: Center(
                        child: Text(s.cancel, style: Styles.body.copyWith(color: palette.ink2)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (yes ?? false) await sora.deleteSubscription(state.settings.id);
  }
}

/// A byte count as people read it: one decimal where it matters, a unit.
String formatBytes(S s, Int64 bytes, String locale) {
  final (value, unit) = Sora.scaleBytes(bytes);
  final number = NumberFormat(value >= 100 || unit == 0 ? '0' : '0.#', locale).format(value);
  return switch (unit) {
    0 => s.bytesB(number),
    1 => s.bytesKB(number),
    2 => s.bytesMB(number),
    3 => s.bytesGB(number),
    _ => s.bytesTB(number),
  };
}
