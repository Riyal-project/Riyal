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

const subscriptionsSpent = 950.0;
const subscriptionsBudget = 2000.0;

// Mirrors AppColors.subscriptions/utilities/people (lib/theme/app_theme.dart)
// as raw ints — this file stays free of a Flutter/Material import so it
// can be a plain data file.
const overview = [
  SpendingCategory(label: 'Subscriptions', amount: 950, color: 0xFFCBA960),
  SpendingCategory(label: 'Utilities', amount: 1623, color: 0xFF2CB3B3),
  SpendingCategory(label: 'People', amount: 7000, color: 0xFFBD7D60),
];
