import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'theme.dart';

/// Light along the edge of a rounded shape, in the manner of Apple
/// Intelligence: four strokes of the same spectrum, each wider and softer
/// than the one before, whose colours drift to new places every 0.4 s while
/// the whole ring turns.
///
/// [energy] fades the light in and out (0 is dark, 1 is full). [busy] makes
/// it turn and drift quickly, for work in progress; otherwise it breathes
/// slowly. Without motion the light holds still.
class Glow extends StatefulWidget {
  const Glow({
    super.key,
    required this.child,
    required this.radius,
    required this.energy,
    this.busy = false,
    this.scale = 1,
    this.inFront = false,
  });

  final Widget child;
  final double radius;
  final double energy;
  final bool busy;

  /// Multiplies the stroke widths and blurs: the ring of a button is finer
  /// than the edge of a window.
  final double scale;

  /// Paints over the child, for the edge of a window, instead of behind it.
  final bool inFront;

  @override
  State<Glow> createState() => _GlowState();
}

class _Layer {
  _Layer(this.width, this.blur, this.duration, math.Random random) : from = _shuffle(random), to = _shuffle(random);

  final double width;
  final double blur;
  final double duration;
  List<double> from;
  List<double> to;
  double changedAt = 0;

  static List<double> _shuffle(math.Random random) =>
      List.generate(Palette.spectrum.length, (_) => random.nextDouble());

  static List<double> even() => List.generate(Palette.spectrum.length, (i) => i / Palette.spectrum.length);

  List<double> at(double now) {
    final t = Curves.easeInOut.transform(((now - changedAt) / duration).clamp(0, 1));
    return List.generate(from.length, (i) => from[i] + (to[i] - from[i]) * t);
  }
}

class _GlowState extends State<Glow> with SingleTickerProviderStateMixin {
  static const _interval = 0.4;
  final _random = math.Random();
  late final List<_Layer> _layers = [
    _Layer(6, 0, 0.5, _random),
    _Layer(9, 4, 0.6, _random),
    _Layer(11, 12, 0.8, _random),
    _Layer(15, 15, 1.0, _random),
  ];
  late final Ticker _ticker = createTicker(_tick);
  final _clock = ValueNotifier<double>(0);
  double _turn = 0;
  double _nextShuffle = 0;
  Duration _last = Duration.zero;
  bool _moving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(Glow old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    final move = widget.energy > 0 && Motion.enabled(context);
    if (move == _moving) return;
    _moving = move;
    if (move) {
      _last = Duration.zero;
      _ticker.start();
    } else {
      _ticker.stop();
      for (final layer in _layers) {
        layer
          ..from = _Layer.even()
          ..to = _Layer.even();
      }
      _turn = 0;
      _clock.value = 0;
    }
  }

  void _tick(Duration elapsed) {
    final dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    final now = _clock.value + dt;
    // A full turn in 2.6 s while busy and in 16 s at rest.
    _turn += dt * 2 * math.pi / (widget.busy ? 2.6 : 16);
    if (now >= _nextShuffle) {
      _nextShuffle = now + (widget.busy ? _interval : _interval * 4);
      for (final layer in _layers) {
        layer
          ..from = layer.at(now)
          ..to = _Layer._shuffle(_random)
          ..changedAt = now;
      }
    }
    _clock.value = now;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: widget.energy),
      duration: Motion.of(context, Motion.slow),
      curve: Curves.easeOut,
      builder: (context, energy, child) {
        final painter = energy <= 0.001
            ? null
            : _GlowPainter(
                layers: _layers,
                clock: _clock,
                turn: () => _turn,
                radius: widget.radius,
                energy: energy,
                scale: widget.scale,
              );
        return CustomPaint(
          painter: widget.inFront ? null : painter,
          foregroundPainter: widget.inFront ? painter : null,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _GlowPainter extends CustomPainter {
  _GlowPainter({
    required this.layers,
    required this.clock,
    required this.turn,
    required this.radius,
    required this.energy,
    required this.scale,
  }) : super(repaint: clock);

  final List<_Layer> layers;
  final ValueNotifier<double> clock;
  final double Function() turn;
  final double radius;
  final double energy;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final shape = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final colors = Palette.spectrum;
    for (final layer in layers.reversed) {
      final places = layer.at(clock.value);
      final order = List.generate(colors.length, (i) => i)..sort((a, b) => places[a].compareTo(places[b]));
      final stops = [for (final i in order) places[i]];
      final ordered = [for (final i in order) colors[i]];
      // The sweep has to meet itself at the seam, so both ends take the colour
      // between the last stop and the first.
      final gap = 1 - stops.last + stops.first;
      final seam = Color.lerp(ordered.last, ordered.first, gap == 0 ? 0 : (1 - stops.last) / gap)!;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = layer.width * scale
        ..shader = SweepGradient(
          colors: [seam, ...ordered, seam],
          stops: [0, ...stops, 1],
          transform: GradientRotation(turn()),
        ).createShader(rect)
        ..colorFilter = ColorFilter.mode(Color.fromRGBO(255, 255, 255, energy), BlendMode.modulate);
      if (layer.blur > 0) paint.maskFilter = MaskFilter.blur(BlurStyle.normal, layer.blur * scale);
      canvas.drawRRect(shape, paint);
    }
  }

  @override
  bool shouldRepaint(_GlowPainter old) => old.energy != energy || old.radius != radius || old.scale != scale;
}
