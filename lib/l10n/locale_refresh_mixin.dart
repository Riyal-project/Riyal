import 'package:flutter/widgets.dart';

import 'app_locale.dart';

/// Makes a [State] rebuild immediately when [AppLocale.locale] changes.
///
/// `Strings.t()` reads `AppLocale.locale.value` synchronously rather than
/// through an `InheritedWidget`, so switching language only reliably
/// rebuilds the one screen that triggered the switch (Settings) — every
/// other already-mounted screen keeps showing stale-locale text until some
/// unrelated `setState` happens to touch it. That's mostly invisible for
/// screens reached via `Navigator.push` (a fresh push always builds fresh,
/// so it already picks up the current locale) but it's a real, persistent
/// bug for the four tab bodies living in [MainShell]'s `IndexedStack` —
/// they're mounted for the entire app session and are exactly the screens
/// a user keeps coming back to. Mix this in and call
/// [addLocaleRefreshListener] from `initState` (and nothing else — disposal
/// is automatic) to fix that, without the bigger blast radius of forcing a
/// full teardown/rebuild of the whole navigation stack.
mixin LocaleRefreshState<T extends StatefulWidget> on State<T> {
  void addLocaleRefreshListener() {
    AppLocale.locale.addListener(_onLocaleChanged);
  }

  void _onLocaleChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    AppLocale.locale.removeListener(_onLocaleChanged);
    super.dispose();
  }
}
