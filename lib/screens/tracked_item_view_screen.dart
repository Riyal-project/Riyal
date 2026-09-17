import '../widgets/action_confirmation.dart';
import 'package:flutter/material.dart';

import '../data/bank_transaction_matcher.dart';
import '../data/item_payment_history.dart';
import '../data/item_status.dart';
import '../data/mock_bank_transaction.dart';
import '../data/people_categories.dart';
import '../data/people_domain.dart';
import '../data/subscription.dart' show BillingCycle;
import '../data/tracked_category.dart';
import '../data/tracked_domain.dart';
import '../data/tracked_item.dart';
import '../data/utilities_domain.dart';
import '../data/utility_anomaly_detection.dart';
import '../l10n/strings.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../widgets/category_filter_bar.dart';
import '../widgets/coin_back_button.dart';
import '../widgets/logo_image.dart';
import '../widgets/status_badge.dart';
import '../widgets/trend_chart.dart';

/// The read/manage details page for one existing Utilities/People item —
/// distinct from [TrackedItemDetailsScreen], which is the "add a new item"
/// form. Shared between both domains (like [TrackedItemsScreen] already
/// is), branching on `identical(domain, utilitiesDomain/peopleDomain)` for
/// the handful of sections that differ.
class TrackedItemViewScreen extends StatefulWidget {
  const TrackedItemViewScreen({
    super.key,
    required this.domain,
    required this.itemId,
  });

  final TrackedDomain domain;
  final String itemId;

  @override
  State<TrackedItemViewScreen> createState() => _TrackedItemViewScreenState();
}

class _TrackedItemViewScreenState extends State<TrackedItemViewScreen> {
  late final Future<List<MockBankTransactionRow>> _historyFuture =
      _loadHistory();

  bool get _isUtility => identical(widget.domain, utilitiesDomain);
  bool get _isPeople => identical(widget.domain, peopleDomain);

  Future<List<MockBankTransactionRow>> _loadHistory() async {
    final item = _find(widget.domain.store.items.value);
    if (item == null) return const [];
    final all = await loadAllConnectedTransactions();
    return historyForItemName(all, item.name);
  }

  TrackedItem? _find(List<TrackedItem> items) {
    for (final item in items) {
      if (item.id == widget.itemId) return item;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<TrackedItem>>(
      valueListenable: widget.domain.store.items,
      builder: (context, items, _) {
        final item = _find(items);
        if (item == null) {
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
            return _buildBody(context, item, history);
          },
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    TrackedItem item,
    List<MockBankTransactionRow> history,
  ) {
    final anomaly = _isUtility ? _detectAnomaly(item, history) : null;

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
                      item.name,
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
                        LogoImage(
                          assetPath: item.logoAsset,
                          icon: item.icon,
                          iconColor: item.iconColor,
                          size: 56,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              StatusBadge(status: item.status),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '⃁${item.amount.toStringAsFixed(0)}',
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
                            item.cycle == BillingCycle.monthly
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
                      Strings.renewsIn(item.renewsInDays),
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (anomaly != null) ...[
                      const SizedBox(height: 18),
                      _AnomalyBanner(anomaly: anomaly),
                    ],
                    if (_isPeople) ...[
                      const SizedBox(height: 22),
                      _SectionLabel(Strings.t('role_label')),
                      const SizedBox(height: 8),
                      _RoleChip(category: item.category),
                    ],
                    if (_isUtility) ...[
                      const SizedBox(height: 22),
                      _StatRow(
                        label: Strings.t('average_monthly_spend'),
                        value:
                            '⃁${_averageSpend(item, history).toStringAsFixed(0)}',
                      ),
                      const SizedBox(height: 12),
                      _LastBillComparison(history: history),
                      const SizedBox(height: 22),
                      _SectionLabel(Strings.t('amount_history')),
                      const SizedBox(height: 8),
                      TrendChart(
                        values: history.isEmpty
                            ? [item.amount]
                            : history.reversed.map((t) => t.amount).toList(),
                        color: AppColors.utilities,
                      ),
                    ],
                    if (_isPeople) ...[
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
                      const SizedBox(height: 22),
                      _SectionLabel(Strings.t('pause_allowance')),
                      const SizedBox(height: 8),
                      _PauseScheduleCard(
                        item: item,
                        onPause: (date) => widget.domain.store.update(
                          item.copyWith(
                            status: ItemStatus.paused,
                            pausedUntil: date,
                          ),
                        ),
                        onResume: () => widget.domain.store.update(
                          item.copyWith(
                            status: ItemStatus.active,
                            clearPausedUntil: true,
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      _SectionLabel(Strings.t('notes_label')),
                      const SizedBox(height: 8),
                      Text(
                        item.notes?.isNotEmpty == true
                            ? item.notes!
                            : Strings.t('not_set'),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    _NotificationToggle(
                      value: item.notificationsEnabled,
                      onChanged: (v) => widget.domain.store.update(
                        item.copyWith(notificationsEnabled: v),
                      ),
                    ),
                    const SizedBox(height: 22),
                    _ActionButtons(
                      showPause: _isPeople,
                      status: item.status,
                      onEdit: () => _edit(context, item),
                      onTogglePause: () => _togglePause(item),
                      onDelete: () => _delete(context, item),
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

  double _averageSpend(TrackedItem item, List<MockBankTransactionRow> history) {
    if (history.isEmpty) return item.amount;
    return history.fold<double>(0, (sum, t) => sum + t.amount) / history.length;
  }

  UtilityAnomaly? _detectAnomaly(
    TrackedItem item,
    List<MockBankTransactionRow> history,
  ) {
    if (history.isEmpty) return null;
    return UtilityAnomalyDetector.detect(
      category: item.category,
      priorAmounts: history.skip(1).take(3).map((t) => t.amount).toList(),
      currentAmount: history.first.amount,
    );
  }

  Future<void> _edit(BuildContext context, TrackedItem item) async {
    final updated = await showModalBottomSheet<TrackedItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _EditTrackedItemSheet(item: item, isPeople: _isPeople),
    );
    if (updated != null && context.mounted) {
      final confirmed = await showActionConfirmation(
        context,
        title: Strings.t('edit_confirm_title'),
        message: Strings.t('edit_confirm_message'),
        confirmLabel: Strings.t('save'),
      );
      if (confirmed != true || !context.mounted) return;
      widget.domain.store.update(updated);
    }
  }

  void _togglePause(TrackedItem item) {
    final next = item.status == ItemStatus.paused
        ? ItemStatus.active
        : ItemStatus.paused;
    widget.domain.store.update(
      item.copyWith(status: next, clearPausedUntil: next == ItemStatus.active),
    );
  }

  Future<void> _delete(BuildContext context, TrackedItem item) async {
    final confirmed = await showActionConfirmation(
      context,
      title: Strings.t('delete_confirm_title'),
      message: Strings.t('delete_confirm_message'),
      confirmLabel: Strings.t('delete_action'),
    );
    if (confirmed == true) {
      widget.domain.store.remove(item.id);
      if (context.mounted) Navigator.of(context).maybePop();
    }
  }
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

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.category});
  final TrackedCategory category;
  @override
  Widget build(BuildContext context) {
    final isUnassigned = category == PeopleCategories.unassigned;
    final color = isUnassigned ? AppColors.gold : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: isUnassigned
            ? AppColors.gold.withValues(alpha: 0.1)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUnassigned
              ? AppColors.gold.withValues(alpha: 0.4)
              : AppColors.cardBorder,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(category.icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            category.label,
            style: TextStyle(
              color: color,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
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

class _LastBillComparison extends StatelessWidget {
  const _LastBillComparison({required this.history});
  final List<MockBankTransactionRow> history;

  @override
  Widget build(BuildContext context) {
    if (history.length < 2) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          Strings.t('not_enough_history'),
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      );
    }
    final current = history[0].amount;
    final previous = history[1].amount;
    final percent = previous == 0 ? 0.0 : (current - previous) / previous * 100;
    final isUp = percent > 0;
    final color = percent == 0
        ? AppColors.textSecondary
        : (isUp ? AppColors.statusCancelled : AppColors.statusActive);
    return Container(
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
              Strings.t('vs_last_bill'),
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Row(
            children: [
              Icon(
                percent == 0
                    ? Icons.remove_rounded
                    : (isUp
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded),
                size: 14,
                color: color,
              ),
              const SizedBox(width: 4),
              Text(
                '${percent.abs().toStringAsFixed(0)}%',
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnomalyBanner extends StatelessWidget {
  const _AnomalyBanner({required this.anomaly});
  final UtilityAnomaly anomaly;

  @override
  Widget build(BuildContext context) {
    final isRed = anomaly.level == UtilityAnomalyLevel.red;
    final color = isRed ? AppColors.statusCancelled : AppColors.statusTrial;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isRed
                      ? Strings.t('check_for_leak_label')
                      : Strings.t('unusual_spike_label'),
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${anomaly.percentAbove}% above your average (⃁${anomaly.trailingAverage.toStringAsFixed(0)})',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
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

class _PauseScheduleCard extends StatelessWidget {
  const _PauseScheduleCard({
    required this.item,
    required this.onPause,
    required this.onResume,
  });

  final TrackedItem item;
  final ValueChanged<DateTime> onPause;
  final VoidCallback onResume;

  bool get _isPaused =>
      item.status == ItemStatus.paused && item.pausedUntil != null;

  Future<void> _pick(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) onPause(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: _isPaused
          ? Row(
              children: [
                const Icon(
                  Icons.pause_circle_outline_rounded,
                  color: AppColors.statusPaused,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${Strings.t('status_paused')} · ${_formatDate(item.pausedUntil!)}',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onResume,
                  child: Text(
                    Strings.t('resume_now'),
                    style: const TextStyle(color: AppColors.gold),
                  ),
                ),
              ],
            )
          : GestureDetector(
              onTap: () => _pick(context),
              child: Row(
                children: [
                  const Icon(
                    Icons.pause_circle_outline_rounded,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      Strings.t('pause_allowance'),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
    );
  }
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
    required this.showPause,
    required this.status,
    required this.onEdit,
    required this.onTogglePause,
    required this.onDelete,
  });

  final bool showPause;
  final ItemStatus status;
  final VoidCallback onEdit;
  final VoidCallback onTogglePause;
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
            if (showPause) ...[
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
            ],
            Expanded(
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
        ),
      ],
    );
  }
}

class _EditTrackedItemSheet extends StatefulWidget {
  const _EditTrackedItemSheet({required this.item, required this.isPeople});
  final TrackedItem item;

  /// Gates both the notes field and the role/category picker below —
  /// Utilities don't expose either from this sheet.
  final bool isPeople;

  @override
  State<_EditTrackedItemSheet> createState() => _EditTrackedItemSheetState();
}

class _EditTrackedItemSheetState extends State<_EditTrackedItemSheet> {
  late final TextEditingController _amountController = TextEditingController(
    text: widget.item.amount.toStringAsFixed(0),
  );
  late final TextEditingController _notesController = TextEditingController(
    text: widget.item.notes ?? '',
  );
  late BillingCycle _cycle = widget.item.cycle;
  late TrackedCategory _category = widget.item.category;

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save() {
    final amount =
        double.tryParse(_amountController.text) ?? widget.item.amount;
    final notes = _notesController.text.trim();
    Navigator.of(context).pop(
      widget.item.copyWith(
        amount: amount,
        cycle: _cycle,
        category: widget.isPeople ? _category : widget.item.category,
        notes: widget.isPeople ? (notes.isEmpty ? null : notes) : null,
        clearNotes: widget.isPeople && notes.isEmpty,
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
                Strings.t('edit_details_title'),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              _SectionLabel(Strings.t('amount_sar')),
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
              _SectionLabel(Strings.t('billing_cycle')),
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
              if (widget.isPeople) ...[
                const SizedBox(height: 18),
                _SectionLabel(Strings.t('role_label')),
                const SizedBox(height: 8),
                CategoryFilterBar(
                  categories: PeopleCategories.values,
                  showAll: false,
                  selected: _category,
                  onChanged: (c) => setState(() => _category = c ?? _category),
                ),
                const SizedBox(height: 18),
                _SectionLabel(Strings.t('notes_label')),
                const SizedBox(height: 8),
                TextField(
                  controller: _notesController,
                  maxLines: 3,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: Strings.t('add_notes_hint'),
                    hintStyle: const TextStyle(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.surfaceElevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
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
