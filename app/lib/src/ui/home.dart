import 'dart:async';
import 'dart:math' as math;

import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../l10n/strings.dart';
import '../core/link.dart';
import '../design/glow.dart';
import '../design/logo.dart';
import '../design/theme.dart';
import '../groups.dart';
import '../rules.dart';
import '../sora.dart';
import 'kit.dart';
import 'notifications_screen.dart';
import 'servers.dart';
import 'shell.dart';
import 'tour.dart';
import 'subscription_sheet.dart';

/// Connection workspace, with independent panes on wide desktop windows.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => CallbackShortcuts(
    bindings: {const SingleActivator(LogicalKeyboardKey.enter): () => unawaited(SoraScope.read(context).toggle())},
    child: Focus(
      autofocus: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (MediaQuery.sizeOf(context).width >= 1000) {
            final width = (constraints.maxWidth * 0.43).clamp(360.0, 480.0);
            return Row(
              key: const ValueKey('wide-layout'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(width: width, child: const ServersScreen(embedded: true)),
                VerticalDivider(width: 1, color: Palette.of(context).field),
                const Expanded(child: SingleChildScrollView(child: _ConnectionPane())),
              ],
            );
          }
          return SingleChildScrollView(
            key: ValueKey(MediaQuery.sizeOf(context).width >= 720 ? 'medium-layout' : 'compact-layout'),
            child: const Column(children: [_ConnectionPane(), ServersScreen(embedded: true, scrollable: false)]),
          );
        },
      ),
    ),
  );
}

class _ConnectionPane extends StatelessWidget {
  const _ConnectionPane();

  @override
  Widget build(BuildContext context) {
    final sora = SoraScope.of(context), s = S.of(context), palette = Palette.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    String bytes(double value) => formatBytes(s, Int64(value.round()), locale);
    final stats = sora.stats;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(s.sectionConnection, style: Styles.heading.copyWith(color: palette.ink)),
          const SizedBox(height: 24),
          const _Status(),
          const SizedBox(height: 12),
          const Center(child: TourTarget(step: 2, child: _Orb())),
          const SizedBox(height: 32),
          Text(s.currentServer, style: Styles.caption.copyWith(color: palette.ink2)),
          const SizedBox(height: 8),
          const _ServerCard(key: ValueKey('current-server')),
          const SizedBox(height: 20),
          TourTarget(
            step: 3,
            child: Column(
              children: [
                Segments<String>(
                  value: sora.settings.tunnel,
                  choices: {'tun': s.tunnelTun, 'proxy': s.tunnelProxy},
                  onChanged: (v) => unawaited(sora.change((x) => x.tunnel = v)),
                ),
                const SizedBox(height: 8),
                SwitchTile(
                  title: s.killSwitch,
                  value: sora.settings.killSwitch,
                  onChanged: (v) => unawaited(sora.setKillSwitch(v)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (stats != null)
            Row(
              children: [
                for (final (label, speed, total, icon) in [
                  (s.trafficDown, sora.speedDown, stats.bytesDown, Symbols.south_rounded),
                  (s.trafficUp, sora.speedUp, stats.bytesUp, Symbols.north_rounded),
                ])
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(icon, size: 16, color: palette.ink2),
                            const SizedBox(width: 4),
                            Text(label, style: Styles.caption.copyWith(color: palette.ink2)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          speed == null ? s.trafficUnavailable : s.perSecond(bytes(speed)),
                          style: Styles.figures(Styles.bodyStrong).copyWith(color: palette.ink),
                        ),
                        Text(
                          formatBytes(s, total, locale),
                          style: Styles.figures(Styles.secondary).copyWith(color: palette.ink3),
                        ),
                      ],
                    ),
                  ),
              ],
            )
          else
            Text(s.trafficUnavailable, style: Styles.caption.copyWith(color: palette.ink3)),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              key: const ValueKey('check-speed'),
              onPressed: () => ShellScope.of(context).select(7),
              child: Text(s.speedtestCheck, style: Styles.secondary.copyWith(color: palette.ink)),
            ),
          ),
          if (MediaQuery.sizeOf(context).width >= 1000) ...[
            const SizedBox(height: 24),
            Group(
              children: [
                LinkTile(
                  title: s.activeRules(sora.settings.rules.map(UserRule.parse).nonNulls.length),
                  onTap: () => ShellScope.of(context).select(1),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Text(s.recentNotifications, style: Styles.bodyStrong.copyWith(color: palette.ink)),
                ),
                TextButton(
                  onPressed: () => ShellScope.of(context).select(4),
                  child: Text(s.notifications, style: Styles.secondary.copyWith(color: palette.ink)),
                ),
              ],
            ),
            if (sora.history.isEmpty)
              Text(s.notificationsEmpty, style: Styles.caption.copyWith(color: palette.ink3))
            else
              Group(children: [for (final notice in sora.history.take(3)) NotificationRow(notice: notice)]),
          ],
        ],
      ),
    );
  }
}

class _Orb extends StatefulWidget {
  const _Orb();

  @override
  State<_Orb> createState() => _OrbState();
}

class _OrbState extends State<_Orb> with SingleTickerProviderStateMixin {
  static const _size = 176.0;
  late final _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 460));
  CoreFailure? _shown;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final failure = SoraScope.of(context).failure;
    if (failure != null && !identical(failure, _shown) && Motion.enabled(context)) {
      unawaited(_shake.forward(from: 0));
    }
    _shown = failure;
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sora = SoraScope.of(context);
    final palette = Palette.of(context);
    final phase = sora.phase;
    final on = phase == Phase.connected;
    final working = phase == Phase.connecting || phase == Phase.reconnecting || phase == Phase.disconnecting;
    final reachable = phase != Phase.offline && !sora.busy;
    return AnimatedBuilder(
      animation: _shake,
      builder: (context, child) {
        final t = _shake.value;
        return Transform.translate(offset: Offset(math.sin(t * math.pi * 6) * (1 - t) * 10, 0), child: child);
      },
      child: Semantics(
        button: true,
        toggled: on,
        label: on ? S.of(context).stateConnected : S.of(context).stateOff,
        child: Pressable(
          onTap: reachable ? sora.toggle : null,
          radius: _size / 2,
          give: 0.95,
          wash: false,
          child: Glow(
            radius: _size / 2,
            energy: working ? 1 : (on ? 0.75 : 0),
            busy: working,
            scale: 0.75,
            child: AnimatedContainer(
              duration: Motion.of(context, Motion.slow),
              curve: Motion.curve,
              width: _size,
              height: _size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: palette.surface,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: palette.shadow, blurRadius: on ? 18 : 34, offset: Offset(0, on ? 4 : 12))],
              ),
              child: TweenAnimationBuilder<Color?>(
                tween: ColorTween(end: on || working ? palette.ink : palette.ink3),
                duration: Motion.of(context, Motion.slow),
                builder: (context, color, _) => SoraMark(size: 58, color: color!),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Status extends StatelessWidget {
  const _Status();

  @override
  Widget build(BuildContext context) {
    final sora = SoraScope.of(context);
    final s = S.of(context);
    final palette = Palette.of(context);
    final title = switch (sora.phase) {
      Phase.offline => s.coreMissing,
      Phase.off => s.stateOff,
      Phase.connecting => s.stateConnecting,
      Phase.connected => s.stateConnected,
      Phase.reconnecting => s.stateReconnecting,
      Phase.disconnecting => s.stateDisconnecting,
    };
    final failure = sora.failure;
    final Widget detail = failure != null && sora.phase != Phase.offline
        ? Text(
            describe(s, failure),
            key: ValueKey(failure.key),
            textAlign: TextAlign.center,
            style: Styles.secondary.copyWith(color: palette.danger),
          )
        : sora.phase == Phase.connected && sora.since != null
        ? _Elapsed(key: const ValueKey('elapsed'), since: sora.since!)
        : const SizedBox(key: ValueKey('none'));
    return Column(
      children: [
        _Swap(
          child: Text(
            title,
            key: ValueKey(title),
            textAlign: TextAlign.center,
            style: (sora.phase == Phase.offline ? Styles.bodyStrong : Styles.status).copyWith(color: palette.ink),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(height: 44, child: _Swap(child: detail)),
      ],
    );
  }
}

/// Crossfades state text when the connection phase changes.
class _Swap extends StatelessWidget {
  const _Swap({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: Motion.of(context, Motion.medium),
      switchInCurve: Motion.curve,
      switchOutCurve: Curves.easeIn,
      layoutBuilder: (current, previous) => Stack(alignment: Alignment.topCenter, children: [...previous, ?current]),
      transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
      child: child,
    );
  }
}

class _Elapsed extends StatefulWidget {
  const _Elapsed({super.key, required this.since});

  final DateTime since;

  @override
  State<_Elapsed> createState() => _ElapsedState();
}

class _ElapsedState extends State<_Elapsed> {
  late final Timer _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final span = DateTime.now().difference(widget.since);
    final d = span.isNegative ? Duration.zero : span;
    String two(int n) => n.toString().padLeft(2, '0');
    final text = d.inHours > 0
        ? '${d.inHours}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}'
        : '${two(d.inMinutes)}:${two(d.inSeconds % 60)}';
    return Text(text, style: Styles.figures(Styles.bodyStrong).copyWith(color: Palette.of(context).ink));
  }
}

class _ServerCard extends StatelessWidget {
  const _ServerCard({super.key});

  @override
  Widget build(BuildContext context) {
    final sora = SoraScope.of(context);
    final s = S.of(context);
    final palette = Palette.of(context);
    final offline = sora.phase == Phase.offline;
    final empty = sora.servers.isEmpty && sora.selected != 'bypass';
    final selected = sora.selected;
    final name = empty
        ? s.addSubscription
        : switch (selected) {
            'auto' => s.serverAuto,
            'bypass' => s.serverBypass,
            _ => sora.nameOf(selected),
          };
    // Use the prospective active member's latency for a group selection.
    final group = selected.startsWith(groupPrefix) ? entryOf(selected, sora.subscriptions) : null;
    final ms = sora.latency[group == null ? selected : pickMember(group, sora.latency).id];
    return AnimatedOpacity(
      opacity: offline ? 0.4 : 1,
      duration: Motion.of(context, Motion.medium),
      child: Pressable(
        radius: 12,
        give: 0.98,
        wash: false,
        onTap: offline
            ? null
            : () => empty ? showSubscriptionSheet(context) : push<void>(context, const ServersScreen()),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(color: palette.surface, borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Styles.bodyStrong.copyWith(color: palette.ink),
                ),
              ),
              if (!empty && ms != null) ...[
                Text(s.milliseconds(ms), style: Styles.figures(Styles.secondary).copyWith(color: palette.ink)),
                const SizedBox(width: 10),
              ],
              Icon(
                empty ? Symbols.add_rounded : Symbols.chevron_right_rounded,
                size: empty ? 20 : 16,
                color: empty ? palette.ink : palette.ink3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
