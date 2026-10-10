import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sora/l10n/strings_ru.dart';
import 'package:sora/l10n/strings.dart';
import 'package:sora/src/design/theme.dart';
import 'package:sora/src/ui/subscription.dart';
import 'package:sora/main.dart';
import 'package:sora/src/core/link.dart';
import 'package:sora/src/generated/sora/core/v1/core_control.pb.dart';
import 'package:sora/src/groups.dart';
import 'package:sora/src/rules.dart';
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

    test('a profile runs alone, and the fastest of profiles is picked when there is nothing else', () {
      final profiles = [
        OutboundSpec(id: 'p1', displayName: 'NL', protocol: 'xray-profile'),
        OutboundSpec(id: 'p2', displayName: 'DE', protocol: 'xray-profile'),
      ];
      final picked = buildPlan(servers: [...servers, ...profiles], choice: 'p2', settings: settings);
      expect(picked.outbounds.map((o) => o.id), ['p2']);
      expect(picked.groups, isEmpty);
      expect(picked.routing.proxyTarget, 'p2');

      final mixed = buildPlan(servers: [...servers, ...profiles], choice: 'auto', settings: settings);
      expect(mixed.outbounds.map((o) => o.id), ['a', 'b'], reason: 'the fastest is chosen among ordinary servers');
      expect(mixed.groups.single.members, ['a', 'b']);

      final onlyProfiles = buildPlan(
        servers: profiles,
        choice: 'auto',
        settings: settings,
        latency: {'p1': 300, 'p2': 70},
      );
      expect(onlyProfiles.outbounds.single.id, 'p2');
    });

    test('a control port is asked for only when the person allowed one', () {
      expect(buildPlan(servers: servers, choice: 'auto', settings: settings).networkControlAllowed, isFalse);
      settings.controlPort = true;
      expect(buildPlan(servers: servers, choice: 'auto', settings: settings).networkControlAllowed, isTrue);
    });

    test('the person\'s rules come first, and failover keeps the picked server first', () {
      settings
        ..rules = ['direct domain:bank.ru', 'proxy process:telegram', 'block 203.0.113.0/24']
        ..failover = true;
      final plan = buildPlan(servers: servers, choice: 'b', settings: settings, latency: {'a': 40, 'b': 90});
      expect(plan.groups.single.name, Sora.failoverGroup);
      expect(plan.groups.single.type, GroupType.GROUP_TYPE_FALLBACK);
      expect(plan.groups.single.members, ['b', 'a']);
      expect(plan.routing.proxyTarget, Sora.failoverGroup);
      expect(plan.routes.map((r) => '${r.destination}>${r.outboundId}'), [
        'domain:bank.ru>direct',
        'process:telegram>${Sora.failoverGroup}',
        '203.0.113.0/24>reject',
      ]);
      settings.engine = 'sing-box';
      expect(
        buildPlan(servers: servers, choice: 'b', settings: settings).groups,
        isEmpty,
        reason: 'only mihomo has fallback groups; a pinned engine keeps the picked server alone',
      );
    });

    test('group names never collide with server ids', () {
      expect(Sora.autoGroup, isNot(anyOf('a', 'b')));
      expect(Sora.autoGroup.startsWith('sora:'), isTrue);
    });

    test('mihomo TUN stack survives only in its own TUN plans', () {
      settings.mihomoTunStack = 'mips';
      for (final engine in ['', 'sing-box', 'xray', 'mihomo']) {
        settings.engine = engine;
        expect(buildPlan(servers: servers, choice: 'a', settings: settings).tunStack, engine == 'mihomo' ? 'mips' : '');
      }
      settings.tunnel = 'proxy';
      expect(buildPlan(servers: servers, choice: 'a', settings: settings).tunStack, isEmpty);
      settings.tunnel = 'tun';
      expect(buildPlan(servers: servers, choice: 'bypass', settings: settings).tunStack, isEmpty);
      expect(settings.mihomoTunStack, 'mips');
      settings.mihomoTunStack = 'unsupported';
      expect(settings.mihomoTunStack, 'mixed');
    });

    test('Xray stacks stay isolated and native gVisor works with older cores', () {
      expect(settings.xrayTunStack, 'gvisor');
      settings.engine = 'xray';
      expect(buildPlan(servers: servers, choice: 'a', settings: settings).tunStack, isEmpty);
      settings.xrayTunStack = 'system';
      settings.mihomoTunStack = 'mips';
      for (final engine in ['', 'sing-box', 'xray', 'mihomo']) {
        settings.engine = engine;
        expect(buildPlan(servers: servers, choice: 'a', settings: settings).tunStack, switch (engine) {
          'xray' => 'system',
          'mihomo' => 'mips',
          _ => '',
        });
      }
      settings.engine = 'xray';
      settings.tunnel = 'proxy';
      expect(buildPlan(servers: servers, choice: 'a', settings: settings).tunStack, isEmpty);
      settings.tunnel = 'tun';
      expect(buildPlan(servers: servers, choice: 'bypass', settings: settings).tunStack, isEmpty);
      settings.xrayTunStack = 'unknown';
      expect(settings.xrayTunStack, 'gvisor');
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
      expect(settings.theme, 'light');
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
    await sora.settings.completeTour();
    await tester.pumpWidget(SoraApp(sora: sora));
    await tester.pumpAndSettle();
    expect(find.text(SRu().coreMissing), findsOneWidget);
    expect(find.text(SRu().addSubscription), findsWidgets);
    sora.dispose();
  });

  testWidgets('subscription page tile and menu exist without provider metadata', (tester) async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final sora = _SubscriptionSora(await Settings.load());
    addTearDown(sora.dispose);
    Widget screen(Widget child) => SoraScope(
      sora: sora,
      child: MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        theme: buildTheme(Brightness.light),
        home: child,
      ),
    );
    await tester.pumpWidget(screen(const SubscriptionScreen(id: 'subscription-id')));
    await tester.pumpAndSettle();
    expect(find.text('Сайт подписки'), findsOneWidget);
    expect(find.text('Сайт провайдера'), findsNothing);
    await tester.tap(find.text('Сайт подписки'));
    expect(sora.opened, ['subscription-id']);

    await tester.pumpWidget(screen(const ServersScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Symbols.more_horiz_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Сайт подписки'), findsOneWidget);
    expect(find.text('Сайт провайдера'), findsNothing);
    await tester.tap(find.text('Сайт подписки'));
    await tester.pumpAndSettle();
    expect(sora.opened, ['subscription-id', 'subscription-id']);
  });

  test('what a person types becomes a rule', () {
    expect(UserRule.destinationOf('bank.ru'), 'domain:bank.ru');
    expect(UserRule.destinationOf('*.Bank.RU'), 'domain:bank.ru');
    expect(UserRule.destinationOf('https://www.youtube.com/watch?v=1'), 'domain:www.youtube.com');
    expect(UserRule.destinationOf('1.2.3.4'), '1.2.3.4/32');
    expect(UserRule.destinationOf('10.0.0.0/8'), '10.0.0.0/8');
    expect(UserRule.destinationOf('2001:db8::1'), '2001:db8::1/128');
    expect(UserRule.destinationOf('telegram-desktop'), 'process:telegram-desktop');
    expect(UserRule.destinationOf('Telegram.exe'), 'process:Telegram.exe', reason: 'Windows names programs with .exe');
    for (final bad in ['', 'two words', '10.0.0.0/40', 'bad_host.ru']) {
      expect(UserRule.destinationOf(bad), isNull, reason: bad);
    }
    final rule = UserRule.parse('proxy process:telegram')!;
    expect(rule.target, RuleTarget.proxy);
    expect(rule.shown, 'telegram');
    expect(UserRule.parse('unknown x'), isNull);
  });

  group('named groups', () {
    SubscriptionState sub(List<OutboundSpec> servers) => SubscriptionState(
      settings: SubscriptionSettings(id: 's1'),
      outbounds: servers,
    );
    OutboundSpec server(String id, String name, [String protocol = 'vless']) =>
        OutboundSpec(id: id, displayName: name, protocol: protocol);

    test('a role at the end of a name is read in either language and shape', () {
      expect(splitRole('Нидерланды (основной)'), ('Нидерланды', Role.main));
      expect(splitRole('Нидерланды \u00b7 запасной'), ('Нидерланды', Role.backup));
      expect(splitRole('🇳🇱 Netherlands [backup]'), ('🇳🇱 Netherlands', Role.backup));
      expect(splitRole('Germany - primary'), ('Germany', Role.main));
      expect(splitRole('Белые списки \u00b7 main'), ('Белые списки', Role.main));
      expect(splitRole('Белые списки: РЕЗЕРВНЫЙ'), ('Белые списки', Role.backup));
      expect(splitRole('Netherlands (Fallback)'), ('Netherlands', Role.backup));
      expect(splitRole('Германия \u2014 главный'), ('Германия', Role.main));
      expect(splitRole('Белые списки +'), ('Белые списки +', null));
      expect(splitRole('Main'), ('Main', null), reason: 'a name that is only a role keeps it');
    });

    test('servers sharing a name are one entry; others stay alone', () {
      final entries = entriesOf(
        sub([
          server('a', 'Нидерланды (основной)'),
          server('b', 'Нидерланды (запасной)'),
          server('c', 'Германия'),
          server('d', 'Польша'),
          server('e', 'Польша'),
        ]),
      );
      expect(entries.map((e) => e.name), ['Нидерланды', 'Германия', 'Польша']);
      final nl = entries[0], pl = entries[2];
      expect(nl.isGroup && nl.ordered, isTrue);
      expect(nl.byRole.map((o) => o.id), ['a', 'b']);
      expect(pl.isGroup && !pl.ordered, isTrue);
      expect(entries[1].id, 'c');
      expect(
        entryOf(nl.id, [
          sub([server('a', 'Нидерланды (основной)'), server('b', 'Нидерланды (запасной)')]),
        ])?.name,
        'Нидерланды',
      );
    });

    test('ordered servers become a fallback group on mihomo, the main ones alone elsewhere', () async {
      SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
      final settings = await Settings.load();
      final servers = [server('b', 'NL (backup)'), server('a', 'NL (main)'), server('c', 'DE')];
      final nl = entriesOf(sub(servers)).first;
      var plan = buildPlan(servers: servers, choice: nl.id, settings: settings, entry: nl);
      expect(plan.groups.single.type, GroupType.GROUP_TYPE_FALLBACK);
      expect(plan.groups.single.members, ['a', 'b'], reason: 'the main one first, whatever the list order');
      expect(plan.routing.proxyTarget, Sora.entryGroup);
      settings.engine = 'xray';
      plan = buildPlan(servers: servers, choice: nl.id, settings: settings, entry: nl);
      expect(plan.groups.single.type, GroupType.GROUP_TYPE_URL_TEST);
      expect(plan.groups.single.members, ['a']);
    });

    test('of profiles one runs: the main one that answers, or the fastest', () async {
      SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
      final settings = await Settings.load();
      final ordered = entriesOf(
        sub([server('m', 'NL (основной)', 'xray-profile'), server('r', 'NL (запасной)', 'xray-profile')]),
      ).single;
      expect(pickMember(ordered, {}).id, 'm');
      expect(pickMember(ordered, {'m': null}).id, 'r', reason: 'a main one measured unreachable is passed over');
      final plan = buildPlan(servers: ordered.members, choice: ordered.id, settings: settings, entry: ordered);
      expect(plan.outbounds.single.id, 'm');
      final best = entriesOf(sub([server('x', 'PL', 'xray-profile'), server('y', 'PL', 'xray-profile')])).single;
      expect(pickMember(best, {'x': 90, 'y': 40}).id, 'y');
      expect(pickMember(best, {'x': 90, 'y': null}).id, 'x');
    });
  });
}

class _SubscriptionSora extends Sora {
  _SubscriptionSora(super.settings);

  final opened = <String>[];

  @override
  List<SubscriptionState> get subscriptions => [
    SubscriptionState(
      settings: SubscriptionSettings(id: 'subscription-id'),
      displayName: 'Subscription',
    ),
  ];

  @override
  Future<CoreFailure?> openSubscriptionPage(String id) async {
    opened.add(id);
    return null;
  }
}
