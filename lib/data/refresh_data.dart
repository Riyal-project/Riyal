import 'package:flutter/foundation.dart';

import 'notifications_store.dart';
import 'subscriptions_store.dart';
import 'user_bank_accounts_store.dart';

/// Pull-to-refresh: re-reads what can change behind the app's back —
/// subscriptions and connected banks from Supabase (the banks' spending
/// history reloads with them) — and rechecks the inbox. Always takes a
/// moment, so a refresh never looks like nothing happened; a failed step
/// (offline) is skipped and the rest still refresh.
Future<void> refreshAppData() async {
  Future<void> safe(Future<void> Function() step) async {
    try {
      await step();
    } catch (error) {
      debugPrint('Refresh step failed: $error');
    }
  }

  await Future.wait([
    safe(SubscriptionsStore.instance.load),
    safe(UserBankAccountsStore.instance.load),
    Future<void>.delayed(const Duration(milliseconds: 900)),
  ]);
  NotificationsStore.instance.refresh();
}
