import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/strings.dart';
import '../design/theme.dart';
import '../sora.dart';
import 'kit.dart';

/// Prompts for a subscription URL. Prefills [link] from a browser or messenger
/// import; otherwise checks the clipboard for a URL.
Future<void> showSubscriptionSheet(BuildContext context, {String? link, String name = ''}) async {
  final sora = SoraScope.read(context);
  final s = S.of(context);
  var initial = link ?? '';
  if (link == null) {
    final clip = await Clipboard.getData(Clipboard.kTextPlain);
    final text = clip?.text?.trim() ?? '';
    if (text.startsWith('https://') && !text.contains('\n')) initial = text;
  }
  if (!context.mounted) return;
  await showFieldSheet(
    context,
    title: link == null ? s.subscription : s.importTitle,
    hint: s.subscriptionLink,
    action: s.add,
    initial: initial,
    keyboard: TextInputType.url,
    submit: (url) async {
      final failure = await sora.addSubscription(url, name: name);
      return failure == null ? null : describe(s, failure);
    },
  );
}

/// Shows a centred field sheet with a scale transition. [submit] returns an
/// error to display below the field, or null to close the sheet.
Future<void> showFieldSheet(
  BuildContext context, {
  required String title,
  required String hint,
  required String action,
  required Future<String?> Function(String) submit,
  String initial = '',
  TextInputType keyboard = TextInputType.text,
  bool allowEmpty = false,
  Widget? extra,
  TextEditingController? controller,
}) {
  final motion = Motion.enabled(context);
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Palette.of(context).scrim,
    transitionDuration: motion ? Motion.medium : Duration.zero,
    pageBuilder: (_, _, _) => _FieldSheet(
      title: title,
      hint: hint,
      action: action,
      submit: submit,
      initial: initial,
      keyboard: keyboard,
      allowEmpty: allowEmpty,
      extra: extra,
      controller: controller,
    ),
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(parent: animation, curve: Motion.curve, reverseCurve: Curves.easeIn);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(scale: Tween(begin: 0.94, end: 1.0).animate(curved), child: child),
      );
    },
  );
}

class _FieldSheet extends StatefulWidget {
  const _FieldSheet({
    required this.title,
    required this.hint,
    required this.action,
    required this.submit,
    required this.initial,
    required this.keyboard,
    required this.allowEmpty,
    this.extra,
    this.controller,
  });

  final String title;
  final String hint;
  final String action;
  final Future<String?> Function(String) submit;
  final String initial;
  final TextInputType keyboard;

  /// Allows empty input to select the default value.
  final bool allowEmpty;

  /// An additional setting displayed below the field.
  final Widget? extra;
  final TextEditingController? controller;

  @override
  State<_FieldSheet> createState() => _FieldSheetState();
}

class _FieldSheetState extends State<_FieldSheet> {
  late final _field = widget.controller ?? TextEditingController(text: widget.initial);
  String? _failure;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _field.addListener(() => setState(() => _failure = null));
  }

  @override
  void dispose() {
    if (widget.controller == null) _field.dispose();
    super.dispose();
  }

  Future<void> _go() async {
    final value = _field.text.trim();
    if (_busy) return;
    setState(() => _busy = true);
    final failure = await widget.submit(value);
    if (!mounted) return;
    if (failure == null) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _busy = false;
        _failure = failure;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    final s = S.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Material(
          color: palette.raised,
          elevation: 24,
          shadowColor: palette.shadow,
          borderRadius: BorderRadius.circular(26),
          child: SizedBox(
            width: 400,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(widget.title, style: Styles.bodyStrong.copyWith(color: palette.ink)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _field,
                    autofocus: true,
                    keyboardType: widget.keyboard,
                    autocorrect: false,
                    enableSuggestions: false,
                    onSubmitted: (_) => unawaited(_go()),
                    style: Styles.body.copyWith(color: palette.ink),
                    decoration: InputDecoration(
                      hintText: widget.hint,
                      hintStyle: Styles.body.copyWith(color: palette.ink3),
                      filled: true,
                      fillColor: palette.raisedField,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                  ),
                  if (widget.extra != null) ...[const SizedBox(height: 12), widget.extra!],
                  AnimatedSize(
                    duration: Motion.of(context, Motion.fast),
                    curve: Motion.curve,
                    child: _failure == null
                        ? const SizedBox(width: double.infinity)
                        : Padding(
                            padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
                            child: Text(_failure!, style: Styles.caption.copyWith(color: palette.danger)),
                          ),
                  ),
                  const SizedBox(height: 18),
                  ListenableBuilder(
                    listenable: _field,
                    builder: (context, _) => PrimaryButton(
                      label: widget.action,
                      busy: _busy,
                      onTap: _field.text.trim().isEmpty && !widget.allowEmpty ? null : () => unawaited(_go()),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Pressable(
                    onTap: () => Navigator.of(context).pop(),
                    radius: 22,
                    child: SizedBox(
                      height: 44,
                      child: Center(
                        child: Text(s.cancel, style: Styles.body.copyWith(color: palette.ink)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
