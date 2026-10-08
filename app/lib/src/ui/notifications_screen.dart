import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../l10n/strings.dart';
import '../design/theme.dart';
import '../notifications.dart';
import '../sora.dart';
import '../speedtest_services.dart';
import 'kit.dart';
import 'logs.dart';
import 'subscription.dart';
import 'speedtest.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sora = SoraScope.of(context), s = S.of(context);
    return Screen(
      title: s.notifications,
      actions: [
        RoundButton(
          icon: Symbols.done_all_rounded,
          label: s.markAllRead,
          onTap: sora.unreadCount == 0 ? null : sora.markNotificationsRead,
        ),
        RoundButton(
          icon: Symbols.delete_rounded,
          label: s.clear,
          onTap: sora.history.isEmpty ? null : sora.clearNotifications,
        ),
      ],
      fill: sora.history.isEmpty
          ? null
          : ListView.builder(
              itemCount: sora.history.length,
              itemBuilder: (_, index) => NotificationRow(notice: sora.history[index]),
            ),
      children: [
        if (sora.history.isEmpty)
          Text(s.notificationsEmpty, style: Styles.secondary.copyWith(color: Palette.of(context).ink2)),
      ],
    );
  }
}

class NotificationRow extends StatelessWidget {
  const NotificationRow({super.key, required this.notice});
  final AppNotification notice;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context), palette = Palette.of(context);
    final action = switch (notice.action) {
      'connect' => s.retryConnect,
      'logs' => s.openLogs,
      'subscription' => s.subscription,
      'speedtest' => s.refresh,
      _ => null,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (!notice.read) ...[
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(color: palette.ink, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(notice.title, style: Styles.bodyStrong.copyWith(color: palette.ink)),
              ),
              const SizedBox(width: 8),
              Text(
                DateFormat('dd.MM HH:mm').format(notice.time.toLocal()),
                style: Styles.figures(Styles.caption).copyWith(color: palette.ink3),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(notice.body, style: Styles.secondary.copyWith(color: palette.ink2)),
          if (action != null)
            TextButton(
              onPressed: () => runNotificationAction(context, notice),
              child: Text(action, style: Styles.secondary.copyWith(color: palette.ink)),
            ),
        ],
      ),
    );
  }
}

void runNotificationAction(BuildContext context, AppNotification notice) {
  final sora = SoraScope.read(context);
  switch (notice.action) {
    case 'connect':
      unawaited(sora.connect());
    case 'logs':
      unawaited(push<void>(context, const LogsScreen()));
    case 'subscription':
      unawaited(push<void>(context, SubscriptionScreen(id: notice.argument)));
    case 'speedtest':
      final service = speedtestServices.where((s) => s.url == notice.argument).firstOrNull;
      if (service != null) unawaited(push<void>(context, Scaffold(body: SpeedtestScreen(initialService: service))));
  }
}
