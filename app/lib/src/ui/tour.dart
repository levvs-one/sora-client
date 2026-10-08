import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';

import '../../l10n/strings.dart';
import '../design/theme.dart';

class TourScope extends InheritedWidget {
  const TourScope({super.key, required this.keys, required this.view, required this.targetRect, required super.child});
  final List<GlobalKey> keys;
  final ShowcaseView view;
  final void Function(int, Rect, BuildContext) targetRect;
  static TourScope? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<TourScope>();
  @override
  bool updateShouldNotify(TourScope oldWidget) => view != oldWidget.view;
}

class TourTarget extends StatelessWidget {
  const TourTarget({super.key, required this.step, required this.child});
  final int step;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tour = TourScope.maybeOf(context);
    if (tour == null) return child;
    final s = S.of(context), palette = Palette.of(context);
    final descriptions = [s.tourAdd, s.tourServer, s.tourConnect, s.tourMode, s.tourSettings];
    TooltipActionButton action(TooltipDefaultActionType type, String name) => TooltipActionButton(
      type: type,
      name: name,
      backgroundColor: palette.raised,
      textStyle: Styles.secondary.copyWith(color: palette.ink),
      borderRadius: BorderRadius.circular(6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    );
    return Showcase(
      key: tour.keys[step],
      title: s.tourStep(step + 1),
      description: descriptions[step],
      titleAlignment: Alignment.centerLeft,
      descriptionAlignment: Alignment.centerLeft,
      titleTextStyle: Styles.bodyStrong.copyWith(color: palette.ink),
      descTextStyle: Styles.secondary.copyWith(color: palette.ink2),
      tooltipBackgroundColor: palette.raised,
      textColor: palette.ink,
      tooltipPadding: const EdgeInsets.all(16),
      tooltipBorderRadius: BorderRadius.circular(12),
      overlayColor: Colors.black,
      overlayOpacity: 0,
      onTargetRectUpdate: (rect) => tour.targetRect(step, rect, context),
      blurValue: 0,
      disableBarrierInteraction: true,
      disableDefaultTargetGestures: true,
      disableMovingAnimation: true,
      disableScaleAnimation: !Motion.enabled(context),
      scaleAnimationDuration: Motion.of(context, const Duration(milliseconds: 220)),
      scaleAnimationCurve: Curves.easeOutCubic,
      enableAutoScroll: true,
      tooltipActionConfig: const TooltipActionConfig(actionGap: 4, mainAxisSize: MainAxisSize.min),
      tooltipActions: [
        if (step > 0) action(TooltipDefaultActionType.previous, s.tourBack),
        action(TooltipDefaultActionType.next, step == 4 ? s.tourFinish : s.tourNext),
        action(TooltipDefaultActionType.skip, s.tourSkip),
      ],
      child: child,
    );
  }
}

// Showcase owns target measurements and controls; Flutter interpolates the cutout between targets.
class TourScrim extends StatelessWidget {
  const TourScrim({super.key, required this.rect, required this.duration});
  final Rect rect;
  final Duration duration;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: TweenAnimationBuilder<Rect?>(
      tween: RectTween(begin: rect, end: rect),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (_, value, _) => CustomPaint(painter: _Cutout(value!), size: Size.infinite),
    ),
  );
}

class _Cutout extends CustomPainter {
  const _Cutout(this.rect);
  final Rect rect;
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)));
    canvas.drawPath(path, Paint()..color = const Color(0xB3000000));
  }

  @override
  bool shouldRepaint(_Cutout oldDelegate) => rect != oldDelegate.rect;
}
