import 'package:flutter/foundation.dart';

import 'bank_transaction_matcher.dart';
import 'mock_bank_transaction.dart';
import 'user_bank_accounts_store.dart';

/// What was actually paid in each of the [months] months before this one,
/// per category, summed from the connected banks' real transactions. It
/// feeds the earlier months of the Analytics trend and the "vs. last month"
/// change on Home; with no bank connected there is no history and every
/// month stays 0. Reloads itself whenever the connected banks change.
class SpendingHistory {
  SpendingHistory._() {
    UserBankAccountsStore.instance.accounts.addListener(refresh);
    refresh();
  }
  static final instance = SpendingHistory._();

  static const months = 5;

  /// Category ('Subscriptions' / 'Utilities' / 'People') to its earlier
  /// months' totals, oldest first.
  final earlier = ValueNotifier<Map<String, List<double>>>(const {});
  int _run = 0;

  /// Forgets the history (e.g. when another account opens).
  void clear() {
    _run++;
    earlier.value = const {};
  }

  Future<void> refresh() async {
    final run = ++_run;
    if (UserBankAccountsStore.instance.accounts.value.isEmpty) {
      earlier.value = const {};
      return;
    }
    try {
      final rows = await loadAllConnectedTransactions();
      // A newer refresh or an account switch supersedes this result.
      if (run == _run) earlier.value = aggregate(rows, DateTime.now());
    } catch (error) {
      debugPrint('Spending history unavailable: $error');
    }
  }

  static const _categories = {
    'subscription': 'Subscriptions',
    'utility': 'Utilities',
    'person': 'People',
  };

  /// Monthly totals for the [months] calendar months before [now]'s month,
  /// oldest first. This month and anything older are left out.
  static Map<String, List<double>> aggregate(
    List<MockBankTransactionRow> rows,
    DateTime now,
  ) {
    final totals = {
      for (final category in _categories.values)
        category: List<double>.filled(months, 0),
    };
    for (final row in rows) {
      final category = _categories[row.category];
      if (category == null) continue;
      final date = row.transactionDate;
      final ago = (now.year - date.year) * 12 + now.month - date.month;
      if (ago < 1 || ago > months) continue;
      totals[category]![months - ago] += row.amount;
    }
    return totals;
  }
}
