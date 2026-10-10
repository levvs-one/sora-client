import 'dart:async';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../l10n/strings.dart';
import '../core/link.dart';
import '../design/theme.dart';
import '../generated/sora/core/v1/core_control.pbgrpc.dart';
import '../sora.dart';
import 'kit.dart';

/// Streams core and engine logs, displaying newest entries first.
class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  /// UI retention limit; the core retains a larger log history.
  static const _keep = 2000;

  final _search = TextEditingController();
  LogLevel _level = LogLevel.LOG_LEVEL_DEBUG;
  List<LogEntry> _entries = [];
  StreamSubscription<LogEntry>? _watch;
  Timer? _debounce;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _search.addListener(() {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 250), _reload);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    unawaited(_watch?.cancel());
    _search.dispose();
    super.dispose();
  }

  LogFilter get _filter => LogFilter(minLevel: _level, contains: _search.text.trim());

  Future<void> _reload() async {
    if (!mounted) return;
    final link = SoraScope.read(context).link;
    await _watch?.cancel();
    _watch = null;
    if (!mounted) return;
    if (link == null) {
      SoraScope.read(context).reportFailure(CoreFailure.unavailable, source: 'logs');
      return;
    }
    try {
      final page = await link.stub.queryLogs(
        QueryLogsRequest(apiVersion: apiVersion, controlAuthenticator: link.token, filter: _filter, limit: 500),
      );
      if (page.hasError()) throw CoreFailure(page.error.userMessageKey);
      if (!mounted) return;
      setState(() {
        _entries = page.entries.toList();
        SoraScope.read(context).recovered('logs');
        _loaded = true;
      });
      final after = _entries.isEmpty ? null : _entries.first.sequence;
      _watch = link.stub
          .watchLogs(
            WatchLogsRequest(
              apiVersion: apiVersion,
              controlAuthenticator: link.token,
              filter: _filter,
              afterSequence: after,
            ),
          )
          .listen(
            _arrive,
            onError: (Object e) {
              if (mounted) SoraScope.read(context).reportFailure(e, source: 'logs');
            },
          );
    } catch (error) {
      if (mounted) SoraScope.read(context).reportFailure(error, source: 'logs');
    }
  }

  void _arrive(LogEntry entry) {
    setState(() {
      // Repeated messages retain their sequence number and update the repeat
      // count.
      final index = _entries.indexWhere((e) => e.sequence == entry.sequence);
      if (index >= 0) {
        _entries[index] = entry;
      } else {
        _entries.insert(0, entry);
        if (_entries.length > _keep) _entries.removeLast();
      }
    });
  }

  Future<void> _export(LogExportFormat format) async {
    final link = SoraScope.read(context).link;
    if (link == null) return;
    try {
      final answer = await link.stub.exportLogs(
        ExportLogsRequest(apiVersion: apiVersion, controlAuthenticator: link.token, filter: _filter, format: format),
      );
      if (answer.hasError()) throw CoreFailure(answer.error.userMessageKey);
      final place = await getSaveLocation(suggestedName: answer.fileName);
      if (place == null) return;
      await File(place.path).writeAsBytes(answer.data, flush: true);
    } catch (error) {
      if (mounted) SoraScope.read(context).reportFailure(error, source: 'logs');
    }
  }

  Future<void> _clear() async {
    final link = SoraScope.read(context).link;
    if (link == null) return;
    try {
      final answer = await link.stub.clearLogs(
        ClearLogsRequest(apiVersion: apiVersion, controlAuthenticator: link.token),
      );
      if (answer.hasError()) throw CoreFailure(answer.error.userMessageKey);
      if (mounted) setState(() => _entries = []);
    } catch (error) {
      if (mounted) SoraScope.read(context).reportFailure(error, source: 'logs');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final palette = Palette.of(context);
    return Screen(
      title: s.logs,
      actions: [
        MenuAnchor(
          alignmentOffset: const Offset(-150, 4),
          menuChildren: [
            for (final (format, label) in [
              (LogExportFormat.LOG_EXPORT_FORMAT_UNSPECIFIED, s.exportText),
              (LogExportFormat.LOG_EXPORT_FORMAT_JSON_LINES, 'JSON Lines'),
              (LogExportFormat.LOG_EXPORT_FORMAT_CSV, 'CSV'),
            ])
              MenuItemButton(
                onPressed: () => unawaited(_export(format)),
                style: ButtonStyle(
                  minimumSize: const WidgetStatePropertyAll(Size(190, 40)),
                  shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(9))),
                  overlayColor: WidgetStatePropertyAll(palette.hover),
                  padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 12)),
                ),
                child: Text(label, style: Styles.secondary.copyWith(color: palette.ink)),
              ),
          ],
          builder: (context, controller, _) => RoundButton(
            icon: Symbols.ios_share_rounded,
            label: s.export,
            onTap: () => controller.isOpen ? controller.close() : controller.open(),
          ),
        ),
        const SizedBox(width: 4),
        RoundButton(icon: Symbols.delete_rounded, label: s.clear, onTap: () => unawaited(_clear())),
      ],
      fill: !_loaded
          ? const SizedBox()
          : _entries.isEmpty
          ? Center(
              child: Text(s.logsEmpty, style: Styles.secondary.copyWith(color: palette.ink)),
            )
          : SelectionArea(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: _entries.length,
                itemBuilder: (context, i) => _Entry(entry: _entries[i]),
              ),
            ),
      children: [
        Segments<LogLevel>(
          value: _level,
          choices: {
            LogLevel.LOG_LEVEL_DEBUG: s.logsAll,
            LogLevel.LOG_LEVEL_WARNING: s.logsImportant,
            LogLevel.LOG_LEVEL_ERROR: s.logsErrors,
          },
          onChanged: (level) {
            setState(() => _level = level);
            unawaited(_reload());
          },
        ),
        const SizedBox(height: 12),
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
      ],
    );
  }
}

class _Entry extends StatelessWidget {
  const _Entry({required this.entry});

  final LogEntry entry;

  static final _time = DateFormat('HH:mm:ss');

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    final color = switch (entry.level) {
      LogLevel.LOG_LEVEL_ERROR => palette.ink,
      LogLevel.LOG_LEVEL_WARNING => palette.ink,
      _ => palette.ink2,
    };
    final meta = [
      _time.format(entry.time.toDateTime().toLocal()),
      entry.source,
      if (entry.repeat > 1) '×${entry.repeat}',
    ].join('  ');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(meta, style: Styles.figures(Styles.caption).copyWith(color: palette.ink)),
          const SizedBox(height: 2),
          Text(entry.message, style: Styles.secondary.copyWith(color: color)),
        ],
      ),
    );
  }
}
