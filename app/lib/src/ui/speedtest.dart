import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_all/webview_all.dart';
import 'package:webview_all_linux/webview_all_linux.dart';
import 'package:webview_all_windows/webview_all_windows.dart';

import '../../l10n/strings.dart';
import '../design/theme.dart';
import '../notifications.dart';
import '../sora.dart';
import '../speedtest_services.dart';
import 'kit.dart';
import 'shell.dart';
import 'toasts.dart';

class SpeedtestScreen extends StatefulWidget {
  const SpeedtestScreen({super.key, this.initialService});
  final SpeedtestService? initialService;

  @override
  State<SpeedtestScreen> createState() => _SpeedtestScreenState();
}

class _SpeedtestScreenState extends State<SpeedtestScreen> {
  final _search = TextEditingController();
  final _browser = GlobalKey<_SpeedtestBrowserState>();
  SpeedtestService? _selected;
  bool _opened = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selected ??=
        widget.initialService ??
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
    final shell = context.dependOnInheritedWidgetOfExactType<ShellScope>();
    final toastVisible = ToastVisibility.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final browser = SpeedtestBrowser(
          key: _browser,
          service: _selected!,
          visible: !toastVisible && (shell?.nativeContentVisible ?? true) && (wide || _opened),
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
        final list = _list();
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

  Widget _list() {
    final palette = Palette.of(context), s = S.of(context);
    final query = _search.text.trim().toLowerCase();
    final shown = speedtestServices
        .where((service) => '${service.name} ${service.url}'.toLowerCase().contains(query))
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
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Semantics(
                          selected: chosen,
                          button: true,
                          child: Material(
                            color: chosen ? palette.field : palette.surface,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            child: InkWell(
                              key: ValueKey('speedtest-service-${service.url}'),
                              borderRadius: BorderRadius.circular(8),
                              onTap: () => _choose(service),
                              child: SizedBox(
                                height: 56,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Center(
                                    child: Text(
                                      service.name,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: Styles.bodyStrong.copyWith(color: palette.ink),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (MediaQuery.sizeOf(context).width >= 1000)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  RoundButton(
                    icon: Symbols.arrow_back_rounded,
                    label: s.tourBack,
                    onTap: () => unawaited(_browser.currentState?._back()),
                  ),
                  RoundButton(
                    icon: Symbols.refresh_rounded,
                    label: s.refresh,
                    onTap: () => unawaited(_browser.currentState?._retry()),
                  ),
                  RoundButton(
                    icon: Symbols.open_in_new_rounded,
                    label: s.speedtestOpenBrowser,
                    onTap: () => unawaited(_browser.currentState?._open()),
                  ),
                ],
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
  String? _failure;
  String? _mainUrl;
  Timer? _deadline;
  Timer? _retryDelay;
  int _automaticRetries = 0;
  Future<void>? _releaseWork;
  bool _starting = false;
  int _generation = 0;
  String get _url => widget.service.url;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_start());
    });
  }

  @override
  void didUpdateWidget(SpeedtestBrowser oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.service.url != _url) {
      _deadline?.cancel();
      _retryDelay?.cancel();
      _retryDelay = null;
      _automaticRetries = 0;
      _generation++;
      _failure = null;
      _mainUrl = null;
      unawaited(_start());
    }
  }

  Future<void> _release() async {
    final controller = _controller;
    _controller = null;
    if (controller == null) {
      await _releaseWork;
      return;
    }
    try {
      _releaseWork = (switch (controller.platform) {
        final LinuxWebViewController platform => platform.dispose(),
        final WindowsWebViewController platform => platform.dispose(),
        _ => null,
      })?.catchError((Object error) => debugPrint('Speedtest browser cleanup failed: $error'));
      await _releaseWork;
    } catch (error) {
      debugPrint('Speedtest browser cleanup failed: $error');
    } finally {
      _releaseWork = null;
    }
  }

  @override
  void dispose() {
    _generation++;
    _deadline?.cancel();
    _retryDelay?.cancel();
    unawaited(_release());
    super.dispose();
  }

  void _failed(String message, {bool retry = true}) {
    if (!mounted || _failure != null) return;
    _deadline?.cancel();
    _generation++;
    setState(() {
      _ready = false;
      _failure = retry && _automaticRetries < 2 ? null : message;
    });
    unawaited(_release());
    if (_failure == null) {
      _automaticRetries++;
      _retryDelay = Timer(Duration(seconds: _automaticRetries), () {
        _retryDelay = null;
        if (mounted) unawaited(_start());
      });
      return;
    }
    unawaited(
      SoraScope.read(context).recordNotification(
        AppNotification(
          time: DateTime.now(),
          title: widget.service.name,
          body: message,
          action: 'speedtest',
          argument: _url,
        ),
      ),
    );
  }

  Future<void> _start() async {
    if (_starting || !mounted) return;
    _starting = true;
    final generation = _generation;
    final s = S.of(context);
    _watchLoad();
    try {
      await _releaseWork?.timeout(const Duration(seconds: 10));
      if (!mounted || generation != _generation) return;
      final controller = _controller ??= WebViewPlatform.instance is LinuxWebViewPlatform
          ? WebViewController.fromPlatformCreationParams(
              const LinuxWebViewControllerCreationParams(
                pageCacheEnabled: false,
                mediaPlaybackRequiresUserGesture: true,
                javascriptCanOpenWindowsAutomatically: false,
              ),
            )
          : WebViewController();
      // Attach the initialization error handler before other asynchronous calls.
      await controller.setJavaScriptMode(JavaScriptMode.unrestricted).timeout(const Duration(seconds: 25));
      if (!mounted || generation != _generation) return;
      await controller.setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) => const {'https', 'http'}.contains(Uri.tryParse(request.url)?.scheme)
              ? NavigationDecision.navigate
              : NavigationDecision.prevent,
          onPageStarted: (url) {
            if (!mounted || generation != _generation) return;
            if (!const {'https', 'http'}.contains(Uri.tryParse(url)?.scheme)) return;
            _mainUrl = url;
            if (!mounted || _failure != null) return;
            _watchLoad();
          },
          onPageFinished: (url) {
            if (mounted && generation == _generation && url == _mainUrl) {
              _deadline?.cancel();
              _automaticRetries = 0;
            }
          },
          onWebResourceError: (error) {
            // WebView2 cancels the previous navigation when another service
            // is selected; its callback can arrive after the delegate changes.
            if (error is WindowsWebResourceError && error.description == 'WebErrorStatusOperationCanceled') return;
            if (generation == _generation &&
                error.isForMainFrame == true &&
                (error.url == null || error.url == (_mainUrl ?? _url))) {
              _failed(s.speedtestPageFailed, retry: error.errorType != WebResourceErrorType.failedSslHandshake);
            }
          },
          onHttpError: (error) {
            if (generation == _generation && error.request?.uri.toString() == (_mainUrl ?? _url)) {
              _failed(s.speedtestPageFailed);
            }
          },
        ),
      );
      if (!mounted || generation != _generation) return;
      await controller.loadRequest(Uri.parse(_url)).timeout(const Duration(seconds: 5));
      if (!mounted || generation != _generation || _failure != null) return;
      setState(() => _ready = true);
    } catch (error) {
      if (generation == _generation) {
        final missingRuntime =
            error is MissingPluginException ||
            (error is TimeoutException && _controller == null) ||
            (error is PlatformException &&
                const {'webkit_unavailable', 'webview2_runtime_unavailable'}.contains(error.code));
        _failed(s.speedtestUnavailable, retry: !missingRuntime);
      }
    } finally {
      _starting = false;
      if (mounted && generation != _generation && _failure == null && _retryDelay == null) unawaited(_start());
    }
  }

  void _watchLoad() {
    _deadline?.cancel();
    _deadline = Timer(const Duration(seconds: 45), () => _failed(S.of(context).speedtestPageFailed));
  }

  Future<void> _retry() async {
    if (_starting || !mounted) return;
    _retryDelay?.cancel();
    _retryDelay = null;
    _automaticRetries = 0;
    _generation++;
    setState(() => _failure = null);
    await _start();
  }

  Future<void> _back() async {
    final controller = _controller;
    if (controller == null || _starting) return;
    try {
      if (await controller.canGoBack() && mounted && controller == _controller) await controller.goBack();
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
    } catch (_) {
      if (mounted) {
        unawaited(
          SoraScope.read(context)
              .recordNotification(AppNotification(time: DateTime.now(), title: widget.service.name, body: message)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context), palette = Palette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.onReturn != null)
          Align(
            alignment: Alignment.centerLeft,
            child: RoundButton(
              key: const ValueKey('speedtest-return'),
              icon: Symbols.chevron_left_rounded,
              label: s.speedtestBackToList,
              onTap: widget.onReturn,
            ),
          ),
        Expanded(
          child: _failure != null
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _failure!,
                          textAlign: TextAlign.center,
                          style: Styles.secondary.copyWith(color: palette.ink2),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          key: const ValueKey('speedtest-reload'),
                          onPressed: () => unawaited(_retry()),
                          child: Text(s.refresh),
                        ),
                        TextButton.icon(
                          key: const ValueKey('speedtest-fallback'),
                          onPressed: () => unawaited(_open()),
                          icon: const Icon(Symbols.open_in_new_rounded, size: 18),
                          label: Text(s.speedtestOpenBrowser),
                        ),
                      ],
                    ),
                  ),
                )
              : !_ready
              ? Center(child: CupertinoActivityIndicator(color: palette.ink))
              // Native GTK children cannot interleave with Flutter drawers or overlays.
              : widget.visible
              ? WebViewWidget(controller: _controller!)
              : const SizedBox.expand(),
        ),
      ],
    );
  }
}
