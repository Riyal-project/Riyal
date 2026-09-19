import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;

import '../l10n/strings.dart';
import 'auth_store.dart';
import 'device_id_store.dart';

/// English display label for a profile field key -> its localized text.
/// The keys themselves ('Full name', 'Email', ...) stay English: they're
/// used for persistence and equality checks throughout profile_screen.dart.
String profileFieldLabel(String field) => switch (field) {
  'Full name' => Strings.t('field_full_name'),
  'Email' => Strings.t('field_email'),
  'Phone number' => Strings.t('field_phone_number'),
  'Joined on' => Strings.t('field_joined_on'),
  _ => field,
};

class ProfileStore {
  static final instance = ProfileStore();
  SharedPreferencesAsync get _prefs => SharedPreferencesAsync();
  static const storageKey = 'riyal.demo_profile.v1';
  static Map<String, String> _defaults() => {
    'Full name': 'Riyal User',
    'Email': 'user@example.com',
    'Phone number': '+966 50 000 0000',
    'Joined on': DateTime.now().toIso8601String().split('T').first,
  };
  Map<String, String> values = _defaults();

  /// Back to the placeholders — call before loading another account's profile.
  void reset() => values = _defaults();

  Future<String> _key() => DeviceIdStore.instance.scoped(storageKey);

  Future<void> load() async {
    final key = await _key();
    final saved = await _prefs.getString(key);
    if (saved == null) {
      // First run for this device: seed from whatever the user actually
      // typed in at sign-up (Supabase Auth's user metadata) instead of the
      // generic "Riyal User" placeholder, when that's available.
      User? user;
      try {
        user = AuthStore.instance.currentUser;
      } catch (_) {
        // Supabase Auth isn't in use (or isn't up yet); fine without it.
      }
      final authName = user?.userMetadata?['full_name'] as String?;
      if (authName != null && authName.trim().isNotEmpty) {
        values = {...values, 'Full name': authName.trim()};
      }
      if (user?.email != null) {
        values = {...values, 'Email': user!.email!};
      }
      await _prefs.setString(key, jsonEncode(values));
    }
    if (saved != null) {
      values = {
        ...values,
        ...Map<String, String>.from(jsonDecode(saved) as Map),
      };
    }
  }

  Future<void> save(String field, String value) async {
    if (!['Full name', 'Email', 'Phone number'].contains(field)) {
      throw ArgumentError('This profile field is read-only');
    }
    final next = {...values, field: value};
    await _prefs.setString(await _key(), jsonEncode(next));
    values = next;
  }
}
