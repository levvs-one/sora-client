import 'dart:async';

import 'package:fixnum/fixnum.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../l10n/strings.dart';
import '../design/theme.dart';
import '../generated/sora/core/v1/core_control.pb.dart';
import '../groups.dart';
import '../sora.dart';
import 'kit.dart';
import 'subscription.dart';
import 'subscription_sheet.dart';
import 'tour.dart';
import 'announcement.dart';

/// Keeps subscription order while building only visible server rows.
class ServersScreen extends StatefulWidget {
  const ServersScreen({super.key, this.embedded = false, this.scrollable = true});

  final bool embedded;
  final bool scrollable;

  @override
  State<ServersScreen> createState() => _ServersScreenState();
}

class _ServersScreenState extends State<ServersScreen> {
  final _search = TextEditingController();
  bool _probed = false;
  final _collapsed = <String>{};

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final sora = SoraScope.of(context);
    if (!_probed && sora.canProbe && sora.phase == Phase.off && sora.servers.isNotEmpty) {
      // The desktop pane opens before the subscription stream arrives.
      _probed = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(sora.probe());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sora = SoraScope.of(context);
    final s = S.of(context);
    final palette = Palette.of(context);
    if (widget.embedded && sora.subscriptions.isEmpty) {
      return widget.scrollable ? const SizedBox.expand() : const SliverToBoxAdapter();
    }
    final query = _search.text.trim().toLowerCase();
    final actions = [
      if (sora.probing)
        SizedBox.square(dimension: 36, child: CupertinoActivityIndicator(color: palette.ink))
      else
        RoundButton(
          icon: Symbols.speed_rounded,
          label: s.probeServers,
          onTap: sora.canProbe ? () => unawaited(sora.probe()) : null,
        ),
      _tourTarget(
        0,
        RoundButton(icon: Symbols.add_rounded, label: s.addSubscription, onTap: () => showSubscriptionSheet(context)),
      ),
    ];
    final search = Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        key: const ValueKey('server-search'),
        controller: _search,
        style: Styles.secondary.copyWith(color: palette.ink),
        decoration: InputDecoration(
          hintText: s.search,
          hintStyle: Styles.secondary.copyWith(color: palette.ink3),
          prefixIcon: Icon(Symbols.search_rounded, size: 18, color: palette.ink3),
          isDense: true,
          filled: true,
          fillColor: palette.field,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        ),
      ),
    );
    final automatic = Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _tourTarget(
        1,
        DecoratedBox(
          decoration: BoxDecoration(color: palette.surface, borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: sora.servers.isNotEmpty
                ? _ServerRow(id: 'auto', name: s.serverAuto)
                : Tile(
                    title: s.addSubscription,
                    onTap: () => showSubscriptionSheet(context),
                    trailing: Icon(Symbols.add_rounded, size: 18, color: palette.ink),
                  ),
          ),
        ),
      ),
    );
    final toolbar = Row(
      children: [
        if (!widget.embedded)
          RoundButton(
            icon: Symbols.chevron_left_rounded,
            label: MaterialLocalizations.of(context).backButtonTooltip,
            onTap: () => Navigator.of(context).maybePop(),
          ),
        const Spacer(),
        ...actions,
      ],
    );
    final slivers = <Widget>[
      SliverToBoxAdapter(child: Column(children: [toolbar, const SizedBox(height: 8), search])),
      SliverToBoxAdapter(child: automatic),
    ];
    final separator = palette.ink3.withValues(alpha: 0.28);
    for (final subscription in sora.subscriptions) {
      final entries = _matching(entriesOf(subscription), query);
      if (query.isNotEmpty && entries.isEmpty) continue;
      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.only(bottom: 16),
          sliver: DecoratedSliver(
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: separator),
            ),
            sliver: SliverMainAxisGroup(
              slivers: [
                SliverToBoxAdapter(
                  child: _SubscriptionHeader(
                    key: ValueKey(subscription.settings.id),
                    state: subscription,
                    expanded: !_collapsed.contains(subscription.settings.id),
                    onToggle: () => setState(() {
                      final id = subscription.settings.id;
                      if (!_collapsed.remove(id)) _collapsed.add(id);
                    }),
                  ),
                ),
                if (!_collapsed.contains(subscription.settings.id))
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
                    sliver: SliverList.separated(
                      itemCount: entries.length,
                      itemBuilder: (_, index) {
                        final entry = entries[index];
                        return _ServerRow(id: entry.id, name: entry.name, entry: entry);
                      },
                      separatorBuilder: (_, _) =>
                          Divider(height: 1, thickness: 1, indent: 8, endIndent: 8, color: separator),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }
    if (!widget.scrollable) {
      return SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        sliver: SliverMainAxisGroup(slivers: slivers),
      );
    }
    final list = CustomScrollView(
      key: const PageStorageKey('servers-list'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          sliver: SliverMainAxisGroup(slivers: slivers),
        ),
      ],
    );
    return widget.embedded ? list : Scaffold(backgroundColor: palette.background, body: list);
  }

  Widget _tourTarget(int step, Widget child) =>
      widget.embedded ? TourTarget(step: step, radius: step == 0 ? 18 : 12, child: child) : child;
}

List<Entry> _matching(List<Entry> entries, String query) => query.isEmpty
    ? entries
    : [
        for (final e in entries)
          if (e.name.toLowerCase().contains(query)) e,
      ];

final _flagPrefix = RegExp(r'^([\u{1F1E6}-\u{1F1FF}]{2})\s*', unicode: true);

InlineSpan serverNameSpan(String name) {
  final flag = _flagPrefix.firstMatch(name);
  if (flag == null) return TextSpan(text: name);
  final code = String.fromCharCodes(flag.group(1)!.runes.map((r) => r - 0x1F1E6 + 97));
  return TextSpan(
    children: [
      WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Image.asset(
              'assets/flags/$code.png',
              width: 22,
              height: 14,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => SizedBox(width: 22, child: Text(code.toUpperCase(), style: Styles.caption)),
            ),
          ),
        ),
      ),
      TextSpan(text: name.substring(flag.end)),
    ],
  );
}

class _ServerRow extends StatelessWidget {
  const _ServerRow({required this.id, required this.name, this.entry});

  final String id;
  final String name;

  /// Group data when multiple servers share a name.
  final Entry? entry;

  @override
  Widget build(BuildContext context) {
    final sora = SoraScope.of(context);
    final palette = Palette.of(context);
    final s = S.of(context);
    final chosen = sora.selected == id;
    // Use the prospective active member's latency for a group row.
    final measuredId = entry == null ? id : pickMember(entry!, sora.latency).id;
    final measured = sora.latency.containsKey(measuredId);
    final ms = sora.latency[measuredId];
    final group = entry;
    final detail = group?.members.map(protocolLine).toSet().join(' | ');
    return Semantics(
      selected: chosen,
      button: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: chosen ? palette.field : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Pressable(
          onTap: () => unawaited(sora.select(id)),
          radius: 8,
          give: 1,
          child: SizedBox(
            height: entry == null ? 40 : 52,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          serverNameSpan(name),
                          semanticsLabel: name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Styles.row.copyWith(color: palette.ink),
                        ),
                        if (detail != null && detail.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Text(
                              detail,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Styles.caption.copyWith(color: palette.ink3),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 76,
                    child: Text(
                      !measured
                          ? ''
                          : ms == null
                          ? s.noAnswer
                          : s.milliseconds(ms),
                      textAlign: TextAlign.right,
                      style: Styles.figures(Styles.caption).copyWith(color: palette.ink2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SubscriptionHeader extends StatefulWidget {
  const _SubscriptionHeader({super.key, required this.state, required this.expanded, required this.onToggle});

  final SubscriptionState state;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  State<_SubscriptionHeader> createState() => _SubscriptionHeaderState();
}

class _SubscriptionHeaderState extends State<_SubscriptionHeader> {
  SubscriptionState get state => widget.state;
  bool _descriptionVisible = true;

  @override
  Widget build(BuildContext context) {
    final sora = SoraScope.of(context);
    final palette = Palette.of(context);
    final s = S.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final info = state.info;
    final facts = <String>[];
    if (info.hasUsage) {
      final used = formatBytes(s, info.uploadBytes + info.downloadBytes, locale);
      facts.add(info.totalBytes == Int64.ZERO ? used : s.usage(used, formatBytes(s, info.totalBytes, locale)));
    }
    if (info.hasExpire()) {
      final expire = info.expire.toDateTime().toLocal();
      if (expire.isBefore(DateTime.now())) {
        facts.add(s.expired);
      } else {
        // Include the year for expiry dates outside the current year to avoid
        // ambiguous dates.
        final format = expire.year == DateTime.now().year ? DateFormat.MMMMd(locale) : DateFormat.yMMMMd(locale);
        facts.add(s.until(format.format(expire)));
      }
    }
    final factStyle = Styles.caption.copyWith(color: palette.ink3);

    final used = (info.uploadBytes + info.downloadBytes).toDouble();
    final share = info.hasUsage && info.totalBytes > Int64.ZERO
        ? (used / info.totalBytes.toDouble()).clamp(0.0, 1.0)
        : null;
    final announce = info.announce.trim();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Semantics(
                expanded: widget.expanded,
                child: RoundButton(
                  key: ValueKey('collapse-subscription-${state.settings.id}'),
                  icon: widget.expanded ? Symbols.keyboard_arrow_down_rounded : Symbols.keyboard_arrow_right_rounded,
                  label: widget.expanded ? s.collapseServers : s.expandServers,
                  onTap: widget.onToggle,
                ),
              ),
              const SizedBox(width: 4),
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
                        child: Wrap(spacing: 14, children: [for (final f in facts) Text(f, style: factStyle)]),
                      ),
                  ],
                ),
              ),
              if (sora.probing && (sora.probingSubscription == null || sora.probingSubscription == state.settings.id))
                SizedBox.square(
                  key: ValueKey('probe-subscription-${state.settings.id}'),
                  dimension: 36,
                  child: CupertinoActivityIndicator(color: palette.ink),
                )
              else
                Tooltip(
                  message: '${s.probeServers}: ${state.displayName}',
                  child: RoundButton(
                    key: ValueKey('probe-subscription-${state.settings.id}'),
                    icon: Symbols.speed_rounded,
                    label: '${s.probeServers}: ${state.displayName}',
                    onTap: !sora.canProbe || state.outbounds.isEmpty
                        ? null
                        : () => unawaited(sora.probe(subscriptionId: state.settings.id)),
                  ),
                ),
              if (state.updating)
                SizedBox.square(
                  key: ValueKey('refresh-subscription-${state.settings.id}'),
                  dimension: 36,
                  child: CupertinoActivityIndicator(color: palette.ink),
                )
              else
                Tooltip(
                  message: '${s.refresh}: ${state.displayName}',
                  child: RoundButton(
                    key: ValueKey('refresh-subscription-${state.settings.id}'),
                    icon: Symbols.refresh_rounded,
                    label: '${s.refresh}: ${state.displayName}',
                    onTap: () => unawaited(sora.refreshSubscription(state.settings.id)),
                  ),
                ),
              MenuAnchor(
                alignmentOffset: const Offset(-150, 4),
                menuChildren: [
                  _item(context, s.website, () => unawaited(sora.openSubscriptionPage(state.settings.id))),
                  if (info.webPageUrl.isNotEmpty)
                    _item(context, s.providerWebsite, () => unawaited(openLink(context, info.webPageUrl))),
                  if (info.supportUrl.isNotEmpty)
                    _item(context, s.support, () => unawaited(openLink(context, info.supportUrl))),
                  _item(
                    context,
                    s.subscriptionSettings,
                    () => unawaited(push<void>(context, SubscriptionScreen(id: state.settings.id))),
                  ),
                  _item(context, s.delete, () => unawaited(deleteSubscription(context, state)), danger: true),
                ],
                builder: (context, controller, _) => RoundButton(
                  icon: Symbols.more_horiz_rounded,
                  label: state.displayName,
                  onTap: () => controller.isOpen ? controller.close() : controller.open(),
                ),
              ),
            ],
          ),
          if (share != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 10, 0),
              child: UsageBar(share: share),
            ),
          if (announce.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8, top: 4),
              child: Column(
                children: [
                  Center(
                    child: Semantics(
                      expanded: _descriptionVisible,
                      child: RoundButton(
                        key: ValueKey('description-subscription-${state.settings.id}'),
                        icon: _descriptionVisible
                            ? Symbols.keyboard_arrow_up_rounded
                            : Symbols.keyboard_arrow_down_rounded,
                        label: _descriptionVisible ? s.hideDescription : s.showDescription,
                        onTap: () => setState(() => _descriptionVisible = !_descriptionVisible),
                      ),
                    ),
                  ),
                  if (_descriptionVisible)
                    Padding(padding: const EdgeInsets.only(top: 4), child: Announcement(announce)),
                ],
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
}

/// Confirms deletion, then removes the subscription and its servers.
Future<void> deleteSubscription(BuildContext context, SubscriptionState state) async {
  final sora = SoraScope.read(context);
  final s = S.of(context);
  if (await confirm(context, question: s.deleteSubscription(state.displayName), action: s.delete)) {
    await sora.deleteSubscription(state.settings.id);
  }
}

/// Formats a localized byte count with a unit and up to one decimal place.
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

/// Returns a warning for expired subscriptions, expiry within three days or
/// less than 10% traffic remaining. Returns null otherwise.
String? subscriptionWarning(S s, SubscriptionState sub, String locale) {
  const soon = Duration(days: 3);
  const little = 0.1;
  final info = sub.info;
  if (info.hasExpire()) {
    final left = info.expire.toDateTime().difference(DateTime.now());
    if (left.isNegative) return '${sub.displayName}: ${s.expired.toLowerCase()}';
    if (left < soon) return s.expiresIn(sub.displayName, left.inDays);
  }
  if (info.hasUsage && info.totalBytes > Int64.ZERO) {
    final rest = info.totalBytes - info.uploadBytes - info.downloadBytes;
    if (rest.toDouble() < info.totalBytes.toDouble() * little) {
      return s.trafficLow(sub.displayName, formatBytes(s, rest < Int64.ZERO ? Int64.ZERO : rest, locale));
    }
  }
  return null;
}

String protocolLine(OutboundSpec server) => [
  if (server.displayProtocol.isNotEmpty)
    server.displayProtocol.toUpperCase()
  else if (server.protocol.isNotEmpty)
    server.protocol == 'xray-profile' ? 'XRAY' : server.protocol.toUpperCase(),
  if (server.transport.isNotEmpty) server.transport.toUpperCase(),
  if (server.security.isNotEmpty && server.security.toLowerCase() != 'none') server.security.toUpperCase(),
  if (isProfile(server)) 'JSON',
].join(' | ');
