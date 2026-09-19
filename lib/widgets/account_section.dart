import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'riyal_coin_painter.dart';

class AccountSection extends StatelessWidget {
  const AccountSection({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: AppColors.cardBorder),
    ),
    child: child,
  );
}

class AccountPageHeader extends StatelessWidget {
  const AccountPageHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title, subtitle;
  @override
  // Stretched to the full width with every line centered inside it, so the
  // logo, title and subtitle sit on the page's center line in both LTR and
  // RTL — whatever the parent's alignment or the text's own width.
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Center(
          child: SizedBox(
            width: 88,
            height: 88,
            child: CustomPaint(
              painter: const RiyalCoinPainter(),
              child: Center(child: Icon(icon, color: AppColors.gold, size: 40)),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 25,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
        const SizedBox(height: 28),
      ],
    ),
  );
}
