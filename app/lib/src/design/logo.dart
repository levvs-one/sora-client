import 'package:flutter/widgets.dart';

/// The Sora logo traced from the master artwork: a geometric S at 45 degrees
/// with rounded inner corners. The lower half is the upper half rotated 180
/// degrees around the centre.
class SoraMark extends StatelessWidget {
  const SoraMark({super.key, required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.square(size), painter: _MarkPainter(color));
}

class _MarkPainter extends CustomPainter {
  _MarkPainter(this.color);

  final Color color;

  // Coordinates use the master artwork's 1254-unit space.
  static const _left = 182.0, _top = 154.0, _right = 1104.0, _bottom = 1076.0;
  static const _cx = 643.0, _cy = 615.0;

  static Path _half({required bool turned}) {
    Offset p(double x, double y) => turned ? Offset(2 * _cx - x, 2 * _cy - y) : Offset(x, y);
    final a = p(493, 154), b = p(1090, 154), c = p(880, 357), d = p(512, 357);
    final d1 = p(440, 357), d2 = p(410, 420), e = p(462, 470);
    final f = p(706, 716), g = p(465, 716), gq = p(434, 716), h = p(420, 702);
    final i = p(250, 532), iq = p(182, 464), j = p(250, 397);
    return Path()
      ..moveTo(a.dx, a.dy)
      ..lineTo(b.dx, b.dy)
      ..lineTo(c.dx, c.dy)
      ..lineTo(d.dx, d.dy)
      ..cubicTo(d1.dx, d1.dy, d2.dx, d2.dy, e.dx, e.dy)
      ..lineTo(f.dx, f.dy)
      ..lineTo(g.dx, g.dy)
      ..quadraticBezierTo(gq.dx, gq.dy, h.dx, h.dy)
      ..lineTo(i.dx, i.dy)
      ..quadraticBezierTo(iq.dx, iq.dy, j.dx, j.dy)
      ..close();
  }

  static final _mark = Path()
    ..addPath(_half(turned: false), Offset.zero)
    ..addPath(_half(turned: true), Offset.zero);

  @override
  void paint(Canvas canvas, Size size) {
    const w = _right - _left, h = _bottom - _top;
    final scale = size.shortestSide / (w > h ? w : h);
    canvas
      ..save()
      ..translate((size.width - w * scale) / 2, (size.height - h * scale) / 2)
      ..scale(scale)
      ..translate(-_left, -_top)
      ..drawPath(
        _mark,
        Paint()
          ..color = color
          ..isAntiAlias = true,
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.color != color;
}
