import 'dart:math' as math;

import 'home_data.dart';
import 'item_status.dart';
import 'people_store.dart';
import 'spending_history.dart';
import 'subscriptions_store.dart';
import 'utilities_store.dart';

class AnalyticsItem {
  const AnalyticsItem(
    this.name,
    this.category,
    this.amount,
    this.days,
    this.group,
  );
  final String name;
  final String category;
  final double amount;
  final int days;
  final String group;
}

bool _counts(ItemStatus status) =>
    status == ItemStatus.active || status == ItemStatus.trial;

/// One row per active card that costs something this month, across the
/// Subscriptions / Utilities / People screens. [AnalyticsItem.group] is the
/// card's own category (e.g. Entertainment, Electricity, Driving).
List<AnalyticsItem> get analyticsItems {
  final now = DateTime.now();
  return [
    for (final s in SubscriptionsStore.instance.subscriptions.value)
      if (_counts(s.status) && s.monthlyAmount > 0)
        AnalyticsItem(
          s.name,
          'Subscriptions',
          s.monthlyAmount,
          math.max(0, s.renewsInDays),
          s.category.label,
        ),
    for (final i in UtilitiesStore.instance.items.value)
      if (_counts(i.status) && i.monthlyAmount > 0)
        AnalyticsItem(
          i.name,
          'Utilities',
          i.monthlyAmount,
          math.max(0, i.renewsInDays),
          i.category.label,
        ),
    for (final i in PeopleStore.instance.items.value)
      if (_counts(i.status) &&
          !(i.pausedUntil?.isAfter(now) ?? false) &&
          i.monthlyAmount > 0)
        AnalyticsItem(
          i.name,
          'People',
          i.monthlyAmount,
          math.max(0, i.renewsInDays),
          i.category.label,
        ),
  ];
}

/// Six months per category, oldest first; the last entry is this month and
/// always equals the Home overview (its recurring commitments). The earlier
/// five are what the connected banks show was actually paid that month, and
/// stay 0 when there is no bank data for them.
Map<String, List<double>> get analyticsHistory {
  final earlier = SpendingHistory.instance.earlier.value;
  return {
    for (final category in overview)
      category.label: [
        ...(earlier[category.label] ??
            List<double>.filled(SpendingHistory.months, 0)),
        category.amount,
      ],
  };
}
