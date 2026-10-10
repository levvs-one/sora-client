import 'dart:async';

import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../l10n/strings.dart';
import '../core/link.dart';
import '../sora.dart';
import '../design/theme.dart';

/// A tappable surface with hover feedback and animated press scaling. A null
/// callback disables interaction.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    required this.onTap,
    this.radius = 14,
    this.give = 0.97,
    this.wash = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double radius;
  final double give;
  final bool wash;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _hover = false;
  bool _down = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    final enabled = widget.onTap != null;
    final fill = !enabled || !widget.wash
        ? Colors.transparent
        : _down
        ? palette.pressed
        : _hover || _focused
        ? palette.hover
        : Colors.transparent;
    return FocusableActionDetector(
      enabled: enabled,
      onShowFocusHighlight: (value) => setState(() => _focused = value),
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap?.call();
            return null;
          },
        ),
      },
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = _down = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled ? (_) => setState(() => _down = true) : null,
          onTapUp: enabled ? (_) => setState(() => _down = false) : null,
          onTapCancel: enabled ? () => setState(() => _down = false) : null,
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _down ? widget.give : 1,
            duration: Motion.of(context, Motion.fast),
            curve: Motion.curve,
            child: AnimatedContainer(
              duration: Motion.of(context, Motion.fast),
              decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(widget.radius)),
              foregroundDecoration: _focused
                  ? BoxDecoration(
                      border: Border.all(color: palette.ink3, width: 2),
                      borderRadius: BorderRadius.circular(widget.radius),
                    )
                  : null,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

/// A circular icon button with an optional accessibility label.
class RoundButton extends StatelessWidget {
  const RoundButton({super.key, required this.icon, required this.onTap, this.label});

  final IconData icon;
  final VoidCallback? onTap;

  /// Screen-reader label; not displayed visually.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    return Semantics(
      button: true,
      label: label,
      child: Pressable(
        onTap: onTap,
        radius: 18,
        give: 0.9,
        child: SizedBox.square(
          dimension: 36,
          child: Icon(icon, size: 20, color: onTap == null ? palette.ink3 : palette.ink),
        ),
      ),
    );
  }
}

/// A detail screen with back navigation, title and constrained content width.
/// By default, title and content scroll together; [fill] keeps [children] below
/// the title and provides a separate scroll area.
class Screen extends StatelessWidget {
  const Screen({super.key, required this.title, required this.children, this.actions = const [], this.fill});

  final String title;
  final List<Widget> actions;
  final List<Widget> children;
  final Widget? fill;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    final heading = Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 16),
      child: Text(title, style: Styles.heading.copyWith(color: palette.ink)),
    );
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Row(
                children: [
                  if (Navigator.of(context).canPop())
                    RoundButton(
                      icon: Symbols.chevron_left_rounded,
                      label: MaterialLocalizations.of(context).backButtonTooltip,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                  const Spacer(),
                  ...actions,
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 880),
                  child: fill == null
                      ? ListView(padding: const EdgeInsets.fromLTRB(20, 6, 20, 32), children: [heading, ...children])
                      : Padding(
                          padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              heading,
                              ...children,
                              Expanded(child: fill!),
                            ],
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Groups related rows on a rounded surface, separated by spacing without
/// dividers.
class Group extends StatelessWidget {
  const Group({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DecoratedBox(
        decoration: BoxDecoration(color: Palette.of(context).surface, borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
        ),
      ),
    );
  }
}

/// A sentence-case settings group label, spaced closer to its group.
class Heading extends StatelessWidget {
  const Heading(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
    child: Text(text, style: Styles.bodyStrong.copyWith(color: Palette.of(context).ink)),
  );
}

/// Shows a dialog and returns true on confirmation. [destructive] colours the
/// action red; disabling [cancellable] removes the cancel button for a
/// single-action informational dialog.
Future<bool> confirm(
  BuildContext context, {
  required String question,
  required String action,
  bool destructive = true,
  bool cancellable = true,
}) async {
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
        elevation: 0,
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
                  question,
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
                    decoration: BoxDecoration(
                      color: destructive ? palette.danger : palette.ink,
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Text(
                      action,
                      style: Styles.bodyStrong.copyWith(color: destructive ? Colors.white : palette.raised),
                    ),
                  ),
                ),
                if (cancellable) ...[
                  const SizedBox(height: 4),
                  Pressable(
                    onTap: () => Navigator.of(context).pop(false),
                    radius: 22,
                    child: SizedBox(
                      height: 44,
                      child: Center(
                        child: Text(s.cancel, style: Styles.body.copyWith(color: palette.ink)),
                      ),
                    ),
                  ),
                ] else
                  const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  return yes ?? false;
}

/// A tappable row with title, optional detail and trailing content.
class Tile extends StatelessWidget {
  const Tile({
    super.key,
    required this.title,
    this.detail,
    this.trailing,
    this.onTap,
    this.detailColor,
    this.titleColor,
  });

  final String title;
  final Color? titleColor;
  final String? detail;
  final Color? detailColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    return Pressable(
      onTap: onTap,
      radius: 8,
      give: 0.99,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 40),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: Styles.body.copyWith(color: titleColor ?? palette.ink),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (detail != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(detail!, style: Styles.caption.copyWith(color: detailColor ?? palette.ink)),
                      ),
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 12), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}

/// A switch row that toggles when any part of the row is tapped.
class SwitchTile extends StatelessWidget {
  const SwitchTile({super.key, required this.title, required this.value, required this.onChanged});

  final String title;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    return Tile(
      title: title,
      onTap: onChanged == null ? null : () => onChanged!(!value),
      trailing: CupertinoSwitch(
        value: value,
        onChanged: onChanged,
        activeTrackColor: palette.ink,
        inactiveTrackColor: palette.field,
        thumbColor: palette.surface,
      ),
    );
  }
}

/// A choice row with a menu anchored to the row.
class ChoiceTile<T> extends StatelessWidget {
  const ChoiceTile({
    super.key,
    required this.title,
    required this.value,
    required this.choices,
    required this.onChanged,
  });

  final String title;
  final T value;
  final Map<T, String> choices;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    return MenuAnchor(
      alignmentOffset: const Offset(0, 4),
      menuChildren: [
        for (final entry in choices.entries)
          MenuItemButton(
            onPressed: () => onChanged(entry.key),
            style: ButtonStyle(
              minimumSize: const WidgetStatePropertyAll(Size(220, 40)),
              shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(9))),
              overlayColor: WidgetStatePropertyAll(palette.hover),
              padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 12)),
            ),
            trailingIcon: entry.key == value ? Icon(Symbols.check_rounded, size: 18, color: palette.ink) : null,
            child: Text(entry.value, style: Styles.secondary.copyWith(color: palette.ink)),
          ),
      ],
      builder: (context, controller, _) => Tile(
        title: title,
        onTap: () => controller.isOpen ? controller.close() : controller.open(),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(choices[value] ?? '', style: Styles.secondary.copyWith(color: palette.ink)),
            const SizedBox(width: 6),
            Icon(Symbols.unfold_more_rounded, size: 14, color: palette.ink3),
          ],
        ),
      ),
    );
  }
}

/// A navigation row with an optional current value.
class LinkTile extends StatelessWidget {
  const LinkTile({super.key, required this.title, required this.onTap, this.value});

  final String title;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    return Tile(
      title: title,
      onTap: onTap,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value != null) Text(value!, style: Styles.secondary.copyWith(color: palette.ink)),
          const SizedBox(width: 6),
          Icon(Symbols.chevron_right_rounded, size: 15, color: palette.ink3),
        ],
      ),
    );
  }
}

/// Equal-width choices with an animated selection indicator and no segment
/// dividers.
class Segments<T> extends StatelessWidget {
  const Segments({super.key, required this.value, required this.choices, required this.onChanged});

  final T value;
  final Map<T, String> choices;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    final keys = choices.keys.toList();
    final index = keys.indexOf(value);
    return Container(
      height: 36,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: palette.field, borderRadius: BorderRadius.circular(11)),
      child: Stack(
        children: [
          AnimatedAlign(
            alignment: Alignment(keys.length == 1 ? 0 : -1 + 2 * index / (keys.length - 1), 0),
            duration: Motion.of(context, Motion.medium),
            curve: Motion.curve,
            child: FractionallySizedBox(
              widthFactor: 1 / keys.length,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [BoxShadow(color: palette.shadow, blurRadius: 6, offset: const Offset(0, 1))],
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (final key in keys)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: key == value,
                    child: Pressable(
                      onTap: () => onChanged(key),
                      radius: 8,
                      give: 1,
                      child: Center(
                        child: Text(choices[key]!, style: Styles.caption.copyWith(color: palette.ink)),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Displays the used share of subscription traffic; [alarm] colours it red for
/// low remaining quota.
class UsageBar extends StatelessWidget {
  const UsageBar({super.key, required this.share, this.alarm = false});

  /// Used fraction from 0 to 1.
  final double share;
  final bool alarm;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    return SizedBox(
      height: 4,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(color: palette.field, borderRadius: BorderRadius.circular(2)),
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: share),
          duration: Motion.of(context, Motion.slow),
          curve: Motion.curve,
          builder: (context, value, _) => Align(
            alignment: AlignmentDirectional.centerStart,
            child: FractionallySizedBox(
              widthFactor: value,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: alarm ? palette.danger : palette.ink,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Opens a provider link externally. Allows only HTTP, HTTPS and Telegram
/// schemes, matching core validation.
Future<void> openLink(BuildContext context, String link) async {
  final uri = Uri.tryParse(link.trim());
  if (uri == null || !const {'https', 'http', 'tg'}.contains(uri.scheme)) return;
  final sora = SoraScope.read(context);
  sora.recovered('browser');
  try {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) throw const CoreFailure('app.browser_unavailable');
  } catch (_) {
    sora.reportFailure(const CoreFailure('app.browser_unavailable'), source: 'browser', action: '');
  }
}

/// A capsule action button with disabled and busy states.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.label, required this.onTap, this.busy = false});

  final String label;
  final VoidCallback? onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    return Pressable(
      onTap: busy ? null : onTap,
      radius: 26,
      wash: false,
      child: AnimatedContainer(
        duration: Motion.of(context, Motion.fast),
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: onTap == null ? palette.raisedField : palette.ink,
          borderRadius: BorderRadius.circular(26),
        ),
        child: busy
            ? CupertinoActivityIndicator(color: palette.surface)
            : Text(label, style: Styles.bodyStrong.copyWith(color: onTap == null ? palette.ink3 : palette.surface)),
      ),
    );
  }
}

/// Pushes a detail screen with slide and fade transitions. Disabled motion
/// makes the transition immediate.
Future<T?> push<T>(BuildContext context, Widget screen) {
  final motion = Motion.enabled(context);
  return Navigator.of(context).push<T>(
    PageRouteBuilder<T>(
      transitionDuration: motion ? Motion.medium : Duration.zero,
      reverseTransitionDuration: motion ? const Duration(milliseconds: 220) : Duration.zero,
      pageBuilder: (_, _, _) => screen,
      transitionsBuilder: (context, animation, secondary, child) {
        final curved = CurvedAnimation(parent: animation, curve: Motion.curve, reverseCurve: Curves.easeIn);
        final behind = CurvedAnimation(parent: secondary, curve: Motion.curve);
        return FadeTransition(
          opacity: Tween(begin: 1.0, end: 0.0).animate(behind),
          child: FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween(begin: const Offset(0.06, 0), end: Offset.zero).animate(curved),
              child: child,
            ),
          ),
        );
      },
    ),
  );
}

/// Returns a localized UI message for a core or app failure.
String describe(S s, CoreFailure failure) {
  final key = failure.key;
  return switch (key) {
    'app.core_unavailable' => s.errCore,
    'app.no_servers' => s.errNoServers,
    'app.browser_unavailable' => s.speedtestExternalFailed,
    'core.auth.unauthenticated' || 'core.auth.permission_denied' => s.errAuth,
    'core.api.version_mismatch' => s.errVersion,
    'core.session.busy' => s.errBusy,
    'core.engine.binary_missing' => s.errEngineMissing,
    'core.plan.engine_unsupported' => s.errEngineUnsupported,
    'core.guard.restore_failed' => s.errRestore,
    'core.session.unknown' || 'core.session.required' => s.errSessionEnded,
    'core.engine.start_failed' => s.errEngineStart,
    'core.engine.stopped' || 'core.engine.restart_budget_spent' => s.errEngineStopped,
    'core.plan.tunnel_unsupported' => s.errTunnel,
    'core.guard.firewall_failed' => s.errFirewall,
    'core.network.timeout' || 'core.request.deadline_exceeded' => s.errTimeout,
    'core.network.failed' || 'core.network.connection_refused' || 'core.tls.certificate' => s.errNetwork,
    'core.subscription.duplicate' => s.errSubDuplicate,
    'core.subscription.limit' => s.errSubLimit,
    'core.subscription.scheme_unsupported' || 'core.subscription.redirect_rejected' => s.errSubScheme,
    'core.subscription.format_unknown' || 'core.request.invalid' => s.errSubFormat,
    'core.subscription.no_servers' || 'core.subscription.empty' => s.errSubEmpty,
    'core.subscription.fetch_failed' || 'core.subscription.status' || 'core.subscription.too_large' => s.errSubFetch,
    'core.secret.store_corrupt' || 'core.secret.store_unavailable' => s.errSecretStore,
    _ when key.startsWith('core.plan.') => s.errServers,
    _ => s.errGeneric,
  };
}
