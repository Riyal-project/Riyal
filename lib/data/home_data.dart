import 'package:flutter/foundation.dart';

import 'budget_store.dart';
import 'people_store.dart';
import 'spending_history.dart';
import 'subscriptions_store.dart';
import 'utilities_store.dart';

class SpendingCategory {
  const SpendingCategory({
    required this.label,
    required this.amount,
    required this.color,
  });

  final String label;
  final double amount;
  final int color;
}

/// Fires whenever a card is added, edited, paused or removed — anything on
/// the Home and Analytics tabs that is derived from the cards listens to it.
Listenable get dashboardChanges => Listenable.merge([
  SubscriptionsStore.instance.subscriptions,
  UtilitiesStore.instance.items,
  PeopleStore.instance.items,
  SpendingHistory.instance.earlier,
]);

// Mirrors AppColors.subscriptions/utilities/people (lib/theme/app_theme.dart)
// as raw ints.
const _categoryColors = {
  BudgetDomain.subscriptions: 0xFFCBA960,
  BudgetDomain.utilities: 0xFF2CB3B3,
  BudgetDomain.people: 0xFFBD7D60,
};

/// This month's recurring commitments per category, built from the cards on
/// the Subscriptions / Utilities / People screens. It is the same figure the
/// budgets use as "committed", so the dashboard, analytics and budget cards
/// always agree with each other.
List<SpendingCategory> get overview => [
  for (final domain in BudgetDomain.values)
    SpendingCategory(
      label: domain.categoryKey,
      amount: BudgetStore.instance.snapshot(domain).committed,
      color: _categoryColors[domain]!,
    ),
];
