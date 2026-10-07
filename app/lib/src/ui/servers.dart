import 'dart:async';

import 'package:fixnum/fixnum.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/strings.dart';
import '../core/link.dart';
import '../design/theme.dart';
import '../generated/sora/core/v1/core_control.pb.dart';
import '../groups.dart';
import '../sora.dart';
import 'kit.dart';
import 'subscription.dart';
import 'subscription_sheet.dart';

/// Every server of every subscription, with the two choices that need none:
/// the fastest one, picked by the core, and no server at all.
class ServersScreen extends StatefulWidget {
  const ServersScreen({super.key});

  @override
  State<ServersScreen> createState() => _ServersScreenState();
}

class _ServersScreenState extends State<ServersScreen> {
  /// Above this many servers a search field helps more than it costs.
  static const _searchFrom = 12;
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
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
    final query = _search.text.trim().toLowerCase();
    return Screen(
      title: s.servers,
      actions: [
        if (sora.probing)
          SizedBox.square(dimension: 36, child: CupertinoActivityIndicator(color: palette.ink))
        else
          RoundButton(icon: CupertinoIcons.arrow_clockwise, label: s.refresh, onTap: sora.probe),
        const SizedBox(width: 4),
        RoundButton(icon: CupertinoIcons.plus, label: s.addSubscription, onTap: () => showSubscriptionSheet(context)),
      ],
      children: [
        if (sora.servers.length > _searchFrom)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: CupertinoSearchTextField(
              controller: _search,
              placeholder: s.search,
              style: Styles.body.copyWith(color: palette.ink),
              placeholderStyle: Styles.body.copyWith(color: palette.ink3),
              backgroundColor: palette.field,
              borderRadius: BorderRadius.circular(12),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
              itemColor: palette.ink3,
            ),
          ),
        if (query.isEmpty)
          Group(
            children: [
              _ServerRow(id: 'auto', name: s.serverAuto),
              _ServerRow(id: 'bypass', name: s.serverBypass),
              if (sora.subscriptions.isEmpty)
                Tile(
                  title: s.addSubscription,
                  onTap: () => showSubscriptionSheet(context),
                  trailing: Icon(CupertinoIcons.plus, size: 18, color: palette.ink),
                ),
            ],
          ),
        for (final subscription in sora.subscriptions) ...[
          if (query.isEmpty) _SubscriptionHeader(state: subscription),
          if (_matching(entriesOf(subscription), query) case final shown when shown.isNotEmpty)
            Group(
              children: [for (final e in shown) _ServerRow(id: e.id, name: e.name, entry: e.isGroup ? e : null)],
            )
          else if (query.isEmpty)
            const SizedBox(height: 20),
        ],
      ],
    );
  }
}

List<Entry> _matching(List<Entry> entries, String query) => query.isEmpty
    ? entries
    : [
        for (final e in entries)
          if (e.name.toLowerCase().contains(query)) e,
      ];

class _ServerRow extends StatelessWidget {
  const _ServerRow({required this.id, required this.name, this.entry});

  final String id;
  final String name;

  /// Set for several servers under one name.
  final Entry? entry;

  @override
  Widget build(BuildContext context) {
    final sora = SoraScope.of(context);
    final palette = Palette.of(context);
    final s = S.of(context);
    final chosen = sora.selected == id;
    // A group shows the latency of the member it would run.
    final measuredId = entry == null ? id : pickMember(entry!, sora.latency).id;
    final measured = sora.latency.containsKey(measuredId);
    final ms = sora.latency[measuredId];
    final group = entry;
    return Tile(
      title: name,
      detail: group == null
          ? null
          : group.ordered
          ? s.groupOrdered(group.members.length)
          : s.groupBest(group.members.length),
      onTap: () => unawaited(sora.select(id)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: Motion.of(context, Motion.medium),
            child: Text(
              !measured ? '' : (ms == null ? '—' : s.milliseconds(ms)),
              key: ValueKey(ms ?? (measured ? -1 : -2)),
              style: Styles.figures(Styles.secondary).copyWith(color: palette.ink),
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
    final facts = <String>[];
    var alarm = false;
    if (info.hasUsage) {
      final used = formatBytes(s, info.uploadBytes + info.downloadBytes, locale);
      facts.add(info.totalBytes == Int64.ZERO ? used : s.usage(used, formatBytes(s, info.totalBytes, locale)));
    }
    if (info.hasExpire()) {
      final expire = info.expire.toDateTime().toLocal();
      if (expire.isBefore(DateTime.now())) {
        facts.add(s.expired);
        alarm = true;
      } else {
        // A date in another year names its year: "until 13 September" of a
        // subscription that runs to 2030 would read as this autumn.
        final format = expire.year == DateTime.now().year ? DateFormat.MMMMd(locale) : DateFormat.yMMMMd(locale);
        facts.add(s.until(format.format(expire)));
      }
    }
    final error = state.hasLastError() && state.lastError.userMessageKey.isNotEmpty;
    if (error) {
      facts
        ..clear()
        ..add(describe(s, CoreFailure(state.lastError.userMessageKey)));
    }
    final factStyle = Styles.caption.copyWith(color: error || alarm ? palette.danger : palette.ink);

    final used = (info.uploadBytes + info.downloadBytes).toDouble();
    final share = info.hasUsage && info.totalBytes > Int64.ZERO
        ? (used / info.totalBytes.toDouble()).clamp(0.0, 1.0)
        : null;
    final announce = info.announce.trim();
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 4, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                    if (facts.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        // Space, not punctuation, keeps the facts apart.
                        child: Wrap(spacing: 14, children: [for (final f in facts) Text(f, style: factStyle)]),
                      ),
                  ],
                ),
              ),
              if (state.updating)
                SizedBox.square(dimension: 36, child: CupertinoActivityIndicator(color: palette.ink))
              else
                MenuAnchor(
                  alignmentOffset: const Offset(-150, 4),
                  menuChildren: [
                    _item(context, s.refresh, () => unawaited(sora.refreshSubscription(state.settings.id))),
                    if (info.webPageUrl.isNotEmpty)
                      _item(context, s.website, () => unawaited(openLink(info.webPageUrl))),
                    if (info.supportUrl.isNotEmpty)
                      _item(context, s.support, () => unawaited(openLink(info.supportUrl))),
                    _item(
                      context,
                      s.subscriptionSettings,
                      () => unawaited(push<void>(context, SubscriptionScreen(id: state.settings.id))),
                    ),
                    _item(context, s.delete, () => unawaited(deleteSubscription(context, state)), danger: true),
                  ],
                  builder: (context, controller, _) => RoundButton(
                    icon: CupertinoIcons.ellipsis,
                    label: state.displayName,
                    onTap: () => controller.isOpen ? controller.close() : controller.open(),
                  ),
                ),
            ],
          ),
          if (share != null && !error)
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 10, 0),
              child: UsageBar(share: share, alarm: share > 0.9),
            ),
          if (announce.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 10, 10, 0),
              child: LinkedText(announce, style: Styles.caption.copyWith(color: palette.ink)),
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
}

/// Asks, then deletes a subscription and its servers.
Future<void> deleteSubscription(BuildContext context, SubscriptionState state) async {
  final sora = SoraScope.read(context);
  final s = S.of(context);
  if (await confirm(context, question: s.deleteSubscription(state.displayName), action: s.delete)) {
    await sora.deleteSubscription(state.settings.id);
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
