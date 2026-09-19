import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:riyal/data/budget_store.dart';
import 'package:riyal/data/item_status.dart';
import 'package:riyal/data/notifications_store.dart';
import 'package:riyal/data/subscription_category.dart';
import 'package:riyal/data/people_categories.dart';
import 'package:riyal/data/people_store.dart';
import 'package:riyal/data/subscription.dart';
import 'package:riyal/data/tracked_item.dart';
import 'package:riyal/data/subscriptions_store.dart';
import 'package:riyal/data/utilities_store.dart';
import 'package:riyal/data/utility_categories.dart';
import 'package:riyal/l10n/app_locale.dart';
import 'package:riyal/l10n/strings.dart';
import 'package:riyal/screens/budget_setup_screen.dart';
import 'package:riyal/screens/signup_screen.dart';
import 'package:riyal/screens/subscriptions_screen.dart';
import 'package:riyal/screens/utilities_screen.dart';
import 'package:riyal/screens/people_screen.dart';
import 'package:riyal/screens/home_screen.dart';
import 'package:riyal/theme/app_theme.dart';
import 'package:riyal/widgets/budget_progress_card.dart';

Subscription subscription(
  double amount, {
  String id = 'budget-sub',
  BillingCycle cycle = BillingCycle.monthly,
  ItemStatus status = ItemStatus.active,
  bool trial = false,
}) => Subscription(
  id: id,
  name: 'Budget subscription',
  logoAsset: null,
  amount: amount,
  cycle: cycle,
  nextBillingDate: DateTime(2030, 1, 1),
  status: status,
  trialStartDate: trial ? DateTime.now() : null,
  trialDuration: trial ? FreeTrialDuration.month : null,
);

Map<BudgetDomain, double> limits(double amount) => {
  BudgetDomain.subscriptions: amount,
  BudgetDomain.utilities: 1000,
  BudgetDomain.people: 2000,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.empty();
  final store = BudgetStore.instance;

  setUp(() async {
    SubscriptionsStore.instance.subscriptions.value = [];
    UtilitiesStore.instance.items.value = [];
    PeopleStore.instance.items.value = [];
    AppLocale.locale.value = const Locale('en');
    await store.activate(
      'unconfigured-${DateTime.now().microsecondsSinceEpoch}@test.com',
    );
  });

  test('Budget boundaries include exact 80%, 100%, zero, and overspending', () {
    expect(
      const BudgetSnapshot(limit: 100, committed: 79.99).level,
      BudgetLevel.normal,
    );
    expect(
      const BudgetSnapshot(limit: 100, committed: 80).level,
      BudgetLevel.near,
    );
    expect(
      const BudgetSnapshot(limit: 100, committed: 100).level,
      BudgetLevel.exceeded,
    );
    expect(const BudgetSnapshot(limit: 100, committed: 150).fraction, 1.5);
    expect(
      const BudgetSnapshot(limit: 0, committed: 0).level,
      BudgetLevel.normal,
    );
    expect(
      const BudgetSnapshot(limit: 0, committed: 1).level,
      BudgetLevel.exceeded,
    );
  });

  test('Limits survive reload and remain separate between accounts', () async {
    await store.activate('first@test.com');
    await store.save(limits(100));
    await store.activate('second@test.com');
    expect(store.configured, isFalse);
    await store.save(limits(200));
    await store.activate(' FIRST@test.com ');
    expect(store.limitFor(BudgetDomain.subscriptions), 100);
    await store.load();
    expect(store.configured, isTrue);
    expect(store.limitFor(BudgetDomain.subscriptions), 100);
  });

  test(
    'Monthly commitments normalize annual plans and exclude stopped and free subscriptions',
    () async {
      SubscriptionsStore.instance.subscriptions.value = [
        subscription(120, cycle: BillingCycle.yearly),
        subscription(50, id: 'cancelled', status: ItemStatus.cancelled),
        subscription(70, id: 'paused', status: ItemStatus.paused),
        subscription(80, id: 'trial', trial: true, status: ItemStatus.trial),
      ];
      await store.save(limits(100));
      expect(store.snapshot(BudgetDomain.subscriptions).committed, 10);
    },
  );

  test(
    'Budget alerts enter the inbox once per stage and month, and survive restart',
    () async {
      final inbox = NotificationsStore.instance;
      await store.activate('alerts@test.com');
      await store.save(limits(100));
      SubscriptionsStore.instance.subscriptions.value = [subscription(80)];
      expect(store.alerts, hasLength(1));
      expect(store.alerts.single.level, BudgetLevel.near);
      SubscriptionsStore.instance.subscriptions.value = [subscription(100)];
      store.recalculate();
      inbox.refresh();
      expect(store.alerts, hasLength(2));
      expect(
        inbox.notices.value.where(
          (notice) => notice.kind == PaymentNoticeKind.budgetWarning,
        ),
        hasLength(2),
      );
      await store.activate('alerts@test.com');
      expect(store.alerts, hasLength(2));
      final now = DateTime.now();
      store.recalculate(at: DateTime(now.year, now.month + 1));
      expect(store.alerts, hasLength(3));
      await store.activate('different@test.com');
      expect(
        inbox.notices.value.where(
          (notice) => notice.kind == PaymentNoticeKind.budgetWarning,
        ),
        isEmpty,
      );
    },
  );

  testWidgets('Progress changes to orange and red with warning triangle', (
    tester,
  ) async {
    await tester.runAsync(() => store.save(limits(100)));
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: const Scaffold(
          body: BudgetProgressCard(domain: BudgetDomain.subscriptions),
        ),
      ),
    );
    await tester.runAsync(() async {
      SubscriptionsStore.instance.subscriptions.value = [subscription(80)];
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pump();
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .color,
      Colors.orange,
    );
    expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
    await tester.runAsync(() async {
      SubscriptionsStore.instance.subscriptions.value = [subscription(110)];
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pump();
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .color,
      Colors.redAccent,
    );
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      1,
    );
  });

  testWidgets('Setup validates input and saves all three budgets', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: const BudgetSetupScreen(
          afterSetup: Scaffold(body: Text('Saved destination')),
        ),
      ),
    );
    await tester.scrollUntilVisible(
      find.text('Save budgets'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Save budgets'));
    await tester.pump();
    expect(
      find.text('Enter a valid amount of zero or more.'),
      findsNWidgets(3),
    );
    for (final domain in BudgetDomain.values) {
      await tester.ensureVisible(find.byKey(ValueKey('budget-${domain.name}')));
      await tester.enterText(
        find.byKey(ValueKey('budget-${domain.name}')),
        '100',
      );
    }
    await tester.scrollUntilVisible(
      find.text('Save budgets'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.runAsync(() async {
      await tester.tap(find.text('Save budgets'));
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pumpAndSettle();
    expect(find.text('Saved destination'), findsOneWidget);
    expect(store.configured, isTrue);
    expect(store.snapshot().limit, 300);
  });

  testWidgets('Signup opens budget questions before connecting a bank', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: buildAppTheme(), home: const SignupScreen()),
    );
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'New User');
    await tester.enterText(fields.at(1), 'new-signup@test.com');
    await tester.enterText(fields.at(2), 'password123');
    await tester.enterText(fields.at(3), 'password123');
    await tester.ensureVisible(find.text(Strings.t('create_account_button')));
    await tester.runAsync(() async {
      await tester.tap(find.text(Strings.t('create_account_button')));
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pumpAndSettle();
    expect(find.byType(BudgetSetupScreen), findsOneWidget);
    expect(store.account, 'new-signup@test.com');
  });

  testWidgets(
    'Budget only appears in analytics and total spend only appears in overview',
    (tester) async {
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      AppLocale.locale.value = const Locale('ar');
      // Analytics only draws its charts once its category has a card.
      final due = DateTime.now().add(const Duration(days: 5));
      SubscriptionsStore.instance.subscriptions.value = [
        Subscription(
          id: 's1',
          name: 'Netflix',
          logoAsset: null,
          amount: 45,
          cycle: BillingCycle.monthly,
          nextBillingDate: due,
          category: SubscriptionCategories.entertainment,
        ),
      ];
      UtilitiesStore.instance.add(
        TrackedItem(
          id: 'u1',
          name: 'Water',
          amount: 100,
          cycle: BillingCycle.monthly,
          nextBillingDate: due,
          category: UtilityCategories.water,
        ),
      );
      PeopleStore.instance.add(
        TrackedItem(
          id: 'p1',
          name: 'Driver',
          amount: 2000,
          cycle: BillingCycle.monthly,
          nextBillingDate: due,
          category: PeopleCategories.driving,
        ),
      );
      await tester.runAsync(() => store.save(limits(100)));
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(languageCode: 'ar'),
          home: const Scaffold(body: HomeBody()),
        ),
      );
      await tester.pump();
      expect(find.text(Strings.t('total_spend_this_month')), findsOneWidget);
      expect(find.byType(BudgetProgressCard), findsNothing);
      await tester.tap(find.text(Strings.t('analytics_tab')));
      await tester.pump();
      expect(find.text(Strings.t('total_spend_this_month')), findsNothing);
      expect(find.byType(BudgetProgressCard), findsOneWidget);
      expect(
        tester.getTopLeft(find.text(Strings.t('budget_monthly'))).dy,
        lessThan(tester.getTopLeft(find.text(Strings.t('spend_over_time'))).dy),
      );

      for (final page in [
        const SubscriptionsBody(),
        const UtilitiesBody(),
        const PeopleBody(),
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(languageCode: 'ar'),
            home: Scaffold(
              body: Directionality(
                textDirection: TextDirection.rtl,
                child: page,
              ),
            ),
          ),
        );
        await tester.pump();
        expect(find.byType(BudgetProgressCard), findsNothing);
        await tester.tap(find.text(Strings.t('analytics_tab')));
        await tester.pump();
        expect(find.byType(BudgetProgressCard), findsOneWidget);
        expect(
          tester.getTopLeft(find.text(Strings.t('budget_monthly'))).dy,
          lessThan(
            tester.getTopLeft(find.text(Strings.t('spend_over_time'))).dy,
          ),
        );
        expect(tester.takeException(), isNull);
      }
    },
  );
}
