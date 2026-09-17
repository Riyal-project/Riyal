import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riyal/data/people_categories.dart';
import 'package:riyal/data/people_domain.dart';
import 'package:riyal/data/subscription.dart';
import 'package:riyal/data/subscriptions_store.dart';
import 'package:riyal/data/tracked_item.dart';
import 'package:riyal/data/utilities_domain.dart';
import 'package:riyal/data/utility_categories.dart';
import 'package:riyal/l10n/app_locale.dart';
import 'package:riyal/screens/subscription_view_screen.dart';
import 'package:riyal/screens/tracked_item_view_screen.dart';

/// Smoke coverage for the new item details pages — pumps each with a real
/// seeded item and lets the async bank-history lookup resolve, so a null
/// dereference or a missing switch case in the build method (not caught by
/// `dart analyze`) fails a test instead of only surfacing on-device.
void main() {
  Future<void> pump(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    AppLocale.locale.value = const Locale('en');
    await tester.pumpWidget(MaterialApp(home: screen));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('SubscriptionViewScreen renders with no history', (
    tester,
  ) async {
    final subscription = Subscription(
      id: 'smoke-sub-1',
      name: 'Smoke Test Sub',
      logoAsset: null,
      amount: 45,
      cycle: BillingCycle.monthly,
      nextBillingDate: DateTime.now().add(const Duration(days: 5)),
    );
    SubscriptionsStore.instance.subscriptions.value = [
      ...SubscriptionsStore.instance.subscriptions.value,
      subscription,
    ];
    await pump(
      tester,
      const SubscriptionViewScreen(subscriptionId: 'smoke-sub-1'),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Smoke Test Sub'), findsWidgets);
    await tester.scrollUntilVisible(find.text('Edit'), 300);
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(
      SubscriptionsStore.instance.subscriptions.value.firstWhere(
        (item) => item.id == subscription.id,
      ),
      same(subscription),
    );
  });

  testWidgets('TrackedItemViewScreen renders for a utility with no history', (
    tester,
  ) async {
    final item = TrackedItem(
      id: 'smoke-utility-1',
      name: 'Smoke Test Utility',
      amount: 100,
      cycle: BillingCycle.monthly,
      nextBillingDate: DateTime.now().add(const Duration(days: 5)),
      category: UtilityCategories.water,
    );
    utilitiesDomain.store.items.value = [
      ...utilitiesDomain.store.items.value,
      item,
    ];
    await pump(
      tester,
      TrackedItemViewScreen(
        domain: utilitiesDomain,
        itemId: 'smoke-utility-1',
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Smoke Test Utility'), findsWidgets);
  });

  testWidgets('TrackedItemViewScreen renders for a person with no history', (
    tester,
  ) async {
    final item = TrackedItem(
      id: 'smoke-person-1',
      name: 'Smoke Test Person',
      amount: 200,
      cycle: BillingCycle.monthly,
      nextBillingDate: DateTime.now().add(const Duration(days: 5)),
      category: PeopleCategories.household,
      notes: 'A test note',
    );
    peopleDomain.store.items.value = [...peopleDomain.store.items.value, item];
    await pump(
      tester,
      TrackedItemViewScreen(domain: peopleDomain, itemId: 'smoke-person-1'),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Smoke Test Person'), findsWidgets);
    expect(find.text('A test note'), findsOneWidget);
  });
}
