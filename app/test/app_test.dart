import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sora/l10n/strings_ru.dart';
import 'package:sora/main.dart';
import 'package:sora/src/core/link.dart';
import 'package:sora/src/generated/sora/core/v1/core_control.pb.dart';
import 'package:sora/src/settings.dart';
import 'package:sora/src/sora.dart';
import 'package:sora/src/ui/kit.dart';
import 'package:sora/src/ui/servers.dart';

void main() {
  final servers = [
    OutboundSpec(id: 'a', displayName: 'A', protocol: 'vless'),
    OutboundSpec(id: 'b', displayName: 'B', protocol: 'shadowsocks'),
  ];

  group('plan', () {
    test('the fastest server is a url-test group the routing points at', () {
      final plan = buildPlan(servers: servers, choice: 'auto', preset: 'ru', blockAds: true, engine: '');
      expect(plan.tunnelMode, TunnelMode.TUNNEL_MODE_SYSTEM);
      expect(plan.outbounds.map((o) => o.id), ['a', 'b']);
      expect(plan.groups.single.name, Sora.autoGroup);
      expect(plan.groups.single.type, GroupType.GROUP_TYPE_URL_TEST);
      expect(plan.groups.single.members, ['a', 'b']);
      expect(plan.routing.proxyTarget, Sora.autoGroup);
      expect(plan.routing.preset, 'ru');
      expect(plan.routing.blockAds, isTrue);
      expect(plan.engines, isEmpty, reason: 'an empty preference lets the core choose');
    });

    test('a picked server is the target, with no group', () {
      final plan = buildPlan(servers: servers, choice: 'b', preset: 'global', blockAds: false, engine: 'xray');
      expect(plan.groups, isEmpty);
      expect(plan.routing.proxyTarget, 'b');
      expect(plan.engines, ['xray']);
    });

    test('no server carries everything through zapret and nothing else', () {
      final plan = buildPlan(servers: servers, choice: 'bypass', preset: 'ru', blockAds: true, engine: '');
      expect(plan.outbounds.single.protocol, 'bypass');
      expect(plan.outbounds.single.bypass.splitPos, isNotEmpty);
      expect(plan.routing.proxyTarget, Sora.bypassId);
      expect(plan.groups, isEmpty);
    });

    test('group names never collide with server ids', () {
      expect(Sora.autoGroup, isNot(anyOf('a', 'b')));
      expect(Sora.autoGroup.startsWith('sora:'), isTrue);
    });
  });

  group('settings', () {
    setUp(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

    test('a first start records the format and keeps the defaults', () async {
      final settings = await Settings.load();
      expect(settings.server, 'auto');
      expect(settings.blockAds, isTrue);
      expect(settings.killSwitch, isFalse);
      expect(settings.animations, isTrue);
      expect(settings.engine, isEmpty);
      expect(['global', 'ru', 'ir', 'cn'], contains(settings.preset));
    });

    test('a stored choice survives a restart', () async {
      final first = await Settings.load();
      first
        ..preset = 'cn'
        ..server = 'b'
        ..animations = false;
      await Future<void>.delayed(Duration.zero);
      final second = await Settings.load();
      expect(second.preset, 'cn');
      expect(second.server, 'b');
      expect(second.animations, isFalse);
    });
  });

  test('bytes read as people read them', () {
    final s = SRu();
    expect(formatBytes(s, Int64(512), 'ru'), '512 Б');
    expect(formatBytes(s, Int64(1536), 'ru'), '1,5 КБ');
    expect(formatBytes(s, Int64(107374182400), 'ru'), '100 ГБ');
    expect(formatBytes(s, Int64(14173392076), 'ru'), '13,2 ГБ');
  });

  test('every failure reads as words, never as a catalog key', () {
    final s = SRu();
    for (final key in [
      'app.core_unavailable',
      'app.no_servers',
      'core.plan.tunnel_unsupported',
      'core.subscription.fetch_failed',
      'core.plan.groups_invalid',
      'core.something.new',
    ]) {
      final text = describe(s, CoreFailure(key));
      expect(text, isNot(contains('core.')), reason: key);
      expect(text, isNotEmpty, reason: key);
    }
    expect(describe(s, const CoreFailure('core.plan.tunnel_unsupported')), s.errTunnel);
  });

  testWidgets('without a core the home screen says so and stays still', (tester) async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    tester.platformDispatcher.localesTestValue = const [Locale('ru')];
    late Sora sora;
    await tester.runAsync(() async => sora = Sora(await Settings.load()));
    await tester.pumpWidget(SoraApp(sora: sora));
    await tester.pumpAndSettle();
    expect(find.text(SRu().coreMissing), findsOneWidget);
    expect(find.text(SRu().addSubscription), findsOneWidget);
    sora.dispose();
  });
}
