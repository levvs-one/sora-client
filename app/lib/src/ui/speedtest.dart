import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_all/webview_all.dart';
import 'package:webview_all_linux/webview_all_linux.dart';
import 'package:webview_all_windows/webview_all_windows.dart';

import '../../l10n/strings.dart';
import '../design/theme.dart';
import '../settings.dart';
import '../sora.dart';
import '../speedtest_services.dart';
import 'kit.dart';
import 'shell.dart';

class SpeedtestScreen extends StatefulWidget {
  const SpeedtestScreen({super.key});

  @override
  State<SpeedtestScreen> createState() => _SpeedtestScreenState();
}

class _SpeedtestScreenState extends State<SpeedtestScreen> {
  final _search = TextEditingController();
  SpeedtestService? _selected;
  bool _opened = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selected ??=
        speedtestServices.where((s) => s.url == SoraScope.read(context).settings.speedtestService).firstOrNull ??
        speedtestServices.first;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _choose(SpeedtestService service) {
    setState(() {
      _selected = service;
      _opened = true;
    });
    unawaited(SoraScope.read(context).settings.saveSpeedtestService(service.url));
  }

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    final settings = SoraScope.of(context).settings;
    final shell = context.dependOnInheritedWidgetOfExactType<ShellScope>();
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final browser = SpeedtestBrowser(
          key: ValueKey(_selected!.url),
          service: _selected!,
          visible: (shell?.nativeContentVisible ?? true) && (wide || _opened),
          onReturn: wide ? null : () => setState(() => _opened = false),
        );
        if (!wide && _opened) {
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) setState(() => _opened = false);
            },
            child: browser,
          );
        }
        final list = _list(settings);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (wide) SizedBox(width: 320, child: list) else Expanded(child: list),
            if (wide) ...[VerticalDivider(width: 1, color: palette.field), Expanded(child: browser)],
          ],
        );
      },
    );
  }

  Widget _list(Settings settings) {
    final palette = Palette.of(context), s = S.of(context);
    final query = _search.text.trim().toLowerCase();
    final filter = settings.speedtestFilter;
    final shown = speedtestServices
        .where(
          (service) =>
              (filter == 'all' || (filter == 'cis' ? service.isCis : !service.isCis)) &&
              '${service.name} ${service.url} ${service.regions.join(' ')} ${service.operator} ${service.measures} ${service.note}'
                  .toLowerCase()
                  .contains(query),
        )
        .toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(s.speedtest, style: Styles.heading.copyWith(color: palette.ink)),
          const SizedBox(height: 16),
          TextField(
            key: const ValueKey('speedtest-search'),
            controller: _search,
            onChanged: (_) => setState(() {}),
            enableInteractiveSelection: false,
            style: Styles.secondary.copyWith(color: palette.ink),
            decoration: InputDecoration(
              hintText: s.speedtestSearch,
              hintStyle: Styles.secondary.copyWith(color: palette.ink3),
              prefixIcon: Icon(Symbols.search_rounded, size: 18, color: palette.ink3),
              isDense: true,
              filled: true,
              fillColor: palette.field,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              for (final (value, label) in [
                ('all', s.speedtestAll),
                ('cis', s.speedtestCis),
                ('world', s.speedtestWorld),
              ])
                ChoiceChip(
                  key: ValueKey('speedtest-filter-$value'),
                  label: Text(label, style: Styles.caption.copyWith(color: palette.ink)),
                  selected: filter == value,
                  showCheckmark: false,
                  backgroundColor: palette.background,
                  selectedColor: palette.field,
                  side: BorderSide(color: filter == value ? palette.ink3 : palette.field),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  visualDensity: VisualDensity.compact,
                  onSelected: (_) async {
                    await settings.saveSpeedtestFilter(value);
                    if (mounted) setState(() {});
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(s.speedtestCount(shown.length), style: Styles.caption.copyWith(color: palette.ink3)),
          const SizedBox(height: 8),
          Expanded(
            child: shown.isEmpty
                ? Align(
                    alignment: Alignment.topLeft,
                    child: Text(s.speedtestEmpty, style: Styles.secondary.copyWith(color: palette.ink2)),
                  )
                : ListView.builder(
                    key: const PageStorageKey('speedtest-list'),
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: shown.length,
                    itemBuilder: (context, index) {
                      final service = shown[index];
                      final chosen = service == _selected;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Semantics(
                          selected: chosen,
                          button: true,
                          child: Material(
                            color: chosen ? palette.field : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            child: InkWell(
                              key: ValueKey('speedtest-service-${service.url}'),
                              borderRadius: BorderRadius.circular(8),
                              onTap: () => _choose(service),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(service.name, style: Styles.row.copyWith(color: palette.ink)),
                                    const SizedBox(height: 4),
                                    Text(
                                      service.regions.join(', '),
                                      style: Styles.caption.copyWith(color: palette.ink3),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class SpeedtestBrowser extends StatefulWidget {
  const SpeedtestBrowser({super.key, required this.service, this.visible = true, this.onReturn});

  final SpeedtestService service;
  final bool visible;
  final VoidCallback? onReturn;

  @override
  State<SpeedtestBrowser> createState() => _SpeedtestBrowserState();
}

class _SpeedtestBrowserState extends State<SpeedtestBrowser> {
  WebViewController? _controller;
  bool _ready = false;
  bool _canGoBack = false;
  String? _failure;
  String? _externalFailure;
  int _progress = 0;
  String? _mainUrl;
  Timer? _deadline;
  String get _url => widget.service.url;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_start());
    });
  }

  Future<void> _release() async {
    final controller = _controller;
    _controller = null;
    try {
      switch (controller?.platform) {
        case final LinuxWebViewController platform:
          await platform.dispose();
        case final WindowsWebViewController platform:
          await platform.dispose();
      }
    } catch (error) {
      debugPrint('Speedtest browser cleanup failed: $error');
    }
  }

  @override
  void dispose() {
    _deadline?.cancel();
    unawaited(_release());
    super.dispose();
  }

  void _failed(String message) {
    if (!mounted || _failure != null) return;
    _deadline?.cancel();
    setState(() {
      _failure = message;
      _ready = false;
    });
    unawaited(_release());
  }

  Future<void> _start() async {
    final s = S.of(context);
    _watchLoad();
    try {
      final controller = WebViewController();
      _controller = controller;
      // Attach the initialization error handler before other asynchronous calls.
      await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      await controller.setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) => const {'https', 'http'}.contains(Uri.tryParse(request.url)?.scheme)
              ? NavigationDecision.navigate
              : NavigationDecision.prevent,
          onPageStarted: (url) {
            _mainUrl = url;
            if (!mounted || _failure != null) return;
            setState(() => _progress = 0);
            _watchLoad();
          },
          onPageFinished: (_) async {
            _deadline?.cancel();
            try {
              final back = await controller.canGoBack();
              if (mounted && _failure == null) {
                setState(() {
                  _progress = 100;
                  _canGoBack = back;
                });
              }
            } catch (_) {
              _failed(s.speedtestPageFailed);
            }
          },
          onProgress: (progress) {
            if (mounted && _failure == null) setState(() => _progress = progress);
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame == true) _failed(s.speedtestPageFailed);
          },
          onHttpError: (error) {
            if (error.request?.uri.toString() == (_mainUrl ?? _url)) _failed(s.speedtestPageFailed);
          },
        ),
      );
      await controller.loadRequest(Uri.parse(_url));
      if (!mounted || _failure != null) return;
      setState(() => _ready = true);
      if (_progress < 100) _watchLoad();
    } catch (_) {
      _failed(s.speedtestUnavailable);
    }
  }

  void _watchLoad() {
    _deadline?.cancel();
    _deadline = Timer(const Duration(seconds: 45), () => _failed(S.of(context).speedtestPageFailed));
  }

  Future<void> _navigate({bool back = false}) async {
    if (_failure != null) {
      setState(() {
        _failure = null;
        _progress = 0;
      });
      await _start();
      return;
    }
    try {
      if (back) {
        await _controller!.goBack();
      } else {
        await _controller!.reload();
      }
    } catch (_) {
      if (mounted) _failed(S.of(context).speedtestPageFailed);
    }
  }

  Future<void> _open() async {
    final message = S.of(context).speedtestExternalFailed;
    try {
      final current = await _controller?.currentUrl() ?? _url;
      final uri = Uri.tryParse(current);
      if (uri == null ||
          !const {'https', 'http'}.contains(uri.scheme) ||
          !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw const FormatException('Browser did not open');
      }
      if (mounted) setState(() => _externalFailure = null);
    } catch (_) {
      if (mounted) setState(() => _externalFailure = message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context), palette = Palette.of(context), sora = SoraScope.of(context);
    final server = switch (sora.selected) {
      'auto' => s.serverAuto,
      'bypass' => s.serverBypass,
      final id => sora.nameOf(id),
    };
    final route = switch (sora.phase) {
      Phase.connected when sora.selected != 'bypass' => s.speedtestViaVpn(server),
      Phase.connecting => s.stateConnecting,
      Phase.reconnecting => s.stateReconnecting,
      Phase.disconnecting => s.stateDisconnecting,
      _ => s.speedtestNoVpn,
    };
    final service = widget.service;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: palette.surface,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    if (widget.onReturn != null)
                      RoundButton(
                        key: const ValueKey('speedtest-return'),
                        icon: Symbols.chevron_left_rounded,
                        label: s.speedtestBackToList,
                        onTap: widget.onReturn,
                      ),
                    Expanded(
                      child: Text(
                        service.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Styles.bodyStrong.copyWith(color: palette.ink),
                      ),
                    ),
                    RoundButton(
                      icon: Symbols.arrow_back_rounded,
                      label: s.speedtestBack,
                      onTap: _ready && _canGoBack ? () => unawaited(_navigate(back: true)) : null,
                    ),
                    RoundButton(
                      key: const ValueKey('speedtest-reload'),
                      icon: Symbols.refresh_rounded,
                      label: s.refresh,
                      onTap: _ready || _failure != null ? () => unawaited(_navigate()) : null,
                    ),
                    RoundButton(
                      key: const ValueKey('speedtest-external'),
                      icon: Symbols.open_in_new_rounded,
                      label: s.speedtestOpenBrowser,
                      onTap: () => unawaited(_open()),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  route,
                  key: const ValueKey('speedtest-route'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Styles.caption.copyWith(color: palette.ink2),
                ),
                const SizedBox(height: 4),
                Text(
                  _failure != null
                      ? s.speedtestOpenBrowser
                      : _progress < 100
                      ? s.speedtestLoading
                      : Uri.parse(_url).host,
                  style: Styles.caption.copyWith(color: palette.ink3),
                ),
                if (_externalFailure != null)
                  Text(_externalFailure!, style: Styles.caption.copyWith(color: palette.danger)),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${service.operator}: ${service.measures}', style: Styles.caption.copyWith(color: palette.ink2)),
              const SizedBox(height: 4),
              Text('${service.note}. ${s.speedtestRoutingNote}', style: Styles.caption.copyWith(color: palette.ink3)),
            ],
          ),
        ),
        Expanded(
          child: _failure != null
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _failure!,
                          key: const ValueKey('speedtest-fallback'),
                          style: Styles.body.copyWith(color: palette.ink),
                        ),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: () => unawaited(_open()),
                          icon: const Icon(Symbols.open_in_new_rounded, size: 18),
                          label: Text(s.speedtestOpenBrowser),
                        ),
                      ],
                    ),
                  ),
                )
              : !_ready
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(s.speedtestStarting, style: Styles.secondary.copyWith(color: palette.ink2)),
                )
              // Native GTK children cannot interleave with Flutter drawers or overlays.
              : widget.visible
              ? WebViewWidget(controller: _controller!)
              : const SizedBox.expand(),
        ),
      ],
    );
  }
}
