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
  Widget build(BuildContext context) => Column(
    children: [
      const SizedBox(height: 8),
      SizedBox(
        width: 88,
        height: 88,
        child: CustomPaint(
          painter: const RiyalCoinPainter(),
          child: Center(child: Icon(icon, color: AppColors.gold, size: 40)),
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
  );
}
