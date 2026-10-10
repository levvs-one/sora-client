import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/strings.dart';
import '../core/link.dart';
import '../design/theme.dart';
import '../desktop/desktop.dart';
import '../generated/sora/core/v1/core_control.pbgrpc.dart';
import '../settings.dart';
import '../sora.dart';
import 'about.dart';
import 'connections.dart';
import 'kit.dart';
import 'logs.dart';
import 'rules_screen.dart';
import 'subscription.dart';
import 'subscription_sheet.dart';
import 'shell.dart';
import 'modes.dart';

/// App settings, with common options first and advanced options in named
/// groups.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  /// Core log settings; null until loaded or when unavailable.
  LogSettings? _log;

  /// Temporarily shows confirmation after copying the proxy address.
  bool _copied = false;

  // Match core validation to reject invalid settings before connection.
  static final _range = RegExp(r'^\d{1,5}-\d{1,5}$');
  static final _packets = RegExp(r'^(tlshello|\d{1,3}-\d{1,3})$');
  static final _position = RegExp(r'^(-?\d{1,4}|(method|host|endhost|sld|midsld|endsld|sniext)([+-]\d{1,4})?)$');
  static final _resolver = RegExp(r'^[A-Za-z0-9\[\]:._/-]+$');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_readLog()));
  }

  Future<void> _readLog() async {
    final link = SoraScope.read(context).link;
    if (link == null) return;
    try {
      final answer = await link.stub.getLogSettings(
        GetLogSettingsRequest(apiVersion: apiVersion, controlAuthenticator: link.token),
      );
      if (answer.hasError()) throw CoreFailure(answer.error.userMessageKey);
      if (mounted) {
        SoraScope.read(context).recovered('log-settings');
        setState(() => _log = answer.settings);
      }
    } catch (error) {
      if (mounted) SoraScope.read(context).reportFailure(error, source: 'log-settings');
      // Keep log navigation available when core settings cannot be loaded.
    }
  }

  Future<void> _writeLog(void Function(LogSettings) apply) async {
    final link = SoraScope.read(context).link;
    final current = _log;
    if (link == null || current == null) return;
    final next = current.deepCopy();
    apply(next);
    setState(() => _log = next);
    try {
      final answer = await link.stub.setLogSettings(
        SetLogSettingsRequest(apiVersion: apiVersion, controlAuthenticator: link.token, settings: next),
      );
      if (answer.hasError()) throw CoreFailure(answer.error.userMessageKey);
      if (mounted) {
        SoraScope.read(context).recovered('log-settings');
        setState(() => _log = answer.settings);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _log = current);
        SoraScope.read(context).reportFailure(error, source: 'log-settings');
      }
    }
  }

  /// Edits a text setting; empty input restores the default.
  void _edit({
    required String title,
    required String hint,
    required String initial,
    required bool Function(String) valid,
    required void Function(Settings, String) apply,
  }) {
    final s = S.of(context);
    final sora = SoraScope.read(context);
    unawaited(
      showFieldSheet(
        context,
        title: title,
        hint: hint,
        action: s.save,
        initial: initial,
        allowEmpty: true,
        submit: (value) async {
          if (value.isNotEmpty && !valid(value)) return s.invalidValue;
          await sora.change((x) => apply(x, value));
          return null;
        },
      ),
    );
  }

  static List<String> _parts(String value) => [
    for (final p in value.split(RegExp(r'[,\s]+')))
      if (p.isNotEmpty) p,
  ];

  static bool _web(String value) {
    final uri = Uri.tryParse(value);
    return uri != null && (uri.isScheme('https') || uri.isScheme('http')) && uri.host.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final sora = SoraScope.of(context);
    final settings = sora.settings;
    final s = S.of(context);
    final palette = Palette.of(context);
    void set(void Function(Settings) apply, {bool replan = true}) => unawaited(sora.change(apply, replan: replan));
    final log = _log;
    final desktop = DesktopScope.maybeOf(context);
    final local = sora.localProxy;
    return Screen(
      title: s.settings,
      children: [
        if (sora.needsReconnect) ...[const ConnectionChanges(), const SizedBox(height: 16)],
        Group(
          children: [
            ChoiceTile<String>(
              title: s.routes,
              value: settings.preset,
              choices: {'global': s.presetGlobal, 'ru': s.presetRu, 'ir': s.presetIr, 'cn': s.presetCn},
              onChanged: (v) => set((x) => x.preset = v),
            ),
            LinkTile(title: s.modes, onTap: () => showModes(context)),
            if (settings.tunnel == 'proxy' && local != null)
              // Expose the endpoint for manual configuration when apps or
              // desktops do not use the system proxy.
              LinkTile(
                title: s.proxyAddress,
                value: _copied ? s.copied : '${local.host}:${local.port}',
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: '${local.host}:${local.port}'));
                  setState(() => _copied = true);
                  await Future<void>.delayed(const Duration(milliseconds: 1500));
                  if (mounted) setState(() => _copied = false);
                },
              ),
            SwitchTile(title: s.blockAds, value: settings.blockAds, onChanged: (v) => set((x) => x.blockAds = v)),
          ],
        ),
        Group(
          children: [
            SwitchTile(
              title: s.checkUpdates,
              value: settings.checkUpdates,
              onChanged: (v) => unawaited(sora.updates.setChecking(v)),
            ),
            if (desktop != null)
              SwitchTile(
                title: s.launchAtLogin,
                value: settings.launchAtLogin,
                onChanged: (v) async {
                  await sora.change((x) => x.launchAtLogin = v, replan: false);
                  desktop.syncLaunchAtLogin();
                },
              ),
            SwitchTile(
              title: s.connectOnStart,
              value: settings.connectOnStart,
              onChanged: (v) => set((x) => x.connectOnStart = v, replan: false),
            ),
            if (desktop != null) ...[
              SwitchTile(
                title: s.closeToTray,
                value: settings.closeToTray,
                onChanged: (v) => set((x) => x.closeToTray = v, replan: false),
              ),
              SwitchTile(
                title: s.notifications,
                value: settings.notifications,
                onChanged: (v) => set((x) => x.notifications = v, replan: false),
              ),
            ],
          ],
        ),
        Group(
          children: [
            ChoiceTile<String>(
              title: s.theme,
              value: settings.theme,
              choices: {'system': s.themeSystem, 'light': s.themeLight, 'dark': s.themeDark},
              onChanged: (v) => set((x) => x.theme = v, replan: false),
            ),
            ChoiceTile<String>(
              title: s.language,
              value: settings.language,
              // Use native language names so the current UI language does not
              // prevent selection.
              choices: {'system': s.languageSystem, 'ru': 'Русский', 'en': 'English'},
              onChanged: (v) => set((x) => x.language = v, replan: false),
            ),
            SwitchTile(
              title: s.animations,
              value: settings.animations,
              onChanged: (v) => set((x) => x.animations = v, replan: false),
            ),
            if (context.getInheritedWidgetOfExactType<ShellScope>() case final shell?)
              LinkTile(title: s.tourReplay, onTap: shell.replayTour),
          ],
        ),

        Heading(s.sectionConnection),
        Group(
          children: [
            LinkTile(
              title: s.rules,
              value: settings.rules.isEmpty ? null : '${settings.rules.length}',
              onTap: () => push<void>(context, const RulesScreen()),
            ),
            SwitchTile(title: s.failover, value: settings.failover, onChanged: (v) => set((x) => x.failover = v)),
            SwitchTile(title: s.ipv6, value: settings.ipv6, onChanged: (v) => set((x) => x.ipv6 = v)),
            LinkTile(
              title: s.dns,
              value: settings.dns.isEmpty ? s.dnsAuto : settings.dns.first,
              onTap: () => _edit(
                title: s.dns,
                hint: s.dnsHint,
                initial: settings.dns.join(', '),
                valid: (v) => _parts(v).every(_resolver.hasMatch),
                apply: (x, v) => x.dns = _parts(v),
              ),
            ),
            SwitchTile(title: s.fragment, value: settings.fragment, onChanged: (v) => set((x) => x.fragment = v)),
            if (settings.fragment) ...[
              LinkTile(
                title: s.fragmentPackets,
                value: settings.fragmentPackets.isEmpty ? s.byDefault : settings.fragmentPackets,
                onTap: () => _edit(
                  title: s.fragmentPackets,
                  hint: 'tlshello',
                  initial: settings.fragmentPackets,
                  valid: _packets.hasMatch,
                  apply: (x, v) => x.fragmentPackets = v,
                ),
              ),
              LinkTile(
                title: s.fragmentLength,
                value: settings.fragmentLength.isEmpty ? s.byDefault : settings.fragmentLength,
                onTap: () => _edit(
                  title: s.fragmentLength,
                  hint: s.rangeHint,
                  initial: settings.fragmentLength,
                  valid: _range.hasMatch,
                  apply: (x, v) => x.fragmentLength = v,
                ),
              ),
              LinkTile(
                title: s.fragmentInterval,
                value: settings.fragmentInterval.isEmpty ? s.byDefault : settings.fragmentInterval,
                onTap: () => _edit(
                  title: s.fragmentInterval,
                  hint: s.rangeHint,
                  initial: settings.fragmentInterval,
                  valid: _range.hasMatch,
                  apply: (x, v) => x.fragmentInterval = v,
                ),
              ),
            ],
          ],
        ),

        if (sora.serverlessAvailable) ...[
          Heading(s.sectionNoServer),
          Group(
            children: [
              LinkTile(
                title: s.splitPos,
                value: settings.splitPos.join(', '),
                onTap: () => _edit(
                  title: s.splitPos,
                  hint: s.splitPosHint,
                  initial: settings.splitPos.join(', '),
                  valid: (v) => _parts(v).every(_position.hasMatch),
                  apply: (x, v) => x.splitPos = v.isEmpty ? const ['1', 'midsld'] : _parts(v),
                ),
              ),
              SwitchTile(title: s.disorder, value: settings.disorder, onChanged: (v) => set((x) => x.disorder = v)),
              ChoiceTile<String>(
                title: s.tlsRecord,
                value: settings.tlsRecord,
                choices: {'': s.tlsRecordNo, 'sniext': s.tlsRecordSni, '1': s.tlsRecordFirst},
                onChanged: (v) => set((x) => x.tlsRecord = v),
              ),
              SwitchTile(title: s.hostCase, value: settings.hostCase, onChanged: (v) => set((x) => x.hostCase = v)),
            ],
          ),
        ],
        Heading(s.sectionPing),
        Group(
          children: [
            ChoiceTile<String>(
              title: s.probeMethod,
              value: settings.probeMethod,
              choices: {'auto': s.probeAuto, 'engine': s.probeEngine, 'connect': s.probeConnect},
              onChanged: (v) => set((x) => x.probeMethod = v, replan: false),
            ),
            LinkTile(
              title: s.probeUrl,
              value: settings.probeUrl.isEmpty ? s.byDefault : Uri.parse(settings.probeUrl).host,
              onTap: () => _edit(
                title: s.probeUrl,
                hint: 'https://www.gstatic.com/generate_204',
                initial: settings.probeUrl,
                valid: _web,
                apply: (x, v) => x.probeUrl = v,
              ),
            ),
            ChoiceTile<int>(
              title: s.probeTimeout,
              value: settings.probeTimeout,
              choices: {0: s.byDefault, 2000: s.seconds(2), 5000: s.seconds(5), 10000: s.seconds(10)},
              onChanged: (v) => set((x) => x.probeTimeout = v, replan: false),
            ),
          ],
        ),

        const SizedBox(height: 12),
        Group(
          children: [
            Tile(
              title: s.subscriptions,
              titleStyle: Styles.bodyStrong,
              trailing: Icon(Icons.chevron_right_rounded, size: 20, color: palette.ink),
              onTap: () => push<void>(context, const SubscriptionsScreen()),
            ),
          ],
        ),

        Heading(s.sectionLog),
        Group(
          children: [
            if (log != null) ...[
              ChoiceTile<LogLevel>(
                title: s.logLevel,
                value: log.captureLevel == LogLevel.LOG_LEVEL_UNSPECIFIED ? LogLevel.LOG_LEVEL_INFO : log.captureLevel,
                choices: {
                  LogLevel.LOG_LEVEL_DEBUG: s.levelDebug,
                  LogLevel.LOG_LEVEL_INFO: s.levelInfo,
                  LogLevel.LOG_LEVEL_WARNING: s.levelWarning,
                  LogLevel.LOG_LEVEL_ERROR: s.levelError,
                },
                onChanged: (v) => unawaited(_writeLog((x) => x.captureLevel = v)),
              ),
              SwitchTile(
                title: s.recordDestinations,
                value: log.recordDestinations,
                onChanged: (v) => unawaited(_writeLog((x) => x.recordDestinations = v)),
              ),
            ],
            LinkTile(title: s.logs, onTap: () => push<void>(context, const LogsScreen())),
            LinkTile(title: s.connections, onTap: () => push<void>(context, const ConnectionsScreen())),
          ],
        ),

        Group(
          children: [
            LinkTile(
              title: s.about,
              value: sora.updates.hasUpdate ? s.updateAvailable(sora.updates.latest!.version) : null,
              onTap: () => push<void>(context, const AboutScreen()),
            ),
            Tile(
              title: s.reset,
              titleColor: palette.danger,
              onTap: () async {
                if (await confirm(context, question: s.resetConfirm, action: s.resetAction)) await sora.reset();
              },
            ),
          ],
        ),
      ],
    );
  }
}
