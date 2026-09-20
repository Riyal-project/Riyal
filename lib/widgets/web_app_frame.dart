import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Keeps routes, sheets and navigation inside a readable desktop width.
/// Native mobile layouts are unchanged.
class WebAppFrame extends StatelessWidget {
  const WebAppFrame({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return child;
    return ColoredBox(
      color: AppColors.background,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: LayoutBuilder(
            builder: (context, constraints) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                size: Size(constraints.maxWidth, constraints.maxHeight),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
