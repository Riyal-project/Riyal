import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:riyal/data/account_session.dart';
import 'package:riyal/data/analytics_data.dart';
import 'package:riyal/data/demo_mode.dart';
import 'package:riyal/data/device_id_store.dart';
import 'package:riyal/data/home_data.dart';
import 'package:riyal/data/notifications_store.dart';
import 'package:riyal/data/people_store.dart';
import 'package:riyal/data/subscriptions_store.dart';
import 'package:riyal/data/utilities_store.dart';
import 'package:riyal/l10n/app_locale.dart';
import 'package:riyal/l10n/strings.dart';
import 'package:riyal/screens/home_screen.dart';
import 'package:riyal/theme/app_theme.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    AppLocale.locale.value = const Locale('en');
    DemoMode.enabled = true;
    PeopleStore.reset();
    UtilitiesStore.reset();
  });

  test('demo login is seeded with the same prices as the mock database', () {
    expect(PeopleStore.instance.items.value.map((i) => i.amount), [
      2200,
      1800,
      3000,
    ]);
    expect(UtilitiesStore.instance.items.value.map((i) => i.amount), [
      1189,
      250,
      234,
      150,
    ]);
    final utilities = overview[1].amount;
    expect(
      utilities,
      analyticsItems
          .where((i) => i.category == 'Utilities')
          .fold<double>(0, (sum, i) => sum + i.amount),
    );
    expect(
      utilities,
      UtilitiesStore.instance.items.value.fold<double>(
        0,
        (sum, i) => sum + i.amount,
      ),
    );
  });

  test(
    'sign-up starts with no defaults; the demo login gets them back',
    () async {
      final demoId = await DeviceIdStore.instance.getOrCreateDeviceId();
      await AccountSession.instance.signUp('new@user.com');

      expect(DemoMode.enabled, isFalse);
      expect(PeopleStore.instance.items.value, isEmpty);
      expect(UtilitiesStore.instance.items.value, isEmpty);
      expect(SubscriptionsStore.instance.subscriptions.value, isEmpty);
      expect(NotificationsStore.instance.notices.value, isEmpty);
      expect(overview.every((c) => c.amount == 0), isTrue);
      expect(analyticsItems, isEmpty);
      expect(await DeviceIdStore.instance.getOrCreateDeviceId(), isNot(demoId));

      // Sign-in reloads from Supabase, which isn't available in tests; the
      // account switch itself happens before that call.
      try {
        await AccountSession.instance.signIn('someone@else.com');
      } catch (_) {}
      expect(DemoMode.enabled, isTrue);
      expect(PeopleStore.instance.items.value, hasLength(3));
      expect(UtilitiesStore.instance.items.value, hasLength(4));
      expect(await DeviceIdStore.instance.getOrCreateDeviceId(), demoId);

      // Logging back in as the signed-up email returns to its empty account.
      try {
        await AccountSession.instance.signIn('New@User.com');
      } catch (_) {}
      expect(DemoMode.enabled, isFalse);
      expect(PeopleStore.instance.items.value, isEmpty);
    },
  );

  testWidgets('home renders for a new sign-up with nothing spent yet', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    DemoMode.enabled = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: const Scaffold(body: HomeBody()),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text(Strings.t('analytics_tab')));
    await tester.pump();
    expect(find.text(Strings.t('analytics_empty')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
