import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:toastification/toastification.dart';

import '../../l10n/strings.dart';
import '../design/theme.dart';
import '../notifications.dart';
import '../sora.dart';
import 'kit.dart';
import 'notifications_screen.dart';

class ToastVisibility extends InheritedWidget {
  const ToastVisibility({super.key, required this.visible, required super.child});
  final bool visible;
  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ToastVisibility>()?.visible ?? false;
  @override
  bool updateShouldNotify(ToastVisibility oldWidget) => visible != oldWidget.visible;
}

class NotificationToasts extends StatefulWidget {
  const NotificationToasts({super.key, required this.sora, required this.navigator, required this.child});
  final Sora sora;
  final GlobalKey<NavigatorState> navigator;
  final Widget child;

  @override
  State<NotificationToasts> createState() => _NotificationToastsState();
}

class _NotificationToastsState extends State<NotificationToasts> {
  StreamSubscription<AppNotification>? _watch;
  final _active = <ToastificationItem, VoidCallback>{};
  final _pending = Queue<AppNotification>();

  @override
  void initState() {
    super.initState();
    _watch = widget.sora.messages.listen((notice) {
      _pending.add(notice);
      if (_pending.length == 1) _show();
    });
  }

  void _show() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final notice = _pending.removeFirst();
      final overlay = widget.navigator.currentState?.overlay;
      if (overlay == null) return;
      final context = overlay.context;
      final palette = Palette.of(context);
      final item = toastification.show(
        context: context,
        overlayState: overlay,
        alignment: Alignment.topRight,
        direction: TextDirection.ltr,
        autoCloseDuration: const Duration(seconds: 5),
        animationDuration: Motion.of(context, const Duration(milliseconds: 180)),
        animationBuilder: (_, animation, _, child) => FadeTransition(opacity: animation, child: child),
        style: ToastificationStyle.flat,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notice.title,
              key: ObjectKey(notice),
              style: Styles.bodyStrong.copyWith(color: palette.ink, height: 4 / 3),
            ),
            if (notice.body.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                notice.body,
                style: Styles.secondary.copyWith(color: palette.ink2, height: 16 / 13),
              ),
            ],
          ],
        ),
        showIcon: false,
        showProgressBar: false,
        backgroundColor: palette.raised,
        foregroundColor: palette.ink,
        primaryColor: palette.ink,
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: palette.field),
        boxShadow: const [],
        padding: const EdgeInsets.all(15),
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        sizeConstraints: BoxConstraints(
          minHeight: 80,
          minWidth: (MediaQuery.sizeOf(context).width - 24).clamp(0, 360),
          maxWidth: (MediaQuery.sizeOf(context).width - 24).clamp(0, 360),
        ),
        closeButton: ToastCloseButton(
          buttonBuilder: (_, close) => Semantics(
            button: true,
            label: S.of(context).close,
            child: Pressable(
              onTap: close,
              radius: 8,
              child: SizedBox.square(dimension: 30, child: Icon(Symbols.close_rounded, size: 18, color: palette.ink2)),
            ),
          ),
        ),
        pauseOnHover: true,
        dragToClose: true,
        dismissDirection: DismissDirection.startToEnd,
        closeOnClick: notice.action.isNotEmpty,
        onHoverMouseCursor: notice.action.isEmpty ? SystemMouseCursors.basic : SystemMouseCursors.click,
        callbacks: ToastificationCallbacks(onTap: (_) => runNotificationAction(context, notice)),
      );
      void changed() {
        if (item.isRunning) return;
        item.removeListenerOnTimeStatus(changed);
        if (mounted) setState(() => _active.remove(item));
      }

      item.addListenerOnTimeStatus(changed);
      setState(() => _active[item] = changed);
      // AnimatedList must finish inserting before a burst can evict that item.
      if (_pending.isNotEmpty) _show();
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  void dispose() {
    unawaited(_watch?.cancel());
    for (final entry in _active.entries) {
      entry.key.removeListenerOnTimeStatus(entry.value);
    }
    toastification.dismissAll(delayForAnimation: false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ToastVisibility(visible: _active.isNotEmpty, child: widget.child);
}
