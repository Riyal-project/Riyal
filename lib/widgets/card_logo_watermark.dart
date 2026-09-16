import 'dart:math' as math;

import 'package:flutter/material.dart';

enum WatermarkCorner { topEnd, bottomEnd }

/// A decorative Riyal logo that always remains fully visible inside its card.
/// Its size responds to both card dimensions, which keeps it proportional on
/// narrow phones and prevents short cards from cropping the coin.
class CardLogoWatermark extends StatelessWidget {
  const CardLogoWatermark({
    super.key,
    this.corner = WatermarkCorner.bottomEnd,
    this.size = 130,
    this.opacity = 0.1,
  });

  final WatermarkCorner corner;
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: LayoutBuilder(
      builder: (context, constraints) {
        const inset = 10.0;
        final responsiveSize = math
            .max(
              0.0,
              math.min(
                size,
                math.min(
                  constraints.maxWidth * 0.34,
                  constraints.maxHeight - inset * 2,
                ),
              ),
            )
            .toDouble();
        return IgnorePointer(
          child: ExcludeSemantics(
            child: Align(
              alignment: corner == WatermarkCorner.topEnd
                  ? AlignmentDirectional.topEnd
                  : AlignmentDirectional.bottomEnd,
              child: Padding(
                padding: const EdgeInsets.all(inset),
                child: Opacity(
                  opacity: opacity,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(responsiveSize * 0.16),
                    child: SizedBox.square(
                      dimension: responsiveSize,
                      child: Image.asset(
                        'assets/icon/app_icon.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}
