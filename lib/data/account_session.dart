import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'demo_mode.dart';
import 'device_id_store.dart';
import 'notifications_store.dart';
import 'people_store.dart';
import 'subscriptions_store.dart';
import 'user_bank_accounts_store.dart';
import 'utilities_store.dart';

/// There's no real Supabase Auth user (see [AuthStore]), so an "account" is
/// just a data namespace on this device: logging in gets the original demo
/// namespace (seeded data) unless that email signed up here, and every
/// sign-up gets a fresh, empty namespace with no default subscriptions,
/// people, utilities or notices. Logging back in with a signed-up email
/// returns to its own data.
class AccountSession {
  AccountSession._();
  static final instance = AccountSession._();

  SharedPreferencesAsync get _prefs => SharedPreferencesAsync();
  static const _demoIdKey = 'riyal.demo_device_id.v1';
  static const _demoFlagKey = 'riyal.demo_mode.v1';

  String _accountKey(String email) =>
      'riyal.account_ns.v1.${base64Url.encode(utf8.encode(email.trim().toLowerCase()))}';

  /// Restores the last active mode at startup, before any store loads.
  Future<void> load() async {
    DemoMode.enabled = await _prefs.getBool(_demoFlagKey) ?? true;
  }

  Future<void> signUp(String email) async {
    await _demoId();
    final id = DeviceIdStore.instance.generateId();
    await _prefs.setString(_accountKey(email), id);
    await _switchTo(id, demo: false);
    // A brand-new namespace is known to be empty — no need to ask Supabase.
    SubscriptionsStore.instance.subscriptions.value = [];
    UserBankAccountsStore.instance.clear();
  }

  Future<void> signIn(String email) async {
    final own = await _prefs.getString(_accountKey(email));
    await _switchTo(own ?? await _demoId(), demo: own == null);
    await SubscriptionsStore.instance.load();
    await UserBankAccountsStore.instance.load();
  }

  /// The original namespace, remembered before the first sign-up switches
  /// away from it (the active id is still the demo one until then).
  Future<String> _demoId() async {
    final saved = await _prefs.getString(_demoIdKey);
    if (saved != null) return saved;
    final id = DemoMode.enabled
        ? await DeviceIdStore.instance.getOrCreateDeviceId()
        : DeviceIdStore.instance.generateId();
    await _prefs.setString(_demoIdKey, id);
    return id;
  }

  Future<void> _switchTo(String id, {required bool demo}) async {
    await DeviceIdStore.instance.setDeviceId(id);
    await _prefs.setBool(_demoFlagKey, demo);
    DemoMode.enabled = demo;
    PeopleStore.reset();
    UtilitiesStore.reset();
    NotificationsStore.instance.reset();
  }
}
