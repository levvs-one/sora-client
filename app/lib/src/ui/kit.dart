import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../l10n/strings.dart';
import '../core/link.dart';
import '../design/theme.dart';

/// Anything that responds to a pointer: a hover wash, and a small give under
/// the finger that springs back, as Apple controls do.
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

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    final enabled = widget.onTap != null;
    final fill = !enabled || !widget.wash
        ? Colors.transparent
        : _down
        ? palette.pressed
        : _hover
        ? palette.hover
        : Colors.transparent;
    return MouseRegion(
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
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// A round icon button.
class RoundButton extends StatelessWidget {
  const RoundButton({super.key, required this.icon, required this.onTap, this.label});

  final IconData icon;
  final VoidCallback? onTap;

  /// Read by screen readers; never shown.
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

/// A screen below the main one: a back button, a large title that sits on
/// the page, and the content in one column of a comfortable width.
///
/// The content scrolls with the title, unless [fill] is given: then
/// [children] stay under the title and [fill] scrolls on its own, as a long
/// list does.
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
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 22),
      child: Text(title, style: Styles.title.copyWith(color: palette.ink)),
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
                  RoundButton(
                    icon: CupertinoIcons.chevron_left,
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
                  constraints: const BoxConstraints(maxWidth: 560),
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

/// Rows that belong together, on one rounded surface. Space separates groups
/// and rows; there are no rules between them.
class Group extends StatelessWidget {
  const Group({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: DecoratedBox(
        decoration: BoxDecoration(color: Palette.of(context).surface, borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
        ),
      ),
    );
  }
}

/// The name of a group of settings: dark and in sentence case, set close to
/// its group and far from the one before, so it reads as a label of what
/// follows rather than a banner.
class Heading extends StatelessWidget {
  const Heading(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
    child: Text(text, style: Styles.bodyStrong.copyWith(color: Palette.of(context).ink)),
  );
}

/// Asks before something that cannot be undone: the question, the action in
/// red, and a way out. Answers true when the person goes ahead.
Future<bool> confirm(BuildContext context, {required String question, required String action}) async {
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
                    decoration: BoxDecoration(color: palette.danger, borderRadius: BorderRadius.circular(26)),
                    child: Text(action, style: Styles.bodyStrong.copyWith(color: Colors.white)),
                  ),
                ),
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
              ],
            ),
          ),
        ),
      ),
    ),
  );
  return yes ?? false;
}

/// One row: a title, an optional detail under it, and what goes on the right.
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
      radius: 16,
      give: 0.99,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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

/// A row with a switch; the whole row toggles it.
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

/// A row whose value is one of a few choices, picked from a menu that opens
/// where the row is.
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
            trailingIcon: entry.key == value ? Icon(CupertinoIcons.checkmark_alt, size: 18, color: palette.ink) : null,
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
            Icon(CupertinoIcons.chevron_up_chevron_down, size: 14, color: palette.ink3),
          ],
        ),
      ),
    );
  }
}

/// A row that opens another screen.
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
          Icon(CupertinoIcons.chevron_right, size: 15, color: palette.ink3),
        ],
      ),
    );
  }
}

/// A row of equal choices with a plate that slides to the chosen one. The
/// built-in control draws rules between segments; this one has none.
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
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onChanged(key),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Center(
                          child: Text(choices[key]!, style: Styles.caption.copyWith(color: palette.ink)),
                        ),
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

/// A wide capsule button, ink on the page.
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

/// Pushes a screen with a short slide and fade, the way a Mac app moves to a
/// detail; without motion it simply appears.
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

/// The words for a failure, in the language of the interface.
String describe(S s, CoreFailure failure) {
  final key = failure.key;
  return switch (key) {
    'app.core_unavailable' => s.errCore,
    'app.no_servers' => s.errNoServers,
    'core.auth.unauthenticated' || 'core.auth.permission_denied' => s.errAuth,
    'core.api.version_mismatch' => s.errVersion,
    'core.session.busy' => s.errBusy,
    'core.engine.binary_missing' => s.errEngineMissing,
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
