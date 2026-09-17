import '../widgets/action_confirmation.dart';
import 'package:flutter/material.dart';
import '../widgets/free_trial_fields.dart';

import '../data/bank_transaction_matcher.dart';
import '../data/item_payment_history.dart';
import '../data/item_status.dart';
import '../data/mock_bank_transaction.dart';
import '../data/monthly_review.dart';
import '../data/subscription.dart';
import '../data/subscription_category.dart';
import '../data/subscriptions_store.dart';
import '../data/tracked_category.dart';
import '../l10n/strings.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../widgets/category_filter_bar.dart';
import '../widgets/coin_back_button.dart';
import '../widgets/logo_image.dart';
import '../widgets/status_badge.dart';
import '../widgets/trend_chart.dart';

/// The read/manage details page for one existing subscription — distinct
/// from [SubscriptionDetailsScreen], which is the "add a new subscription"
/// form. Reached by tapping a subscription tile.
class SubscriptionViewScreen extends StatefulWidget {
  const SubscriptionViewScreen({super.key, required this.subscriptionId});

  final String subscriptionId;

  @override
  State<SubscriptionViewScreen> createState() => _SubscriptionViewScreenState();
}

class _SubscriptionViewScreenState extends State<SubscriptionViewScreen> {
  late final Future<List<MockBankTransactionRow>> _historyFuture =
      _loadHistory();

  Future<List<MockBankTransactionRow>> _loadHistory() async {
    final subscription = _find(SubscriptionsStore.instance.subscriptions.value);
    if (subscription == null) return const [];
    final all = await loadAllConnectedTransactions();
    return historyForItemName(all, subscription.name);
  }

  Subscription? _find(List<Subscription> subscriptions) {
    for (final s in subscriptions) {
      if (s.id == widget.subscriptionId) return s;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Subscription>>(
      valueListenable: SubscriptionsStore.instance.subscriptions,
      builder: (context, subscriptions, _) {
        final subscription = _find(subscriptions);
        if (subscription == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          });
          return const Scaffold(backgroundColor: AppColors.background);
        }
        return FutureBuilder<List<MockBankTransactionRow>>(
          future: _historyFuture,
          builder: (context, snapshot) {
            final history = snapshot.data ?? const [];
            return _buildBody(context, subscription, history);
          },
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    Subscription subscription,
    List<MockBankTransactionRow> history,
  ) {
    final changes = priceChanges(history);
    final totalPaid = history.isEmpty
        ? (subscription.hasFreeTrial ? 0.0 : subscription.amount)
        : history.fold<double>(0, (sum, t) => sum + t.amount);
    final reviewAnswer = _reviewAnswerFor(subscription);
    final showYearlyNudge =
        subscription.cycle == BillingCycle.monthly &&
        _hasAnnualPlanRecommendation(subscription);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CoinBackButton(),
                  Expanded(
                    child: Text(
                      subscription.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LogoImage(assetPath: subscription.logoAsset, size: 56),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                subscription.name,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (subscription.hasFreeTrial &&
                                  subscription.status == ItemStatus.trial)
                                const FreeTrialBadge()
                              else
                                StatusBadge(status: subscription.status),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    if (subscription.hasFreeTrial) ...[
                      _SectionLabel(Strings.t('trial_amount')),
                      const SizedBox(height: 8),
                    ],
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '⃁${subscription.amount.toStringAsFixed(0)}',
                          style: AppTypography.amount(
                            color: AppColors.textPrimary,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Text(
                            subscription.cycle == BillingCycle.monthly
                                ? Strings.t('monthly')
                                : Strings.t('yearly'),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subscription.hasFreeTrial
                          ? '${Strings.t(subscription.isInFreeTrial ? 'trial_end_date' : 'trial_ended')}'
                                ' · ${trialDateLabel(subscription.trialEndDate!)}'
                          : Strings.renewsIn(subscription.renewsInDays),
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _CategoryChip(category: subscription.category),
                    const SizedBox(height: 22),
                    _StatRow(
                      label: Strings.t('total_paid_to_date'),
                      value: '⃁${totalPaid.toStringAsFixed(0)}',
                    ),
                    if (showYearlyNudge) ...[
                      const SizedBox(height: 14),
                      _NudgeCard(
                        title: Strings.t('yearly_plan_nudge_title'),
                        icon: Icons.savings_outlined,
                      ),
                    ],
                    const SizedBox(height: 14),
                    _CheckInCard(answer: reviewAnswer),
                    if (changes.isNotEmpty) ...[
                      const SizedBox(height: 22),
                      _SectionLabel(Strings.t('price_history')),
                      const SizedBox(height: 8),
                      ...changes.map(
                        (row) => _HistoryRow(
                          date: row.transactionDate,
                          amount: row.amount,
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    _SectionLabel(Strings.t('payment_history')),
                    const SizedBox(height: 8),
                    if (history.isEmpty)
                      Text(
                        Strings.t('no_payment_history_yet'),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      )
                    else
                      ...history.map(
                        (row) => _HistoryRow(
                          date: row.transactionDate,
                          amount: row.amount,
                        ),
                      ),
                    if (subscription.purposeTag != null ||
                        subscription.reminderDate != null) ...[
                      const SizedBox(height: 22),
                      if (subscription.purposeTag != null) ...[
                        _SectionLabel(Strings.t('purpose_tag_label')),
                        const SizedBox(height: 8),
                        Text(
                          subscription.purposeTag!,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                      if (subscription.reminderDate != null) ...[
                        const SizedBox(height: 12),
                        _SectionLabel(Strings.t('reminder_date_label')),
                        const SizedBox(height: 8),
                        Text(
                          _formatDate(subscription.reminderDate!),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                    const SizedBox(height: 22),
                    _SectionLabel(Strings.t('spend_over_time')),
                    const SizedBox(height: 8),
                    TrendChart(
                      values: history.isEmpty
                          ? [
                              subscription.hasFreeTrial
                                  ? 0.0
                                  : subscription.amount,
                            ]
                          : history.reversed.map((t) => t.amount).toList(),
                    ),
                    const SizedBox(height: 22),
                    _NotificationToggle(
                      value: subscription.notificationsEnabled,
                      onChanged: (v) => SubscriptionsStore.instance.update(
                        subscription.copyWith(notificationsEnabled: v),
                      ),
                    ),
                    const SizedBox(height: 22),
                    _ActionButtons(
                      status: subscription.status,
                      onEdit: () => _edit(context, subscription),
                      onTogglePause: () => _togglePause(subscription),
                      onCancel: () => _cancel(context, subscription),
                      onDelete: () => _delete(context, subscription),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _ReviewAnswerDisplay? _reviewAnswerFor(Subscription subscription) {
    final snapshot = MonthlyReviewStore.instance.currentSnapshot;
    if (snapshot == null) return null;
    final id = 'subscription:${subscription.name.trim().toLowerCase()}';
    for (final answer in snapshot.answers) {
      if (answer.item.id == id) {
        return _ReviewAnswerDisplay(
          need: answer.need,
          activity: answer.activity,
        );
      }
    }
    return null;
  }

  bool _hasAnnualPlanRecommendation(Subscription subscription) {
    final snapshot = MonthlyReviewStore.instance.currentSnapshot;
    if (snapshot == null) return false;
    final id = 'subscription:${subscription.name.trim().toLowerCase()}';
    return snapshot.recommendations.any(
      (r) => r.item.id == id && r.type == RecommendationType.annualPlan,
    );
  }

  Future<void> _edit(BuildContext context, Subscription subscription) async {
    final updated = await showModalBottomSheet<Subscription>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _EditSubscriptionSheet(subscription: subscription),
    );
    if (updated != null && context.mounted) {
      final confirmed = await showActionConfirmation(
        context,
        title: Strings.t('edit_confirm_title'),
        message: Strings.t('edit_confirm_message'),
        confirmLabel: Strings.t('save'),
      );
      if (confirmed != true || !context.mounted) return;
      await SubscriptionsStore.instance.update(updated);
    }
  }

  void _togglePause(Subscription subscription) {
    final next = subscription.status == ItemStatus.paused
        ? (subscription.isInFreeTrial ? ItemStatus.trial : ItemStatus.active)
        : ItemStatus.paused;
    SubscriptionsStore.instance.update(subscription.copyWith(status: next));
  }

  Future<void> _cancel(BuildContext context, Subscription subscription) async {
    final confirmed = await showActionConfirmation(
      context,
      title: Strings.t('cancel_confirm_title'),
      message: Strings.t('cancel_confirm_message'),
      confirmLabel: Strings.t('cancel_subscription_action'),
    );
    if (confirmed == true) {
      await SubscriptionsStore.instance.update(
        subscription.copyWith(status: ItemStatus.cancelled),
      );
    }
  }

  Future<void> _delete(BuildContext context, Subscription subscription) async {
    final confirmed = await showActionConfirmation(
      context,
      title: Strings.t('delete_confirm_title'),
      message: Strings.t('delete_confirm_message'),
      confirmLabel: Strings.t('delete_action'),
    );
    if (confirmed == true) {
      await SubscriptionsStore.instance.remove(subscription.id);
      if (context.mounted) Navigator.of(context).maybePop();
    }
  }
}

class _ReviewAnswerDisplay {
  const _ReviewAnswerDisplay({required this.need, required this.activity});
  final ReviewNeed need;
  final ReviewActivity activity;
}

String _formatDate(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
  );
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category});
  final TrackedCategory category;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.cardBorder),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(category.icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(
          category.label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: AppTypography.amount(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _NudgeCard extends StatelessWidget {
  const _NudgeCard({required this.title, required this.icon});
  final String title;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.gold.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
    ),
    child: Row(
      children: [
        Icon(icon, color: AppColors.gold, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.gold,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

class _CheckInCard extends StatelessWidget {
  const _CheckInCard({required this.answer});
  final _ReviewAnswerDisplay? answer;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.fact_check_outlined,
          color: AppColors.textSecondary,
          size: 18,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                Strings.t('still_using_this'),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                answer == null
                    ? Strings.t('not_reviewed_this_month')
                    : '${answer!.need.subscriptionLabel} · ${answer!.activity.subscriptionLabel}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.date, required this.amount});
  final DateTime date;
  final double amount;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          _formatDate(date),
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        Text(
          '⃁${amount.toStringAsFixed(2)}',
          style: AppTypography.amount(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _NotificationToggle extends StatelessWidget {
  const _NotificationToggle({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.notifications_outlined,
          color: AppColors.textSecondary,
          size: 18,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            Strings.t('notifications_toggle_label'),
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.gold,
        ),
      ],
    ),
  );
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.status,
    required this.onEdit,
    required this.onTogglePause,
    required this.onCancel,
    required this.onDelete,
  });

  final ItemStatus status;
  final VoidCallback onEdit;
  final VoidCallback onTogglePause;
  final VoidCallback onCancel;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isPaused = status == ItemStatus.paused;
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onEdit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.goldForeground,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: Text(Strings.t('edit_action')),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onTogglePause,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.cardBorder),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: Icon(
                  isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                  size: 18,
                ),
                label: Text(
                  isPaused
                      ? Strings.t('resume_action')
                      : Strings.t('pause_action'),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onCancel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.statusCancelled,
                  side: BorderSide(
                    color: AppColors.statusCancelled.withValues(alpha: 0.4),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.cancel_outlined, size: 18),
                label: Text(Strings.t('cancel_subscription_action')),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: onDelete,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textTertiary,
            ),
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            label: Text(Strings.t('delete_action')),
          ),
        ),
      ],
    );
  }
}

class _EditSubscriptionSheet extends StatefulWidget {
  const _EditSubscriptionSheet({required this.subscription});
  final Subscription subscription;

  @override
  State<_EditSubscriptionSheet> createState() => _EditSubscriptionSheetState();
}

class _EditSubscriptionSheetState extends State<_EditSubscriptionSheet> {
  late bool _freeTrial = widget.subscription.hasFreeTrial;
  late FreeTrialDuration _trialDuration =
      widget.subscription.trialDuration ?? FreeTrialDuration.week;
  late DateTime _trialStartDate =
      widget.subscription.trialStartDate ?? DateTime.now();
  late final TextEditingController _amountController = TextEditingController(
    text: widget.subscription.amount.toStringAsFixed(0),
  );
  late final TextEditingController _purposeController = TextEditingController(
    text: widget.subscription.purposeTag ?? '',
  );
  late BillingCycle _cycle = widget.subscription.cycle;
  late TrackedCategory _category = widget.subscription.category;
  DateTime? _reminderDate;

  @override
  void initState() {
    super.initState();
    _reminderDate = widget.subscription.reminderDate;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  Future<void> _pickReminderDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _reminderDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _reminderDate = picked);
  }

  void _save() {
    final amount =
        double.tryParse(_amountController.text) ?? widget.subscription.amount;
    if (!amount.isFinite || amount < 0) return;
    final purpose = _purposeController.text.trim();
    Navigator.of(context).pop(
      widget.subscription.copyWith(
        amount: amount,
        cycle: _cycle,
        category: _category,
        purposeTag: purpose.isEmpty ? null : purpose,
        clearPurposeTag: purpose.isEmpty,
        reminderDate: _reminderDate,
        clearReminderDate: _reminderDate == null,
        trialStartDate: _freeTrial ? _trialStartDate : null,
        trialDuration: _freeTrial ? _trialDuration : null,
        clearFreeTrial: !_freeTrial,
        nextBillingDate: _freeTrial
            ? freeTrialEndDate(_trialStartDate, _trialDuration)
            : null,
        status:
            widget.subscription.status == ItemStatus.cancelled ||
                widget.subscription.status == ItemStatus.paused
            ? widget.subscription.status
            : (_freeTrial ? ItemStatus.trial : ItemStatus.active),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.cardBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                Strings.t('edit_subscription_title'),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              FreeTrialFields(
                enabled: _freeTrial,
                duration: _trialDuration,
                startDate: _trialStartDate,
                onEnabledChanged: (value) => setState(() => _freeTrial = value),
                onDurationChanged: (value) =>
                    setState(() => _trialDuration = value),
                onStartDateChanged: (value) {
                  if (mounted) setState(() => _trialStartDate = value);
                },
              ),
              _SectionLabel(
                Strings.t(_freeTrial ? 'trial_amount' : 'amount_sar'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.surfaceElevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _SectionLabel(
                Strings.t(_freeTrial ? 'trial_cycle' : 'billing_cycle'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _CycleOption(
                      label: Strings.t('monthly'),
                      isSelected: _cycle == BillingCycle.monthly,
                      onTap: () =>
                          setState(() => _cycle = BillingCycle.monthly),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _CycleOption(
                      label: Strings.t('yearly'),
                      isSelected: _cycle == BillingCycle.yearly,
                      onTap: () => setState(() => _cycle = BillingCycle.yearly),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _SectionLabel(Strings.t('category_field')),
              const SizedBox(height: 8),
              CategoryFilterBar(
                categories: SubscriptionCategories.values,
                showAll: false,
                selected: _category,
                onChanged: (c) => setState(() => _category = c ?? _category),
              ),
              const SizedBox(height: 18),
              _SectionLabel(Strings.t('purpose_tag_label')),
              const SizedBox(height: 8),
              TextField(
                controller: _purposeController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.surfaceElevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _SectionLabel(Strings.t('reminder_date_label')),
                  if (_reminderDate != null)
                    GestureDetector(
                      onTap: () => setState(() => _reminderDate = null),
                      child: Text(
                        Strings.t('clear_action'),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickReminderDate,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        color: AppColors.gold,
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _reminderDate != null
                            ? _formatDate(_reminderDate!)
                            : Strings.t('no_reminder_set'),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.goldForeground,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    Strings.t('save_action'),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CycleOption extends StatelessWidget {
  const _CycleOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gold : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? AppColors.goldForeground
                : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
