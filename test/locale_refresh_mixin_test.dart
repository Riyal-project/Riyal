import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riyal/l10n/app_locale.dart';
import 'package:riyal/l10n/locale_refresh_mixin.dart';

class _Probe extends StatefulWidget {
  const _Probe();
  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> with LocaleRefreshState {
  @override
  void initState() {
    super.initState();
    addLocaleRefreshListener();
  }

  @override
  Widget build(BuildContext context) =>
      Text(AppLocale.locale.value.languageCode);
}

void main() {
  tearDown(() => AppLocale.locale.value = const Locale('en'));

  testWidgets(
    'a State mixing in LocaleRefreshState rebuilds when AppLocale.locale '
    'changes, with no navigation or unrelated setState involved — this is '
    'what fixes tab bodies that stay mounted for the whole app session '
    '(Home/Subscriptions/Utilities/People) showing stale-locale text',
    (tester) async {
      AppLocale.locale.value = const Locale('en');
      await tester.pumpWidget(const MaterialApp(home: _Probe()));
      expect(find.text('en'), findsOneWidget);

      // Same widget, same Element — never removed from the tree, no push/
      // pop, no setState from anywhere else. Only the locale changes.
      AppLocale.locale.value = const Locale('ar');
      await tester.pump();

      expect(find.text('ar'), findsOneWidget);
      expect(find.text('en'), findsNothing);
    },
  );

  testWidgets('the listener is removed on dispose (no leak, no late '
      'setState-after-dispose crash)', (tester) async {
    AppLocale.locale.value = const Locale('en');
    await tester.pumpWidget(const MaterialApp(home: _Probe()));

    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    AppLocale.locale.value = const Locale('ar');
    await tester.pump();
    // No exception thrown above is the assertion — a leaked listener
    // calling setState on a disposed State would throw during pump().
    expect(tester.takeException(), isNull);
  });
}
