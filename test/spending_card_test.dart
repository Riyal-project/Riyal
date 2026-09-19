import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riyal/data/people_categories.dart';
import 'package:riyal/data/people_store.dart';
import 'package:riyal/data/subscription.dart';
import 'package:riyal/data/subscription_category.dart';
import 'package:riyal/data/subscriptions_store.dart';
import 'package:riyal/data/tracked_item.dart';
import 'package:riyal/data/utilities_store.dart';
import 'package:riyal/data/utility_categories.dart';
import 'package:riyal/l10n/app_locale.dart';
import 'package:riyal/screens/home_screen.dart';
import 'package:riyal/theme/app_theme.dart';

void main() {
  testWidgets('spend card switches between overall and each category', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    AppLocale.locale.value = const Locale('en');
    final due = DateTime.now().add(const Duration(days: 5));
    SubscriptionsStore.instance.subscriptions.value = [
      Subscription(
        id: 's',
        name: 'Netflix',
        logoAsset: null,
        amount: 45,
        cycle: BillingCycle.monthly,
        nextBillingDate: due,
        category: SubscriptionCategories.entertainment,
      ),
    ];
    UtilitiesStore.reset();
    PeopleStore.reset();
    UtilitiesStore.instance.add(
      TrackedItem(
        id: 'u',
        name: 'Water',
        amount: 640,
        cycle: BillingCycle.monthly,
        nextBillingDate: due,
        category: UtilityCategories.water,
      ),
    );
    PeopleStore.instance.add(
      TrackedItem(
        id: 'p',
        name: 'Driver',
        amount: 2000,
        cycle: BillingCycle.monthly,
        nextBillingDate: due,
        category: PeopleCategories.driving,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: const Scaffold(body: HomeBody()),
      ),
    );
    await tester.pump();

    Finder capsule(String label) => find.widgetWithText(GestureDetector, label);
    for (final label in ['Overall', 'Subscriptions', 'Utilities', 'People']) {
      expect(capsule(label), findsOneWidget);
    }
    expect(find.text('⃁2685'), findsOneWidget); // overall total

    await tester.tap(capsule('Utilities'));
    await tester.pump();
    expect(find.text('⃁2685'), findsNothing);
    expect(find.text('⃁640'), findsNWidgets(2)); // card + the overview stat

    await tester.tap(capsule('People'));
    await tester.pump();
    expect(find.text('⃁2000'), findsNWidgets(2));

    await tester.tap(capsule('Overall'));
    await tester.pump();
    expect(find.text('⃁2685'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
