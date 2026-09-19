import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../l10n/strings.dart';
import '../theme/app_theme.dart';
import '../widgets/riyal_coin_painter.dart';

class BottomNav extends StatelessWidget {
  const BottomNav({super.key, required this.index, required this.onTap});

  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: NavItem(
                  icon: Icons.home_rounded,
                  label: Strings.t('nav_home'),
                  isActive: index == 0,
                  onTap: () => onTap(0),
                ),
              ),
              Expanded(
                child: NavItem(
                  icon: Icons.subscriptions_outlined,
                  label: Strings.t('nav_subscriptions'),
                  isActive: index == 1,
                  onTap: () => onTap(1),
                ),
              ),
              const SizedBox(width: 48),
              Expanded(
                child: NavItem(
                  icon: Icons.bolt_outlined,
                  label: Strings.t('nav_utilities'),
                  isActive: index == 2,
                  onTap: () => onTap(2),
                ),
              ),
              Expanded(
                child: NavItem(
                  icon: Icons.groups_outlined,
                  label: Strings.t('nav_people'),
                  isActive: index == 3,
                  onTap: () => onTap(3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NavItem extends StatelessWidget {
  const NavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.gold : AppColors.textSecondary;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(color: color, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class NavFab extends StatelessWidget {
  const NavFab({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'riyal-bot-button',
      tooltip: 'ريال / Riyal',
      onPressed: onPressed,
      elevation: 0,
      hoverElevation: 0,
      focusElevation: 0,
      highlightElevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.surface,
      shape: const CircleBorder(),
      child: SizedBox.expand(
        child: CustomPaint(
          // A solid face keeps the navigation coin distinct from the bar
          // without changing the shared coin style.
          painter: const RiyalCoinPainter(faceColor: AppColors.surface),
          child: Center(
            child: SvgPicture.asset(
              'assets/icons/saudi_riyal.svg',
              width: 22,
              semanticsLabel: 'Saudi riyal',
              colorFilter: const ColorFilter.mode(
                AppColors.gold,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
