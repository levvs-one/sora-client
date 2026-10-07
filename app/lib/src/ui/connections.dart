import 'dart:async';

import 'package:flutter/cupertino.dart';

import '../../l10n/strings.dart';
import '../core/link.dart';
import '../design/theme.dart';
import '../generated/sora/core/v1/core_control.pbgrpc.dart';
import '../sora.dart';
import 'kit.dart';
import 'servers.dart';

/// The live connections of the session: where each goes, which program
/// opened it, what carries it, and how much it moved. Any of them can be cut.
class ConnectionsScreen extends StatefulWidget {
  const ConnectionsScreen({super.key});

  @override
  State<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends State<ConnectionsScreen> {
  /// The engines keep their own counters; once a second reads them without
  /// making the list jump.
  static const _every = Duration(seconds: 1);

  final _search = TextEditingController();
  Timer? _timer;
  List<Connection> _list = [];
  CoreFailure? _failure;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_read());
      _timer = Timer.periodic(_every, (_) => unawaited(_read()));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _read() async {
    if (!mounted) return;
    final sora = SoraScope.read(context);
    final link = sora.link, session = sora.sessionId;
    if (link == null || session == null) {
      setState(() {
        _list = [];
        _loaded = true;
      });
      return;
    }
    try {
      final answer = await link.stub.listConnections(
        ListConnectionsRequest(apiVersion: apiVersion, controlAuthenticator: link.token, sessionId: session),
      );
      if (answer.hasError()) throw CoreFailure(answer.error.userMessageKey);
      if (!mounted) return;
      setState(() {
        // Newest first: what was just opened is what a person is looking for.
        _list = answer.connections.toList()..sort((a, b) => b.start.seconds.compareTo(a.start.seconds));
        _failure = null;
        _loaded = true;
      });
    } catch (error) {
      if (mounted) setState(() => _failure = CoreFailure.from(error));
    }
  }

  Future<void> _close(Connection c) async {
    final sora = SoraScope.read(context);
    final link = sora.link, session = sora.sessionId;
    if (link == null || session == null) return;
    setState(
      () => _list = [
        for (final x in _list)
          if (x.id != c.id) x,
      ],
    );
    try {
      final answer = await link.stub.closeConnection(
        CloseConnectionRequest(
          apiVersion: apiVersion,
          controlAuthenticator: link.token,
          sessionId: session,
          connectionId: c.id,
        ),
      );
      if (answer.hasError()) throw CoreFailure(answer.error.userMessageKey);
    } catch (error) {
      if (mounted) setState(() => _failure = CoreFailure.from(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final palette = Palette.of(context);
    final query = _search.text.trim().toLowerCase();
    final shown = query.isEmpty
        ? _list
        : [
            for (final c in _list)
              if ('${c.host} ${c.process} ${c.chain.join(' ')}'.toLowerCase().contains(query)) c,
          ];
    return Screen(
      title: s.connections,
      fill: !_loaded
          ? const SizedBox()
          : shown.isEmpty
          ? Center(
              child: Text(s.logsEmpty, style: Styles.secondary.copyWith(color: palette.ink)),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: shown.length,
              itemBuilder: (context, i) => _Row(connection: shown[i], onClose: () => unawaited(_close(shown[i]))),
            ),
      children: [
        CupertinoSearchTextField(
          controller: _search,
          placeholder: s.search,
          style: Styles.body.copyWith(color: palette.ink),
          placeholderStyle: Styles.body.copyWith(color: palette.ink3),
          backgroundColor: palette.field,
          borderRadius: BorderRadius.circular(12),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
          itemColor: palette.ink3,
        ),
        const SizedBox(height: 14),
        if (_failure != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
            child: Text(describe(s, _failure!), style: Styles.caption.copyWith(color: palette.danger)),
          ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.connection, required this.onClose});

  final Connection connection;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final palette = Palette.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final c = connection;
    final where = c.port == 0 ? c.host : '${c.host}:${c.port}';
    final detail = [
      if (c.process.isNotEmpty) c.process,
      if (c.chain.isNotEmpty) _carrier(s, SoraScope.read(context), c.chain.last),
      '↑ ${formatBytes(s, c.upload, locale)}  ↓ ${formatBytes(s, c.download, locale)}',
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    where,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Styles.body.copyWith(color: palette.ink),
                  ),
                  const SizedBox(height: 2),
                  // Space, not punctuation, keeps the facts apart.
                  Wrap(
                    spacing: 14,
                    children: [
                      for (final fact in detail)
                        Text(fact, style: Styles.figures(Styles.caption).copyWith(color: palette.ink)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          RoundButton(icon: CupertinoIcons.xmark, label: s.close, onTap: onClose),
        ],
      ),
    );
  }
}

/// The outbound that carried a connection, by the name a person knows it by.
String _carrier(S s, Sora sora, String hop) => switch (hop) {
  'direct' || 'DIRECT' => s.chainDirect,
  'reject' || 'REJECT' || 'block' => s.chainBlocked,
  Sora.autoGroup => s.serverAuto,
  Sora.entryGroup => sora.nameOf(sora.selected),
  Sora.bypassId => s.serverBypass,
  _ => sora.nameOf(hop),
};
