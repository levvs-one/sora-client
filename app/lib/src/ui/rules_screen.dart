import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../l10n/strings.dart';
import '../design/theme.dart';
import '../rules.dart';
import '../sora.dart';
import 'kit.dart';
import 'subscription_sheet.dart';
import 'program_picker.dart';

/// Edits user rules for domains, addresses and processes. These rules take
/// precedence over the routing preset.
class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sora = SoraScope.of(context);
    final s = S.of(context);
    final palette = Palette.of(context);
    final rules = sora.settings.rules.map(UserRule.parse).nonNulls.toList();
    void save(List<UserRule> next) => unawaited(sora.change((x) => x.rules = [for (final r in next) r.stored]));
    return Screen(
      title: s.rules,
      actions: [RoundButton(icon: Symbols.add_rounded, label: s.ruleAdd, onTap: () => _add(context, rules, save))],
      children: [
        Group(
          children: [
            for (final (i, rule) in rules.indexed)
              _RuleTile(
                rule: rule,
                onTarget: (t) => save([...rules]..[i] = UserRule(t, rule.destination)),
                onDelete: () => save([...rules]..removeAt(i)),
              ),
            if (rules.isEmpty)
              Tile(
                title: s.ruleAdd,
                onTap: () => _add(context, rules, save),
                trailing: Icon(Symbols.add_rounded, size: 18, color: palette.ink),
              ),
          ],
        ),
      ],
    );
  }

  void _add(BuildContext context, List<UserRule> rules, void Function(List<UserRule>) save) {
    final s = S.of(context);
    final target = ValueNotifier(RuleTarget.direct);
    final field = TextEditingController();
    String? program;
    unawaited(
      showFieldSheet(
        context,
        title: s.ruleAdd,
        hint: s.ruleHint,
        action: s.add,
        keyboard: TextInputType.url,
        controller: field,
        extra: ValueListenableBuilder(
          valueListenable: target,
          builder: (context, value, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Segments<RuleTarget>(value: value, choices: _labels(s), onChanged: (t) => target.value = t),
              const SizedBox(height: 8),
              TextButton.icon(
                icon: const Icon(Symbols.apps_rounded, size: 18),
                label: Text(s.chooseProgram),
                onPressed: () async {
                  final selected = await chooseProgram(context);
                  if (selected != null) {
                    program = selected;
                    field.text = selected;
                  }
                },
              ),
            ],
          ),
        ),
        submit: (text) async {
          final destination = program != null && text == program ? 'process:$program' : UserRule.destinationOf(text);
          if (destination == null) return s.ruleInvalid;
          // Replace an existing destination so each destination has only one
          // target.
          save([
            for (final r in rules)
              if (r.destination != destination) r,
            UserRule(target.value, destination),
          ]);
          return null;
        },
      ).whenComplete(() {
        target.dispose();
        field.dispose();
      }),
    );
  }
}

Map<RuleTarget, String> _labels(S s) => {
  RuleTarget.direct: s.ruleDirect,
  RuleTarget.proxy: s.ruleProxy,
  RuleTarget.block: s.ruleBlock,
};

class _RuleTile extends StatelessWidget {
  const _RuleTile({required this.rule, required this.onTarget, required this.onDelete});

  final UserRule rule;
  final ValueChanged<RuleTarget> onTarget;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final palette = Palette.of(context);
    final labels = _labels(s);
    ButtonStyle style() => ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(200, 40)),
      shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(9))),
      overlayColor: WidgetStatePropertyAll(palette.hover),
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 12)),
    );
    return MenuAnchor(
      alignmentOffset: const Offset(0, 4),
      menuChildren: [
        for (final entry in labels.entries)
          MenuItemButton(
            onPressed: () => onTarget(entry.key),
            style: style(),
            trailingIcon: entry.key == rule.target ? Icon(Symbols.check_rounded, size: 18, color: palette.ink) : null,
            child: Text(entry.value, style: Styles.secondary.copyWith(color: palette.ink)),
          ),
        MenuItemButton(
          onPressed: onDelete,
          style: style(),
          child: Text(s.delete, style: Styles.secondary.copyWith(color: palette.danger)),
        ),
      ],
      builder: (context, controller, _) => Tile(
        title: rule.shown,
        onTap: () => controller.isOpen ? controller.close() : controller.open(),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(labels[rule.target]!, style: Styles.secondary.copyWith(color: palette.ink)),
            const SizedBox(width: 6),
            Icon(Symbols.unfold_more_rounded, size: 14, color: palette.ink3),
          ],
        ),
      ),
    );
  }
}
