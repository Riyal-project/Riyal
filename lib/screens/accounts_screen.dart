import '../widgets/action_confirmation.dart';
import 'package:flutter/material.dart';

import '../data/bank_transaction_matcher.dart';
import '../data/notifications_store.dart';
import '../data/recurring_detection.dart';
import '../data/people_catalog.dart';
import '../data/people_domain.dart';
import '../data/subscription_catalog.dart';
import '../data/subscriptions_store.dart';
import '../data/user_bank_account.dart';
import '../data/user_bank_accounts_store.dart';
import '../data/utilities_domain.dart';
import '../data/utility_catalog.dart';
import '../l10n/strings.dart';
import '../theme/app_theme.dart';
import '../widgets/coin_back_button.dart';
import '../widgets/logo_image.dart';
import 'connect_bank_screen.dart';
import 'subscription_details_screen.dart';
import 'tracked_item_details_screen.dart';

/// Connected mock bank accounts — replaces what used to be Lean-backed.
/// Reachable from Settings.
class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  final _suggestions = ValueNotifier<List<DetectedSubscription>>([]);

  @override
  void initState() {
    super.initState();
    _refreshSuggestions();
  }

  @override
  void dispose() {
    _suggestions.dispose();
    super.dispose();
  }

  Future<void> _refreshSuggestions() async {
    // Runs auto-detection first (rather than waiting for its periodic
    // timer) so a charge that just crossed the auto-add threshold is
    // already in its proper store — and excluded below — by the time this
    // screen decides what still needs a manual confirm.
    await NotificationsStore.instance.checkForAutoAdditions();
    final transactions = await loadAllConnectedTransactions();
    final detected = RecurringDetectionEngine.detect(transactions);
    // Exclude merchants that already became a tracked subscription/utility/
    // people entry — otherwise the same recurring charge keeps resurfacing
    // every time this screen re-runs detection, since the engine itself has
    // no memory of what's already been added.
    final alreadyTracked = <String>{
      for (final s in SubscriptionsStore.instance.subscriptions.value)
        s.name.toUpperCase(),
      for (final i in utilitiesDomain.store.items.value) i.name.toUpperCase(),
      for (final i in peopleDomain.store.items.value) i.name.toUpperCase(),
    };
    if (mounted) {
      _suggestions.value = detected
          .where(
            (s) =>
                // Anything at or above the auto-add threshold either just
                // got added above, or is mid-race with the periodic
                // auto-detection tick — either way it no longer belongs in
                // the manual "possible" list.
                s.occurrences < RecurringDetectionEngine.autoAddOccurrences &&
                !alreadyTracked.contains(s.merchantName.toUpperCase()),
          )
          .toList();
    }
  }

  /// Resolves the best available picture for a suggestion: the real logo
  /// stored on its transaction when there is one, otherwise a best-effort
  /// match against the relevant domain's catalog — the same catalogs the
  /// "add from scratch" flows use, so a suggestion looks identical to
  /// something added manually.
  ({String? logoAsset, IconData? icon, Color? iconColor}) _resolveVisual(
    DetectedSubscription suggestion,
  ) {
    if (suggestion.logoAsset != null) {
      return (logoAsset: suggestion.logoAsset, icon: null, iconColor: null);
    }
    final merchant = suggestion.merchantName.toUpperCase();
    switch (suggestion.category) {
      case 'utility':
        for (final entry in utilityCatalog) {
          if (merchant.contains(entry.name.toUpperCase())) {
            return (
              logoAsset: entry.logoAsset,
              icon: entry.icon,
              iconColor: entry.iconColor,
            );
          }
        }
      case 'person':
        for (final entry in peopleCatalog) {
          if (merchant.contains(entry.name.toUpperCase())) {
            return (
              logoAsset: entry.logoAsset,
              icon: entry.icon,
              iconColor: entry.iconColor,
            );
          }
        }
      default:
        for (final app in subscriptionCatalog) {
          if (merchant.contains(app.name.toUpperCase())) {
            return (logoAsset: app.logoAsset, icon: null, iconColor: null);
          }
        }
    }
    return (logoAsset: null, icon: null, iconColor: null);
  }

  Future<void> _addAccount() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const ConnectBankScreen()),
    );
    await _refreshSuggestions();
  }

  /// Asks the user where a detected recurring payment actually belongs
  /// (rather than guessing from the transaction's own category, which is
  /// only ever a best-effort classification) and lets them review/adjust
  /// everything on the normal add-details screen before it's saved — the
  /// same screen "add from scratch"/"add from a transaction" already use,
  /// so the save logic itself isn't duplicated here.
  Future<void> _addSuggestion(DetectedSubscription suggestion) async {
    final destination = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                Strings.t('add_suggestion_where_title'),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                Strings.t('add_suggestion_where_sub'),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              _DestinationOption(
                icon: Icons.subscriptions_outlined,
                label: Strings.t('nav_subscriptions'),
                onTap: () => Navigator.pop(sheetContext, 'subscription'),
              ),
              const SizedBox(height: 10),
              _DestinationOption(
                icon: Icons.bolt_rounded,
                label: Strings.t('nav_utilities'),
                onTap: () => Navigator.pop(sheetContext, 'utility'),
              ),
              const SizedBox(height: 10),
              _DestinationOption(
                icon: Icons.people_outline_rounded,
                label: Strings.t('nav_people'),
                onTap: () => Navigator.pop(sheetContext, 'person'),
              ),
            ],
          ),
        ),
      ),
    );
    if (destination == null || !mounted) return;

    final visual = _resolveVisual(suggestion);
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => switch (destination) {
          'utility' => TrackedItemDetailsScreen(
            domain: utilitiesDomain,
            name: suggestion.merchantName,
            logoAsset: visual.logoAsset,
            icon: visual.icon,
            iconColor: visual.iconColor,
            initialAmount: suggestion.amount,
          ),
          'person' => TrackedItemDetailsScreen(
            domain: peopleDomain,
            name: suggestion.merchantName,
            logoAsset: visual.logoAsset,
            icon: visual.icon,
            iconColor: visual.iconColor,
            initialAmount: suggestion.amount,
          ),
          _ => SubscriptionDetailsScreen(
            name: suggestion.merchantName,
            logoAsset: visual.logoAsset,
            initialAmount: suggestion.amount,
          ),
        },
      ),
    );
    // Whether they saved (the destination screen pops all the way back to
    // MainShell itself) or backed out without saving (pops back to just
    // here), re-checking is cheap and keeps the list correct either way.
    await _refreshSuggestions();
  }

  void _openAccountDetails(UserBankAccount account) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  LogoImage(
                    assetPath: account.bankLogoAssetPath,
                    icon: Icons.account_balance_rounded,
                    iconColor: account.bankPrimaryColor,
                    size: 44,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account.bankName,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          account.maskedAccountNumber,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.statusCancelled,
                  ),
                  onPressed: () async {
                    final confirmed = await showActionConfirmation(
                      sheetContext,
                      title: Strings.t('disconnect_confirm_title'),
                      message: Strings.t('disconnect_confirm_message'),
                      confirmLabel: Strings.t('disconnect'),
                    );
                    if (confirmed != true || !sheetContext.mounted || !mounted) {
                      return;
                    }
                    Navigator.pop(sheetContext);
                    await UserBankAccountsStore.instance.remove(account.id);
                    await _refreshSuggestions();
                  },
                  icon: const Icon(Icons.link_off_rounded, size: 20),
                  label: Text(Strings.t('disconnect')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        leading: const CoinBackButton(),
        title: Text(Strings.t('accounts_title')),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ValueListenableBuilder<List<UserBankAccount>>(
                valueListenable: UserBankAccountsStore.instance.accounts,
                builder: (context, accounts, _) => ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  children: [
                    if (accounts.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 60),
                        child: Center(
                          child: Text(
                            Strings.t('no_accounts_yet'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      )
                    else
                      for (final account in accounts)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _AccountTile(
                            account: account,
                            onTap: () => _openAccountDetails(account),
                          ),
                        ),
                    ValueListenableBuilder<List<DetectedSubscription>>(
                      valueListenable: _suggestions,
                      builder: (context, suggestions, _) {
                        if (suggestions.isEmpty) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                Strings.t('suggested_subscriptions'),
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                Strings.t('suggested_subscriptions_sub'),
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12.5,
                                ),
                              ),
                              const SizedBox(height: 14),
                              for (final suggestion in suggestions)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _SuggestionTile(
                                    suggestion: suggestion,
                                    onAdd: () => _addSuggestion(suggestion),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _addAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.goldForeground,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.add_rounded),
                  label: Text(
                    Strings.t('add_account'),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({required this.account, required this.onTap});

  final UserBankAccount account;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            LogoImage(
              assetPath: account.bankLogoAssetPath,
              icon: Icons.account_balance_rounded,
              iconColor: account.bankPrimaryColor,
              size: 44,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.bankName,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    account.maskedAccountNumber,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.statusActive,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({required this.suggestion, required this.onAdd});

  final DetectedSubscription suggestion;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  suggestion.merchantName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '⃁${suggestion.amount.toStringAsFixed(0)} · '
                  '${Strings.f('occurrences_count', '${suggestion.occurrences}')}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: onAdd,
            style: TextButton.styleFrom(foregroundColor: AppColors.gold),
            child: Text(Strings.t('add_suggestion')),
          ),
        ],
      ),
    );
  }
}

class _DestinationOption extends StatelessWidget {
  const _DestinationOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.trackBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.gold, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
