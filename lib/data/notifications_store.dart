import 'package:flutter/foundation.dart';
import '../l10n/strings.dart';
import 'auto_add_classifier.dart';
import 'bank_transaction_matcher.dart';
import 'id_generator.dart';
import 'item_payment_history.dart';
import 'item_status.dart';
import 'mock_bank_transaction.dart';
import 'recurring_detection.dart';
import 'subscription.dart';
import 'subscriptions_store.dart';
import 'tracked_item.dart';
import 'utilities_store.dart';
import 'people_store.dart';
import 'app_settings.dart';
import 'monthly_review.dart';
import 'notice_read_state.dart';
import 'user_bank_accounts_store.dart';
import 'utility_anomaly_detection.dart';
import 'dart:async';
import 'dart:convert';
import 'budget_store.dart';

enum PaymentNoticeKind {
  itemAdded,
  paymentReminder,
  monthlyReview,
  utilityAnomaly,
  autoAdded,
  freeTrialEnding,
  budgetWarning,
}

class PaymentNotice {
  const PaymentNotice({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.reminder,
    this.kind = PaymentNoticeKind.itemAdded,
    this.itemId,
    this.autoAddedDomain,
  });
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool reminder;
  final PaymentNoticeKind kind;

  /// Set on [PaymentNoticeKind.utilityAnomaly] and [PaymentNoticeKind.autoAdded]
  /// notices — the id of the item to open when tapped.
  final String? itemId;

  /// Set only on [PaymentNoticeKind.autoAdded] notices — one of
  /// 'subscription' / 'utility' / 'person', so tapping it opens the right
  /// details page for [itemId].
  final String? autoAddedDomain;
}

/// In-app demo inbox, fed by the same observable stores as the payment screens.
class NotificationsStore {
  NotificationsStore._() {
    refresh(seed: true);
    SubscriptionsStore.instance.subscriptions.addListener(refresh);
    UtilitiesStore.instance.items.addListener(refresh);
    PeopleStore.instance.items.addListener(refresh);
    MonthlyReviewStore.instance.revision.addListener(refresh);
    BudgetStore.instance.revision.addListener(refresh);
  }
  static final instance = NotificationsStore._();
  final notices = ValueNotifier<List<PaymentNotice>>([]);
  final readState = NoticeReadState();
  final Map<Object, String> _itemIds = Map.identity();
  final Set<Object> _seen = Set.identity();
  final Map<Object, Set<DateTime>> _reminded = Map.identity();

  /// The current-bill amount last notified about, per utility id — so an
  /// unchanged anomaly doesn't re-notify on every refresh tick, but a new
  /// bill that crosses the threshold again does.
  final Map<String, double> _lastAnomalyAmount = {};

  void refresh({bool seed = false, DateTime? at}) {
    final now = at ?? DateTime.now();
    final additions = <PaymentNotice>[];
    final budgets = BudgetStore.instance;
    for (final alert in budgets.alerts) {
      if (notices.value.any((notice) => notice.id == alert.id)) continue;
      additions.add(
        PaymentNotice(
          id: alert.id,
          title: Strings.t(
            alert.level == BudgetLevel.exceeded
                ? 'budget_exceeded_notice'
                : 'budget_near_notice',
          ),
          message:
              '${Strings.categoryDisplay(alert.domain.categoryKey)}\n'
              '${Strings.t('budget_committed')}: SAR ${alert.committed.toStringAsFixed(2)} / SAR ${alert.limit.toStringAsFixed(2)}',
          createdAt: alert.createdAt,
          reminder: true,
          kind: PaymentNoticeKind.budgetWarning,
          itemId: alert.domain.categoryKey,
        ),
      );
    }
    void visit(
      Object identity,
      String name,
      String category,
      double amount,
      DateTime due, {
      required bool notificationsEnabled,
      required bool isActive,
      DateTime? trialEnd,
    }) {
      if (!notificationsEnabled) return;
      final date = DateTime(due.year, due.month, due.day);
      final itemId = _itemIds.putIfAbsent(
        identity,
        () => jsonEncode([
          seed
              ? 'demo'
              : 'added-${now.microsecondsSinceEpoch}-${_itemIds.length}',
          category,
          name,
          amount,
        ]),
      );
      final formattedDate = '${date.day}/${date.month}/${date.year}';
      final categoryDisplay = Strings.categoryDisplay(category);
      if (_seen.add(identity)) {
        additions.add(
          PaymentNotice(
            id: 'added:$itemId',
            title: category == 'Subscriptions'
                ? Strings.t('notice_new_subscription')
                : Strings.t('notice_new_commitment'),
            message: trialEnd != null
                ? '${Strings.f('trial_added_message', name)} ${trialEnd.day}/${trialEnd.month}/${trialEnd.year}'
                : '$name · $categoryDisplay\nSAR ${amount.toStringAsFixed(2)} · Next payment $formattedDate',
            createdAt: seed
                ? now.subtract(Duration(days: 7, seconds: _seen.length))
                : now,
            reminder: false,
          ),
        );
      }
      // Calendar subtraction avoids truncating 5 days to 4 due to time of day.
      final leadDays = AppSettings.instance.reminderDays;
      final reminderDate = DateTime(date.year, date.month, date.day - leadDays);
      if (trialEnd == null &&
          isActive &&
          AppSettings.instance.paymentReminders &&
          !reminderDate.isAfter(now) &&
          (_reminded[identity] ??= {}).add(date)) {
        additions.add(
          PaymentNotice(
            id: 'reminder:$itemId:${itemId.contains('"demo"') ? 'seed' : date.toIso8601String()}',
            title: category == 'Subscriptions'
                ? Strings.t('notice_renewal_reminder')
                : Strings.t('notice_payment_reminder'),
            message:
                '$name · $categoryDisplay\nSAR ${amount.toStringAsFixed(2)} due $formattedDate\n${Strings.reminderLeadNote(leadDays)}',
            createdAt: reminderDate,
            reminder: true,
            kind: PaymentNoticeKind.paymentReminder,
          ),
        );
      }
    }

    for (final item in SubscriptionsStore.instance.subscriptions.value) {
      visit(
        item,
        item.name,
        'Subscriptions',
        item.amount,
        item.nextBillingDate,
        notificationsEnabled: item.notificationsEnabled,
        isActive:
            item.status == ItemStatus.active || item.status == ItemStatus.trial,
        trialEnd:
            item.hasFreeTrial &&
                !item.nextBillingDate.isAfter(item.trialEndDate!)
            ? item.trialEndDate
            : null,
      );
      final end = item.trialEndDate;
      final reminderDate = item.trialReminderDate;
      if (end != null &&
          reminderDate != null &&
          item.notificationsEnabled &&
          AppSettings.instance.paymentReminders &&
          (item.status == ItemStatus.active ||
              item.status == ItemStatus.trial) &&
          !reminderDate.isAfter(now) &&
          !DateTime(now.year, now.month, now.day).isAfter(end)) {
        final noticeId = 'free-trial:${item.id}:${end.toIso8601String()}';
        if (!notices.value.any((notice) => notice.id == noticeId)) {
          additions.add(
            PaymentNotice(
              id: noticeId,
              title: Strings.t('trial_ending_title'),
              message:
                  '${Strings.f('trial_ending_message', item.name)} '
                  '${end.day}/${end.month}/${end.year}\n'
                  '${Strings.t('trial_ending_note')}',
              createdAt: reminderDate,
              reminder: true,
              kind: PaymentNoticeKind.freeTrialEnding,
              itemId: item.id,
            ),
          );
        }
      }
    }
    for (final item in UtilitiesStore.instance.items.value) {
      visit(
        item,
        item.name,
        'Utilities',
        item.amount,
        item.nextBillingDate,
        notificationsEnabled: item.notificationsEnabled,
        isActive: item.status == ItemStatus.active,
      );
    }
    for (final item in PeopleStore.instance.items.value) {
      visit(
        item,
        item.name,
        'People',
        item.amount,
        item.nextBillingDate,
        notificationsEnabled: item.notificationsEnabled,
        isActive: item.status == ItemStatus.active,
      );
    }
    final reviewStore = MonthlyReviewStore.instance;
    final reviewId = 'monthly-review:${reviewStore.currentPeriod}';
    final reviewIsDue =
        reviewStore.initialized &&
        AppSettings.instance.monthlyReviewReminders &&
        DateTime.now().day >= AppSettings.instance.monthlyReviewDay &&
        !reviewStore.isCurrentMonthComplete;
    if (reviewIsDue && !notices.value.any((notice) => notice.id == reviewId)) {
      additions.add(
        PaymentNotice(
          id: reviewId,
          title: Strings.t('monthly_review_notice_title'),
          message: Strings.t('monthly_review_notice_message'),
          createdAt: now,
          reminder: true,
          kind: PaymentNoticeKind.monthlyReview,
        ),
      );
    }
    final accountNotices = notices.value
        .where(
          (notice) =>
              notice.kind != PaymentNoticeKind.budgetWarning ||
              budgets.alerts.any((alert) => alert.id == notice.id),
        )
        .toList();
    final retained = !reviewIsDue
        ? accountNotices.where((notice) => notice.id != reviewId).toList()
        : accountNotices;
    if (additions.isNotEmpty) {
      notices.value = [...retained, ...additions]
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      readState.updateIds(notices.value.map((notice) => notice.id));
    } else if (retained.length != notices.value.length) {
      notices.value = retained;
      readState.updateIds(notices.value.map((notice) => notice.id));
    }

    // Fire-and-forget: unlike everything above, this needs a network call
    // (connected banks' transaction history), so it can't run synchronously
    // inline with the rest of refresh() without delaying — or, worse,
    // making callers await — every other notice update.
    unawaited(_refreshUtilityAnomalies());
    unawaited(_refreshAutoDetection());
  }

  bool _autoDetectionRunning = false;

  /// Runs the same auto-detection [refresh] triggers on a timer, but
  /// awaitable — the Accounts screen calls this directly before deciding
  /// what still belongs in its manual "possible" suggestion list, so a
  /// charge that just crossed the auto-add threshold doesn't sit there
  /// waiting for the next periodic tick.
  Future<void> checkForAutoAdditions() => _refreshAutoDetection();

  /// Scans connected-bank transaction history for recurring charges that
  /// have crossed [RecurringDetectionEngine.autoAddOccurrences] and adds
  /// them straight to the right store (Subscriptions/Utilities/People) —
  /// classified by matching the merchant against the subscription/utility
  /// reference catalogs (see lib/data/auto_add_classifier.dart) — instead
  /// of waiting for the user to confirm them from the Accounts screen.
  /// Fires a dedicated notice for each addition the same way
  /// [_refreshUtilityAnomalies] does, and pre-marks the new item as "seen"
  /// so the generic new-item notice below doesn't also fire for it.
  Future<void> _refreshAutoDetection() async {
    if (_autoDetectionRunning) return;
    if (UserBankAccountsStore.instance.accounts.value.isEmpty) return;
    _autoDetectionRunning = true;
    try {
      final List<MockBankTransactionRow> allTransactions;
      try {
        allTransactions = await loadAllConnectedTransactions();
      } catch (error) {
        debugPrint('Auto-detection check failed: $error');
        return;
      }

      final detected = RecurringDetectionEngine.detect(allTransactions)
          .where(
            (d) => d.occurrences >= RecurringDetectionEngine.autoAddOccurrences,
          )
          .toList();
      if (detected.isEmpty) return;

      final alreadyTracked = <String>{
        for (final s in SubscriptionsStore.instance.subscriptions.value)
          s.name.toUpperCase(),
        for (final i in UtilitiesStore.instance.items.value)
          i.name.toUpperCase(),
        for (final i in PeopleStore.instance.items.value) i.name.toUpperCase(),
      };

      final additions = <PaymentNotice>[];
      final now = DateTime.now();
      for (final suggestion in detected) {
        final key = suggestion.merchantName.toUpperCase();
        if (alreadyTracked.contains(key)) continue;
        alreadyTracked.add(key);

        final classification = classifyForAutoAdd(suggestion);
        switch (classification.domain) {
          case AutoAddDomain.subscription:
            final subscription = Subscription(
              id: IdGenerator.uuidV4(),
              name: suggestion.merchantName,
              logoAsset: classification.logoAsset,
              amount: suggestion.amount,
              cycle: suggestion.cycle,
              nextBillingDate: suggestion.suggestedNextBillingDate,
              category: classification.category,
            );
            _seen.add(subscription);
            await SubscriptionsStore.instance.add(subscription);
            additions.add(
              PaymentNotice(
                id: 'auto-added:${subscription.id}',
                title: Strings.t('notice_auto_added_title'),
                message: Strings.autoAddedItemMessage(
                  name: subscription.name,
                  amount: subscription.amount,
                  isMonthly: subscription.cycle == BillingCycle.monthly,
                  categoryDisplay: Strings.categoryDisplay('Subscriptions'),
                ),
                createdAt: now,
                reminder: false,
                kind: PaymentNoticeKind.autoAdded,
                itemId: subscription.id,
                autoAddedDomain: 'subscription',
              ),
            );
          case AutoAddDomain.utility:
            final item = TrackedItem(
              id: IdGenerator.uuidV4(),
              name: suggestion.merchantName,
              logoAsset: classification.logoAsset,
              icon: classification.icon,
              iconColor: classification.iconColor,
              amount: suggestion.amount,
              cycle: suggestion.cycle,
              nextBillingDate: suggestion.suggestedNextBillingDate,
              category: classification.category,
            );
            _seen.add(item);
            UtilitiesStore.instance.add(item);
            additions.add(
              PaymentNotice(
                id: 'auto-added:${item.id}',
                title: Strings.t('notice_auto_added_title'),
                message: Strings.autoAddedItemMessage(
                  name: item.name,
                  amount: item.amount,
                  isMonthly: item.cycle == BillingCycle.monthly,
                  categoryDisplay: Strings.categoryDisplay('Utilities'),
                ),
                createdAt: now,
                reminder: false,
                kind: PaymentNoticeKind.autoAdded,
                itemId: item.id,
                autoAddedDomain: 'utility',
              ),
            );
          case AutoAddDomain.person:
            final item = TrackedItem(
              id: IdGenerator.uuidV4(),
              name: suggestion.merchantName,
              logoAsset: classification.logoAsset,
              icon: classification.icon,
              iconColor: classification.iconColor,
              amount: suggestion.amount,
              cycle: suggestion.cycle,
              nextBillingDate: suggestion.suggestedNextBillingDate,
              category: classification.category,
            );
            _seen.add(item);
            PeopleStore.instance.add(item);
            additions.add(
              PaymentNotice(
                id: 'auto-added:${item.id}',
                title: Strings.t('notice_auto_added_title'),
                message: Strings.autoAddedPersonMessage(item.name),
                createdAt: now,
                reminder: false,
                kind: PaymentNoticeKind.autoAdded,
                itemId: item.id,
                autoAddedDomain: 'person',
              ),
            );
        }
      }

      if (additions.isEmpty) return;
      notices.value = [...notices.value, ...additions]
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      readState.updateIds(notices.value.map((notice) => notice.id));
    } finally {
      _autoDetectionRunning = false;
    }
  }

  /// Flags utility bills whose latest charge is unusual relative to their
  /// own trailing history (see lib/data/utility_anomaly_detection.dart) and
  /// turns any newly-crossed threshold into a notice, same as every other
  /// notice kind above. Only bills matched against a connected bank's
  /// transaction history have enough data to evaluate — utilities added
  /// from scratch with no matching transactions are silently skipped, same
  /// as the "needs 3 prior bills" rule already requires.
  Future<void> _refreshUtilityAnomalies() async {
    if (UserBankAccountsStore.instance.accounts.value.isEmpty) return;
    final List<MockBankTransactionRow> allTransactions;
    try {
      allTransactions = await loadAllConnectedTransactions();
    } catch (error) {
      debugPrint('Utility anomaly check failed: $error');
      return;
    }

    final additions = <PaymentNotice>[];
    for (final item in UtilitiesStore.instance.items.value) {
      if (!item.notificationsEnabled) continue;
      final history = historyForItemName(allTransactions, item.name);
      if (history.isEmpty) continue;
      final anomaly = UtilityAnomalyDetector.detect(
        category: item.category,
        priorAmounts: history.skip(1).take(3).map((t) => t.amount).toList(),
        currentAmount: history.first.amount,
      );
      if (anomaly == null) continue;
      if (_lastAnomalyAmount[item.id] == anomaly.currentAmount) continue;
      _lastAnomalyAmount[item.id] = anomaly.currentAmount;

      additions.add(
        PaymentNotice(
          id: 'utility-anomaly:${item.id}:${anomaly.currentAmount}',
          title: Strings.t('notice_utility_anomaly_title'),
          message: Strings.utilityAnomalyMessage(
            name: item.name,
            currentAmount: anomaly.currentAmount,
            averageAmount: anomaly.trailingAverage,
            percentAbove: anomaly.percentAbove,
          ),
          createdAt: DateTime.now(),
          reminder: true,
          kind: PaymentNoticeKind.utilityAnomaly,
          itemId: item.id,
        ),
      );
    }
    if (additions.isEmpty) return;
    notices.value = [...notices.value, ...additions]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    readState.updateIds(notices.value.map((notice) => notice.id));
  }
}
