import 'item_status.dart';
import 'subscription_category.dart';
import 'tracked_category.dart';

enum BillingCycle { monthly, yearly }

enum FreeTrialDuration { week, month }

DateTime freeTrialEndDate(DateTime start, FreeTrialDuration duration) {
  final date = DateTime(start.year, start.month, start.day);
  if (duration == FreeTrialDuration.week) {
    return DateTime(date.year, date.month, date.day + 7);
  }
  final lastDay = DateTime(date.year, date.month + 2, 0).day;
  return DateTime(
    date.year,
    date.month + 1,
    date.day > lastDay ? lastDay : date.day,
  );
}

class Subscription {
  const Subscription({
    required this.id,
    required this.name,
    required this.logoAsset,
    required this.amount,
    required this.cycle,
    required this.nextBillingDate,
    this.category = SubscriptionCategories.other,
    this.status = ItemStatus.active,
    this.purposeTag,
    this.reminderDate,
    this.notificationsEnabled = true,
    this.trialStartDate,
    this.trialDuration,
  }) : assert((trialStartDate == null) == (trialDuration == null));

  final String id;
  final String name;
  final String? logoAsset;
  final double amount;
  final BillingCycle cycle;
  final DateTime nextBillingDate;
  final TrackedCategory category;
  final ItemStatus status;

  /// Free-text note on why this subscription exists or how long it's meant
  /// to last (e.g. "Shared with family", "Cancel after the trip") — shown
  /// on the details page; optional.
  final String? purposeTag;

  /// A user-set date to revisit this subscription, independent of the
  /// automatic renewal reminder (e.g. "check before the trial ends").
  final DateTime? reminderDate;
  final bool notificationsEnabled;
  final DateTime? trialStartDate;
  final FreeTrialDuration? trialDuration;

  bool get hasFreeTrial => trialStartDate != null && trialDuration != null;
  DateTime? get trialEndDate =>
      hasFreeTrial ? freeTrialEndDate(trialStartDate!, trialDuration!) : null;
  bool get isInFreeTrial =>
      hasFreeTrial && DateTime.now().isBefore(trialEndDate!);
  DateTime? get trialReminderDate => trialEndDate == null
      ? null
      : DateTime(
          trialEndDate!.year,
          trialEndDate!.month,
          trialEndDate!.day - 5,
        );

  int get renewsInDays => nextBillingDate.difference(DateTime.now()).inDays;

  double get monthlyAmount => isInFreeTrial
      ? 0
      : (cycle == BillingCycle.monthly ? amount : amount / 12);

  Subscription copyWith({
    double? amount,
    BillingCycle? cycle,
    DateTime? nextBillingDate,
    TrackedCategory? category,
    ItemStatus? status,
    String? purposeTag,
    bool clearPurposeTag = false,
    DateTime? reminderDate,
    bool clearReminderDate = false,
    bool? notificationsEnabled,
    DateTime? trialStartDate,
    FreeTrialDuration? trialDuration,
    bool clearFreeTrial = false,
  }) => Subscription(
    id: id,
    name: name,
    logoAsset: logoAsset,
    amount: amount ?? this.amount,
    cycle: cycle ?? this.cycle,
    nextBillingDate: nextBillingDate ?? this.nextBillingDate,
    category: category ?? this.category,
    status: status ?? this.status,
    purposeTag: clearPurposeTag ? null : (purposeTag ?? this.purposeTag),
    reminderDate: clearReminderDate
        ? null
        : (reminderDate ?? this.reminderDate),
    notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    trialStartDate: clearFreeTrial
        ? null
        : trialStartDate ?? this.trialStartDate,
    trialDuration: clearFreeTrial ? null : trialDuration ?? this.trialDuration,
  );
}
