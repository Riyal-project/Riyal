import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'device_id_store.dart';
import 'monthly_review.dart';
import 'notifications_store.dart';
import 'people_store.dart';
import 'profile_store.dart';
import 'spending_history.dart';
import 'subscriptions_store.dart';
import 'supabase_config.dart';
import 'user_bank_accounts_store.dart';
import 'utilities_store.dart';

/// Thrown by [AccountSession.signUp] when the email already has an account.
class AccountExistsException implements Exception {
  const AccountExistsException();
}

/// The sample data older builds put in every account: (name, monthly amount).
/// It came from no real transaction, so [AccountSession.signIn] removes it
/// from accounts that were created back then.
const _oldSeededCards = {
  ('Driver', 2200),
  ('Housekeeper', 1800),
  ('Nanny', 3000),
  ('Saudi Electricity Company', 1189),
  ('STC', 250),
  ('National Water Company', 234),
  ('Zain', 150),
};
const _oldSeededSubscriptions = {
  ('Netflix', 45),
  ('ChatGPT Plus', 80),
  ('Duolingo', 30),
  ('Spotify', 25),
  ('Adobe Creative Cloud', 249),
};

/// There's no real Supabase Auth user (see [AuthStore]), so an "account" is
/// a private data namespace on this device, one per email: its
/// subscriptions and connected banks (Supabase, keyed by the namespace id),
/// People/Utilities cards, profile, monthly check-ins and read
/// notifications (local storage, keyed the same way) and budgets (keyed by
/// email). Nothing is shared between emails, and every account starts empty.
class AccountSession {
  AccountSession._();
  static final instance = AccountSession._();

  SharedPreferencesAsync get _prefs => SharedPreferencesAsync();

  String _email(String email) =>
      base64Url.encode(utf8.encode(email.trim().toLowerCase()));
  String _nsKey(String email) => 'riyal.account_ns.v1.${_email(email)}';

  /// Set on accounts created by older builds, which seeded sample data.
  String _oldSeedsKey(String email) => 'riyal.account_demo.v1.${_email(email)}';

  Future<void> signUp(String email) async {
    if (await _prefs.getString(_nsKey(email)) != null) {
      throw const AccountExistsException();
    }
    final id = DeviceIdStore.instance.generateId();
    await _prefs.setString(_nsKey(email), id);
    await _open(id);
    // A brand-new account is known to be empty — no need to ask Supabase.
    SubscriptionsStore.instance.subscriptions.value = [];
    UserBankAccountsStore.instance.clear();
    await _loadLocal();
    NotificationsStore.instance.reset();
  }

  /// Opens the account for [email]; an email that never signed up gets a
  /// fresh, empty account of its own.
  Future<void> signIn(String email) async {
    var id = await _prefs.getString(_nsKey(email));
    final isNew = id == null;
    if (id == null) {
      id = DeviceIdStore.instance.generateId();
      await _prefs.setString(_nsKey(email), id);
    }
    await _open(id);
    await _loadLocal();
    if (await _prefs.getBool(_oldSeedsKey(email)) ?? false) {
      await _removeOldSeeds(id, email);
    }
    if (isNew) await _rememberEmail(email);
    await SubscriptionsStore.instance.load();
    await UserBankAccountsStore.instance.load();
    NotificationsStore.instance.reset();
  }

  Future<void> _open(String id) async {
    // Let the outgoing account's last edits reach storage first.
    await PeopleStore.instance.flush();
    await UtilitiesStore.instance.flush();
    await DeviceIdStore.instance.setDeviceId(id);
    SpendingHistory.instance.clear();
  }

  Future<void> _loadLocal() async {
    ProfileStore.instance.reset();
    await ProfileStore.instance.load();
    await PeopleStore.restore();
    await UtilitiesStore.restore();
    await MonthlyReviewStore.instance.switchAccount();
  }

  /// Removes only the exact sample items (same name and amount) — anything
  /// the user added or a bank detected is kept.
  Future<void> _removeOldSeeds(String id, String email) async {
    for (final store in [PeopleStore.instance, UtilitiesStore.instance]) {
      store.items.value = [
        for (final item in store.items.value)
          if (!_oldSeededCards.contains((item.name, item.amount.round()))) item,
      ];
    }
    try {
      for (final (name, amount) in _oldSeededSubscriptions) {
        await supabase
            .from('subscriptions')
            .delete()
            .eq('device_id', id)
            .eq('name', name)
            .eq('amount', amount);
      }
      await _prefs.setBool(_oldSeedsKey(email), false);
    } catch (error) {
      // Stays flagged, so the next login tries again.
      debugPrint('Old sample data cleanup failed: $error');
    }
  }

  /// A new account shows the email it was opened with.
  Future<void> _rememberEmail(String email) async {
    final profile = ProfileStore.instance;
    if (profile.values['Email'] == 'user@example.com') {
      await profile.save('Email', email.trim());
    }
  }
}
