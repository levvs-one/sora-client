import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../design/theme.dart';
import 'kit.dart';

class Announcement extends StatelessWidget {
  const Announcement(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    final style = Styles.caption.copyWith(color: palette.ink2);
    final markdown = IntrinsicWidth(
      child: MarkdownBody(
        data: text,
        fitContent: false,
        styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
          p: style,
          a: style.copyWith(color: palette.ink, decoration: TextDecoration.underline),
          strong: style.copyWith(fontWeight: FontWeight.w600),
          em: style.copyWith(fontStyle: FontStyle.italic),
          listBullet: style,
          blockSpacing: 8,
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
    return Center(child: markdown);
  }
}
