import 'dart:async';

import 'package:fixnum/fixnum.dart';
import 'package:flutter/widgets.dart' hide ConnectionState;

import 'core/link.dart';
import 'generated/sora/core/v1/core_control.pbgrpc.dart';
import 'groups.dart';
import 'rules.dart';
import 'settings.dart';

/// Where the connection is, in the terms the interface shows.
enum Phase { offline, off, connecting, connected, reconnecting, disconnecting }

/// Something that happened to the connection on its own, worth telling a
/// person who is not looking at the window.
sealed class Notice {
  const Notice();
}

/// The connection dropped and the core is bringing it back.
final class ConnectionLost extends Notice {
  const ConnectionLost();
}

/// The connection is back after a drop.
final class ConnectionRestored extends Notice {
  const ConnectionRestored();
}

/// The connection ended, or never came up, with [failure].
final class ConnectionFailed extends Notice {
  const ConnectionFailed(this.failure);

  final CoreFailure failure;
}

/// A server of the group [entry] failed and the next one took over;
/// [backup] when the names said which one is the backup.
final class ServerSwitched extends Notice {
  const ServerSwitched(this.entry, {required this.backup});

  final String entry;
  final bool backup;
}

/// The state of the app and everything it asks the core to do. Screens read
/// it through [SoraScope] and rebuild when it notifies.
class Sora extends ChangeNotifier {
  Sora(this.settings);

  final Settings settings;

  /// Group names never collide with server ids, which the core derives from
  /// the server itself and never starts with "sora:".
  static const autoGroup = 'sora:auto';
  static const bypassId = 'sora:bypass';
  static const failoverGroup = 'sora:failover';
  static const entryGroup = 'sora:group';

  CoreLink? _link;
  bool _disposed = false;
  bool _startedOnce = false;

  /// The profile of a named group the session runs, and how many other
  /// members are left to try when it fails.
  String? _member;
  int _memberSpare = 0;
  StreamSubscription<SubscriptionState>? _subscriptionWatch;
  StreamSubscription<CoreEvent>? _sessionWatch;

  /// Ends the current line to the core when a call finds it gone.
  void Function(Object error) _drop = (_) {};

  /// Set while the person ends the session, so its end is not news.
  bool _stopping = false;

  /// A drop was announced, so the return is worth announcing too.
  bool _lostAnnounced = false;

  final _notices = StreamController<Notice>.broadcast();

  /// What happened to the connection on its own.
  Stream<Notice> get notices => _notices.stream;

  /// Where the core's local proxy listens; the system proxy points here in
  /// the proxy mode. Null until the core said.
  Endpoint? localProxy;

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
    if (chosen.startsWith(groupPrefix)) return entryOf(chosen, _subscriptions.values) != null ? chosen : 'auto';
    return servers.any((o) => o.id == chosen) ? chosen : 'auto';
  }

  String nameOf(String id) => id.startsWith(groupPrefix)
      ? entryOf(id, _subscriptions.values)?.name ?? id
      : servers.firstWhere((o) => o.id == id, orElse: () => OutboundSpec(displayName: id)).displayName;

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
        await _readStatus(report: false);
        final about = await link.stub.getAbout(GetAboutRequest(apiVersion: apiVersion));
        localProxy = about.about.hasLocalProxy() ? about.about.localProxy : null;
        _watchSubscriptions();
        _watchSession();
        notifyListeners();
        if (settings.connectOnStart && !_startedOnce && phase == Phase.off) {
          // Once per launch: a line that drops and comes back must not
          // reconnect a person who disconnected on purpose.
          _startedOnce = true;
          // The servers arrive through the watch a moment after it opens.
          await Future<void>.delayed(const Duration(milliseconds: 600));
          if (phase == Phase.off) unawaited(connect());
        }
        _startedOnce = true;
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

  /// Reads where the session is. [report] shows a failure the state carries;
  /// on opening it is off, because a failure from before the window opened is
  /// not news to whoever just opened it.
  Future<void> _readStatus({bool report = true}) async {
    final link = _link!;
    final answer = await link.stub.getStatus(GetStatusRequest(apiVersion: apiVersion));
    _applyState(answer.status.connection, report: report);
  }

  void _applyState(ConnectionState state, {bool report = true}) {
    final before = phase;
    phase = switch (state.value) {
      ConnectionStateValue.CONNECTION_STATE_VALUE_CONNECTING => Phase.connecting,
      ConnectionStateValue.CONNECTION_STATE_VALUE_CONNECTED => Phase.connected,
      ConnectionStateValue.CONNECTION_STATE_VALUE_RECONNECTING => Phase.reconnecting,
      _ => Phase.off,
    };
    // Events of a session carry its state without its id, so an empty id
    // keeps the one already known; only the end of the session clears it.
    if (phase == Phase.off) {
      sessionId = null;
    } else if (state.sessionId.isNotEmpty) {
      sessionId = state.sessionId;
    }
    since = state.hasChangedAt() ? state.changedAt.toDateTime() : null;
    if (report &&
        state.value == ConnectionStateValue.CONNECTION_STATE_VALUE_FAILED &&
        _member != null &&
        _memberSpare > 0) {
      // The profile in use failed: mark it unreachable and run the next one
      // of its group, the way the core moves along a fallback group.
      latency[_member!] = null;
      _memberSpare--;
      final entry = entryOf(settings.server, _subscriptions.values);
      if (entry != null) _notices.add(ServerSwitched(entry.name, backup: entry.ordered));
      Future.microtask(() => connect(retry: true));
      return;
    }
    if (report &&
        state.value == ConnectionStateValue.CONNECTION_STATE_VALUE_FAILED &&
        state.reason != SoraErrorCode.SORA_ERROR_CODE_UNSPECIFIED) {
      // The answer of the call that failed names the cause better than the
      // code the state carries, so it is kept when there is one.
      failure ??= CoreFailure(_keyOfCode(state.reason));
    }
    if (report) _announce(before, state);
  }

  /// Tells listeners what the session did on its own: a drop, a return, an
  /// end nobody asked for.
  void _announce(Phase before, ConnectionState state) {
    if (before == Phase.connected && phase == Phase.reconnecting) {
      _lostAnnounced = true;
      _notices.add(const ConnectionLost());
    } else if (phase == Phase.connected && _lostAnnounced) {
      _lostAnnounced = false;
      _notices.add(const ConnectionRestored());
    } else if (phase == Phase.off && state.value == ConnectionStateValue.CONNECTION_STATE_VALUE_FAILED && !_stopping) {
      _lostAnnounced = false;
      _notices.add(ConnectionFailed(failure ?? CoreFailure(_keyOfCode(state.reason))));
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

  /// [retry] is set when a failed member of a named group hands over to the
  /// next one: the count of members left to try then carries on.
  Future<void> connect({bool retry = false}) async {
    final link = _link;
    if (link == null) return;
    failure = null;
    if (selected != 'bypass' && servers.isEmpty) {
      failure = const CoreFailure('app.no_servers');
      _notices.add(ConnectionFailed(failure!));
      notifyListeners();
      return;
    }
    final choice = selected;
    final entry = choice.startsWith(groupPrefix) ? entryOf(choice, _subscriptions.values) : null;
    final plan = buildPlan(servers: servers, choice: choice, settings: settings, latency: latency, entry: entry);
    // A group of profiles runs one member at a time; remember which, so a
    // failure can move to the next.
    _member = entry != null && entry.members.any(isProfile) ? plan.outbounds.single.id : null;
    if (!retry) _memberSpare = entry == null ? 0 : entry.members.length - 1;
    phase = Phase.connecting;
    notifyListeners();
    try {
      final answer = await link.stub.connect(
        ConnectRequest(apiVersion: apiVersion, sessionPlan: plan, controlAuthenticator: link.token),
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
      await _readStatus(report: false).catchError((Object _) {});
      if (phase == Phase.connecting) phase = Phase.off;
      if (phase == Phase.off) _notices.add(ConnectionFailed(failure!));
    }
    notifyListeners();
  }

  Future<void> disconnect() async {
    final link = _link;
    if (link == null) return;
    failure = null;
    phase = Phase.disconnecting;
    _stopping = true;
    _lostAnnounced = false;
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
    } finally {
      _stopping = false;
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

  /// Changes settings. A change that alters the plan applies at once while
  /// connected; a change of looks only redraws.
  Future<void> change(void Function(Settings) apply, {bool replan = true}) async {
    apply(settings);
    notifyListeners();
    if (replan) await _replan();
  }

  /// Forgets every choice and starts from the defaults again.
  Future<void> reset() async {
    await settings.reset();
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

  /// Saves a new subscription; the core fetches it and announces the servers
  /// through the watch. Returns the failure to show next to the field.
  Future<CoreFailure?> addSubscription(String url, {String name = ''}) async {
    final link = _link;
    if (link == null) return CoreFailure.unavailable;
    try {
      final answer = await link.stub.saveSubscription(
        SaveSubscriptionRequest(
          apiVersion: apiVersion,
          controlAuthenticator: link.token,
          settings: SubscriptionSettings(url: url.trim(), name: name.trim(), autoUpdate: true),
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

  /// Saves what the person chose for a subscription; the link stays as stored.
  Future<CoreFailure?> saveSubscription(SubscriptionSettings chosen) => _call(() async {
    final link = _link!;
    final answer = await link.stub.saveSubscription(
      SaveSubscriptionRequest(apiVersion: apiVersion, controlAuthenticator: link.token, settings: chosen..url = ''),
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
      await for (final r in link.stub.probeServers(
        ProbeServersRequest(
          apiVersion: apiVersion,
          outbounds: all,
          options: ProbeOptions(
            method: switch (settings.probeMethod) {
              'engine' => ProbeMethod.PROBE_METHOD_ENGINE,
              'connect' => ProbeMethod.PROBE_METHOD_CONNECT,
              _ => ProbeMethod.PROBE_METHOD_UNSPECIFIED,
            },
            url: settings.probeUrl,
            timeoutMs: settings.probeTimeout,
          ),
        ),
      )) {
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
    unawaited(_notices.close());
    unawaited(_cancelWatches());
    unawaited(_link?.close());
    super.dispose();
  }
}

/// The plan for a connection: every server, and what carries the traffic the
/// routing preset does not send direct. [choice] is "auto" for the fastest
/// server, picked by the core, "bypass" for no server at all, or a server id.
///
/// A profile — a whole Xray configuration a provider wrote for one server —
/// runs alone: it is the plan's only outbound when picked, and the fastest of
/// the ordinary servers is chosen among the others. A subscription of profiles
/// only picks the profile that answered fastest, from [latency].
SessionPlan buildPlan({
  required List<OutboundSpec> servers,
  required String choice,
  required Settings settings,
  Map<String, int?> latency = const {},
  Entry? entry,
}) {
  final plan = SessionPlan(
    tunnelMode: settings.tunnel == 'proxy' ? TunnelMode.TUNNEL_MODE_APPLICATION : TunnelMode.TUNNEL_MODE_SYSTEM,
    engines: [if (settings.engine.isNotEmpty) settings.engine],
    networkControlAllowed: settings.controlPort,
    routing: RoutingOptions(preset: settings.preset, blockAds: settings.blockAds),
    ipv6: settings.ipv6,
    dnsPolicy: DnsPolicy(servers: settings.dns),
    antiCensorship: AntiCensorship(
      tlsFragment: settings.fragment,
      fragmentPackets: settings.fragmentPackets,
      fragmentLength: settings.fragmentLength,
      fragmentInterval: settings.fragmentInterval,
    ),
  );
  // The person's own rules come before the preset; "through VPN" points at
  // whatever carries the rest, which is known once the target is.
  void addRules(String proxy) {
    for (final rule in settings.rules.map(UserRule.parse).nonNulls) {
      final target = switch (rule.target) {
        RuleTarget.direct => 'direct',
        RuleTarget.block => 'reject',
        RuleTarget.proxy => proxy,
      };
      plan.routes.add(RoutingRule(destination: rule.destination, outboundId: target));
    }
  }

  if (choice == 'bypass') {
    plan.outbounds.add(
      OutboundSpec(
        id: Sora.bypassId,
        displayName: 'zapret',
        protocol: 'bypass',
        bypass: BypassStrategy(
          splitPos: settings.splitPos,
          disorder: settings.disorder,
          tlsRecord: settings.tlsRecord,
          hostCase: settings.hostCase,
        ),
      ),
    );
    plan.routing.proxyTarget = Sora.bypassId;
    addRules(Sora.bypassId);
    return plan;
  }
  final profiles = [
    for (final o in servers)
      if (isProfile(o)) o,
  ];
  final ordinary = [
    for (final o in servers)
      if (!isProfile(o)) o,
  ];
  if (entry != null && entry.members.any(isProfile)) {
    // Profiles cannot share one engine, so of a named group of them the
    // interface runs one: the first main one that answers, or the fastest.
    choice = pickMember(entry, latency).id;
  } else if (entry != null) {
    // Servers of one name: the core keeps them as a group. Roles order them
    // where the engine has fallback groups (mihomo); elsewhere the main ones
    // alone are measured against each other.
    final fallback = entry.ordered && (settings.engine.isEmpty || settings.engine == 'mihomo');
    final members = fallback
        ? entry.byRole
        : entry.ordered
        ? [
            for (final o in entry.members)
              if (entry.roles[o.id] == Role.main) o,
          ]
        : entry.members;
    plan.outbounds.addAll(ordinary);
    plan.groups.add(
      GroupSpec(
        name: Sora.entryGroup,
        type: fallback ? GroupType.GROUP_TYPE_FALLBACK : GroupType.GROUP_TYPE_URL_TEST,
        members: [for (final o in members.isEmpty ? entry.members : members) o.id],
        toleranceMs: fallback ? 0 : 50,
      ),
    );
    plan.routing.proxyTarget = Sora.entryGroup;
    addRules(Sora.entryGroup);
    return plan;
  }
  final picked = profiles.where((o) => o.id == choice).firstOrNull;
  if (picked != null || (choice == 'auto' && ordinary.isEmpty && profiles.isNotEmpty)) {
    final profile = picked ?? _fastest(profiles, latency);
    plan.outbounds.add(profile);
    plan.routing.proxyTarget = profile.id;
    addRules(profile.id);
    return plan;
  }
  plan.outbounds.addAll(ordinary);
  if (choice == 'auto') {
    plan.groups.add(
      GroupSpec(
        name: Sora.autoGroup,
        type: GroupType.GROUP_TYPE_URL_TEST,
        members: [for (final o in ordinary) o.id],
        toleranceMs: 50,
      ),
    );
    plan.routing.proxyTarget = Sora.autoGroup;
  } else if (settings.failover && ordinary.length > 1 && (settings.engine.isEmpty || settings.engine == 'mihomo')) {
    // Only mihomo has fallback groups; a pinned sing-box or Xray keeps the
    // picked server alone rather than refusing to connect.
    // The picked server first, then the others from the fastest: the core
    // moves to the next one that answers and back once the first does.
    final others = [
      for (final o in ordinary)
        if (o.id != choice) o,
    ]..sort((a, b) => (latency[a.id] ?? 1 << 30).compareTo(latency[b.id] ?? 1 << 30));
    plan.groups.add(
      GroupSpec(
        name: Sora.failoverGroup,
        type: GroupType.GROUP_TYPE_FALLBACK,
        members: [choice, for (final o in others) o.id],
      ),
    );
    plan.routing.proxyTarget = Sora.failoverGroup;
  } else {
    plan.routing.proxyTarget = choice;
  }
  addRules(plan.routing.proxyTarget);
  return plan;
}

/// The member of a named group to run: the first that has not been measured
/// as unreachable — in role order when the names carry roles, otherwise the
/// fastest.
OutboundSpec pickMember(Entry entry, Map<String, int?> latency) {
  bool down(OutboundSpec o) => latency.containsKey(o.id) && latency[o.id] == null;
  if (entry.ordered) return entry.byRole.firstWhere((o) => !down(o), orElse: () => entry.byRole.first);
  final up = [
    for (final o in entry.members)
      if (!down(o)) o,
  ];
  return _fastest(up.isEmpty ? entry.members : up, latency);
}

/// Whether a server is a whole Xray configuration from a JSON subscription.
bool isProfile(OutboundSpec o) => o.protocol == 'xray-profile';

/// The profile that answered fastest; the first one when none was measured.
OutboundSpec _fastest(List<OutboundSpec> profiles, Map<String, int?> latency) {
  var best = profiles.first;
  for (final o in profiles) {
    final ms = latency[o.id], bestMs = latency[best.id];
    if (ms != null && (bestMs == null || ms < bestMs)) best = o;
  }
  return best;
}

/// Hands [Sora] to the widgets below and rebuilds them when it changes.
class SoraScope extends InheritedNotifier<Sora> {
  const SoraScope({super.key, required Sora sora, required super.child}) : super(notifier: sora);

  static Sora of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<SoraScope>()!.notifier!;

  /// For callbacks, which must not subscribe to changes.
  static Sora read(BuildContext context) => context.getInheritedWidgetOfExactType<SoraScope>()!.notifier!;
}
