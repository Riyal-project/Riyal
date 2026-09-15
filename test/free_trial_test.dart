import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riyal/data/app_settings.dart';
import 'package:riyal/data/item_status.dart';
import 'package:riyal/data/notifications_store.dart';
import 'package:riyal/data/subscription.dart';
import 'package:riyal/data/subscriptions_store.dart';
import 'package:riyal/l10n/app_locale.dart';
import 'package:riyal/screens/subscription_details_screen.dart';
import 'package:riyal/widgets/free_trial_fields.dart';

Subscription trial(
  String id, {
  ItemStatus status = ItemStatus.trial,
  bool notificationsEnabled = true,
}) => Subscription(
  id: id,
  name: id,
  logoAsset: null,
  amount: 50,
  cycle: BillingCycle.monthly,
  nextBillingDate: DateTime(2030, 1, 8),
  trialStartDate: DateTime(2030, 1, 1),
  trialDuration: FreeTrialDuration.week,
  status: status,
  notificationsEnabled: notificationsEnabled,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Trial durations use calendar days and clamp month end', () {
    expect(
      freeTrialEndDate(DateTime(2030, 1, 1, 22), FreeTrialDuration.week),
      DateTime(2030, 1, 8),
    );
    expect(
      freeTrialEndDate(DateTime(2030, 1, 31), FreeTrialDuration.month),
      DateTime(2030, 2, 28),
    );
    expect(
      freeTrialEndDate(DateTime(2028, 1, 31), FreeTrialDuration.month),
      DateTime(2028, 2, 29),
    );
    expect(
      freeTrialEndDate(DateTime(2030, 12, 15), FreeTrialDuration.month),
      DateTime(2031, 1, 15),
    );
    final subscription = trial('copy');
    expect(
      subscription.copyWith(amount: 70).trialEndDate,
      DateTime(2030, 1, 8),
    );
    expect(subscription.copyWith(clearFreeTrial: true).hasFreeTrial, isFalse);
    expect(subscription.monthlyAmount, 0);
  });

  test(
    'Trial notice appears exactly five days before end and survives edits without duplicates',
    () {
      final settings = AppSettings.instance;
      final previousDays = settings.reminderDays;
      final previousEnabled = settings.paymentReminders;
      final store = SubscriptionsStore.instance;
      final previousSubscriptions = store.subscriptions.value;
      final inbox = NotificationsStore.instance;
      final previousNotices = inbox.notices.value;
      addTearDown(() {
        settings.reminderDays = previousDays;
        settings.paymentReminders = previousEnabled;
        store.subscriptions.value = previousSubscriptions;
        inbox.notices.value = previousNotices;
      });
      settings.reminderDays = 1;
      settings.paymentReminders = true;
      final subscription = trial('trial-boundary');
      store.subscriptions.value = [subscription];
      Iterable<PaymentNotice> reminders() => inbox.notices.value.where(
        (notice) =>
            notice.kind == PaymentNoticeKind.freeTrialEnding &&
            notice.itemId == subscription.id,
      );
      inbox.refresh(at: DateTime(2030, 1, 2, 23, 59));
      expect(reminders(), isEmpty);
      inbox.refresh(at: DateTime(2030, 1, 3));
      expect(reminders(), hasLength(1));
      expect(reminders().single.createdAt, DateTime(2030, 1, 3));
      expect(
        inbox.notices.value.where(
          (notice) =>
              notice.kind == PaymentNoticeKind.paymentReminder &&
              notice.message.contains(subscription.name),
        ),
        isEmpty,
      );
      store.subscriptions.value = [subscription.copyWith(amount: 70)];
      inbox.refresh(at: DateTime(2030, 1, 4));
      inbox.refresh(at: DateTime(2030, 1, 4));
      expect(reminders(), hasLength(1));
    },
  );

  test('Trial reminders respect switches and cancelled or paused states', () {
    final settings = AppSettings.instance;
    final previousEnabled = settings.paymentReminders;
    final store = SubscriptionsStore.instance;
    final previousSubscriptions = store.subscriptions.value;
    final inbox = NotificationsStore.instance;
    final previousNotices = inbox.notices.value;
    addTearDown(() {
      settings.paymentReminders = previousEnabled;
      store.subscriptions.value = previousSubscriptions;
      inbox.notices.value = previousNotices;
    });
    settings.paymentReminders = true;
    store.subscriptions.value = [
      trial('trial-off', notificationsEnabled: false),
      trial('trial-cancelled', status: ItemStatus.cancelled),
      trial('trial-paused', status: ItemStatus.paused),
    ];
    inbox.refresh(at: DateTime(2030, 1, 3));
    expect(
      inbox.notices.value.where(
        (n) =>
            n.kind == PaymentNoticeKind.freeTrialEnding &&
            ['trial-off', 'trial-cancelled', 'trial-paused'].contains(n.itemId),
      ),
      isEmpty,
    );
    settings.paymentReminders = false;
    store.subscriptions.value = [trial('trial-global-off')];
    inbox.refresh(at: DateTime(2030, 1, 3));
    expect(
      inbox.notices.value.where((n) => n.itemId == 'trial-global-off'),
      isEmpty,
    );
  });

  testWidgets('Adding a monthly trial stores the dates and renewal amount', (
    tester,
  ) async {
    final previousLocale = AppLocale.locale.value;
    final store = SubscriptionsStore.instance;
    final previousSubscriptions = store.subscriptions.value;
    addTearDown(() {
      AppLocale.locale.value = previousLocale;
      store.subscriptions.value = previousSubscriptions;
    });
    AppLocale.locale.value = const Locale('en');
    await tester.pumpWidget(
      const MaterialApp(
        home: SubscriptionDetailsScreen(
          name: 'Trial app',
          initialFreeTrial: true,
        ),
      ),
    );
    expect(find.byType(FreeTrialFields), findsOneWidget);
    await tester.tap(find.text('One month'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '45');
    await tester.tap(find.text('Add subscription'));
    await tester.pump();
    final saved = store.subscriptions.value.last;
    expect(saved.name, 'Trial app');
    expect(saved.status, ItemStatus.trial);
    expect(saved.trialDuration, FreeTrialDuration.month);
    expect(saved.amount, 45);
    expect(
      saved.nextBillingDate,
      freeTrialEndDate(saved.trialStartDate!, FreeTrialDuration.month),
    );
  });
}
