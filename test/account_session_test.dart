import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:riyal/data/account_session.dart';
import 'package:riyal/data/analytics_data.dart';
import 'package:riyal/data/device_id_store.dart';
import 'package:riyal/data/home_data.dart';
import 'package:riyal/data/notifications_store.dart';
import 'package:riyal/data/people_categories.dart';
import 'package:riyal/data/people_store.dart';
import 'package:riyal/data/profile_store.dart';
import 'package:riyal/data/subscription.dart';
import 'package:riyal/data/subscriptions_store.dart';
import 'package:riyal/data/tracked_category.dart';
import 'package:riyal/data/tracked_item.dart';
import 'package:riyal/data/utilities_store.dart';
import 'package:riyal/data/utility_categories.dart';
import 'package:riyal/l10n/app_locale.dart';
import 'package:riyal/l10n/strings.dart';
import 'package:riyal/screens/home_screen.dart';
import 'package:riyal/theme/app_theme.dart';

TrackedItem card(String name, TrackedCategory category, [double amount = 99]) =>
    TrackedItem(
      id: name,
      name: name,
      amount: amount,
      cycle: BillingCycle.monthly,
      nextBillingDate: DateTime.now().add(const Duration(days: 4)),
      category: category,
    );

/// The Supabase reload at the end of a login isn't available in tests; the
/// account switch and local data are loaded before it.
Future<void> logIn(String email) async {
  try {
    await AccountSession.instance.signIn(email);
  } catch (_) {}
}

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    PeopleStore.reset();
    UtilitiesStore.reset();
    SubscriptionsStore.instance.subscriptions.value = [];
    AppLocale.locale.value = const Locale('en');
  });

  test('nothing is seeded: an untouched app has no cards and no spend', () {
    expect(PeopleStore.instance.items.value, isEmpty);
    expect(UtilitiesStore.instance.items.value, isEmpty);
    expect(SubscriptionsStore.instance.subscriptions.value, isEmpty);
    expect(overview.every((c) => c.amount == 0), isTrue);
    expect(analyticsItems, isEmpty);
    expect(analyticsHistory['Utilities'], [0, 0, 0, 0, 0, 0]);
  });

  test('sign-up, and logging in with a new email, both start empty', () async {
    await AccountSession.instance.signUp('new@user.com');
    expect(PeopleStore.instance.items.value, isEmpty);
    expect(UtilitiesStore.instance.items.value, isEmpty);
    expect(SubscriptionsStore.instance.subscriptions.value, isEmpty);
    expect(NotificationsStore.instance.notices.value, isEmpty);

    await logIn('never@signed.up');
    expect(PeopleStore.instance.items.value, isEmpty);
    expect(UtilitiesStore.instance.items.value, isEmpty);
    expect(NotificationsStore.instance.notices.value, isEmpty);
    expect(ProfileStore.instance.values['Email'], 'never@signed.up');
  });

  test('each account keeps its own data and never sees another\'s', () async {
    String? name() => ProfileStore.instance.values['Full name'];
    List<String> utilities() =>
        UtilitiesStore.instance.items.value.map((i) => i.name).toList();

    await AccountSession.instance.signUp('a@x.com');
    await ProfileStore.instance.save('Full name', 'Alice');
    UtilitiesStore.instance.add(card('Alice water', UtilityCategories.water));
    PeopleStore.instance.add(
      card('Alice driver', PeopleCategories.driving, 2000),
    );

    await AccountSession.instance.signUp('b@x.com');
    expect(utilities(), isEmpty);
    expect(PeopleStore.instance.items.value, isEmpty);
    expect(name(), isNot('Alice'));
    await ProfileStore.instance.save('Full name', 'Bob');
    UtilitiesStore.instance.add(card('Bob water', UtilityCategories.water));

    // Logging back in restores exactly that account's info.
    await logIn('a@x.com');
    expect(utilities(), ['Alice water']);
    expect(PeopleStore.instance.items.value.single.name, 'Alice driver');
    expect(name(), 'Alice');
    await logIn('B@X.com');
    expect(utilities(), ['Bob water']);
    expect(PeopleStore.instance.items.value, isEmpty);
    expect(name(), 'Bob');

    // Emails that never signed up get their own empty accounts too.
    await logIn('c@x.com');
    expect(utilities(), isEmpty);
    UtilitiesStore.instance.add(card('C gas', UtilityCategories.gas));
    await logIn('d@x.com');
    expect(utilities(), isEmpty);
    await logIn('c@x.com');
    expect(utilities(), ['C gas']);

    // Signing up again with a taken email can't overwrite the account.
    expect(
      () => AccountSession.instance.signUp('A@x.com'),
      throwsA(isA<AccountExistsException>()),
    );
  });

  test(
    'sample data from older builds is removed, real cards are kept',
    () async {
      String enc(String e) => base64Url.encode(utf8.encode(e));
      await DeviceIdStore.instance.setDeviceId('old-id');
      PeopleStore.instance.add(card('Driver', PeopleCategories.driving, 2200));
      PeopleStore.instance.add(card('Gardener', PeopleCategories.other, 1500));
      UtilitiesStore.instance.add(
        card('Saudi Electricity Company', UtilityCategories.electricity, 1189),
      );
      await PeopleStore.instance.flush();
      await UtilitiesStore.instance.flush();
      final prefs = SharedPreferencesAsync();
      await prefs.setString(
        'riyal.account_ns.v1.${enc('old@x.com')}',
        'old-id',
      );
      await prefs.setBool('riyal.account_demo.v1.${enc('old@x.com')}', true);

      await logIn('old@x.com');
      expect(PeopleStore.instance.items.value.map((i) => i.name), ['Gardener']);
      expect(UtilitiesStore.instance.items.value, isEmpty);
    },
  );

  testWidgets('home renders for an account with nothing spent yet', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
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

  testWidgets('a card added later shows up on Home and in Analytics', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: const Scaffold(body: HomeBody()),
      ),
    );
    await tester.pump();
    expect(find.text('⃁0'), findsNWidgets(4)); // total + 3 categories

    UtilitiesStore.instance.add(
      card('Saudi Electricity Company', UtilityCategories.electricity, 640),
    );
    await tester.pump();
    expect(find.text('⃁640'), findsNWidgets(2)); // total + Utilities
    expect(overview[1].amount, 640);

    await tester.tap(find.text(Strings.t('analytics_tab')));
    await tester.pump();
    expect(find.text(Strings.t('analytics_empty')), findsNothing);
    expect(analyticsItems.map((i) => i.name), ['Saudi Electricity Company']);
    expect(analyticsHistory['Utilities']!.last, 640);
    expect(analyticsHistory['Utilities']!.first, 0);
  });
}
