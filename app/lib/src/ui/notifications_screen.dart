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
import 'about.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sora = SoraScope.of(context), s = S.of(context);
    return Screen(
      title: s.notifications,
      actions: [
        RoundButton(
          icon: Symbols.delete_rounded,
          label: s.clear,
          onTap: sora.history.isEmpty ? null : sora.clearNotifications,
        ),
      ],
      fill: sora.history.isEmpty
          ? null
          : ListView.separated(
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: sora.history.length,
              itemBuilder: (_, index) => NotificationRow(notice: sora.history[index]),
              separatorBuilder: (_, _) => const SizedBox(height: 8),
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
      'update' => s.updateOpenAbout,
      _ => null,
    };
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.field),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('dd.MM.yyyy  HH:mm').format(notice.time.toLocal()),
            style: Styles.timestamp.copyWith(color: palette.ink3),
          ),
          const SizedBox(height: 8),
          Text(notice.title, style: Styles.bodyStrong.copyWith(color: palette.ink)),
          const SizedBox(height: 4),
          Text(notice.body, style: Styles.secondary.copyWith(color: palette.ink2)),
          if (action != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Pressable(
                onTap: () => runNotificationAction(context, notice),
                radius: 8,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(action, style: Styles.secondary.copyWith(color: palette.ink)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

void runNotificationAction(BuildContext context, AppNotification notice) {
  final sora = SoraScope.read(context);
  switch (notice.action) {
    case 'update':
      unawaited(push<void>(context, const AboutScreen()));
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
