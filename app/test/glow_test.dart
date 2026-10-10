import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sora/src/design/glow.dart';

class _PaintCounter extends CustomPainter {
  int paints = 0;

  @override
  void paint(Canvas canvas, Size size) => paints++;

  @override
  bool shouldRepaint(_PaintCounter oldDelegate) => false;
}

void main() {
  testWidgets('connection glow does not repaint its content or surrounding page', (tester) async {
    final page = _PaintCounter(), content = _PaintCounter();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: CustomPaint(
          painter: page,
          child: Center(
            child: Glow(
              energy: 1,
              radius: 90,
              child: SizedBox(width: 180, height: 180, child: CustomPaint(painter: content)),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    final initialPage = page.paints, initialContent = content.paints;
    for (var frame = 0; frame < 60; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(page.paints - initialPage, 0, reason: 'The page must stay cached during glow animation.');
    expect(content.paints - initialContent, 0, reason: 'The connection button must stay cached.');
    await tester.pumpWidget(const SizedBox());
  });
}
