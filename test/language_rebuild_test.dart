import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riyal/l10n/app_locale.dart';
import 'package:riyal/l10n/strings.dart';
import 'package:riyal/theme/app_theme.dart';
import 'package:riyal/widgets/account_section.dart';
import 'package:riyal/widgets/rebuild_all.dart';

/// Const, listens to nothing — like the screens that stayed in the old
/// language after a switch.
class _Label extends StatelessWidget {
  const _Label();
  @override
  Widget build(BuildContext context) => Text(Strings.t('overview'));
}

void main() {
  tearDown(() => AppLocale.locale.value = const Locale('en'));

  testWidgets('rebuildAllElements retranslates const screens at once', (
    tester,
  ) async {
    AppLocale.locale.value = const Locale('en');
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: _Label())));
    expect(find.text('Overview'), findsOneWidget);

    AppLocale.locale.value = const Locale('ar');
    await tester.pump();
    expect(find.text('Overview'), findsOneWidget); // stale without the rebuild

    rebuildAllElements();
    await tester.pump();
    expect(find.text('Overview'), findsNothing);
    expect(find.text(Strings.t('overview')), findsOneWidget);
    expect(Strings.t('overview'), isNot('Overview'));
  });

  for (final code in ['en', 'ar']) {
    testWidgets('page header is centered in $code', (tester) async {
      tester.view.physicalSize = const Size(375, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      AppLocale.locale.value = Locale(code);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(languageCode: code),
          locale: Locale(code),
          supportedLocales: const [Locale('en'), Locale('ar')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AccountPageHeader(
                    icon: Icons.tune_rounded,
                    title: Strings.t('settings_header_title'),
                    subtitle: 'Short line',
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      final middle = tester.view.physicalSize.width / 2;
      for (final text in [Strings.t('settings_header_title'), 'Short line']) {
        expect(tester.getCenter(find.text(text)).dx, closeTo(middle, 1));
      }
      expect(
        tester.getCenter(find.byType(CustomPaint).first).dx,
        closeTo(middle, 1),
      );
    });
  }
}
