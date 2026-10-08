import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/strings.dart';
import '../core/link.dart';
import '../design/glow.dart';
import '../design/logo.dart';
import '../design/theme.dart';
import '../groups.dart';
import '../sora.dart';
import 'kit.dart';
import 'servers.dart';
import 'settings_screen.dart';
import 'subscription_sheet.dart';

/// Main connection screen with session controls, status and server selection.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sora = SoraScope.of(context);
    final working = sora.phase == Phase.connecting || sora.phase == Phase.reconnecting;
    final reachable = sora.phase != Phase.offline && !sora.busy;
    void settings() => unawaited(push<void>(context, const SettingsScreen()));
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter): () {
          if (reachable) unawaited(sora.toggle());
        },
        const SingleActivator(LogicalKeyboardKey.comma, control: true): settings,
      },
      child: Focus(
        autofocus: true,
        child: Glow(
          radius: 12,
          energy: working ? 0.9 : 0,
          busy: true,
          inFront: true,
          child: Scaffold(
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Spacer(),
                            RoundButton(icon: CupertinoIcons.gear_alt, label: S.of(context).settings, onTap: settings),
                          ],
                        ),
                        const Spacer(flex: 3),
                        const _Orb(),
                        const SizedBox(height: 36),
                        const _Status(),
                        const Spacer(flex: 4),
                        const _SubscriptionWarning(),
                        const _ServerCard(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
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

/// Crossfades state text with a short upward slide to avoid abrupt changes.
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
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.25), end: Offset.zero).animate(animation),
          child: child,
        ),
      ),
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
  const _ServerCard();

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
        radius: 22,
        give: 0.98,
        wash: false,
        onTap: offline
            ? null
            : () => empty ? showSubscriptionSheet(context) : push<void>(context, const ServersScreen()),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(color: palette.surface, borderRadius: BorderRadius.circular(22)),
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
                empty ? CupertinoIcons.plus : CupertinoIcons.chevron_right,
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

/// Shows subscription expiry and traffic warnings on the main screen before
/// service is interrupted.
class _SubscriptionWarning extends StatelessWidget {
  const _SubscriptionWarning();

  @override
  Widget build(BuildContext context) {
    final sora = SoraScope.of(context);
    final s = S.of(context);
    final palette = Palette.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final warning = sora.subscriptions.map((sub) => subscriptionWarning(s, sub, locale)).nonNulls.firstOrNull;
    return AnimatedSize(
      duration: Motion.of(context, Motion.medium),
      curve: Motion.curve,
      child: warning == null
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
              child: Text(
                warning,
                textAlign: TextAlign.center,
                style: Styles.secondary.copyWith(color: palette.danger),
              ),
            ),
    );
  }
}
