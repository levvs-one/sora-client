import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../../l10n/strings.dart';
import '../design/theme.dart';
import 'kit.dart';

class Announcement extends StatefulWidget {
  const Announcement(this.text, {super.key});
  final String text;
  @override
  State<Announcement> createState() => _AnnouncementState();
}

class _AnnouncementState extends State<Announcement> {
  bool _expanded = false;
  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context), s = S.of(context);
    final style = Styles.caption.copyWith(color: palette.ink2);
    final markdown = IntrinsicWidth(
      child: MarkdownBody(
        data: widget.text,
        fitContent: false,
        styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
          p: style,
          a: style.copyWith(color: palette.ink, decoration: TextDecoration.underline),
          strong: style.copyWith(fontWeight: FontWeight.w600),
          em: style.copyWith(fontStyle: FontStyle.italic),
          listBullet: style,
          blockSpacing: _expanded ? 4 : 0,
          listIndent: 16,
          textAlign: WrapAlignment.center,
          listBulletPadding: EdgeInsets.zero,
          unorderedListAlign: WrapAlignment.center,
          orderedListAlign: WrapAlignment.center,
        ),
        onTapLink: (_, href, _) {
          if (href != null) unawaited(openLink(context, href));
        },
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_expanded)
          Center(child: markdown)
        else
          SizedBox(
            key: const ValueKey('announcement-preview'),
            height: MediaQuery.textScalerOf(context).scale(12) * 1.3 * 3,
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.topCenter,
                maxHeight: double.infinity,
                child: Align(alignment: Alignment.topCenter, heightFactor: 1, child: markdown),
              ),
            ),
          ),
        Center(
          child: TextButton(
            onPressed: () => setState(() => _expanded = !_expanded),
            child: Text(_expanded ? s.less : s.more, style: Styles.caption.copyWith(color: palette.ink)),
          ),
        ),
      ],
    );
  }
}
