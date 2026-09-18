import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// The flat "outline" Riyal coin used throughout the app: a transparent
/// face (nothing painted behind it, unless [faceColor] is overridden), a
/// dashed/reeded gold edge, and a faint inner ring. Every measurement
/// scales from the painted [Size] using the same 48-unit grid as the
/// source design, so it draws correctly at any size a caller wraps it in
/// (a small nav icon, the full-width auth coin, etc). Callers that
/// previously supplied a dark ([AppColors.surface]) icon/text child should
/// switch it to [AppColors.gold] (or another light color) — the face no
/// longer paints a dark disc behind it for contrast.
class RiyalCoinPainter extends CustomPainter {
  const RiyalCoinPainter({
    this.color = AppColors.gold,
    this.faceColor = Colors.transparent,
    this.edgeScale = 1,
    this.edgeOpacity = 1,
    this.dashCount = 39,
  });

  final int dashCount;

  /// Edge dashes, inner ring color.
  final Color color;

  /// Fill inside the ring — transparent by default so the coin reads as an
  /// outline, not a filled disc.
  final Color faceColor;

  /// Scales dash length/width — use < 1 to make the edge detail smaller.
  final double edgeScale;

  /// Opacity applied to the edge dashes/rings — use < 1 to make them fainter.
  final double edgeOpacity;

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.shortestSide / 48; // one unit of the 48-unit design grid
    final c = size.center(Offset.zero);
    final radius = 22 * u;
    final edgeColor = color.withValues(alpha: color.a * edgeOpacity);

    canvas.drawCircle(c, radius, Paint()..color = faceColor);

    // A very thin closing ring right at the rim, so the dashes read as one
    // coin edge instead of a set of disconnected marks with open gaps.
    canvas.drawCircle(
      c,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6 * u
        ..color = edgeColor,
    );

    // A dashed/reeded edge (short radial ticks around the rim) instead of a
    // solid ring outline, for a coin-like milled-edge appearance. Straight
    // (butt) caps, not rounded, so each dash reads as a clean tick mark.
    final dashCount = this.dashCount;
    final dashPaint = Paint()
      ..color = edgeColor
      ..strokeWidth = 1.9 * u * edgeScale
      ..strokeCap = StrokeCap.butt;
    for (var i = 0; i < dashCount; i++) {
      final angle = i * math.pi * 2 / dashCount;
      final direction = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(
        c + direction * (radius - 3.6 * u * edgeScale),
        c + direction * radius,
        dashPaint,
      );
    }

    canvas.drawCircle(
      c,
      radius - 3.6 * u * edgeScale - 0.5 * u,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2 * u
        ..color = edgeColor,
    );
  }

  @override
  bool shouldRepaint(covariant RiyalCoinPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.faceColor != faceColor;
}
