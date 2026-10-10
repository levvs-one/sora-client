import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../l10n/strings.dart';
import '../core/link.dart';
import '../design/logo.dart';
import '../design/theme.dart';
import '../desktop/desktop.dart';
import '../generated/sora/core/v1/core_control.pbgrpc.dart';
import '../sora.dart';
import '../updates.dart';
import 'kit.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  About? _about;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_load()));
  }

  Future<void> _load() async {
    final link = SoraScope.read(context).link;
    if (link == null) return;
    try {
      final answer = await link.stub.getAbout(GetAboutRequest(apiVersion: apiVersion));
      if (answer.hasError()) throw CoreFailure(answer.error.userMessageKey);
      if (mounted) {
        SoraScope.read(context).recovered('about');
        setState(() => _about = answer.about);
      }
    } catch (error) {
      if (mounted) SoraScope.read(context).reportFailure(error, source: 'about');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final palette = Palette.of(context);
    final about = _about;
    final sora = SoraScope.of(context);
    final updates = sora.updates;
    final release = updates.latest;
    final desktop = DesktopScope.maybeOf(context);
    final canInstall = !sora.busy && sora.phase != Phase.reconnecting && sora.phase != Phase.offline;
    final updateButton = TextButton.icon(
      key: const ValueKey('check-app-updates'),
      onPressed: updates.checking || updates.busy ? null : () => unawaited(updates.check(manual: true)),
      icon: updates.checking
          ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Symbols.system_update_alt_rounded, size: 20, weight: 600),
      label: Text(s.updateCheck),
    );
    final updateTitle = Text(
      updates.hasUpdate
          ? s.updateAvailable(release!.version)
          : updates.installed
          ? s.updateInstalled
          : s.updates,
      style: Styles.body.copyWith(color: palette.ink),
    );
    return Screen(
      title: s.about,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 32, 12, 32),
          child: Column(
            children: [
              SoraMark(size: 48, color: palette.ink),
              const SizedBox(height: 12),
              Text('Sora', style: Styles.title.copyWith(color: palette.ink)),
              const SizedBox(height: 4),
              Text(s.appVersion(updates.version), style: Styles.secondary.copyWith(color: palette.ink2)),
            ],
          ),
        ),
        Group(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: LayoutBuilder(
                builder: (_, constraints) => constraints.maxWidth >= 480
                    ? Row(
                        children: [
                          Expanded(child: updateTitle),
                          const SizedBox(width: 12),
                          updateButton,
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [updateTitle, const SizedBox(height: 8), updateButton],
                      ),
              ),
            ),
            if (release != null) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(s.updateNotes(release.version), style: Styles.bodyStrong.copyWith(color: palette.ink)),
                    const SizedBox(height: 8),
                    if (release.notes.isEmpty)
                      Text(s.updateNoNotes, style: Styles.secondary.copyWith(color: palette.ink2))
                    else
                      MarkdownBody(
                        key: const ValueKey('release-notes'),
                        data: release.notes,
                        selectable: true,
                        imageBuilder: (_, _, alt) =>
                            Text(alt ?? '', style: Styles.secondary.copyWith(color: palette.ink2)),
                        styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                          p: Styles.secondary.copyWith(color: palette.ink2),
                          a: Styles.secondary.copyWith(color: palette.ink, decoration: TextDecoration.underline),
                          h1: Styles.heading.copyWith(color: palette.ink),
                          h2: Styles.bodyStrong.copyWith(color: palette.ink),
                          h3: Styles.bodyStrong.copyWith(color: palette.ink),
                          listBullet: Styles.secondary.copyWith(color: palette.ink2),
                          code: Styles.caption.copyWith(color: palette.ink),
                        ),
                        onTapLink: (_, href, _) {
                          if (href != null) unawaited(openLink(context, href));
                        },
                      ),
                  ],
                ),
              ),
            ],
            if (updates.hasUpdate)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PrimaryButton(
                      key: const ValueKey('install-update'),
                      label: s.refresh,
                      busy: updates.busy,
                      onTap: canInstall && desktop != null
                          ? () => unawaited(
                              updates.install(
                                confirmDrop: () => !mounted
                                    ? Future.value(false)
                                    : confirm(
                                        context,
                                        question: s.updateDropWarning,
                                        action: s.refresh,
                                        destructive: false,
                                      ),
                                launchWindows: desktop.launchUpdate,
                                restartLinux: desktop.restartAfterUpdate,
                                quit: desktop.quit,
                              ),
                            )
                          : null,
                    ),
                    if (updates.busy) ...[
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: updates.progress,
                        color: palette.ink,
                        backgroundColor: palette.field,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        updates.progress == null ? s.updateInstalling : s.updateDownloading,
                        style: Styles.caption.copyWith(color: palette.ink2),
                      ),
                    ],
                    if (!canInstall) ...[
                      const SizedBox(height: 8),
                      Text(s.updateWaitConnection, style: Styles.secondary.copyWith(color: palette.ink2)),
                    ],
                  ],
                ),
              ),
            if (updates.error case final error?)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(switch (error) {
                  UpdateError.network => s.updateNetworkError,
                  UpdateError.release => s.updateReleaseError,
                  UpdateError.checksum => s.updateChecksumError,
                  UpdateError.installation => s.updateInstallError,
                  UpdateError.connecting => s.updateWaitConnection,
                  UpdateError.unsupported => s.updateUnsupported,
                }, style: Styles.secondary.copyWith(color: palette.danger)),
              ),
            if (updates.manualCommand case final command?)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(s.updateManual, style: Styles.secondary.copyWith(color: palette.ink2)),
                    const SizedBox(height: 8),
                    SelectableText(
                      command,
                      key: const ValueKey('update-command'),
                      style: Styles.caption.copyWith(color: palette.ink),
                    ),
                    TextButton(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: command));
                      },
                      child: Text(s.updateCopyCommand),
                    ),
                  ],
                ),
              ),
            if (!updates.checking && release == null && !sora.settings.checkUpdates)
              Tile(title: s.updateChecksDisabled),
          ],
        ),
        if (about != null) ...[
          Group(
            children: [
              Tile(title: s.engine, trailing: _value(context, 'Sora ${about.coreVersion}')),
              for (final e in about.engines)
                Tile(
                  title: switch (e.kind) {
                    'xray' => 'Xray',
                    _ => e.kind,
                  },
                  trailing: _value(context, e.installed ? e.version : s.notInstalled),
                ),
            ],
          ),
        ],
        Heading(s.projectLinks),
        Group(
          children: [
            LinkTile(
              title: s.githubReleases,
              value: 'GitHub',
              onTap: () => unawaited(openLink(context, 'https://github.com/levvs-one/sora-client/releases')),
            ),
            LinkTile(
              title: s.telegramChannel,
              value: '@sora_client',
              onTap: () => unawaited(openLink(context, 'https://t.me/sora_client')),
            ),
            LinkTile(
              title: s.sourceCode,
              value: 'GitHub',
              onTap: () => unawaited(openLink(context, 'https://github.com/levvs-one/sora-client')),
            ),
          ],
        ),
        Heading(s.licenses),
        Group(
          children: [
            Tile(title: 'Sora', trailing: _value(context, 'GPL-3.0-only')),
            LinkTile(
              title: s.componentLicenses,
              onTap: () => unawaited(
                push(
                  context,
                  Theme(
                    data: Theme.of(context).copyWith(
                      textTheme: Theme.of(context).textTheme.copyWith(
                        headlineSmall: Styles.heading.copyWith(color: palette.ink),
                        titleLarge: Styles.heading.copyWith(color: palette.ink),
                        titleMedium: Styles.bodyStrong.copyWith(color: palette.ink),
                        bodyLarge: Styles.body.copyWith(color: palette.ink),
                        bodyMedium: Styles.secondary.copyWith(color: palette.ink2),
                        bodySmall: Styles.caption.copyWith(color: palette.ink2),
                      ),
                    ),
                    child: LicensePage(
                      applicationName: 'Sora',
                      applicationVersion: updates.version,
                      applicationIcon: SoraMark(size: 40, color: palette.ink),
                      applicationLegalese: s.appCopyright,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _value(BuildContext context, String text) =>
      Text(text, style: Styles.secondary.copyWith(color: Palette.of(context).ink));
}
