import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// The flat "outline" Riyal coin used throughout the app: a subtle gold
/// face tint, a dashed/reeded gold edge, and a faint inner ring. Every measurement
/// scales from the painted [Size] using the same 48-unit grid as the
/// source design, so it draws correctly at any size a caller wraps it in
/// (a small nav icon, the full-width auth coin, etc). Callers that
/// previously supplied a dark ([AppColors.surface]) icon/text child should
/// switch it to [AppColors.gold] (or another light color) — the face no
/// longer paints a dark disc behind it for contrast.
class RiyalCoinPainter extends CustomPainter {
  const RiyalCoinPainter({
    this.color = AppColors.gold,
    this.faceColor = const Color(0x0FCBA960),
    this.edgeScale = 1,
    this.dashWidthScale = 1,
    this.dashLengthScale = 1,
    this.dashOuterEndOffset = -0.35,
    this.outerRimWidthScale = 1,
    this.innerRingWidthScale = 1,
    this.innerRingInset = 5.4,
    this.edgeOpacity = 1,
    this.dashCount = 22,
  });

  final int dashCount;

  /// Edge dashes, inner ring color.
  final Color color;

  /// Fill inside the ring — subtly tinted by default to give the outline
  /// coin a little depth without becoming a filled disc.
  final Color faceColor;

  /// Scales dash length/width — use < 1 to make the edge detail smaller.
  final double edgeScale;

  /// Scales only the dash thickness; use < 1 for a finer reeded edge.
  final double dashWidthScale;

  /// Scales only the dash length; use < 1 to increase the gap to the ring.
  final double dashLengthScale;

  /// Dash endpoint relative to the coin radius, in design-grid units.
  /// Higher values let the dashes meet the outer rim.
  final double dashOuterEndOffset;

  /// Scales the outer rim thickness without changing the coin diameter.
  final double outerRimWidthScale;

  /// Scales the inner ring thickness without changing its position.
  final double innerRingWidthScale;

  /// Distance of the inner ring from the rim, in design-grid units.
  /// Lower values move the inner ring outward.
  final double innerRingInset;

  /// Opacity applied to the edge dashes/rings — use < 1 to make them fainter.
  final double edgeOpacity;

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.shortestSide / 48; // one unit of the 48-unit design grid
    final c = size.center(Offset.zero);
    final radius = 22 * u;
    final edgeColor = color.withValues(alpha: color.a * edgeOpacity);

    canvas.drawCircle(c, radius, Paint()..color = faceColor);

    // A slightly weightier closing ring gives the coin a defined rim while
    // keeping the familiar gold-outline treatment.
    canvas.drawCircle(
      c,
      radius + 0.3 * u,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8 * u * outerRimWidthScale
        ..color = edgeColor,
    );

    // A dashed/reeded edge contained within the rim, for a coin-like
    // milled-edge appearance without any tick extending beyond the coin.
    final dashCount = this.dashCount;
    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: c, radius: radius + 1.1 * u)),
    );
    final dashInnerRadius =
        radius - 2.45 * u * edgeScale * dashLengthScale;
    final dashPaint = Paint()
      ..color = edgeColor
      ..strokeWidth = 1.1 * u * edgeScale * dashWidthScale
      ..strokeCap = StrokeCap.butt;
    for (var i = 0; i < dashCount; i++) {
      final angle = i * math.pi * 2 / dashCount;
      final direction = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(
        // Flat-ended reeding is crisp at small sizes and leaves a clear,
        // deliberate gap before the inner ring.
        c + direction * dashInnerRadius,
        c + direction * (radius + dashOuterEndOffset * u),
        dashPaint,
      );
    }
    canvas.restore();

    canvas.drawCircle(
      c,
      radius - innerRingInset * u * edgeScale,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9 * u * innerRingWidthScale
        ..color = edgeColor,
    );
  }

  @override
  bool shouldRepaint(covariant RiyalCoinPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.faceColor != faceColor ||
      oldDelegate.edgeScale != edgeScale ||
      oldDelegate.dashWidthScale != dashWidthScale ||
      oldDelegate.dashLengthScale != dashLengthScale ||
      oldDelegate.dashOuterEndOffset != dashOuterEndOffset ||
      oldDelegate.outerRimWidthScale != outerRimWidthScale ||
      oldDelegate.innerRingWidthScale != innerRingWidthScale ||
      oldDelegate.innerRingInset != innerRingInset ||
      oldDelegate.edgeOpacity != edgeOpacity ||
      oldDelegate.dashCount != dashCount;
}
