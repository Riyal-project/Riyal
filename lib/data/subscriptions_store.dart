import 'package:flutter/foundation.dart';

import 'device_id_store.dart';
import 'item_status.dart';
import 'subscription.dart';
import 'subscription_category.dart';
import 'supabase_config.dart';
import 'tracked_category.dart';

/// Backed by the Supabase `subscriptions` table (see
/// supabase/migrations/0001_init.sql) instead of an in-memory list. Starts
/// empty: subscriptions only come from the user, or from recurring payments
/// detected in a connected bank's real transactions.
class SubscriptionsStore {
  SubscriptionsStore._();

  static final SubscriptionsStore instance = SubscriptionsStore._();

  final ValueNotifier<List<Subscription>> subscriptions =
      ValueNotifier<List<Subscription>>([]);

  Future<void> load() async {
    final deviceId = await DeviceIdStore.instance.getOrCreateDeviceId();
    final rows = await supabase
        .from('subscriptions')
        .select()
        .eq('device_id', deviceId)
        .order('created_at', ascending: true);

    subscriptions.value = rows.map(_fromRow).toList();
  }

  /// Updates the in-memory list immediately (callers don't await this), and
  /// persists in the background — a persistence failure shouldn't crash an
  /// unrelated caller that fired this off without awaiting it.
  Future<void> add(Subscription subscription) async {
    subscriptions.value = [...subscriptions.value, subscription];
    try {
      final deviceId = await DeviceIdStore.instance.getOrCreateDeviceId();
      await _insert(deviceId, subscription);
    } catch (error) {
      debugPrint('Subscription persist failed: $error');
    }
  }

  /// Same optimistic-then-persist shape as [add]: the list updates
  /// immediately, and a persistence failure is logged rather than thrown at
  /// an unrelated caller.
  Future<void> update(Subscription subscription) async {
    subscriptions.value = [
      for (final existing in subscriptions.value)
        if (existing.id == subscription.id) subscription else existing,
    ];
    try {
      await supabase
          .from('subscriptions')
          .update({
            'name': subscription.name,
            'logo_asset': subscription.logoAsset,
            'amount': subscription.amount,
            'cycle': subscription.cycle.name,
            'next_billing_date': subscription.nextBillingDate
                .toIso8601String()
                .split('T')
                .first,
            'category_key': subscription.category.key,
            'status': subscription.status.name,
            'purpose_tag': subscription.purposeTag,
            'reminder_date': subscription.reminderDate
                ?.toIso8601String()
                .split('T')
                .first,
            'notifications_enabled': subscription.notificationsEnabled,
            'trial_start_date': subscription.trialStartDate
                ?.toIso8601String()
                .split('T')
                .first,
            'trial_duration': subscription.trialDuration?.name,
          })
          .eq('id', subscription.id);
    } catch (error) {
      debugPrint('Subscription update failed: $error');
    }
  }

  Future<void> remove(String id) async {
    subscriptions.value = subscriptions.value.where((s) => s.id != id).toList();
    try {
      await supabase.from('subscriptions').delete().eq('id', id);
    } catch (error) {
      debugPrint('Subscription delete failed: $error');
    }
  }

  Future<void> _insert(String deviceId, Subscription subscription) {
    return supabase.from('subscriptions').insert({
      'id': subscription.id,
      'device_id': deviceId,
      'name': subscription.name,
      'logo_asset': subscription.logoAsset,
      'amount': subscription.amount,
      'cycle': subscription.cycle.name,
      'next_billing_date': subscription.nextBillingDate
          .toIso8601String()
          .split('T')
          .first,
      'category_key': subscription.category.key,
      'status': subscription.status.name,
      'purpose_tag': subscription.purposeTag,
      'reminder_date': subscription.reminderDate
          ?.toIso8601String()
          .split('T')
          .first,
      'notifications_enabled': subscription.notificationsEnabled,
      'trial_start_date': subscription.trialStartDate
          ?.toIso8601String()
          .split('T')
          .first,
      'trial_duration': subscription.trialDuration?.name,
    });
  }

  Subscription _fromRow(Map<String, dynamic> row) => Subscription(
    id: row['id'] as String,
    name: row['name'] as String,
    logoAsset: row['logo_asset'] as String?,
    amount: (row['amount'] as num).toDouble(),
    cycle: BillingCycle.values.byName(row['cycle'] as String),
    nextBillingDate: DateTime.parse(row['next_billing_date'] as String),
    category: _categoryFromKey(row['category_key'] as String),
    status: ItemStatusDisplay.fromName(row['status'] as String?),
    purposeTag: row['purpose_tag'] as String?,
    reminderDate: row['reminder_date'] != null
        ? DateTime.parse(row['reminder_date'] as String)
        : null,
    notificationsEnabled: row['notifications_enabled'] as bool? ?? true,
    trialStartDate: row['trial_start_date'] == null
        ? null
        : DateTime.parse(row['trial_start_date'] as String),
    trialDuration: row['trial_duration'] == null
        ? null
        : FreeTrialDuration.values.byName(row['trial_duration'] as String),
  );

  TrackedCategory _categoryFromKey(String key) =>
      SubscriptionCategories.values.firstWhere(
        (c) => c.key == key,
        orElse: () => SubscriptionCategories.other,
      );
}
