import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart' show SizedBox;
import 'package:fixnum/fixnum.dart';
import 'package:grpc/grpc.dart' show Server, ServiceCall;
import 'package:sora/main.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sora/src/core/link.dart';
import 'package:sora/src/generated/sora/core/v1/core_control.pbgrpc.dart';
import 'package:sora/src/settings.dart';
import 'package:sora/src/sora.dart';
import 'package:sora/src/ui/logs.dart';

import 'desktop_shell_test.dart' show section;

class _Core extends CoreControlServiceBase {
  ConnectionState state = ConnectionState(value: ConnectionStateValue.CONNECTION_STATE_VALUE_DISCONNECTED);
  Completer<void>? gate;
  bool reject = false;
  bool failCleanup = false;
  bool failStartCleanup = false;
  int minor = 7;
  int connects = 0, disconnects = 0, busyReplies = 0;
  final kills = <bool>[];
  final probeRequests = <ProbeServersRequest>[];
  Completer<void>? probeGate;
  final subscriptions = [
    SubscriptionState(
      settings: SubscriptionSettings(id: 'first'),
      outbounds: [
        OutboundSpec(id: 'a'),
        OutboundSpec(id: 'b'),
      ],
    ),
    SubscriptionState(
      settings: SubscriptionSettings(id: 'second'),
      outbounds: [OutboundSpec(id: 'c')],
    ),
  ];
  SessionPlan? plan;
  final events = StreamController<CoreEvent>.broadcast();
  final logs = StreamController<LogEntry>.broadcast();

  Future<void> close() async {
    await events.close();
    await logs.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError('${invocation.memberName}');

  @override
  Future<HandshakeResponse> handshake(ServiceCall call, HandshakeRequest request) async => HandshakeResponse(
    negotiatedVersion: apiVersion.deepCopy()..minor = minor,
    controlAuthenticator: List.filled(32, 1),
  );

  @override
  Future<GetAboutResponse> getAbout(ServiceCall call, GetAboutRequest request) async =>
      GetAboutResponse(about: About(contract: apiVersion.deepCopy()..capabilities.add('serverless')));

  @override
  Future<GetStatusResponse> getStatus(ServiceCall call, GetStatusRequest request) async =>
      GetStatusResponse(status: SessionStatus(connection: state.deepCopy()));

  @override
  Future<GetStatsResponse> getStats(ServiceCall call, GetStatsRequest request) async =>
      GetStatsResponse(stats: StatsTick());

  @override
  Stream<SubscriptionState> watchSubscriptions(ServiceCall call, WatchSubscriptionsRequest request) =>
      Stream.fromIterable(subscriptions);

  @override
  Stream<ProbeResult> probeServers(ServiceCall call, ProbeServersRequest request) async* {
    probeRequests.add(request);
    await probeGate?.future;
    for (final outbound in request.outbounds) {
      yield ProbeResult(serverId: outbound.id, reachable: true, latencyMs: 42);
    }
  }

  @override
  Stream<CoreEvent> watchEvents(ServiceCall call, WatchEventsRequest request) => events.stream;

  @override
  Future<QueryLogsResponse> queryLogs(ServiceCall call, QueryLogsRequest request) async {
    return QueryLogsResponse(
      entries: [
        LogEntry(sequence: Int64(1), source: 'core', message: 'Service started', level: LogLevel.LOG_LEVEL_INFO),
      ],
    );
  }

  @override
  Stream<LogEntry> watchLogs(ServiceCall call, WatchLogsRequest request) => logs.stream;

  @override
  Future<ConnectResponse> connect(ServiceCall call, ConnectRequest request) async {
    connects++;
    plan = request.sessionPlan;
    await gate?.future;
    if (failStartCleanup) {
      state = ConnectionState(value: ConnectionStateValue.CONNECTION_STATE_VALUE_DISCONNECTED);
      return ConnectResponse(error: SoraError(userMessageKey: 'core.guard.restore_failed'));
    }
    if (reject) return ConnectResponse(error: SoraError(userMessageKey: 'core.engine.binary_missing'));
    state = ConnectionState(
      value: ConnectionStateValue.CONNECTION_STATE_VALUE_CONNECTED,
      sessionId: 'session-$connects',
    );
    return ConnectResponse(status: SessionStatus(connection: state.deepCopy()));
  }

  @override
  Future<DisconnectResponse> disconnect(ServiceCall call, DisconnectRequest request) async {
    disconnects++;
    if (busyReplies-- > 0) return DisconnectResponse(error: SoraError(userMessageKey: 'core.session.busy'));
    state = ConnectionState(value: ConnectionStateValue.CONNECTION_STATE_VALUE_DISCONNECTED);
    if (failCleanup) return DisconnectResponse(error: SoraError(userMessageKey: 'core.guard.restore_failed'));
    return DisconnectResponse(status: SessionStatus(connection: state.deepCopy()));
  }

  @override
  Future<SetKillSwitchResponse> setKillSwitch(ServiceCall call, SetKillSwitchRequest request) async {
    kills.add(request.enabled);
    return SetKillSwitchResponse();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final socket = Platform.environment['SORA_CORE_SOCKET'];
  final isolated = socket != null && socket.startsWith('/tmp/sora-race-');
  late _Core core;
  late Server server;
  late Sora sora;
  late Future<void> running;
  bool disposed = false;

  Future<void> until(bool Function() ready) async {
    final limit = DateTime.now().add(const Duration(seconds: 5));
    while (!ready()) {
      if (DateTime.now().isAfter(limit)) fail('state change timed out');
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
  }

  setUp(() async {
    if (!isolated) return;
    disposed = false;
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    core = _Core();
    server = Server.create(services: [core]);
    await server.serve(address: InternetAddress(socket, type: InternetAddressType.unix), port: 0);
    final settings = await Settings.load();
    settings.server = 'bypass';
    sora = Sora(settings);
    running = sora.run();
    await until(() => sora.serverlessAvailable && sora.servers.length == 3);
  });

  tearDown(() async {
    if (!isolated) return;
    if (core.gate case final gate? when !gate.isCompleted) gate.complete();
    if (core.probeGate case final gate? when !gate.isCompleted) gate.complete();
    if (!disposed) sora.dispose();
    try {
      await running.timeout(const Duration(seconds: 10));
    } finally {
      await server.shutdown();
      await core.close();
      if (await File(socket).exists()) await File(socket).delete();
    }
  });

  group('commands over an isolated RPC socket', () {
    testWidgets('logs opened before the service link arrives load and continue streaming', (tester) async {
      final waiting = Sora(sora.settings);
      await waiting.settings.completeTour();
      waiting.settings.animations = false;
      Future<void>? waitingWork;
      try {
        await tester.pumpWidget(SoraApp(sora: waiting));
        await section(tester, 4);
        expect(find.byType(LogsScreen), findsOneWidget);
        await tester.runAsync(() async {
          waitingWork = waiting.run();
          await until(() => waiting.serverlessAvailable);
        });
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        for (var i = 0; i < 30 && !core.logs.hasListener; i++) {
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(core.logs.hasListener, isTrue);
        await tester.pump();
        expect(find.text('Service started'), findsOneWidget);
        core.logs.add(
          LogEntry(sequence: Int64(2), source: 'xray', message: 'Engine started', level: LogLevel.LOG_LEVEL_INFO),
        );
        for (var i = 0; i < 30 && find.text('Engine started').evaluate().isEmpty; i++) {
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(find.text('Engine started'), findsOneWidget);
        expect(waiting.history, isEmpty);
      } finally {
        await tester.pumpWidget(const SizedBox());
        waiting.dispose();
        await tester.runAsync(() async => await waitingWork?.timeout(const Duration(seconds: 10)));
      }
    });

    test('subscription probing stays scoped and a click burst starts one request', () async {
      await until(() => sora.servers.length == 3);
      core.probeGate = Completer<void>();
      final probes = List.generate(30, (_) => sora.probe(subscriptionId: 'first'));
      await until(() => core.probeRequests.length == 1);
      expect(core.probeRequests.single.outbounds.map((o) => o.id), ['a', 'b']);
      expect(sora.probingSubscription, 'first');
      await sora.probe(subscriptionId: 'second');
      expect(core.probeRequests, hasLength(1));
      core.probeGate!.complete();
      await Future.wait(probes);
      expect(sora.latency, {'a': 42, 'b': 42});
      expect(sora.probing, isFalse);
      expect(sora.probingSubscription, isNull);
      await sora.probe(subscriptionId: 'missing');
      expect(core.probeRequests, hasLength(1));
      await sora.probe(subscriptionId: 'second');
      expect(core.probeRequests.last.outbounds.single.id, 'c');
      expect(sora.latency['c'], 42);
    });
    test('a click burst starts once, and disconnect wins while connecting', () async {
      core.gate = Completer<void>();
      final starts = List.generate(30, (_) => sora.connect());
      await until(() => core.connects == 1);
      final stops = List.generate(30, (_) => sora.disconnect());
      expect(sora.phase, Phase.disconnecting);
      expect(core.disconnects, 0);
      core.gate!.complete();
      await Future.wait([...starts, ...stops]);
      expect(core.connects, 1);
      expect(core.disconnects, 1);
      expect(sora.phase, Phase.off);
      expect(sora.sessionId, isNull);
      expect(sora.history, isEmpty);
    });

    test('settings during startup remain pending until explicit application', () async {
      core.gate = Completer<void>();
      final start = sora.connect();
      await until(() => core.connects == 1);
      await sora.change((s) => s.engine = 'xray');
      core.gate!.complete();
      await start;
      expect(sora.needsReconnect, isTrue);
      expect(core.connects, 1);
      core.gate = null;
      await sora.connect();
      expect(core.plan!.engines, ['xray']);
      expect(sora.needsReconnect, isFalse);
    });

    test('location clicks coalesce to the last choice while a replacement is starting', () async {
      await sora.select('a');
      await sora.connect();
      core.gate = Completer<void>();
      final first = sora.select('b');
      await until(() => core.connects == 2);
      final burst = List.generate(100, (i) => sora.select(['a', 'b', 'c'][i % 3]));
      core.gate!.complete();
      await Future.wait([first, ...burst]);
      expect(core.connects, 3);
      expect(core.plan!.groups.single.members.first, 'a');
      expect(sora.phase, Phase.connected);
      expect(sora.needsReconnect, isFalse);
      expect(sora.history, isEmpty);
    });

    test('explicit disconnect cancels queued location changes without restarting', () async {
      await sora.select('a');
      await sora.connect();
      core.gate = Completer<void>();
      final replacement = sora.select('b');
      await until(() => core.connects == 2);
      final choice = sora.select('c');
      final stop = sora.disconnect();
      core.gate!.complete();
      await Future.wait([replacement, choice, stop]);
      expect(core.connects, 2);
      expect(core.disconnects, 1);
      expect(sora.phase, Phase.off);
      expect(sora.history, isEmpty);
    });

    test('a location selected during the first connection applies automatically', () async {
      await sora.select('a');
      core.gate = Completer<void>();
      final start = sora.connect();
      await until(() => core.connects == 1);
      final choice = sora.select('c');
      core.gate!.complete();
      await Future.wait([start, choice]);
      expect(core.connects, 2);
      expect(core.plan!.groups.single.members.first, 'c');
      expect(sora.needsReconnect, isFalse);
    });

    test('an unsupported location keeps the working connection and reports the error once', () async {
      await sora.select('a');
      await sora.connect();
      final id = sora.sessionId;
      core.reject = true;
      await sora.select('b');
      expect(sora.phase, Phase.connected);
      expect(sora.sessionId, id);
      expect(core.disconnects, 0);
      expect(sora.history, hasLength(1));
    });

    for (final selectedEngine in ['mihomo', 'xray']) {
      test('$selectedEngine TUN stack click bursts are staged until one explicit reconnect', () async {
        await sora.change(
          (s) => s
            ..server = 'a'
            ..engine = selectedEngine,
        );
        await sora.connect();
        final original = selectedEngine == 'mihomo' ? 'mixed' : 'gvisor';
        void stack(Settings s, String value) {
          if (selectedEngine == 'mihomo') {
            s.mihomoTunStack = value;
          } else {
            s.xrayTunStack = value;
          }
        }

        expect(core.plan!.tunStack, selectedEngine == 'mihomo' ? 'mixed' : '');
        for (var i = 0; i < 50; i++) {
          await sora.change((s) => stack(s, i.isEven ? 'system' : 'mips'));
        }
        expect(core.connects, 1);
        expect(sora.needsReconnect, isTrue);
        await sora.change((s) => stack(s, original));
        expect(sora.needsReconnect, isFalse);
        await sora.change((s) => stack(s, 'mips'));
        core.gate = Completer<void>();
        final starts = List.generate(30, (_) => sora.connect());
        await until(() => core.connects == 2);
        final stop = sora.disconnect();
        core.gate!.complete();
        await Future.wait([...starts, stop]);
        expect(core.plan!.tunStack, 'mips');
        expect(core.connects, 2);
        expect(sora.phase, Phase.off);
      });
    }

    test('an older core cannot silently ignore an explicit stack', () async {
      await sora.connect();
      final active = sora.sessionId;
      core.minor = 6;
      await sora.link!.close();
      await until(
        () =>
            sora.link?.minor == 6 &&
            sora.phase == Phase.connected &&
            sora.serverlessAvailable &&
            core.events.hasListener,
      );
      await sora.change(
        (s) => s
          ..server = 'a'
          ..engine = 'mihomo'
          ..mihomoTunStack = 'system',
      );
      await sora.connect();
      expect(core.connects, 1);
      expect(core.disconnects, 0);
      expect(sora.sessionId, active);
      expect(sora.phase, Phase.connected);
      expect(sora.failure!.key, 'core.api.version_mismatch');
    });

    test('a rejected replacement preserves the tunnel and reports one failure', () async {
      await sora.connect();
      final id = sora.sessionId;
      for (var i = 0; i < 100; i++) {
        await sora.change((s) => s.engine = i.isEven ? 'xray' : 'mihomo');
      }
      expect(core.connects, 1);
      await sora.change((s) => s.engine = '');
      expect(sora.needsReconnect, isFalse, reason: 'reverting settings needs no reconnect');
      await sora.change((s) => s.engine = 'sing-box');
      core.reject = true;
      await sora.connect();
      expect(sora.phase, Phase.connected);
      expect(sora.sessionId, id);
      expect(sora.needsReconnect, isTrue);
      expect(sora.failure!.key, 'core.engine.binary_missing');
      expect(sora.history, hasLength(1));
      await sora.disconnect();
      expect(sora.phase, Phase.off);
    });

    test('disconnect retries a busy core without duplicate notices', () async {
      await sora.connect();
      core.busyReplies = 2;
      await sora.disconnect();
      expect(core.disconnects, 3);
      expect(sora.phase, Phase.off);
      expect(sora.history, isEmpty);
    });

    test('events from a replaced session cannot change the new session', () async {
      await sora.connect();
      final old = sora.sessionId!;
      await sora.connect();
      final current = sora.sessionId;
      await Future<void>.delayed(const Duration(milliseconds: 50));
      core.events.add(
        CoreEvent(
          sessionId: old,
          stateChanged: StateChanged(
            state: ConnectionState(
              sessionId: old,
              value: ConnectionStateValue.CONNECTION_STATE_VALUE_FAILED,
              reason: SoraErrorCode.SORA_ERROR_CODE_UNAVAILABLE,
            ),
          ),
        ),
      );
      core.events.add(
        CoreEvent(
          stateChanged: StateChanged(
            state: ConnectionState(sessionId: old, value: ConnectionStateValue.CONNECTION_STATE_VALUE_DISCONNECTED),
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(sora.phase, Phase.connected);
      expect(sora.sessionId, current);
      expect(sora.history, isEmpty);
    });

    test('a failed cleanup stays retryable even when the engine is already off', () async {
      await sora.connect();
      core.failCleanup = true;
      await sora.disconnect();
      expect(sora.phase, Phase.off);
      expect(sora.cleanupPending, isTrue);
      core.failCleanup = false;
      await sora.toggle();
      expect(core.connects, 1);
      expect(core.disconnects, 2);
      expect(sora.cleanupPending, isFalse);
      expect(sora.phase, Phase.off);
    });

    test('kill-switch clicks during connect apply only the final requested value', () async {
      core.gate = Completer<void>();
      final start = sora.connect();
      await until(() => core.connects == 1);
      await Future.wait(List.generate(31, (i) => sora.setKillSwitch(i.isEven)));
      expect(core.kills, isEmpty);
      core.gate!.complete();
      await start;
      expect(core.kills, [true]);
      await sora.disconnect();
      expect(sora.phase, Phase.off);
    });

    test('a failed startup with retained settings offers disconnect before another start', () async {
      core.failStartCleanup = true;
      await sora.connect();
      expect(sora.phase, Phase.off);
      expect(sora.cleanupPending, isTrue);
      expect(sora.failure!.key, 'core.guard.restore_failed');
      await sora.toggle();
      expect(core.connects, 1);
      expect(core.disconnects, 1);
      expect(sora.cleanupPending, isFalse);
      expect(sora.phase, Phase.off);
    });

    test('closing the app during startup does not publish late notices', () async {
      core.gate = Completer<void>();
      final start = sora.connect();
      await until(() => core.connects == 1);
      sora.dispose();
      disposed = true;
      core.gate!.complete();
      await start;
      await running.timeout(const Duration(seconds: 5));
      expect(sora.history, isEmpty);
    });
  }, skip: isolated ? false : 'run with SORA_CORE_SOCKET=/tmp/sora-race-unique.sock');
}
