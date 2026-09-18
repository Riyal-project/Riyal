import 'dart:math' as math;

import 'package:flutter/material.dart';

enum WatermarkCorner { topEnd, bottomEnd }

/// A decorative Riyal logo that scales with the card's width. By default it
/// also clamps to the card's actual height ([respectHeight]), so it adapts
/// safely to cards whose height varies with their content (e.g. a card
/// whose text can wrap to more lines). Set [respectHeight] to false only
/// for a card that's meant to let the coin bleed past its content's own
/// bounds toward the card's true edge — that caller also needs
/// `Stack(clipBehavior: Clip.none)` plus a clipping ancestor (e.g.
/// `Container(clipBehavior: Clip.antiAlias)`) so the coin doesn't spill
/// past the card itself.
class CardLogoWatermark extends StatelessWidget {
  const CardLogoWatermark({
    super.key,
    this.corner = WatermarkCorner.bottomEnd,
    this.size = 200,
    this.opacity = 0.06,
    this.inset = 10,
    this.endInset,
    this.respectHeight = true,
  });

  final WatermarkCorner corner;
  final double size;
  final double opacity;

  /// Vertical inset (from top or bottom, per [corner]) — also shrinks the
  /// [respectHeight] clamp, since that's meant to track this same margin.
  final double inset;

  /// Horizontal inset (from the end edge). Defaults to [inset]. Kept
  /// separate so a card can push the coin away from trailing content (like
  /// a chevron) without also shrinking the height-based size clamp.
  final double? endInset;

  final bool respectHeight;

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: LayoutBuilder(
      builder: (context, constraints) {
        final widthCap = constraints.maxWidth * 0.52;
        final cap = respectHeight
            ? math.min(widthCap, constraints.maxHeight - inset * 2)
            : widthCap;
        final responsiveSize = math.max(0.0, math.min(size, cap)).toDouble();
        return IgnorePointer(
          child: ExcludeSemantics(
            // A Stack + PositionedDirectional (rather than Align + Padding)
            // so a negative `inset` can push the coin past the card's
            // content bounds — Padding asserts non-negative, Positioned
            // doesn't.
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                PositionedDirectional(
                  top: corner == WatermarkCorner.topEnd ? inset : null,
                  bottom: corner == WatermarkCorner.bottomEnd ? inset : null,
                  end: endInset ?? inset,
                  child: Opacity(
                    opacity: opacity,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        responsiveSize * 0.16,
                      ),
                      child: SizedBox.square(
                        dimension: responsiveSize,
                        child: Image.asset(
                          'assets/icon/coin_watermark.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
