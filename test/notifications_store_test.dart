import 'package:riyal/data/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riyal/data/item_status.dart';
import 'package:riyal/data/notifications_store.dart';
import 'package:riyal/data/subscription.dart';
import 'package:riyal/data/subscriptions_store.dart';
import 'package:riyal/data/people_store.dart';
import 'package:riyal/data/utilities_store.dart';
import 'package:riyal/data/tracked_item.dart';
import 'package:riyal/data/people_categories.dart';
import 'package:riyal/data/utility_categories.dart';
import 'package:riyal/data/mock_bank_transaction.dart';

void main() {
  test(
    'Inbox reflects additions across domains and the five-day boundary without duplicates',
    () {
      final inbox = NotificationsStore.instance;
      final now = DateTime.now();
      final due5 = DateTime(now.year, now.month, now.day + 5, 23, 59);
      final due6 = DateTime(now.year, now.month, now.day + 6);
      final initial = inbox.notices.value.length;
      SubscriptionsStore.instance.add(
        Subscription(
          id: 'test-sub-boundary-five',
          name: 'Boundary five',
          logoAsset: null,
          amount: 39,
          cycle: BillingCycle.monthly,
          nextBillingDate: due5,
        ),
      );
      expect(inbox.notices.value.length, initial + 2);
      SubscriptionsStore.instance.add(
        Subscription(
          id: 'test-sub-boundary-six',
          name: 'Boundary six',
          logoAsset: null,
          amount: 50,
          cycle: BillingCycle.monthly,
          nextBillingDate: due6,
        ),
      );
      expect(inbox.notices.value.length, initial + 3);
      UtilitiesStore.instance.add(
        TrackedItem(
          id: 'test-utility-1',
          name: 'Test utility',
          amount: 100,
          cycle: BillingCycle.monthly,
          nextBillingDate: due6,
          category: UtilityCategories.water,
        ),
      );
      PeopleStore.instance.add(
        TrackedItem(
          id: 'test-person-1',
          name: 'Test person',
          amount: 200,
          cycle: BillingCycle.monthly,
          nextBillingDate: due6,
          category: PeopleCategories.household,
        ),
      );
      expect(inbox.notices.value.length, initial + 5);
      inbox.refresh();
      inbox.refresh();
      expect(inbox.notices.value.length, initial + 5);
      expect(
        inbox.notices.value.where(
          (n) => n.reminder && n.message.contains('Boundary six'),
        ),
        isEmpty,
      );
      final notices = inbox.notices.value;
      for (var i = 1; i < notices.length; i++) {
        expect(
          notices[i - 1].createdAt.isBefore(notices[i].createdAt),
          isFalse,
        );
      }
    },
  );
  test(
    'Reminder preferences affect new reminders but not new-item notices',
    () {
      final settings = AppSettings.instance;
      final inbox = NotificationsStore.instance;
      final now = DateTime.now();
      final due = DateTime(now.year, now.month, now.day + 3);
      final before = inbox.notices.value.length;
      settings.paymentReminders = false;
      SubscriptionsStore.instance.add(
        Subscription(
          id: 'test-sub-settings',
          name: 'Settings test',
          logoAsset: null,
          amount: 30,
          cycle: BillingCycle.monthly,
          nextBillingDate: due,
        ),
      );
      expect(inbox.notices.value.length, before + 1);
      settings.paymentReminders = true;
      settings.reminderDays = 1;
      inbox.refresh();
      expect(
        inbox.notices.value.where(
          (n) => n.reminder && n.message.contains('Settings test'),
        ),
        isEmpty,
      );
      settings.reminderDays = 3;
      inbox.refresh();
      expect(
        inbox.notices.value.where(
          (n) => n.reminder && n.message.contains('Settings test'),
        ),
        hasLength(1),
      );
      inbox.refresh();
      expect(
        inbox.notices.value.where(
          (n) => n.reminder && n.message.contains('Settings test'),
        ),
        hasLength(1),
      );
      settings.reminderDays = 5;
    },
  );
  test('An item with notifications off generates no notices at all', () {
    final inbox = NotificationsStore.instance;
    final now = DateTime.now();
    final before = inbox.notices.value.length;
    SubscriptionsStore.instance.add(
      Subscription(
        id: 'test-sub-muted',
        name: 'Muted sub',
        logoAsset: null,
        amount: 20,
        cycle: BillingCycle.monthly,
        nextBillingDate: now.add(const Duration(days: 1)),
        notificationsEnabled: false,
      ),
    );
    expect(inbox.notices.value.length, before);
    expect(
      inbox.notices.value.where((n) => n.message.contains('Muted sub')),
      isEmpty,
    );
  });

  test('A cancelled/paused item stops getting renewal reminders', () {
    final inbox = NotificationsStore.instance;
    final now = DateTime.now();
    SubscriptionsStore.instance.add(
      Subscription(
        id: 'test-sub-cancelled',
        name: 'Cancelled sub',
        logoAsset: null,
        amount: 20,
        cycle: BillingCycle.monthly,
        nextBillingDate: now.add(const Duration(days: 1)),
        status: ItemStatus.cancelled,
      ),
    );
    // The one-time "added" notice still fires, but no renewal reminder does
    // for an item that's no longer active.
    expect(
      inbox.notices.value.where(
        (n) => n.reminder && n.message.contains('Cancelled sub'),
      ),
      isEmpty,
    );
  });

  test(
    'Editing a subscription price emits a price increase, not a new subscription',
    () {
      final inbox = NotificationsStore.instance;
      final subscription = Subscription(
        id: 'manual-price-change',
        name: 'Manual price app',
        logoAsset: null,
        amount: 40,
        cycle: BillingCycle.monthly,
        nextBillingDate: DateTime.now().add(const Duration(days: 20)),
      );
      SubscriptionsStore.instance.add(subscription);
      final addedBefore = inbox.notices.value
          .where(
            (notice) =>
                notice.kind == PaymentNoticeKind.itemAdded &&
                notice.message.contains(subscription.name),
          )
          .length;

      SubscriptionsStore.instance.update(subscription.copyWith(amount: 55));

      expect(
        inbox.notices.value.where(
          (notice) =>
              notice.kind == PaymentNoticeKind.itemAdded &&
              notice.message.contains(subscription.name),
        ),
        hasLength(addedBefore),
      );
      final increases = inbox.notices.value.where(
        (notice) =>
            notice.kind == PaymentNoticeKind.subscriptionPriceIncrease &&
            notice.itemId == subscription.id,
      );
      expect(increases, hasLength(1));
      expect(increases.single.title, 'Subscription price increased');
      expect(increases.single.message, contains('40.00'));
      expect(increases.single.message, contains('55.00'));

      SubscriptionsStore.instance.update(subscription.copyWith(amount: 45));
      expect(
        inbox.notices.value.where(
          (notice) =>
              notice.kind == PaymentNoticeKind.subscriptionPriceIncrease &&
              notice.itemId == subscription.id,
        ),
        hasLength(1),
      );
    },
  );

  test(
    'A higher latest bank withdrawal is detected as a subscription increase',
    () {
      MockBankTransactionRow row(String id, double amount, int day) =>
          MockBankTransactionRow(
            id: id,
            bankId: 'bank',
            merchantName: 'Example',
            amount: amount,
            transactionDate: DateTime(2026, 9, day),
            category: 'subscription',
          );

      final increase = subscriptionPriceIncreaseFromHistory([
        row('latest', 65, 10),
        row('previous', 50, 1),
      ]);
      expect(increase?.previousAmount, 50);
      expect(increase?.newAmount, 65);
      expect(increase?.transactionId, 'latest');
      expect(
        subscriptionPriceIncreaseFromHistory([
          row('latest-lower', 45, 10),
          row('previous-higher', 50, 1),
        ]),
        isNull,
      );
    },
  );
}
