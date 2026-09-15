import 'package:flutter/material.dart';
import '../widgets/coin_back_button.dart';

import '../data/id_generator.dart';
import '../data/item_status.dart';
import '../data/subscription.dart';
import '../data/subscription_category.dart';
import '../data/subscriptions_store.dart';
import '../data/tracked_category.dart';
import '../l10n/strings.dart';
import '../theme/app_theme.dart';
import '../widgets/category_filter_bar.dart';
import '../widgets/logo_image.dart';
import '../widgets/free_trial_fields.dart';

class SubscriptionDetailsScreen extends StatefulWidget {
  const SubscriptionDetailsScreen({
    super.key,
    required this.name,
    this.logoAsset,
    this.initialAmount,
    this.initialCategory,
    this.initialFreeTrial = false,
  });

  final String name;
  final String? logoAsset;
  final double? initialAmount;
  final TrackedCategory? initialCategory;
  final bool initialFreeTrial;

  @override
  State<SubscriptionDetailsScreen> createState() =>
      _SubscriptionDetailsScreenState();
}

class _SubscriptionDetailsScreenState extends State<SubscriptionDetailsScreen> {
  late final TextEditingController _amountController = TextEditingController(
    text: widget.initialAmount != null
        ? widget.initialAmount!.toStringAsFixed(0)
        : '',
  );
  BillingCycle _cycle = BillingCycle.monthly;
  late bool _freeTrial = widget.initialFreeTrial;
  FreeTrialDuration _trialDuration = FreeTrialDuration.week;
  DateTime _trialStartDate = DateTime.now();
  DateTime _nextBillingDate = DateTime.now().add(const Duration(days: 30));
  late TrackedCategory _category =
      widget.initialCategory ?? SubscriptionCategories.other;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextBillingDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _nextBillingDate = picked);
  }

  void _save() {
    final amount = _amountController.text.trim().isEmpty
        ? 0.0
        : double.tryParse(_amountController.text);
    if (amount == null || !amount.isFinite || amount < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Strings.t('invalid_subscription_amount'))),
      );
      return;
    }
    SubscriptionsStore.instance.add(
      Subscription(
        id: IdGenerator.uuidV4(),
        name: widget.name,
        logoAsset: widget.logoAsset,
        amount: amount,
        cycle: _cycle,
        nextBillingDate: _freeTrial
            ? freeTrialEndDate(_trialStartDate, _trialDuration)
            : _nextBillingDate,
        category: _category,
        status: _freeTrial ? ItemStatus.trial : ItemStatus.active,
        trialStartDate: _freeTrial ? _trialStartDate : null,
        trialDuration: _freeTrial ? _trialDuration : null,
      ),
    );
    // MainShell (with the Subscriptions tab already selected) is always the
    // root route, so popping back to it just means popping to the first route.
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
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
                      Strings.t('subscription_details'),
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
                      children: [
                        LogoImage(assetPath: widget.logoAsset, size: 56),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            widget.name,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    FreeTrialFields(
                      enabled: _freeTrial,
                      duration: _trialDuration,
                      startDate: _trialStartDate,
                      onEnabledChanged: (value) =>
                          setState(() => _freeTrial = value),
                      onDurationChanged: (value) =>
                          setState(() => _trialDuration = value),
                      onStartDateChanged: (value) {
                        if (mounted) setState(() => _trialStartDate = value);
                      },
                    ),
                    Text(
                      Strings.t(_freeTrial ? 'trial_amount' : 'amount_sar'),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        hintText: '0',
                        hintStyle: const TextStyle(
                          color: AppColors.textSecondary,
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      Strings.t(_freeTrial ? 'trial_cycle' : 'billing_cycle'),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
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
                            onTap: () =>
                                setState(() => _cycle = BillingCycle.yearly),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Text(
                      Strings.t('category_field'),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CategoryFilterBar(
                      categories: SubscriptionCategories.values,
                      showAll: false,
                      selected: _category,
                      onChanged: (c) =>
                          setState(() => _category = c ?? _category),
                    ),
                    if (!_freeTrial) ...[
                      const SizedBox(height: 22),
                      Text(
                        Strings.t('next_billing_date'),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _pickDate,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
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
                                '${_nextBillingDate.year}-${_nextBillingDate.month.toString().padLeft(2, '0')}-${_nextBillingDate.day.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
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
                    Strings.t('add_subscription_button'),
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
          color: isSelected ? AppColors.gold : AppColors.surface,
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
