import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'demo_mode.dart';
import 'device_id_store.dart';
import 'monthly_review.dart';
import 'notifications_store.dart';
import 'people_store.dart';
import 'profile_store.dart';
import 'subscriptions_store.dart';
import 'user_bank_accounts_store.dart';
import 'utilities_store.dart';

/// Thrown by [AccountSession.signUp] when the email already has an account.
class AccountExistsException implements Exception {
  const AccountExistsException();
}

/// There's no real Supabase Auth user (see [AuthStore]), so an "account" is
/// a private data namespace on this device, one per email: its
/// subscriptions and connected banks (Supabase, keyed by the namespace id),
/// People/Utilities cards, profile, monthly check-ins and read
/// notifications (local storage, keyed the same way) and budgets (keyed by
/// email). Nothing is shared between emails.
///
/// A sign-up creates a fresh, empty account with no default data. Logging in
/// with an email we haven't seen creates a demo account with the seeded
/// sample data; logging in again always returns to that account's own data.
class AccountSession {
  AccountSession._();
  static final instance = AccountSession._();

  SharedPreferencesAsync get _prefs => SharedPreferencesAsync();
  static const _legacyIdKey = 'riyal.demo_device_id.v1';
  static const _legacyClaimedKey = 'riyal.demo_claimed.v1';
  static const _demoFlagKey = 'riyal.demo_mode.v1';

  String _email(String email) =>
      base64Url.encode(utf8.encode(email.trim().toLowerCase()));
  String _nsKey(String email) => 'riyal.account_ns.v1.${_email(email)}';
  String _demoKey(String email) => 'riyal.account_demo.v1.${_email(email)}';

  /// Restores the last active mode at startup, before any store loads.
  Future<void> load() async {
    DemoMode.enabled = await _prefs.getBool(_demoFlagKey) ?? true;
  }

  Future<void> signUp(String email) async {
    if (await _prefs.getString(_nsKey(email)) != null) {
      throw const AccountExistsException();
    }
    await _legacyId();
    final id = DeviceIdStore.instance.generateId();
    await _prefs.setString(_nsKey(email), id);
    await _prefs.setBool(_demoKey(email), false);
    await _activate(id, demo: false);
    // A brand-new account is known to be empty — no need to ask Supabase.
    SubscriptionsStore.instance.subscriptions.value = [];
    UserBankAccountsStore.instance.clear();
    await _loadLocal();
    NotificationsStore.instance.reset();
  }

  Future<void> signIn(String email) async {
    var id = await _prefs.getString(_nsKey(email));
    final created = id == null;
    if (id == null) {
      final claimed = await _claimLegacy();
      id = claimed ?? DeviceIdStore.instance.generateId();
      await _prefs.setString(_nsKey(email), id);
      await _prefs.setBool(_demoKey(email), true);
      if (claimed != null) await _migrateLegacy(claimed);
    }
    await _activate(id, demo: await _prefs.getBool(_demoKey(email)) ?? false);
    await _loadLocal();
    if (created) await _rememberEmail(email);
    await SubscriptionsStore.instance.load();
    await UserBankAccountsStore.instance.load();
    NotificationsStore.instance.reset();
  }

  /// The namespace this device started with, before any account existed.
  Future<String> _legacyId() async {
    final saved = await _prefs.getString(_legacyIdKey);
    if (saved != null) return saved;
    final id = await DeviceIdStore.instance.getOrCreateDeviceId();
    await _prefs.setString(_legacyIdKey, id);
    return id;
  }

  /// The first email that logs in adopts the data this device already had,
  /// so nothing that existed before per-email accounts is lost.
  Future<String?> _claimLegacy() async {
    final id = await _legacyId();
    if (await _prefs.getBool(_legacyClaimedKey) ?? false) return null;
    await _prefs.setBool(_legacyClaimedKey, true);
    return id;
  }

  /// Local data that used to be one shared copy moves to the adopting account.
  Future<void> _migrateLegacy(String id) async {
    for (final base in [
      ProfileStore.storageKey,
      MonthlyReviewStore.storageKey,
    ]) {
      final old = await _prefs.getString(base);
      if (old != null && await _prefs.getString('$base.$id') == null) {
        await _prefs.setString('$base.$id', old);
      }
    }
  }

  Future<void> _activate(String id, {required bool demo}) async {
    // Let the outgoing account's last edits reach storage first.
    await PeopleStore.instance.flush();
    await UtilitiesStore.instance.flush();
    await DeviceIdStore.instance.setDeviceId(id);
    await _prefs.setBool(_demoFlagKey, demo);
    DemoMode.enabled = demo;
  }

  Future<void> _loadLocal() async {
    ProfileStore.instance.reset();
    await ProfileStore.instance.load();
    await PeopleStore.restore();
    await UtilitiesStore.restore();
    await MonthlyReviewStore.instance.switchAccount();
  }

  /// A new demo account shows the email it was opened with.
  Future<void> _rememberEmail(String email) async {
    final profile = ProfileStore.instance;
    if (profile.values['Email'] == 'user@example.com') {
      await profile.save('Email', email.trim());
    }
  }
}
