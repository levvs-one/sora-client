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
    late Settings settings;
    setUp(() async {
      SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
      settings = await Settings.load();
    });

    test('the fastest server is a url-test group the routing points at', () {
      settings
        ..preset = 'ru'
        ..blockAds = true;
      final plan = buildPlan(servers: servers, choice: 'auto', settings: settings);
      expect(plan.tunnelMode, TunnelMode.TUNNEL_MODE_SYSTEM);
      expect(plan.outbounds.map((o) => o.id), ['a', 'b']);
      expect(plan.groups.single.name, Sora.autoGroup);
      expect(plan.groups.single.type, GroupType.GROUP_TYPE_URL_TEST);
      expect(plan.groups.single.members, ['a', 'b']);
      expect(plan.routing.proxyTarget, Sora.autoGroup);
      expect(plan.routing.preset, 'ru');
      expect(plan.routing.blockAds, isTrue);
      expect(plan.engines, isEmpty, reason: 'an empty preference lets the core choose');
      expect(plan.dnsPolicy.servers, isEmpty, reason: 'no resolvers take the core defaults');
      expect(plan.ipv6, isFalse);
      expect(plan.antiCensorship.tlsFragment, isFalse);
    });

    test('a picked server is the target, with no group, and the advanced choices travel', () {
      settings
        ..engine = 'xray'
        ..ipv6 = true
        ..dns = ['https://1.1.1.1/dns-query']
        ..fragment = true
        ..fragmentLength = '100-200';
      final plan = buildPlan(servers: servers, choice: 'b', settings: settings);
      expect(plan.groups, isEmpty);
      expect(plan.routing.proxyTarget, 'b');
      expect(plan.engines, ['xray']);
      expect(plan.ipv6, isTrue);
      expect(plan.dnsPolicy.servers, ['https://1.1.1.1/dns-query']);
      expect(plan.antiCensorship.tlsFragment, isTrue);
      expect(plan.antiCensorship.fragmentLength, '100-200');
    });

    test('no server carries everything through zapret with the chosen strategy', () {
      settings
        ..splitPos = ['2', 'sniext+1']
        ..disorder = false
        ..tlsRecord = 'sniext';
      final plan = buildPlan(servers: servers, choice: 'bypass', settings: settings);
      final bypass = plan.outbounds.single;
      expect(bypass.protocol, 'bypass');
      expect(bypass.bypass.splitPos, ['2', 'sniext+1']);
      expect(bypass.bypass.disorder, isFalse);
      expect(bypass.bypass.tlsRecord, 'sniext');
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

    test('reset forgets every choice', () async {
      final settings = await Settings.load();
      settings
        ..theme = 'dark'
        ..fragment = true;
      await Future<void>.delayed(Duration.zero);
      await settings.reset();
      expect(settings.theme, 'system');
      expect(settings.fragment, isFalse);
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
