/// Whether the built-in demo data (seeded subscriptions/people/utilities and
/// the dashboard numbers) is showing. True for the demo login, false for a
/// brand-new sign-up — see [AccountSession] in lib/data/account_session.dart.
/// Kept as a plain flag so the pure data files can read it without importing
/// any store.
class DemoMode {
  DemoMode._();
  static bool enabled = true;
}
