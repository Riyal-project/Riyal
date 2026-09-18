import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// The big auth-screen coin — a darker solid rim against a brighter,
/// flat-gradient face for clear edge/face contrast, with closely-spaced
/// rim ticks and a small ring of diamond accents. Toned down from the
/// original photorealistic version (fewer diamonds, narrower face
/// gradient) while keeping the coin's layered-ring structure.
class GoldCoinPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    // Rim: solid but only lightly darker than the face, so the edge still
    // reads as its own band without dragging the whole coin down.
    canvas.drawCircle(center, radius, Paint()..color = const Color(0xFFB89651));
    for (var i = 0; i < 60; i++) {
      final angle = i * math.pi * 2 / 60;
      final direction = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(
        center + direction * (radius - 5),
        center + direction * (radius - 1),
        Paint()
          ..color = AppColors.goldDark
          ..strokeWidth = 1.4,
      );
    }
    // Face: brighter than the rim, narrow gradient range for a flat,
    // non-glossy fill. The rim reaches 12px in for a visible edge band.
    canvas.drawCircle(
      center,
      radius - 12,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.gold, Color(0xFFD3BE7E), AppColors.gold],
          stops: [0, 0.5, 1],
        ).createShader(rect),
    );
    for (final inset in [13.0, 24.0]) {
      canvas.drawCircle(
        center,
        radius - inset,
        Paint()
          ..color = AppColors.goldDark.withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }
    // A ring of engraved diamonds — fewer and bolder than the original's
    // fine engraving, kept as an accent rather than removed outright.
    for (var i = 0; i < 20; i++) {
      final angle = i * math.pi * 2 / 20;
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);
      final r = radius - 18.5;
      final path = Path()
        ..moveTo(r - 3, 0)
        ..lineTo(r, -3)
        ..lineTo(r + 3, 0)
        ..lineTo(r, 3)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..color = AppColors.goldDark.withValues(alpha: 0.65)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.9,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant GoldCoinPainter oldDelegate) => false;
}

/// A small, flat-shaded "cartoon coin" treatment for icon-sized circles
/// (e.g. the nav bar's floating action button) — solid fill colors and
/// chunky rim notches outlined in a soft bronze, not black. Deliberately
/// avoids the metallic gradient shine [GoldCoinPainter] uses for the big
/// auth-screen coin; at ~50px that shine just reads as a blurry glow, and
/// flat cel-shading reads clearer at this size anyway.
class NavCoinPainter extends CustomPainter {
  const NavCoinPainter();

  static const _outline = Color(0xFFB08D4C);
  static const _rim = Color(0xFFE3C989);
  static const _face = AppColors.gold;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;

    // Outer rim, flat fill + bold outline.
    canvas.drawCircle(center, radius, Paint()..color = _rim);
    canvas.drawCircle(
      center,
      radius - 1.2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..color = _outline,
    );

    // Chunky, evenly-spaced ridge notches — flat color, no shading.
    const tickCount = 16;
    final tickInner = radius * 0.86;
    final tickOuter = radius - 1.6;
    for (var i = 0; i < tickCount; i++) {
      final angle = i * math.pi * 2 / tickCount;
      final direction = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(
        center + direction * tickInner,
        center + direction * tickOuter,
        Paint()
          ..color = _outline
          ..strokeWidth = 2.6
          ..strokeCap = StrokeCap.round,
      );
    }

    // Inner face, flat fill + bold outline separating it from the rim.
    final faceRadius = radius * 0.78;
    canvas.drawCircle(center, faceRadius, Paint()..color = _face);
    canvas.drawCircle(
      center,
      faceRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = _outline,
    );
  }

  @override
  bool shouldRepaint(covariant NavCoinPainter oldDelegate) => false;
}
