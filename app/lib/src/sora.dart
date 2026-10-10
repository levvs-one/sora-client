import 'dart:async';
import 'dart:io';

import 'package:fixnum/fixnum.dart';
import 'package:flutter/widgets.dart' hide ConnectionState;
import 'package:url_launcher/url_launcher.dart';
import 'package:http/io_client.dart';
import 'package:grpc/grpc.dart' show CallOptions;
import 'package:retry/retry.dart';

import '../l10n/strings.dart';

import 'core/link.dart';
import 'generated/sora/core/v1/core_control.pbgrpc.dart';
import 'groups.dart';
import 'rules.dart';
import 'settings.dart';
import 'notifications.dart';
import 'updates.dart';
import 'ui/kit.dart' show describe;

/// Connection phases exposed to the UI.
enum Phase { offline, off, connecting, connected, reconnecting, disconnecting }

/// An unsolicited connection event for background notifications.
sealed class Notice {
  const Notice();
}

/// A connection drop while the core attempts reconnection.
final class ConnectionLost extends Notice {
  const ConnectionLost();
}

/// A connection restored after a drop.
final class ConnectionRestored extends Notice {
  const ConnectionRestored();
}

/// A connection that ended or failed to start with [failure].
final class ConnectionFailed extends Notice {
  const ConnectionFailed(this.failure);

  final CoreFailure failure;
}

/// A failover within group [entry]. [backup] indicates role-based failover to a
/// backup server.
final class ServerSwitched extends Notice {
  const ServerSwitched(this.entry, {required this.backup});

  final String entry;
  final bool backup;
}

/// A core fallback group back on its first server [entry] after that server
/// answered again.
final class ServerReturned extends Notice {
  const ServerReturned(this.entry);

  final String entry;
}

/// App state and core operations. Screens access it through [SoraScope] and
/// rebuild on notifications.
class Sora extends ChangeNotifier {
  Sora(this.settings) : history = settings.notificationHistory;

  AppUpdater get updates => _updates;
  late final _updates = AppUpdater(
    settings,
    connection: () => switch (phase) {
      Phase.off => UpdateConnection.idle,
      Phase.connected => UpdateConnection.connected,
      Phase.offline => UpdateConnection.unknown,
      _ => UpdateConnection.changing,
    },
    client: () => IOClient(
      HttpClient()
        ..findProxy = (uri) {
          final proxy = localProxy;
          if (settings.tunnel == 'proxy' &&
              proxy != null &&
              (phase == Phase.connected || phase == Phase.reconnecting)) {
            return 'PROXY ${proxy.host}:${proxy.port}';
          }
          return HttpClient.findProxyFromEnvironment(uri);
        },
    ),
    available: (release) => recordNotification(
      AppNotification(
        time: DateTime.now(),
        title: strings.updateAvailable(release.version),
        body: strings.updateOpenAbout,
        action: 'update',
      ),
    ),
  )..addListener(notifyListeners);

  bool get updateBlocked => updates.busy;

  final _messages = StreamController<AppNotification>.broadcast();
  Stream<AppNotification> get messages => _messages.stream;
  final _reported = <String, String>{};
  bool serverlessAvailable = false;

  S get strings {
    final chosen = settings.language == 'system'
        ? WidgetsBinding.instance.platformDispatcher.locale
        : Locale(settings.language);
    return lookupS(S.delegate.isSupported(chosen) ? chosen : const Locale('en'));
  }

  void reportFailure(Object error, {String source = 'request', String action = 'logs', String argument = ''}) {
    if (_disposed) return;
    final failed = CoreFailure.from(error);
    if (_reported[source] == failed.key) return;
    _reported[source] = failed.key;
    unawaited(
      recordNotification(
        AppNotification(
          time: DateTime.now(),
          title: strings.errGeneric,
          body: describe(strings, failed),
          action: action,
          argument: argument,
        ),
      ),
    );
  }

  void recovered(String source) => _reported.remove(source);

  final Settings settings;
  List<AppNotification> history;
  int get unreadCount => history.where((n) => !n.read).length;
  Future<void> _historyWork = Future.value();
  Future<void> _killSwitchWork = Future.value();

  Future<void> recordNotification(AppNotification notice) {
    if (_disposed) return Future.value();
    history = [notice, ...history].take(100).toList();
    _messages.add(notice);
    notifyListeners();
    return _saveHistory();
  }

  Future<void> markNotificationsRead() {
    history = history.map((n) => n.markRead()).toList();
    notifyListeners();
    return _saveHistory();
  }

  Future<void> clearNotifications() {
    history = [];
    notifyListeners();
    return _saveHistory();
  }

  Future<void> _saveHistory() {
    final snapshot = [...history];
    return _historyWork = _historyWork.then((_) => settings.saveNotificationHistory(snapshot));
  }

  AppNotification notificationFor(Notice notice) {
    final chosen = settings.language == 'system'
        ? WidgetsBinding.instance.platformDispatcher.locale
        : Locale(settings.language);
    final s = lookupS(S.delegate.isSupported(chosen) ? chosen : const Locale('en'));
    final server = switch (selected) {
      'auto' => s.serverAuto,
      'bypass' => s.serverBypass,
      final id => nameOf(id),
    };
    final (title, body, action) = switch (notice) {
      ConnectionLost() => (s.noticeLost, s.noticeLostBody, 'logs'),
      ConnectionRestored() => (s.noticeRestored, server, ''),
      ConnectionFailed(:final failure) => (s.noticeFailed, describe(s, failure), 'connect'),
      ServerSwitched(:final entry, :final backup) => (entry, backup ? s.noticeBackup : s.noticeNext, 'logs'),
      ServerReturned(:final entry) => (entry, s.noticeMainBack, ''),
    };
    return AppNotification(time: DateTime.now(), title: title, body: body, action: action);
  }

  /// App group IDs use "sora:", which never prefixes core-generated server IDs.
  static const autoGroup = 'sora:auto';
  static const bypassId = 'sora:bypass';
  static const failoverGroup = 'sora:failover';
  static const entryGroup = 'sora:group';

  CoreLink? _link;
  bool _disposed = false;
  bool _startedOnce = false;

  /// Active profile in a named group, followed by the remaining retry count.
  String? _member;
  int _memberSpare = 0;
  StreamSubscription<SubscriptionState>? _subscriptionWatch;
  StreamSubscription<CoreEvent>? _sessionWatch;

  /// Fallback groups of the watched session by name: members in the order the
  /// core tries them, the main ones, and the name notices give the group.
  Map<String, ({List<String> order, Set<String> mains, String title, bool ordered})> _fallbacks = {};

  /// Last event seen, so a watch reopened on the same session resumes after it
  /// instead of replaying history.
  String? _seenSession;
  Int64 _seenSequence = Int64.ZERO;

  /// Drops the core connection when a request detects it is unavailable.
  void Function(Object error) _drop = (_) {};

  /// Suppresses failure notices during an explicit disconnect.
  bool _stopping = false;
  Completer<void>? _connectionWork;
  SessionPlan? _activePlan;
  bool needsReconnect = false;
  bool cleanupPending = false;

  /// Tracks a reported drop so restoration also emits a notice.
  bool _lostAnnounced = false;

  final _notices = StreamController<Notice>.broadcast();

  /// Unsolicited connection events for notification subscribers.
  Stream<Notice> get notices => _notices.stream;

  /// Notice count used to avoid reporting a failure already announced by state
  /// handling.
  int _emitted = 0;

  void _emit(Notice notice) {
    if (_disposed) return;
    _emitted++;
    unawaited(recordNotification(notificationFor(notice)));
    _notices.add(notice);
  }

  /// The core's local proxy endpoint, used by system proxy mode. Null until
  /// reported by the core.
  Endpoint? localProxy;

  Phase phase = Phase.offline;
  DateTime? since;
  String? sessionId;

  StatsTick? stats;
  double? speedUp, speedDown;
  DateTime? _statsAt;
  Timer? _statsTimer;
  bool _readingStats = false;

  Future<void> readStats() async {
    final link = _link, id = sessionId;
    if (link == null || id == null || _readingStats) return;
    _readingStats = true;
    try {
      final answer = await link.stub.getStats(GetStatsRequest(apiVersion: apiVersion, sessionId: id));
      if (id != sessionId || link != _link) return;
      if (answer.hasError()) throw CoreFailure(answer.error.userMessageKey);
      if (!answer.hasStats()) throw const CoreFailure('core.internal.unexpected');
      final now = DateTime.now(), before = stats, at = _statsAt;
      if (before != null && at != null) {
        final seconds = now.difference(at).inMicroseconds / 1e6;
        if (seconds > 0) {
          speedUp = (answer.stats.bytesUp - before.bytesUp).toDouble().clamp(0, double.infinity) / seconds;
          speedDown = (answer.stats.bytesDown - before.bytesDown).toDouble().clamp(0, double.infinity) / seconds;
        }
      }
      stats = answer.stats;
      _statsAt = now;
      recovered('stats');
    } catch (error) {
      reportFailure(error, source: 'stats');
      stats = null;
      speedUp = speedDown = null;
      _statsAt = null;
    } finally {
      _readingStats = false;
    }
  }

  /// Last displayed failure, cleared by the next action.
  CoreFailure? failure;

  final Map<String, SubscriptionState> _subscriptions = {};
  List<SubscriptionState> get subscriptions => _subscriptions.values.toList();

  /// Server latency in milliseconds; null means the server did not respond.
  final Map<String, int?> latency = {};
  bool probing = false;
  String? probingSubscription;

  /// All subscription servers in list order, deduplicated by ID.
  List<OutboundSpec> get servers {
    final seen = <String>{};
    return [
      for (final s in _subscriptions.values)
        for (final o in s.outbounds)
          if (seen.add(o.id)) o,
    ];
  }

  /// Current selection; falls back to auto if the selected server or group is
  /// no longer present.
  String get selected {
    final chosen = settings.server;
    if (chosen == 'auto') return chosen;
    if (chosen == 'bypass') return serverlessAvailable ? chosen : 'auto';
    if (chosen.startsWith(groupPrefix)) return entryOf(chosen, _subscriptions.values) != null ? chosen : 'auto';
    return servers.any((o) => o.id == chosen) ? chosen : 'auto';
  }

  String nameOf(String id) => id.startsWith(groupPrefix)
      ? entryOf(id, _subscriptions.values)?.name ?? id
      : servers.firstWhere((o) => o.id == id, orElse: () => OutboundSpec(displayName: id)).displayName;

  bool get busy => _connectionWork != null || phase == Phase.connecting || phase == Phase.disconnecting;

  SessionPlan get currentPlan => buildPlan(
    servers: servers,
    choice: selected,
    settings: settings,
    latency: latency,
    entry: selected.startsWith(groupPrefix) ? entryOf(selected, _subscriptions.values) : null,
  );

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  /// Maintains the core connection and watches subscriptions and session state,
  /// reopening the connection after a drop until disposal.
  Future<void> run() async {
    _statsTimer ??= Timer.periodic(const Duration(seconds: 1), (_) => unawaited(readStats()));
    while (!_disposed) {
      final CoreLink link;
      try {
        link = await CoreLink.open(
          onRetry: (error) => reportFailure(error, source: 'core'),
          canceled: () => _disposed,
        );
      } catch (error) {
        failure = CoreFailure.from(error);
        reportFailure(error, source: 'core');
        notifyListeners();
        return;
      }
      if (_disposed) {
        await link.close();
        return;
      }
      _link = link;
      final dropped = Completer<void>();
      _drop = (error) {
        reportFailure(error, source: 'core');
        if (!dropped.isCompleted && CoreFailure.from(error).key == CoreFailure.unavailable.key) dropped.complete();
      };
      try {
        await _readStatus(report: false);
        final about = await link.stub.getAbout(GetAboutRequest(apiVersion: apiVersion));
        if (about.hasError()) throw CoreFailure(about.error.userMessageKey);
        serverlessAvailable = about.about.contract.capabilities.contains('serverless');
        localProxy = about.about.hasLocalProxy() ? about.about.localProxy : null;
        recovered('core');
        _watchSubscriptions();
        _watchSession();
        notifyListeners();
        if ((settings.connectOnStart || settings.resumeAfterUpdate) && !_startedOnce && phase == Phase.off) {
          // Auto-connect only once per launch so core reconnection cannot undo
          // an explicit disconnect.
          _startedOnce = true;
          // Allow time for the initial server list to arrive through the
          // subscription watch.
          await Future<void>.delayed(const Duration(milliseconds: 600));
          if (phase == Phase.off) {
            await settings.saveResumeAfterUpdate(false);
            unawaited(connect());
          }
        }
        if (phase == Phase.connected && settings.resumeAfterUpdate) await settings.saveResumeAfterUpdate(false);
        _startedOnce = true;
        await dropped.future;
      } catch (error) {
        failure = CoreFailure.from(error);
        reportFailure(error, source: 'core');
        notifyListeners();
        // Delay retries after post-handshake failures to avoid a tight loop.
        await Future<void>.delayed(const Duration(seconds: 3));
      }
      await _cancelWatches();
      _link = null;
      serverlessAvailable = false;
      await link.close();
      phase = Phase.offline;
      stats = null;
      speedUp = speedDown = null;
      _statsAt = null;
      notifyListeners();
    }
  }

  Future<void> _cancelWatches() async {
    await _subscriptionWatch?.cancel();
    await _sessionWatch?.cancel();
    _subscriptionWatch = _sessionWatch = null;
  }

  /// Reads session state. [report] enables failure reporting; startup disables
  /// it to suppress failures predating the current UI session.
  Future<void> _readStatus({bool report = true}) async {
    final link = _link!, expected = sessionId;
    final answer = await link.stub.getStatus(GetStatusRequest(apiVersion: apiVersion));
    if (_disposed || link != _link || expected != sessionId) return;
    if (answer.hasError()) throw CoreFailure(answer.error.userMessageKey);
    _applyState(answer.status.connection, report: report);
  }

  void _applyState(ConnectionState state, {bool report = true}) {
    final before = phase;
    if (state.sessionId.isNotEmpty && state.sessionId != sessionId ||
        state.value == ConnectionStateValue.CONNECTION_STATE_VALUE_DISCONNECTED ||
        state.value == ConnectionStateValue.CONNECTION_STATE_VALUE_FAILED) {
      stats = null;
      speedUp = speedDown = null;
      _statsAt = null;
    }
    phase = switch (state.value) {
      ConnectionStateValue.CONNECTION_STATE_VALUE_CONNECTING => Phase.connecting,
      ConnectionStateValue.CONNECTION_STATE_VALUE_CONNECTED => Phase.connected,
      ConnectionStateValue.CONNECTION_STATE_VALUE_RECONNECTING => Phase.reconnecting,
      _ => Phase.off,
    };
    // Session events may omit the ID. Retain the known ID until the session
    // ends.
    if (phase == Phase.off) {
      sessionId = null;
      _activePlan = null;
      needsReconnect = false;
    } else if (state.sessionId.isNotEmpty) {
      sessionId = state.sessionId;
    }
    since = state.hasChangedAt() ? state.changedAt.toDateTime() : null;
    if (_stopping && (phase != Phase.off || _connectionWork != null)) phase = Phase.disconnecting;
    if (report &&
        state.value == ConnectionStateValue.CONNECTION_STATE_VALUE_FAILED &&
        _member != null &&
        _memberSpare > 0) {
      // Profiles need client-side failover because they cannot share a core
      // fallback group.
      latency[_member!] = null;
      _memberSpare--;
      final entry = entryOf(settings.server, _subscriptions.values);
      if (entry != null) _emit(ServerSwitched(entry.name, backup: entry.ordered));
      unawaited((_connectionWork?.future ?? Future.value()).then((_) => connect(retry: true)));
      return;
    }
    if (report &&
        state.value == ConnectionStateValue.CONNECTION_STATE_VALUE_FAILED &&
        state.reason != SoraErrorCode.SORA_ERROR_CODE_UNSPECIFIED) {
      // Preserve the request's detailed error over the less specific state
      // reason.
      failure ??= CoreFailure(_keyOfCode(state.reason));
    }
    if (report) _announce(before, state);
  }

  /// Emits notices for unsolicited drops, restorations and failures.
  void _announce(Phase before, ConnectionState state) {
    if (before == Phase.connected && phase == Phase.reconnecting) {
      _lostAnnounced = true;
      _emit(const ConnectionLost());
    } else if (phase == Phase.connected && _lostAnnounced) {
      _lostAnnounced = false;
      _emit(const ConnectionRestored());
    } else if (before != Phase.off &&
        phase == Phase.off &&
        state.value == ConnectionStateValue.CONNECTION_STATE_VALUE_FAILED &&
        !_stopping) {
      _lostAnnounced = false;
      _emit(ConnectionFailed(failure ?? CoreFailure(_keyOfCode(state.reason))));
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
      final key = state.hasLastError() ? state.lastError.userMessageKey : '';
      if (key.isNotEmpty) {
        reportFailure(CoreFailure(key), source: 'subscription:$id', action: 'subscription', argument: id);
      } else {
        recovered('subscription:$id');
      }
      notifyListeners();
    }, onError: _drop);
  }

  /// Replaces the current session watch. Events before [since] update state
  /// without triggering notices or failover.
  void _watchSession({DateTime? since}) {
    unawaited(_sessionWatch?.cancel());
    _sessionWatch = null;
    final link = _link, id = sessionId;
    if (link == null || id == null) return;
    // Refresh status because a closed watch may mean the session ended or was
    // replaced.
    void resync() {
      if (_link == link) unawaited(_readStatus().then((_) => notifyListeners(), onError: _drop));
    }

    // The stream replays history; old events must not trigger notices or repeat
    // failover.
    final opened = (since ?? DateTime.now()).subtract(const Duration(seconds: 1));
    final stream = link.stub.watchEvents(
      WatchEventsRequest(
        apiVersion: apiVersion,
        sessionId: id,
        afterSequence: id == _seenSession ? _seenSequence : null,
      ),
    );
    _sessionWatch = stream.listen(
      (event) {
        if (link != _link || id != sessionId) return;
        if (event.sessionId.isNotEmpty && event.sessionId != id) return;
        if (event.hasStateChanged() &&
            event.stateChanged.state.sessionId.isNotEmpty &&
            event.stateChanged.state.sessionId != id) {
          return;
        }
        _seenSession = id;
        _seenSequence = event.sequence;
        final fresh = !event.hasEmittedAt() || event.emittedAt.toDateTime().isAfter(opened);
        if (event.hasStateChanged()) {
          _applyState(event.stateChanged.state, report: fresh);
          notifyListeners();
        } else if (event.hasGroupSwitched() && fresh) {
          _fallbackMoved(event.groupSwitched);
        }
      },
      onError: (Object error) {
        _drop(error);
        resync();
      },
      onDone: resync,
    );
  }

  /// Tells the user that a fallback group of the core moved. The core tries
  /// members in order, so a move down the list means a server stopped
  /// answering, and a move up means an earlier one answers again. A move up
  /// to a backup stays quiet: no notice text fits it without naming a main
  /// server that is not there.
  void _fallbackMoved(GroupSwitched moved) {
    final group = _fallbacks[moved.group];
    if (group == null) return;
    final isMain = group.mains.contains(moved.selected);
    if (group.order.indexOf(moved.selected) > group.order.indexOf(moved.previous)) {
      _emit(ServerSwitched(group.title, backup: group.ordered && !isMain));
    } else if (isMain && !group.mains.contains(moved.previous)) {
      _emit(ServerReturned(group.title));
    }
  }

  /// The main members of fallback group [g]: those named main in a group with
  /// roles, otherwise the server the user picked.
  static Set<String> _mainsOf(GroupSpec g, Entry? entry) => entry != null && entry.ordered
      ? {
          for (final m in g.members)
            if (entry.roles[m] == Role.main) m,
        }
      : {g.members.first};

  /// Connects when off; disconnects an active or connecting session.
  Future<void> toggle() async {
    if (cleanupPending) {
      await disconnect();
    } else if (phase == Phase.off) {
      await connect();
    } else if (phase == Phase.connected || phase == Phase.reconnecting || phase == Phase.connecting) {
      await disconnect();
    }
  }

  /// Connects using the current selection and settings. [retry] preserves the
  /// remaining attempt count during profile-group failover.
  Future<void> connect({bool retry = false}) async {
    if (_disposed || updateBlocked || busy || _stopping) return;
    if (cleanupPending) {
      await disconnect();
      if (cleanupPending || _disposed) return;
    }
    final link = _link;
    if (link == null) return;
    failure = null;
    if (selected != 'bypass' && servers.isEmpty) {
      failure = const CoreFailure('app.no_servers');
      _emit(ConnectionFailed(failure!));
      notifyListeners();
      return;
    }
    final choice = selected;
    final entry = choice.startsWith(groupPrefix) ? entryOf(choice, _subscriptions.values) : null;
    final plan = currentPlan;
    if (plan.tunStack.isNotEmpty && link.minor < 7) {
      failure = const CoreFailure('core.api.version_mismatch');
      _emit(ConnectionFailed(failure!));
      notifyListeners();
      return;
    }
    final fallbacks = {
      for (final g in plan.groups)
        if (g.type == GroupType.GROUP_TYPE_FALLBACK && g.members.isNotEmpty)
          g.name: (
            order: g.members,
            mains: _mainsOf(g, entry),
            title: entry?.name ?? nameOf(g.members.first),
            ordered: entry?.ordered ?? false,
          ),
    };
    final armed = settings.killSwitch;
    // Track the active profile because profile groups fail over in the client.
    _member = entry != null && entry.members.any(isProfile) ? plan.outbounds.single.id : null;
    if (!retry) _memberSpare = entry == null ? 0 : entry.members.length - 1;
    final work = _connectionWork = Completer<void>();
    phase = Phase.connecting;
    notifyListeners();
    // Include events emitted during these requests, before the watch opens.
    final started = DateTime.now();
    var connected = false;
    try {
      final answer = await link.stub.connect(
        // The core arms the kill switch before the engine starts, so nothing
        // leaves outside the tunnel while it comes up.
        ConnectRequest(apiVersion: apiVersion, sessionPlan: plan, controlAuthenticator: link.token, killSwitch: armed),
        options: CallOptions(timeout: const Duration(seconds: 35)),
      );
      if (_disposed || link != _link) return;
      if (answer.hasError()) throw CoreFailure(answer.error.userMessageKey);
      _applyState(answer.status.connection);
      _activePlan = plan;
      needsReconnect = currentPlan != plan;
      connected = true;
      // Swapped together with the watch, so events of the previous session
      // never meet the groups of this one.
      _fallbacks = fallbacks;
      _watchSession(since: started);
    } catch (error) {
      if (_disposed || link != _link) return;
      failure = CoreFailure.from(error);
      if (failure!.key == 'core.guard.restore_failed') cleanupPending = true;
      // Read state to trigger profile failover or report a final failure
      // without duplicating notices.
      final before = _emitted;
      await _readStatus().catchError((Object _) {});
      if (phase == Phase.connecting) phase = Phase.off;
      if (!_stopping && _emitted == before) _emit(ConnectionFailed(failure!));
    } finally {
      _connectionWork = null;
      work.complete();
    }
    if (connected && !_disposed && !_stopping && settings.killSwitch != armed && sessionId != null) {
      await setKillSwitch(settings.killSwitch);
    }
    notifyListeners();
  }

  Future<void> disconnect() async {
    final link = _link;
    if (link == null || _stopping) return;
    failure = null;
    recovered('disconnect');
    phase = Phase.disconnecting;
    _stopping = true;
    cleanupPending = true;
    _lostAnnounced = false;
    notifyListeners();
    try {
      await _connectionWork?.future;
      if (_disposed || link != _link) return;
      final answer =
          await const RetryOptions(
            maxAttempts: 10,
            delayFactor: Duration(milliseconds: 100),
            maxDelay: Duration(seconds: 1),
          ).retry(() async {
            final answer = await link.stub.disconnect(
              DisconnectRequest(apiVersion: apiVersion, controlAuthenticator: link.token),
              options: CallOptions(timeout: const Duration(seconds: 20)),
            );
            if (answer.hasError()) throw CoreFailure(answer.error.userMessageKey);
            return answer;
          }, retryIf: (error) => error is CoreFailure && error.key == 'core.session.busy');
      cleanupPending = false;
      _applyState(answer.status.connection);
    } catch (error) {
      failure = CoreFailure.from(error);
      reportFailure(error, source: 'disconnect');
      await _readStatus().catchError((Object _) {});
    } finally {
      _stopping = false;
    }
    notifyListeners();
  }

  /// Defers connection changes until the user explicitly reconnects.
  Future<void> _replan() async {
    if (phase == Phase.connected || phase == Phase.reconnecting || _connectionWork != null) {
      needsReconnect = _activePlan == null || currentPlan != _activePlan;
      notifyListeners();
    }
  }

  Future<void> select(String server) async {
    if (settings.server == server) return;
    settings.server = server;
    notifyListeners();
    await _replan();
  }

  /// Applies settings and stages connection changes. Disable [replan] for
  /// appearance-only changes.
  Future<void> change(void Function(Settings) apply, {bool replan = true}) async {
    final checks = settings.checkUpdates;
    apply(settings);
    if (checks != settings.checkUpdates) await updates.setChecking(settings.checkUpdates);
    notifyListeners();
    if (replan) await _replan();
  }

  /// Resets settings to defaults and reapplies the active connection plan.
  Future<void> reset() async {
    await settings.reset();
    await updates.setChecking(settings.checkUpdates);
    notifyListeners();
    await _replan();
  }

  Future<void> setKillSwitch(bool value) {
    recovered('kill-switch');
    settings.killSwitch = value;
    notifyListeners();
    if (_stopping || _connectionWork != null) return Future.value();
    return _killSwitchWork = _killSwitchWork.then((_) async {
      if (_disposed || _stopping || value != settings.killSwitch) return;
      final link = _link, id = sessionId;
      if (link == null) return;
      if (id == null) {
        // A session still connecting takes the new value when Connect returns.
        // A failed session may retain the kill switch after its ID is cleared;
        // disconnecting it releases the block.
        if (!value && phase != Phase.connecting) {
          try {
            final answer = await link.stub.disconnect(
              DisconnectRequest(apiVersion: apiVersion, controlAuthenticator: link.token),
            );
            if (answer.hasError()) throw CoreFailure(answer.error.userMessageKey);
          } catch (error) {
            reportFailure(error, source: 'kill-switch');
          }
        }
        return;
      }
      try {
        final answer = await link.stub.setKillSwitch(
          SetKillSwitchRequest(apiVersion: apiVersion, sessionId: id, enabled: value),
        );
        if (answer.hasError()) throw CoreFailure(answer.error.userMessageKey);
      } catch (error) {
        failure = CoreFailure.from(error);
        reportFailure(error, source: 'kill-switch');
        notifyListeners();
      }
    });
  }

  /// Saves a subscription; the core fetches it and streams its servers. Returns
  /// null on success; failures are reported through the notification stream.
  Future<CoreFailure?> addSubscription(String url, {String name = ''}) async {
    recovered('request');
    final link = _link;
    if (link == null) {
      reportFailure(CoreFailure.unavailable);
      return CoreFailure.unavailable;
    }
    try {
      final answer = await link.stub.saveSubscription(
        SaveSubscriptionRequest(
          apiVersion: apiVersion,
          controlAuthenticator: link.token,
          settings: SubscriptionSettings(url: url.trim(), name: name.trim(), autoUpdate: true),
        ),
      );
      if (answer.hasError()) throw CoreFailure(answer.error.userMessageKey);
      _subscriptions[answer.state.settings.id] = answer.state;
      notifyListeners();
      return null;
    } catch (error) {
      reportFailure(error);
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

  /// Saves subscription settings without replacing the stored URL.
  Future<CoreFailure?> saveSubscription(SubscriptionSettings chosen) => _call(() async {
    final link = _link!;
    final answer = await link.stub.saveSubscription(
      SaveSubscriptionRequest(apiVersion: apiVersion, controlAuthenticator: link.token, settings: chosen..url = ''),
    );
    if (answer.hasError()) throw CoreFailure(answer.error.userMessageKey);
  });

  /// Fetches the bearer link only for this action, without retaining it in state.
  Future<CoreFailure?> openSubscriptionPage(String id) => _call(() async {
    final link = _link!;
    final answer = await link.stub.getSubscriptionLink(
      GetSubscriptionLinkRequest(apiVersion: apiVersion, controlAuthenticator: link.token, id: id),
    );
    if (answer.hasError()) throw CoreFailure(answer.error.userMessageKey);
    if (!await launchUrl(Uri.parse(answer.url), mode: LaunchMode.externalApplication)) {
      throw const CoreFailure('core.internal.unexpected');
    }
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

  /// Runs a core request; returns null on success or stores and returns its
  /// failure.
  Future<CoreFailure?> _call(Future<void> Function() body) async {
    recovered('request');
    if (_link == null) {
      reportFailure(CoreFailure.unavailable);
      return CoreFailure.unavailable;
    }
    failure = null;
    try {
      await body();
      return null;
    } catch (error) {
      failure = CoreFailure.from(error);
      reportFailure(error);
      notifyListeners();
      return failure;
    }
  }

  /// Probes a subscription or all servers and publishes results as they arrive.
  Future<void> probe({String? subscriptionId}) async {
    final link = _link;
    final all = subscriptionId == null ? servers : _subscriptions[subscriptionId]?.outbounds.toList() ?? [];
    if (_disposed || link == null || probing || all.isEmpty) return;
    probing = true;
    probingSubscription = subscriptionId;
    recovered('probe');
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
        if (_disposed || link != _link) break;
        latency[r.serverId] = r.reachable ? r.latencyMs : null;
        notifyListeners();
      }
    } catch (error) {
      reportFailure(error, source: 'probe');
      // Keep partial results; unmeasured servers remain unknown instead of
      // being marked unreachable.
    }
    probing = false;
    probingSubscription = null;
    notifyListeners();
  }

  /// Core client and authentication token for direct screen requests, such as
  /// logs. Null while the core is unavailable.
  CoreLink? get link => _link;

  /// Scales bytes by powers of 1024, returning the value and unit index (B to
  /// TB).
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
    _drop(CoreFailure.unavailable);
    _statsTimer?.cancel();
    updates.dispose();
    unawaited(_notices.close());
    unawaited(_messages.close());
    unawaited(_cancelWatches());
    unawaited(_link?.close());
    super.dispose();
  }
}

/// Builds routing for [choice]: auto selects the fastest ordinary server,
/// bypass uses no server, or an ID selects one. A provider Xray profile runs as
/// the sole outbound; profile-only auto selection uses [latency].
SessionPlan buildPlan({
  required List<OutboundSpec> servers,
  required String choice,
  required Settings settings,
  Map<String, int?> latency = const {},
  Entry? entry,
}) {
  final plan = SessionPlan(
    tunnelMode: settings.tunnel == 'proxy' ? TunnelMode.TUNNEL_MODE_APPLICATION : TunnelMode.TUNNEL_MODE_SYSTEM,
    tunStack: settings.tunnel == 'tun' && choice != 'bypass'
        ? switch (settings.engine) {
            'mihomo' => settings.mihomoTunStack,
            'xray' when settings.xrayTunStack != 'gvisor' => settings.xrayTunStack,
            _ => '',
          }
        : '',
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
  // User rules take precedence over the preset; resolve proxy rules after the
  // default traffic target is known.
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
    // Profiles cannot share an engine. Select one reachable member by role
    // priority or latency.
    choice = pickMember(entry, latency).id;
  } else if (entry != null) {
    // mihomo supports role-ordered fallback groups. Other engines compare only
    // main members by latency; unlabelled groups compare all members.
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
    // Only mihomo supports fallback groups; pinned sing-box or Xray uses the
    // selected server alone. Try it first, then alternatives by latency, and
    // return to it when reachable.
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

/// Picks a member not measured as unreachable: first by role priority,
/// otherwise by latency. If all are down, uses the first by role or the fastest
/// measured member.
OutboundSpec pickMember(Entry entry, Map<String, int?> latency) {
  bool down(OutboundSpec o) => latency.containsKey(o.id) && latency[o.id] == null;
  if (entry.ordered) return entry.byRole.firstWhere((o) => !down(o), orElse: () => entry.byRole.first);
  final up = [
    for (final o in entry.members)
      if (!down(o)) o,
  ];
  return _fastest(up.isEmpty ? entry.members : up, latency);
}

/// Checks whether a server is a full Xray profile from a JSON subscription.
bool isProfile(OutboundSpec o) => o.protocol == 'xray-profile';

/// Returns the lowest-latency profile, or the first if none has a measurement.
/// Requires a nonempty list.
OutboundSpec _fastest(List<OutboundSpec> profiles, Map<String, int?> latency) {
  var best = profiles.first;
  for (final o in profiles) {
    final ms = latency[o.id], bestMs = latency[best.id];
    if (ms != null && (bestMs == null || ms < bestMs)) best = o;
  }
  return best;
}

/// Provides [Sora] to descendants and rebuilds dependents when state changes.
class SoraScope extends InheritedNotifier<Sora> {
  const SoraScope({super.key, required Sora sora, required super.child}) : super(notifier: sora);

  static Sora of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<SoraScope>()!.notifier!;

  /// Reads [Sora] without subscribing, for use in callbacks.
  static Sora read(BuildContext context) => context.getInheritedWidgetOfExactType<SoraScope>()!.notifier!;
}
