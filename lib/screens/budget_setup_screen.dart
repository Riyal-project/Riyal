import 'package:flutter/material.dart';
import '../data/budget_store.dart';
import '../l10n/strings.dart';
import '../theme/app_theme.dart';
import '../widgets/coin_back_button.dart';

class BudgetSetupScreen extends StatefulWidget {
  const BudgetSetupScreen({super.key, this.afterSetup});
  final Widget? afterSetup;

  @override
  State<BudgetSetupScreen> createState() => _BudgetSetupScreenState();
}

class _BudgetSetupScreenState extends State<BudgetSetupScreen> {
  static const _defaultLimits = {
    BudgetDomain.subscriptions: 1000.0,
    BudgetDomain.utilities: 2000.0,
    BudgetDomain.people: 8000.0,
  };

  final _formKey = GlobalKey<FormState>();
  late final _controllers = {
    for (final domain in BudgetDomain.values)
      domain: TextEditingController(
        text: (BudgetStore.instance.limitFor(domain) ?? _defaultLimits[domain]!)
            .toStringAsFixed(2),
      ),
  };
  bool _saving = false;

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      if (BudgetStore.instance.account == null) {
        await BudgetStore.instance.activate('device');
      }
      await BudgetStore.instance.save({
        for (final entry in _controllers.entries)
          entry.key: double.parse(entry.value.text.trim()),
      });
      if (!mounted) return;
      if (widget.afterSetup != null) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => widget.afterSetup!),
          (_) => false,
        );
      } else {
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(Strings.t('budget_save_error'))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: widget.afterSetup == null,
    child: Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  if (widget.afterSetup == null)
                    const Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: CoinBackButton(),
                    ),
                  if (widget.afterSetup == null) const SizedBox(height: 8),
                  const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: AppColors.gold,
                    size: 54,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    Strings.t('budget_setup_intro'),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    Strings.t('budget_setup_note'),
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  for (final domain in BudgetDomain.values) ...[
                    TextFormField(
                      key: ValueKey('budget-${domain.name}'),
                      controller: _controllers[domain],
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: domain == BudgetDomain.people
                          ? TextInputAction.done
                          : TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: Strings.categoryDisplay(domain.categoryKey),
                        suffixText: 'SAR',
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      validator: (value) {
                        final amount = double.tryParse(value?.trim() ?? '');
                        return amount == null || !amount.isFinite || amount < 0
                            ? Strings.t('budget_invalid_amount')
                            : null;
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(Strings.t('budget_save')),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
