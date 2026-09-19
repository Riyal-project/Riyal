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
import 'package:riyal/data/people_categories.dart';
import 'package:riyal/data/people_store.dart';
import 'package:riyal/data/profile_store.dart';
import 'package:riyal/data/subscription.dart';
import 'package:riyal/data/subscriptions_store.dart';
import 'package:riyal/data/tracked_item.dart';
import 'package:riyal/data/utilities_store.dart';
import 'package:riyal/data/utility_categories.dart';
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
    SubscriptionsStore.instance.subscriptions.value = [];
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

  test('each account keeps its own data and never sees another\'s', () async {
    TrackedItem card(String name) => TrackedItem(
      id: name,
      name: name,
      amount: 99,
      cycle: BillingCycle.monthly,
      nextBillingDate: DateTime.now().add(const Duration(days: 4)),
      category: UtilityCategories.water,
    );
    Future<void> logIn(String email) async {
      try {
        await AccountSession.instance.signIn(email);
      } catch (_) {} // the Supabase reload isn't available in tests
    }

    String? name() => ProfileStore.instance.values['Full name'];
    List<String> utilities() =>
        UtilitiesStore.instance.items.value.map((i) => i.name).toList();

    await AccountSession.instance.signUp('a@x.com');
    await ProfileStore.instance.save('Full name', 'Alice');
    UtilitiesStore.instance.add(card('Alice water'));
    PeopleStore.instance.add(
      TrackedItem(
        id: 'p',
        name: 'Alice driver',
        amount: 2000,
        cycle: BillingCycle.monthly,
        nextBillingDate: DateTime.now().add(const Duration(days: 4)),
        category: PeopleCategories.driving,
      ),
    );

    await AccountSession.instance.signUp('b@x.com');
    expect(utilities(), isEmpty);
    expect(PeopleStore.instance.items.value, isEmpty);
    expect(name(), isNot('Alice'));
    await ProfileStore.instance.save('Full name', 'Bob');
    UtilitiesStore.instance.add(card('Bob water'));

    // Logging back in restores exactly that account's info.
    await logIn('a@x.com');
    expect(utilities(), ['Alice water']);
    expect(PeopleStore.instance.items.value.single.name, 'Alice driver');
    expect(name(), 'Alice');
    await logIn('B@X.com');
    expect(utilities(), ['Bob water']);
    expect(PeopleStore.instance.items.value, isEmpty);
    expect(name(), 'Bob');

    // Two logins with emails that never signed up each get their own demo
    // copy: one's edits don't reach the other, or the real accounts.
    await logIn('c@x.com');
    expect(utilities(), hasLength(4));
    UtilitiesStore.instance.remove(
      UtilitiesStore.instance.items.value.first.id,
    );
    expect(utilities(), hasLength(3));
    await logIn('d@x.com');
    expect(utilities(), hasLength(4));
    await logIn('c@x.com');
    expect(utilities(), hasLength(3));
    // Saved cards come back whole, icon included.
    final driver = PeopleStore.instance.items.value.first;
    expect(driver.icon, Icons.directions_car_outlined);
    expect(driver.amount, 2200);

    // Signing up again with a taken email can't overwrite the account.
    expect(
      () => AccountSession.instance.signUp('A@x.com'),
      throwsA(isA<AccountExistsException>()),
    );
  });

  testWidgets('home renders for a new sign-up with nothing spent yet', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    DemoMode.enabled = false;
    PeopleStore.reset();
    UtilitiesStore.reset();
    SubscriptionsStore.instance.subscriptions.value = [];
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
    DemoMode.enabled = false;
    PeopleStore.reset();
    UtilitiesStore.reset();
    SubscriptionsStore.instance.subscriptions.value = [];
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: const Scaffold(body: HomeBody()),
      ),
    );
    await tester.pump();
    expect(find.text('⃁0'), findsNWidgets(4)); // total + 3 categories

    UtilitiesStore.instance.add(
      TrackedItem(
        id: 'u1',
        name: 'Saudi Electricity Company',
        amount: 640,
        cycle: BillingCycle.monthly,
        nextBillingDate: DateTime.now().add(const Duration(days: 5)),
        category: UtilityCategories.electricity,
      ),
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
