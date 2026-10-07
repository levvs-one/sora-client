import 'dart:async';

import 'package:fixnum/fixnum.dart';
import 'package:flutter/cupertino.dart';
import 'package:protobuf/well_known_types/google/protobuf/duration.pb.dart' as pb;

import '../../l10n/strings.dart';
import '../design/theme.dart';
import '../generated/sora/core/v1/core_control.pb.dart';
import '../sora.dart';
import 'kit.dart';
import 'servers.dart';
import 'subscription_sheet.dart';

/// Every subscription, each one step from its settings.
class SubscriptionsScreen extends StatelessWidget {
  const SubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sora = SoraScope.of(context);
    final s = S.of(context);
    final palette = Palette.of(context);
    return Screen(
      title: s.subscriptions,
      children: [
        Group(
          children: [
            for (final state in sora.subscriptions)
              LinkTile(
                title: state.displayName,
                onTap: () => push<void>(context, SubscriptionScreen(id: state.settings.id)),
              ),
            Tile(
              title: s.addSubscription,
              onTap: () => showSubscriptionSheet(context),
              trailing: Icon(CupertinoIcons.plus, size: 18, color: palette.ink),
            ),
          ],
        ),
      ],
    );
  }
}

/// What a person chooses for one subscription. The link itself is never shown:
/// the core keeps it encrypted and does not send it back.
class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key, required this.id});

  final String id;

  /// Hours between updates the person may pick; zero follows the provider.
  static const _intervals = [0, 1, 3, 6, 12, 24];

  @override
  Widget build(BuildContext context) {
    final sora = SoraScope.of(context);
    final s = S.of(context);
    final palette = Palette.of(context);
    final state = sora.subscriptions.where((x) => x.settings.id == id).firstOrNull;
    if (state == null) {
      // Deleted from here or elsewhere: there is nothing left to set.
      return Screen(title: s.subscriptions, children: const []);
    }
    final chosen = state.settings;
    Future<String?> save(void Function(SubscriptionSettings) apply) async {
      final next = chosen.deepCopy();
      apply(next);
      final failure = await sora.saveSubscription(next);
      return failure == null ? null : describe(s, failure);
    }

    final hours = chosen.hasUpdateInterval() ? chosen.updateInterval.seconds.toInt() ~/ 3600 : 0;
    return Screen(
      title: state.displayName,
      children: [
        Group(
          children: [
            LinkTile(
              title: s.name,
              value: chosen.name.isEmpty ? state.displayName : chosen.name,
              onTap: () => showFieldSheet(
                context,
                title: s.name,
                hint: state.displayName,
                action: s.save,
                initial: chosen.name,
                allowEmpty: true,
                submit: (v) => save((x) => x.name = v),
              ),
            ),
            LinkTile(
              title: s.userAgent,
              value: chosen.userAgent.isEmpty ? s.byDefault : chosen.userAgent,
              onTap: () => showFieldSheet(
                context,
                title: s.userAgent,
                hint: s.byDefault,
                action: s.save,
                initial: chosen.userAgent,
                allowEmpty: true,
                submit: (v) => save((x) => x.userAgent = v),
              ),
            ),
            SwitchTile(
              title: s.autoUpdate,
              value: chosen.autoUpdate,
              onChanged: (v) => unawaited(save((x) => x.autoUpdate = v)),
            ),
            if (chosen.autoUpdate)
              ChoiceTile<int>(
                title: s.updateInterval,
                value: _intervals.contains(hours) ? hours : 0,
                choices: {for (final h in _intervals) h: h == 0 ? s.intervalProvider : s.hours(h)},
                onChanged: (h) => unawaited(
                  save((x) {
                    if (h == 0) {
                      x.clearUpdateInterval();
                    } else {
                      x.updateInterval = pb.Duration(seconds: Int64(h * 3600));
                    }
                  }),
                ),
              ),
          ],
        ),
        Group(
          children: [
            Tile(
              title: s.updateNow,
              onTap: state.updating ? null : () => unawaited(sora.refreshSubscription(id)),
              trailing: state.updating ? CupertinoActivityIndicator(color: palette.ink) : null,
            ),
            Tile(
              title: s.delete,
              titleColor: palette.danger,
              onTap: () async {
                await deleteSubscription(context, state);
                if (context.mounted && !sora.subscriptions.any((x) => x.settings.id == id)) {
                  Navigator.of(context).maybePop();
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}
