import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../l10n/strings.dart';
import '../theme/app_theme.dart';
import 'riyal_coin_painter.dart';

class CoinBackButton extends StatefulWidget {
  const CoinBackButton({super.key, this.onPressed});

  /// Overrides the default `Navigator.maybePop()` — for flows where "back"
  /// means stepping back through in-screen state instead of popping a
  /// route (e.g. the mock bank connect flow's internal steps).
  final VoidCallback? onPressed;

  @override
  State<CoinBackButton> createState() => _CoinBackButtonState();
}

class _CoinBackButtonState extends State<CoinBackButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );
  bool _busy = false;
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// How much of the flip plays before navigation actually starts — just
  /// enough of a head start that the motion registers, without gating the
  /// whole interaction behind the full animation (which felt slow) or
  /// starting navigation instantly, which cut the pop transition off before
  /// a single frame of the flip was visible.
  static const _headStart = Duration(milliseconds: 150);

  Future<void> _back() async {
    if (_busy) return;
    _busy = true;
    if (!MediaQuery.disableAnimationsOf(context)) {
      _controller.forward();
      await Future.delayed(_headStart);
    }
    if (!mounted) return;
    if (widget.onPressed != null) {
      widget.onPressed!();
    } else {
      await Navigator.of(context).maybePop();
    }
    if (mounted) {
      _controller.reset();
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: Strings.t('back'),
    onPressed: _back,
    padding: const EdgeInsets.all(6),
    icon: AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final angle =
            Curves.easeInOutSine.transform(_controller.value) * math.pi;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.002)
            ..rotateY(angle),
          child: SizedBox(
            width: 40,
            height: 40,
            child: CustomPaint(
              painter: const RiyalCoinPainter(),
              child: Center(
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.rotationY(
                    math.cos(angle) < 0 ? math.pi : 0,
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.gold,
                    size: 21,
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
