import 'package:flutter_test/flutter_test.dart';
import 'package:riyal/data/analytics_data.dart';
import 'package:riyal/data/mock_bank_transaction.dart';
import 'package:riyal/data/people_store.dart';
import 'package:riyal/data/spending_history.dart';
import 'package:riyal/data/subscription.dart';
import 'package:riyal/data/subscriptions_store.dart';
import 'package:riyal/data/tracked_item.dart';
import 'package:riyal/data/utilities_store.dart';
import 'package:riyal/data/utility_categories.dart';

MockBankTransactionRow tx(String category, double amount, DateTime date) =>
    MockBankTransactionRow(
      id: '$category$amount$date',
      bankId: 'b',
      merchantName: 'M',
      amount: amount,
      transactionDate: date,
      category: category,
    );

void main() {
  final now = DateTime(2026, 9, 19);

  test('sums real payments per category for the five earlier months', () {
    final totals = SpendingHistory.aggregate([
      tx('utility', 704, DateTime(2026, 6, 16)),
      tx('utility', 788, DateTime(2026, 7, 16)),
      tx('utility', 851, DateTime(2026, 8, 15)),
      tx('utility', 245, DateTime(2026, 8, 15)),
      tx('person', 1800, DateTime(2026, 8, 15)),
      tx('subscription', 45, DateTime(2026, 5, 2)),
      tx('utility', 1189, DateTime(2026, 9, 14)), // this month: not history
      tx('utility', 999, DateTime(2026, 3, 1)), // six months back: too old
      tx('other', 60, DateTime(2026, 8, 1)), // not a tracked category
      tx('subscription', 25, DateTime(2025, 12, 30)), // last year: too old
    ], now);

    // Oldest first: Apr, May, Jun, Jul, Aug.
    expect(totals['Utilities'], [0, 0, 704, 788, 1096]);
    expect(totals['People'], [0, 0, 0, 0, 1800]);
    expect(totals['Subscriptions'], [0, 45, 0, 0, 0]);
  });

  test('handles a year boundary', () {
    final totals = SpendingHistory.aggregate([
      tx('utility', 100, DateTime(2025, 12, 10)),
      tx('utility', 200, DateTime(2026, 1, 10)),
    ], DateTime(2026, 2, 5));
    expect(totals['Utilities'], [0, 0, 0, 100, 200]);
  });

  test('earlier months reach the analytics history; this month stays live', () {
    SubscriptionsStore.instance.subscriptions.value = <Subscription>[];
    PeopleStore.reset();
    UtilitiesStore.reset();
    UtilitiesStore.instance.add(
      TrackedItem(
        id: 'u',
        name: 'Saudi Electricity Company',
        amount: 900,
        cycle: BillingCycle.monthly,
        nextBillingDate: now.add(const Duration(days: 5)),
        category: UtilityCategories.electricity,
      ),
    );
    expect(analyticsHistory['Utilities'], [0, 0, 0, 0, 0, 900]);

    SpendingHistory.instance.earlier.value = SpendingHistory.aggregate([
      tx('utility', 704, DateTime(2026, 6, 16)),
      tx('utility', 851, DateTime(2026, 8, 15)),
    ], DateTime(2026, 9, 19));
    expect(analyticsHistory['Utilities'], [0, 0, 704, 0, 851, 900]);
    expect(analyticsHistory['People'], [0, 0, 0, 0, 0, 0]);

    SpendingHistory.instance.clear();
    expect(analyticsHistory['Utilities'], [0, 0, 0, 0, 0, 900]);
  });
}
