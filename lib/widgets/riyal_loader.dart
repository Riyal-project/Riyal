import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_theme.dart';
import 'riyal_coin_painter.dart';

/// The app's loading indicator: a small Riyal coin, logo inside, that keeps
/// flipping. Use it wherever a spinner would go; pass [color] to tint it for
/// a colored button or bank.
class RiyalLoader extends StatefulWidget {
  const RiyalLoader({super.key, this.size = 34, this.color = AppColors.gold});

  final double size;
  final Color color;

  @override
  State<RiyalLoader> createState() => _RiyalLoaderState();
}

class _RiyalLoaderState extends State<RiyalLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Respect the system "reduce motion" setting: a still coin, no flipping.
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final coin = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: RiyalCoinPainter(color: widget.color),
        child: Center(
          child: SvgPicture.asset(
            'assets/icons/saudi_riyal.svg',
            width: size * 0.42,
            colorFilter: ColorFilter.mode(widget.color, BlendMode.srcIn),
          ),
        ),
      ),
    );
    return AnimatedBuilder(
      animation: _controller,
      child: coin,
      builder: (context, child) {
        // Half a turn per loop, easing slowly through the face-on position.
        // Past edge-on the far face is drawn un-mirrored, so it reads as one
        // coin flipping over and over with the logo always the right way round.
        final half =
            math.pi * Curves.easeInOutSine.transform(_controller.value);
        final angle = half < math.pi / 2 ? half : half - math.pi;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.004)
            ..rotateY(angle),
          child: child,
        );
      },
    );
  }
}
