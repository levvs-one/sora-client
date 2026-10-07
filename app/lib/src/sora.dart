import 'dart:async';

import 'package:fixnum/fixnum.dart';
import 'package:flutter/widgets.dart' hide ConnectionState;

import 'core/link.dart';
import 'generated/sora/core/v1/core_control.pbgrpc.dart';
import 'settings.dart';

/// Where the connection is, in the terms the interface shows.
enum Phase { offline, off, connecting, connected, reconnecting, disconnecting }

/// The state of the app and everything it asks the core to do. Screens read
/// it through [SoraScope] and rebuild when it notifies.
class Sora extends ChangeNotifier {
  Sora(this.settings);

  final Settings settings;

  /// Group names never collide with server ids, which the core derives from
  /// the server itself and never starts with "sora:".
  static const autoGroup = 'sora:auto';
  static const bypassId = 'sora:bypass';

  CoreLink? _link;
  bool _disposed = false;
  StreamSubscription<SubscriptionState>? _subscriptionWatch;
  StreamSubscription<CoreEvent>? _sessionWatch;

  /// Ends the current line to the core when a call finds it gone.
  void Function(Object error) _drop = (_) {};

  Phase phase = Phase.offline;
  DateTime? since;
  String? sessionId;

  /// The last failure worth showing, cleared by the next action.
  CoreFailure? failure;

  final Map<String, SubscriptionState> _subscriptions = {};
  List<SubscriptionState> get subscriptions => _subscriptions.values.toList();

  /// Latency of each server in milliseconds; null where it did not answer.
  final Map<String, int?> latency = {};
  bool probing = false;

  /// Every server of every subscription, each id once, in list order.
  List<OutboundSpec> get servers {
    final seen = <String>{};
    return [
      for (final s in _subscriptions.values)
        for (final o in s.outbounds)
          if (seen.add(o.id)) o,
    ];
  }

  /// The server the person picked, falling back to the fastest when the one
  /// they picked left its subscription.
  String get selected {
    final chosen = settings.server;
    if (chosen == 'auto' || chosen == 'bypass') return chosen;
    return servers.any((o) => o.id == chosen) ? chosen : 'auto';
  }

  String nameOf(String id) =>
      servers.firstWhere((o) => o.id == id, orElse: () => OutboundSpec(displayName: id)).displayName;

  bool get busy => phase == Phase.connecting || phase == Phase.disconnecting;

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  /// Keeps a line to the core for as long as the app runs: opens it, follows
  /// the subscriptions and the session, and opens it again when it drops.
  Future<void> run() async {
    while (!_disposed) {
      final link = await CoreLink.open();
      if (_disposed) {
        await link.close();
        return;
      }
      _link = link;
      final dropped = Completer<void>();
      _drop = (error) {
        if (!dropped.isCompleted && CoreFailure.from(error).key == CoreFailure.unavailable.key) dropped.complete();
      };
      try {
        await _readStatus();
        _watchSubscriptions();
        _watchSession();
        notifyListeners();
        await dropped.future;
      } catch (error) {
        failure = CoreFailure.from(error);
        notifyListeners();
        // A core that answers the handshake and then refuses keeps refusing;
        // asking again at once would only spin.
        await Future<void>.delayed(const Duration(seconds: 3));
      }
      await _cancelWatches();
      _link = null;
      await link.close();
      phase = Phase.offline;
      notifyListeners();
    }
  }

  Future<void> _cancelWatches() async {
    await _subscriptionWatch?.cancel();
    await _sessionWatch?.cancel();
    _subscriptionWatch = _sessionWatch = null;
  }

  Future<void> _readStatus() async {
    final link = _link!;
    final answer = await link.stub.getStatus(GetStatusRequest(apiVersion: apiVersion));
    _applyState(answer.status.connection);
  }

  void _applyState(ConnectionState state) {
    phase = switch (state.value) {
      ConnectionStateValue.CONNECTION_STATE_VALUE_CONNECTING => Phase.connecting,
      ConnectionStateValue.CONNECTION_STATE_VALUE_CONNECTED => Phase.connected,
      ConnectionStateValue.CONNECTION_STATE_VALUE_RECONNECTING => Phase.reconnecting,
      _ => Phase.off,
    };
    sessionId = phase == Phase.off || state.sessionId.isEmpty ? null : state.sessionId;
    since = state.hasChangedAt() ? state.changedAt.toDateTime() : null;
    if (state.value == ConnectionStateValue.CONNECTION_STATE_VALUE_FAILED &&
        state.reason != SoraErrorCode.SORA_ERROR_CODE_UNSPECIFIED) {
      // The answer of the call that failed names the cause better than the
      // code the state carries, so it is kept when there is one.
      failure ??= CoreFailure(_keyOfCode(state.reason));
    }
  }

  static String _keyOfCode(SoraErrorCode code) => switch (code) {
    SoraErrorCode.SORA_ERROR_CODE_DEADLINE_EXCEEDED => 'core.network.timeout',
    SoraErrorCode.SORA_ERROR_CODE_UNAVAILABLE => 'core.network.failed',
    SoraErrorCode.SORA_ERROR_CODE_PERMISSION_DENIED => 'core.plan.tunnel_unsupported',
    _ => 'core.engine.stopped',
  };

  void _watchSubscriptions() {
    final link = _link!;
    final stream = link.stub.watchSubscriptions(
      WatchSubscriptionsRequest(apiVersion: apiVersion, controlAuthenticator: link.token),
    );
    _subscriptionWatch = stream.listen((state) {
      final id = state.settings.id;
      if (state.deleted) {
        _subscriptions.remove(id);
      } else {
        _subscriptions[id] = state;
      }
      notifyListeners();
    }, onError: _drop);
  }

  /// Follows the running session, replacing the watch of an earlier one.
  void _watchSession() {
    unawaited(_sessionWatch?.cancel());
    _sessionWatch = null;
    final link = _link, id = sessionId;
    if (link == null || id == null) return;
    // The session ended or was replaced: the status says which.
    void resync() {
      if (_link == link) unawaited(_readStatus().then((_) => notifyListeners(), onError: _drop));
    }

    final stream = link.stub.watchEvents(WatchEventsRequest(apiVersion: apiVersion, sessionId: id));
    _sessionWatch = stream.listen(
      (event) {
        if (event.hasStateChanged()) {
          _applyState(event.stateChanged.state);
          notifyListeners();
        }
      },
      onError: (Object error) {
        _drop(error);
        resync();
      },
      onDone: resync,
    );
  }

  /// Connects when off and disconnects when on.
  Future<void> toggle() async {
    if (phase == Phase.off) {
      await connect();
    } else if (phase == Phase.connected || phase == Phase.reconnecting || phase == Phase.connecting) {
      await disconnect();
    }
  }

  Future<void> connect() async {
    final link = _link;
    if (link == null) return;
    failure = null;
    if (selected != 'bypass' && servers.isEmpty) {
      failure = const CoreFailure('app.no_servers');
      notifyListeners();
      return;
    }
    phase = Phase.connecting;
    notifyListeners();
    try {
      final answer = await link.stub.connect(
        ConnectRequest(
          apiVersion: apiVersion,
          sessionPlan: buildPlan(
            servers: servers,
            choice: selected,
            preset: settings.preset,
            blockAds: settings.blockAds,
            engine: settings.engine,
          ),
          controlAuthenticator: link.token,
        ),
      );
      if (answer.hasError()) throw CoreFailure(answer.error.userMessageKey);
      _applyState(answer.status.connection);
      if (settings.killSwitch && sessionId != null) {
        final kill = await link.stub.setKillSwitch(
          SetKillSwitchRequest(apiVersion: apiVersion, sessionId: sessionId, enabled: true),
        );
        if (kill.hasError()) failure = CoreFailure(kill.error.userMessageKey);
      }
      _watchSession();
    } catch (error) {
      failure = CoreFailure.from(error);
      await _readStatus().catchError((Object _) {});
      if (phase == Phase.connecting) phase = Phase.off;
    }
    notifyListeners();
  }

  Future<void> disconnect() async {
    final link = _link;
    if (link == null) return;
    failure = null;
    phase = Phase.disconnecting;
    notifyListeners();
    try {
      final answer = await link.stub.disconnect(
        DisconnectRequest(apiVersion: apiVersion, sessionId: sessionId ?? '', controlAuthenticator: link.token),
      );
      if (answer.hasError()) throw CoreFailure(answer.error.userMessageKey);
      _applyState(answer.status.connection);
    } catch (error) {
      failure = CoreFailure.from(error);
      await _readStatus().catchError((Object _) {});
    }
    notifyListeners();
  }

  /// Applies a change of plan at once when connected, so a new server or
  /// preset takes effect without a second press.
  Future<void> _replan() async {
    if (phase == Phase.connected || phase == Phase.reconnecting) await connect();
  }

  Future<void> select(String server) async {
    if (settings.server == server) return;
    settings.server = server;
    notifyListeners();
    await _replan();
  }

  Future<void> setPreset(String preset) async {
    settings.preset = preset;
    notifyListeners();
    await _replan();
  }

  Future<void> setBlockAds(bool value) async {
    settings.blockAds = value;
    notifyListeners();
    await _replan();
  }

  Future<void> setEngine(String engine) async {
    settings.engine = engine;
    notifyListeners();
    await _replan();
  }

  Future<void> setKillSwitch(bool value) async {
    settings.killSwitch = value;
    notifyListeners();
    final link = _link, id = sessionId;
    if (link == null || id == null) return;
    try {
      final answer = await link.stub.setKillSwitch(
        SetKillSwitchRequest(apiVersion: apiVersion, sessionId: id, enabled: value),
      );
      if (answer.hasError()) throw CoreFailure(answer.error.userMessageKey);
    } catch (error) {
      failure = CoreFailure.from(error);
      notifyListeners();
    }
  }

  void setAnimations(bool value) {
    settings.animations = value;
    notifyListeners();
  }

  /// Saves a new subscription; the core fetches it and announces the servers
  /// through the watch. Returns the failure to show next to the field.
  Future<CoreFailure?> addSubscription(String url) async {
    final link = _link;
    if (link == null) return CoreFailure.unavailable;
    try {
      final answer = await link.stub.saveSubscription(
        SaveSubscriptionRequest(
          apiVersion: apiVersion,
          controlAuthenticator: link.token,
          settings: SubscriptionSettings(url: url.trim(), autoUpdate: true),
        ),
      );
      if (answer.hasError()) return CoreFailure(answer.error.userMessageKey);
      _subscriptions[answer.state.settings.id] = answer.state;
      notifyListeners();
      return null;
    } catch (error) {
      return CoreFailure.from(error);
    }
  }

  Future<CoreFailure?> renameSubscription(SubscriptionState state, String name) => _call(() async {
    final link = _link!;
    final settings = state.settings.deepCopy()
      ..name = name.trim()
      ..url = '';
    final answer = await link.stub.saveSubscription(
      SaveSubscriptionRequest(apiVersion: apiVersion, controlAuthenticator: link.token, settings: settings),
    );
    if (answer.hasError()) throw CoreFailure(answer.error.userMessageKey);
  });

  Future<CoreFailure?> refreshSubscription(String id) => _call(() async {
    final link = _link!;
    final answer = await link.stub.refreshSubscription(
      RefreshSubscriptionRequest(apiVersion: apiVersion, controlAuthenticator: link.token, id: id),
    );
    if (answer.hasError()) throw CoreFailure(answer.error.userMessageKey);
  });

  Future<CoreFailure?> deleteSubscription(String id) => _call(() async {
    final link = _link!;
    final answer = await link.stub.deleteSubscription(
      DeleteSubscriptionRequest(apiVersion: apiVersion, controlAuthenticator: link.token, id: id),
    );
    if (answer.hasError()) throw CoreFailure(answer.error.userMessageKey);
    _subscriptions.remove(id);
    notifyListeners();
  });

  /// Runs a request and answers with its failure, which is also kept to show.
  Future<CoreFailure?> _call(Future<void> Function() body) async {
    if (_link == null) return CoreFailure.unavailable;
    failure = null;
    try {
      await body();
      return null;
    } catch (error) {
      failure = CoreFailure.from(error);
      notifyListeners();
      return failure;
    }
  }

  /// Measures every server through an engine where one carries it; results
  /// arrive one by one as they finish.
  Future<void> probe() async {
    final link = _link;
    final all = servers;
    if (link == null || probing || all.isEmpty) return;
    probing = true;
    notifyListeners();
    try {
      await for (final r in link.stub.probeServers(ProbeServersRequest(apiVersion: apiVersion, outbounds: all))) {
        latency[r.serverId] = r.reachable ? r.latencyMs : null;
        notifyListeners();
      }
    } catch (_) {
      // A measurement that stopped halfway leaves the values it got; the
      // rest stay unknown rather than marked as failures.
    }
    probing = false;
    notifyListeners();
  }

  /// The client for screens that talk to the core themselves, such as the
  /// log, with the token they need. Null while the core is out of reach.
  CoreLink? get link => _link;

  /// Bytes as one short number with a unit, in steps of 1024.
  static (double, int) scaleBytes(Int64 bytes) {
    var value = bytes.toDouble();
    var unit = 0;
    while (value >= 1024 && unit < 4) {
      value /= 1024;
      unit++;
    }
    return (value, unit);
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_cancelWatches());
    unawaited(_link?.close());
    super.dispose();
  }
}

/// The plan for a connection: every server, and what carries the traffic the
/// routing preset does not send direct. [choice] is "auto" for the fastest
/// server, picked by the core, "bypass" for no server at all, or a server id.
SessionPlan buildPlan({
  required List<OutboundSpec> servers,
  required String choice,
  required String preset,
  required bool blockAds,
  required String engine,
}) {
  final plan = SessionPlan(
    tunnelMode: TunnelMode.TUNNEL_MODE_SYSTEM,
    engines: [if (engine.isNotEmpty) engine],
    routing: RoutingOptions(preset: preset, blockAds: blockAds),
  );
  if (choice == 'bypass') {
    // zapret's tpws carries every connection directly, with the handshake
    // split the way the interop test runs real traffic through it.
    plan.outbounds.add(
      OutboundSpec(
        id: Sora.bypassId,
        displayName: 'zapret',
        protocol: 'bypass',
        bypass: BypassStrategy(splitPos: ['1', 'midsld'], disorder: true, hostCase: true),
      ),
    );
    plan.routing.proxyTarget = Sora.bypassId;
    return plan;
  }
  plan.outbounds.addAll(servers);
  if (choice == 'auto') {
    plan.groups.add(
      GroupSpec(
        name: Sora.autoGroup,
        type: GroupType.GROUP_TYPE_URL_TEST,
        members: [for (final o in servers) o.id],
        toleranceMs: 50,
      ),
    );
    plan.routing.proxyTarget = Sora.autoGroup;
  } else {
    plan.routing.proxyTarget = choice;
  }
  return plan;
}

/// Hands [Sora] to the widgets below and rebuilds them when it changes.
class SoraScope extends InheritedNotifier<Sora> {
  const SoraScope({super.key, required Sora sora, required super.child}) : super(notifier: sora);

  static Sora of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<SoraScope>()!.notifier!;

  /// For callbacks, which must not subscribe to changes.
  static Sora read(BuildContext context) => context.getInheritedWidgetOfExactType<SoraScope>()!.notifier!;
}
