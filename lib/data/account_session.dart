import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'budget_store.dart';
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

/// Thrown by [AccountSession.signIn] for an email that never signed up or a
/// wrong password — deliberately the same error, so it doesn't reveal which.
class InvalidCredentialsException implements Exception {
  const InvalidCredentialsException();
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
/// an email + password registered on this device, with a private data
/// namespace: its subscriptions and connected banks (Supabase, keyed by the
/// namespace id), People/Utilities cards, profile, monthly check-ins and
/// read notifications (local storage, keyed the same way) and budgets (keyed
/// by email). Only the salted hash of the password is kept. You must sign up
/// before you can log in; nothing is shared between accounts, and every new
/// account starts empty.
class AccountSession {
  AccountSession._();
  static final instance = AccountSession._();

  SharedPreferencesAsync get _prefs => SharedPreferencesAsync();

  String? _activeEmail;

  String _email(String email) =>
      base64Url.encode(utf8.encode(email.trim().toLowerCase()));
  String _nsKey(String email) => 'riyal.account_ns.v1.${_email(email)}';
  String _credKey(String email) => 'riyal.account_cred.v1.${_email(email)}';

  /// Set on accounts created by older builds, which seeded sample data.
  String _oldSeedsKey(String email) => 'riyal.account_demo.v1.${_email(email)}';

  /// Registers a new account and opens it, empty.
  Future<void> signUp(String email, String password) async {
    if (await _prefs.getString(_credKey(email)) != null) {
      throw const AccountExistsException();
    }
    // An account made before passwords existed keeps its data when its owner
    // signs up with that email again.
    var id = await _prefs.getString(_nsKey(email));
    final fresh = id == null;
    if (id == null) {
      id = DeviceIdStore.instance.generateId();
      await _prefs.setString(_nsKey(email), id);
    }
    await _storeCredential(email, password);
    await _enter(id, email, fresh: fresh);
  }

  /// Opens the account for [email]. Throws [InvalidCredentialsException]
  /// unless that email signed up and [password] matches.
  Future<void> signIn(String email, String password) async {
    final id = await _prefs.getString(_nsKey(email));
    if (id == null || !await _passwordMatches(email, password)) {
      throw const InvalidCredentialsException();
    }
    await _enter(id, email, fresh: false);
  }

  /// Deletes the open account: its password, data and budgets. Other
  /// accounts on this device are untouched.
  Future<void> deleteActiveAccount() async {
    final email = _activeEmail;
    final id = DeviceIdStore.instance.cachedId;
    if (email == null || id == null) return;
    try {
      await supabase.from('subscriptions').delete().eq('device_id', id);
      await supabase.from('user_bank_accounts').delete().eq('device_id', id);
    } catch (error) {
      debugPrint('Account cleanup in Supabase failed: $error');
    }
    await BudgetStore.instance.forget(email);
    for (final key in [
      _nsKey(email),
      _credKey(email),
      _oldSeedsKey(email),
      '${ProfileStore.storageKey}.$id',
      '${MonthlyReviewStore.storageKey}.$id',
      '${PeopleStore.instance.storageKey}.$id',
      '${UtilitiesStore.instance.storageKey}.$id',
      'riyal.read_notifications.v1.$id',
    ]) {
      await _prefs.remove(key);
    }
    _activeEmail = null;
    SubscriptionsStore.instance.subscriptions.value = [];
    UserBankAccountsStore.instance.clear();
    PeopleStore.reset();
    UtilitiesStore.reset();
    SpendingHistory.instance.clear();
    NotificationsStore.instance.reset();
  }

  Future<void> _enter(String id, String email, {required bool fresh}) async {
    await _open(id);
    _activeEmail = email.trim().toLowerCase();
    if (fresh) {
      // A brand-new account is known to be empty — no need to ask Supabase.
      SubscriptionsStore.instance.subscriptions.value = [];
      UserBankAccountsStore.instance.clear();
    }
    await _loadLocal();
    if (!fresh) {
      if (await _prefs.getBool(_oldSeedsKey(email)) ?? false) {
        await _removeOldSeeds(id, email);
      }
      await SubscriptionsStore.instance.load();
      await UserBankAccountsStore.instance.load();
    }
    NotificationsStore.instance.reset();
  }

  Future<void> _storeCredential(String email, String password) async {
    final random = Random.secure();
    final salt = List<int>.generate(16, (_) => random.nextInt(256));
    await _prefs.setString(
      _credKey(email),
      jsonEncode({
        'salt': base64Encode(salt),
        'hash': base64Encode(_hash(password, salt)),
      }),
    );
  }

  Future<bool> _passwordMatches(String email, String password) async {
    try {
      final raw = await _prefs.getString(_credKey(email));
      if (raw == null) return false;
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final expected = base64Decode(data['hash'] as String);
      final actual = _hash(password, base64Decode(data['salt'] as String));
      // Compare every byte so timing doesn't reveal how much matched.
      var diff = expected.length ^ actual.length;
      for (var i = 0; i < expected.length && i < actual.length; i++) {
        diff |= expected[i] ^ actual[i];
      }
      return diff == 0;
    } catch (_) {
      return false;
    }
  }

  /// PBKDF2-HMAC-SHA256 (one 32-byte block) — slow on purpose, so a leaked
  /// hash is expensive to brute-force.
  List<int> _hash(String password, List<int> salt, {int iterations = 10000}) {
    final hmac = Hmac(sha256, utf8.encode(password));
    var u = hmac.convert([...salt, 0, 0, 0, 1]).bytes;
    final result = List<int>.of(u);
    for (var i = 1; i < iterations; i++) {
      u = hmac.convert(u).bytes;
      for (var j = 0; j < result.length; j++) {
        result[j] ^= u[j];
      }
    }
    return result;
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
}
