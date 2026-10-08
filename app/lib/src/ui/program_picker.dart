import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:jovial_svg/jovial_svg.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:xdg_icons/xdg_icons.dart';

import '../../l10n/strings.dart';
import '../desktop/programs.dart';
import '../design/theme.dart';
import 'kit.dart';
import '../sora.dart';

Future<String?> chooseProgram(BuildContext context) =>
    showDialog<String>(context: context, builder: (_) => const _ProgramPicker());

class _ProgramPicker extends StatefulWidget {
  const _ProgramPicker();
  @override
  State<_ProgramPicker> createState() => _ProgramPickerState();
}

class _ProgramPickerState extends State<_ProgramPicker> {
  final _search = TextEditingController();
  List<Program>? _programs;
  bool _failed = false;
  bool _running = Platform.isWindows;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
    _load();
  }

  Future<void> _load() async {
    SoraScope.read(context).recovered('programs');
    final request = ++_request;
    setState(() {
      _programs = null;
      _failed = false;
    });
    try {
      final programs = _running ? await runningPrograms() : await installedPrograms();
      if (mounted && request == _request) setState(() => _programs = programs);
    } catch (error) {
      if (mounted && request == _request) {
        setState(() => _failed = true);
        SoraScope.read(context).reportFailure(error, source: 'programs');
      }
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Widget _icon(Program app, Palette palette) {
    final fallback = Icon(app.running ? Symbols.memory_rounded : Symbols.apps_rounded, size: 24, color: palette.ink3);
    if (!Platform.isLinux || app.icon.isEmpty) return fallback;
    // Desktop entries may use a file path instead of an icon-theme name.
    if (app.icon.startsWith('/')) {
      final file = File(app.icon);
      if (app.icon.toLowerCase().endsWith('.svg')) {
        return SizedBox.square(
          dimension: 24,
          child: ScalableImageWidget.fromSISource(
            si: ScalableImageSource.fromSvgFile(file.path, file.readAsString),
            onError: (_) => fallback,
          ),
        );
      }
      return Image.file(file, width: 24, height: 24, errorBuilder: (_, _, _) => fallback);
    }
    return XdgIcon(key: ValueKey(app.icon), name: app.icon, size: 24, iconNotFoundBuilder: () => fallback);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context), palette = Palette.of(context);
    final query = _search.text.toLowerCase();
    final shown = _programs?.where((p) => '${p.name} ${p.binary} ${p.icon}'.toLowerCase().contains(query)).toList();
    return Dialog(
      backgroundColor: palette.raised,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 560),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(s.chooseProgram, style: Styles.heading.copyWith(color: palette.ink)),
                  ),
                  RoundButton(icon: Symbols.close_rounded, label: s.close, onTap: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 12),
              if (Platform.isLinux)
                Segments<bool>(
                  value: _running,
                  choices: {false: s.installedApps, true: s.runningProcesses},
                  onChanged: (value) {
                    _running = value;
                    _load();
                  },
                ),
              if (Platform.isWindows)
                TextButton(
                  onPressed: () async {
                    final file = await openFile(
                      acceptedTypeGroups: const [
                        XTypeGroup(label: 'Windows application', extensions: ['exe']),
                      ],
                    );
                    if (file != null && context.mounted) Navigator.pop(context, file.name);
                  },
                  child: Text(s.selectExe),
                ),
              const SizedBox(height: 12),
              TextField(
                controller: _search,
                autofocus: true,
                style: Styles.body.copyWith(color: palette.ink),
                decoration: InputDecoration(
                  hintText: s.search,
                  prefixIcon: const Icon(Symbols.search_rounded),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _failed
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [TextButton(onPressed: _load, child: Text(s.refresh))],
                        ),
                      )
                    : shown == null
                    ? const Center(child: CircularProgressIndicator())
                    : shown.isEmpty
                    ? Center(
                        child: Text(s.programsEmpty, style: Styles.secondary.copyWith(color: palette.ink2)),
                      )
                    : ListView.builder(
                        itemCount: shown.length,
                        itemBuilder: (context, i) {
                          final app = shown[i];
                          return Tile(
                            title: app.name,
                            detail: app.binary,
                            trailing: _icon(app, palette),
                            onTap: () => Navigator.pop(context, app.binary),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
