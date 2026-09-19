import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// This device's anonymous identifier — scopes both the subscriptions
/// store (see [SubscriptionsStore]) and, for now, connected mock bank
/// accounts too (see lib/data/user_bank_accounts_store.dart). Real
/// Supabase Auth is wired up in lib/data/auth_store.dart but not
/// currently used — email confirmation was blocking testing.
class DeviceIdStore {
  DeviceIdStore._();
  static final instance = DeviceIdStore._();

  SharedPreferencesAsync get _prefs => SharedPreferencesAsync();
  static const _deviceIdKey = 'riyal.device_id.v1';

  Future<String> getOrCreateDeviceId() async {
    final existing = await _prefs.getString(_deviceIdKey);
    if (existing != null) return existing;
    final generated = generateId();
    await _prefs.setString(_deviceIdKey, generated);
    return generated;
  }

  /// Switches the active namespace (see [AccountSession]).
  Future<void> setDeviceId(String id) => _prefs.setString(_deviceIdKey, id);

  String generateId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
