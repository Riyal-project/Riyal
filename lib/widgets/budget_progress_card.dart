import 'package:flutter/material.dart';
import '../data/budget_store.dart';
import '../l10n/strings.dart';
import '../screens/budget_setup_screen.dart';
import '../theme/app_theme.dart';

class BudgetProgressCard extends StatelessWidget {
  const BudgetProgressCard({super.key, this.domain});
  final BudgetDomain? domain;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
    valueListenable: BudgetStore.instance.revision,
    builder: (context, _, child) {
      final store = BudgetStore.instance;
      final current = store.snapshot(domain);
      final color = !store.configured
          ? AppColors.gold
          : switch (current.level) {
              BudgetLevel.normal => AppColors.gold,
              BudgetLevel.near => Colors.orange,
              BudgetLevel.exceeded => Colors.redAccent,
            };
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    Strings.t('budget_monthly'),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (store.configured && current.level == BudgetLevel.exceeded)
                  Icon(Icons.warning_amber_rounded, color: color, size: 22),
                TextButton(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    minimumSize: const Size(0, 28),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const BudgetSetupScreen(),
                    ),
                  ),
                  child: Text(
                    Strings.t(store.configured ? 'budget_edit' : 'budget_set'),
                  ),
                ),
              ],
            ),
            if (store.configured) ...[
              Text(
                '${Strings.t('budget_committed')}: ⃁${current.committed.toStringAsFixed(2)} / ⃁${current.limit.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 10),
              Semantics(
                label: Strings.t('budget_monthly'),
                value: '${(current.fraction * 100).toStringAsFixed(0)}%',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: current.fraction.clamp(0.0, 1.0),
                    minHeight: 7,
                    backgroundColor: AppColors.trackBackground,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${(current.fraction * 100).toStringAsFixed(0)}% · '
                '${Strings.t(current.level == BudgetLevel.exceeded
                    ? 'budget_reached'
                    : current.level == BudgetLevel.near
                    ? 'budget_near'
                    : 'budget_within')}',
                style: TextStyle(color: color, fontSize: 12),
              ),
            ] else
              Text(
                Strings.t('budget_not_set'),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
          ],
        ),
      );
    },
  );
}
