import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Reads Supabase project config from the public-only client asset and
/// initializes the client. The anon key is safe to ship in the app — it
/// only grants what the Postgres row-level-security policies allow (see
/// supabase/migrations/0001_init.sql). The service role key must never be
/// here; it lives only in the Edge Function's environment.
class SupabaseConfig {
  SupabaseConfig._();

  static String get url {
    final value = dotenv.env['SUPABASE_URL'];
    if (value == null || value.isEmpty) {
      throw StateError(
        'SUPABASE_URL is not set. Run scripts/prepare-web.ps1.',
      );
    }
    return value;
  }

  static String get anonKey {
    final value = dotenv.env['SUPABASE_ANON_KEY'];
    if (value == null || value.isEmpty) {
      throw StateError(
        'SUPABASE_ANON_KEY is not set. Run scripts/prepare-web.ps1.',
      );
    }
    return value;
  }

  static Future<void> initialize() async {
    await Supabase.initialize(url: url, publishableKey: anonKey);
  }
}

SupabaseClient get supabase => Supabase.instance.client;
