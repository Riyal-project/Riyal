import 'package:flutter/material.dart';
import '../data/bank_transaction_matcher.dart';
import '../data/analytics_data.dart';
import '../data/home_data.dart';
import '../data/mock_bank_transaction.dart';
import '../data/monthly_review.dart';
import '../data/notifications_store.dart';
import '../data/people_domain.dart';
import '../data/recurring_detection.dart';
import '../data/subscription.dart';
import '../data/profile_store.dart';
import '../data/subscriptions_store.dart';
import '../data/user_bank_account.dart';
import '../data/user_bank_accounts_store.dart';
import '../data/utilities_domain.dart';
import '../l10n/locale_refresh_mixin.dart';
import '../l10n/strings.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../widgets/profile_menu_button.dart';
import '../widgets/notification_coin_button.dart';
import '../widgets/logo_image.dart';
import '../widgets/card_logo_watermark.dart';
import '../widgets/capsule_tab_selector.dart';
import 'accounts_screen.dart';
import 'analytics_screen.dart';
import 'connect_bank_screen.dart';
import 'monthly_review_screen.dart';
import 'subscription_view_screen.dart';

enum _HomeTab { overview, analytics, accounts }

/// The Home tab's content. Lives inside [MainShell]'s [IndexedStack], so it
/// has no Scaffold/bottom nav of its own — the shell provides those once for
/// all tabs.
class HomeBody extends StatefulWidget {
  const HomeBody({super.key});

  @override
  State<HomeBody> createState() => HomeBodyState();
}

/// Public so [MainShell] can reach it through a [GlobalKey] and reset back
/// to the Overview sub-tab when the bottom nav's Home button is tapped
/// while already on Home — otherwise re-tapping Home would just leave
/// whichever sub-tab (Analytics/Accounts) was last selected on screen,
/// since [IndexedStack] keeps this state alive across tab switches.
class HomeBodyState extends State<HomeBody> with LocaleRefreshState {
  _HomeTab _tab = _HomeTab.overview;

  @override
  void initState() {
    super.initState();
    addLocaleRefreshListener();
  }

  void resetToOverview() {
    if (_tab != _HomeTab.overview) setState(() => _tab = _HomeTab.overview);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TopBar(),
            const SizedBox(height: 16),
            CapsuleTabSelector<_HomeTab>(
              options: [
                CapsuleTabOption(Strings.t('overview'), _HomeTab.overview),
                CapsuleTabOption(
                  Strings.t('analytics_tab'),
                  _HomeTab.analytics,
                ),
                CapsuleTabOption(Strings.t('accounts_tab'), _HomeTab.accounts),
              ],
              selected: _tab,
              onChanged: (t) => setState(() => _tab = t),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: switch (_tab) {
                _HomeTab.overview => ListView(
                  padding: const EdgeInsets.only(bottom: 130),
                  children: [
                    const _SpendingCard(),
                    const SizedBox(height: 16),
                    const _MonthlyReviewCard(),
                    const SizedBox(height: 28),
                    _SectionHeader(
                      title: Strings.t('overview'),
                      onSeeAll: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const AnalyticsScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const _OverviewBar(),
                    const SizedBox(height: 16),
                    const _OverviewStats(),
                    const SizedBox(height: 28),
                    _SectionHeader(title: Strings.t('upcoming_renewals')),
                    const SizedBox(height: 14),
                    const _UpcomingRenewals(),
                  ],
                ),
                _HomeTab.analytics => const AnalyticsContent(
                  horizontalPadding: 0,
                  bottomPadding: 130,
                ),
                _HomeTab.accounts => const _BankAccountsTab(),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthlyReviewCard extends StatelessWidget {
  const _MonthlyReviewCard();

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
    valueListenable: MonthlyReviewStore.instance.revision,
    builder: (context, _, child) {
      final completed = MonthlyReviewStore.instance.isCurrentMonthComplete;
      return InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const MonthlyReviewScreen()),
        ),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: completed ? AppColors.cardBorder : AppColors.goldDark,
            ),
          ),
          child: Stack(
            children: [
              // Unpadded, so it sits flush against the card's true edges
              // instead of being inset by the content's own padding below.
              const CardLogoWatermark(
                corner: WatermarkCorner.bottomEnd,
                inset: 6,
                // Pushed further than `inset` alone so the coin ends before
                // the trailing chevron instead of running under it.
                endInset: 42,
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: AppColors.trackBackground,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        completed
                            ? Icons.check_circle_outline
                            : Icons.assignment_outlined,
                        color: AppColors.gold,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            completed
                                ? Strings.t('monthly_review_completed')
                                : Strings.t('monthly_review_card_title'),
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            completed
                                ? Strings.t('monthly_review_completed_sub')
                                : Strings.t('monthly_review_card_sub'),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.gold),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _TopBar extends StatefulWidget {
  @override
  State<_TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<_TopBar> {
  String? _firstName;

  @override
  void initState() {
    super.initState();
    _loadName();
  }

  Future<void> _loadName() async {
    try {
      await ProfileStore.instance.load();
    } catch (_) {
      // Falls back to whatever's already in ProfileStore.instance.values
      // (its in-memory default, or a previous successful load this
      // session) — the greeting just stays hidden if even that's empty.
    }
    final fullName = ProfileStore.instance.values['Full name']?.trim() ?? '';
    if (!mounted || fullName.isEmpty) return;
    setState(() => _firstName = fullName.split(' ').first);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const ProfileMenuButton(),
        const SizedBox(width: 10),
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _firstName == null
                  ? const SizedBox.shrink()
                  : Text(
                      Strings.f('greeting_hi', _firstName!),
                      key: ValueKey(_firstName),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
        const NotificationCoinButton(),
      ],
    );
  }
}

/// The "Accounts" tab: every connected bank as a bigger card, each flagging
/// how many of that bank's recurring charges still need a manual confirm —
/// matching [AccountsScreen]'s own count exactly (not the detection
/// engine's raw count, which also includes merchants that already got
/// auto-added and so no longer show up as a suggestion anywhere).
class _BankAccountsTab extends StatefulWidget {
  const _BankAccountsTab();

  @override
  State<_BankAccountsTab> createState() => _BankAccountsTabState();
}

class _BankAccountsTabState extends State<_BankAccountsTab> {
  Map<String, int> _commitmentCounts = const {};

  @override
  void initState() {
    super.initState();
    _refreshCommitmentCounts();
  }

  Future<void> _refreshCommitmentCounts() async {
    // Same as AccountsScreen._refreshSuggestions(): run auto-detection
    // first so a charge that just crossed the auto-add threshold is
    // already excluded below, then count only what's left for the user
    // to actually confirm.
    await NotificationsStore.instance.checkForAutoAdditions();
    final transactions = await loadAllConnectedTransactions();
    final alreadyTracked = <String>{
      for (final s in SubscriptionsStore.instance.subscriptions.value)
        s.name.toUpperCase(),
      for (final i in utilitiesDomain.store.items.value) i.name.toUpperCase(),
      for (final i in peopleDomain.store.items.value) i.name.toUpperCase(),
    };
    final byBank = <String, List<MockBankTransactionRow>>{};
    for (final transaction in transactions) {
      byBank.putIfAbsent(transaction.bankId, () => []).add(transaction);
    }
    final counts = {
      for (final entry in byBank.entries)
        entry.key: RecurringDetectionEngine.detect(entry.value)
            .where(
              (s) =>
                  s.occurrences < RecurringDetectionEngine.autoAddOccurrences &&
                  !alreadyTracked.contains(s.merchantName.toUpperCase()),
            )
            .length,
    };
    if (mounted) setState(() => _commitmentCounts = counts);
  }

  Future<void> _addAccount() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const ConnectBankScreen()),
    );
    await _refreshCommitmentCounts();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<UserBankAccount>>(
      valueListenable: UserBankAccountsStore.instance.accounts,
      builder: (context, accounts, _) {
        if (accounts.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 60),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    Strings.t('no_accounts_yet'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _addAccount,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.goldForeground,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded),
                    label: Text(Strings.t('add_account')),
                  ),
                ],
              ),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.only(bottom: 130),
          children: [
            for (final account in accounts)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _BankAccountCard(
                  account: account,
                  commitmentCount: _commitmentCounts[account.bankId] ?? 0,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AccountsScreen(),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _addAccount,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.gold,
                  side: const BorderSide(color: AppColors.goldDark),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.add_rounded),
                label: Text(Strings.t('add_account')),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BankAccountCard extends StatelessWidget {
  const _BankAccountCard({
    required this.account,
    required this.commitmentCount,
    required this.onTap,
  });

  final UserBankAccount account;
  final int commitmentCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                LogoImage(
                  assetPath: account.bankLogoAssetPath,
                  icon: Icons.account_balance_rounded,
                  iconColor: account.bankPrimaryColor,
                  size: 52,
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
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
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
                const Icon(Icons.chevron_right, color: AppColors.gold),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(color: AppColors.cardBorder, height: 1),
            const SizedBox(height: 14),
            Row(
              children: [
                if (commitmentCount > 0)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: const BoxDecoration(
                      color: AppColors.gold,
                      shape: BoxShape.circle,
                    ),
                  ),
                Expanded(
                  child: Text(
                    commitmentCount > 0
                        ? Strings.f(
                            'recurring_payments_found_count',
                            '$commitmentCount',
                          )
                        : Strings.t('no_recurring_payments_found'),
                    style: TextStyle(
                      color: commitmentCount > 0
                          ? AppColors.gold
                          : AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: commitmentCount > 0
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SpendingCard extends StatelessWidget {
  const _SpendingCard();

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: dashboardChanges,
    builder: (context, _) => _content(context),
  );

  Widget _content(BuildContext context) {
    final total = overview.fold<double>(0, (sum, item) => sum + item.amount);
    final previous = analyticsHistory.values.fold<double>(
      0,
      (sum, values) => sum + values[values.length - 2],
    );
    final change = previous == 0 ? 0 : (total - previous) / previous * 100;
    return Container(
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const CardLogoWatermark(
            corner: WatermarkCorner.topEnd,
            inset: -14,
            size: 150,
            respectHeight: false,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                Strings.t('total_spend_this_month'),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '⃁${total.toStringAsFixed(0)}',
                style: AppTypography.amount(
                  color: AppColors.textPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                Strings.f(
                  'compared_with_last_month',
                  '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}%',
                ),
                style: const TextStyle(color: AppColors.gold, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.onSeeAll});

  final String title;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (onSeeAll != null) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onSeeAll,
            child: Text(
              Strings.t('see_all'),
              style: const TextStyle(
                color: AppColors.gold,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _OverviewBar extends StatelessWidget {
  const _OverviewBar();

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: dashboardChanges,
    builder: (context, _) => _content(context),
  );

  Widget _content(BuildContext context) {
    final total = overview.fold<double>(0, (sum, c) => sum + c.amount);
    if (total == 0) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: const SizedBox(
          height: 14,
          child: ColoredBox(color: AppColors.trackBackground),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 14,
        child: Row(
          children: overview
              .map(
                (c) => Expanded(
                  flex: (c.amount / total * 1000).round(),
                  child: Container(color: Color(c.color)),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _OverviewStats extends StatelessWidget {
  const _OverviewStats();

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: dashboardChanges,
    builder: (context, _) => _content(context),
  );

  Widget _content(BuildContext context) {
    return Row(
      children: overview
          .map(
            (c) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Color(c.color),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '⃁${c.amount.toStringAsFixed(0)}',
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.amount(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Strings.categoryDisplay(c.label),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _UpcomingRenewals extends StatefulWidget {
  const _UpcomingRenewals();

  @override
  State<_UpcomingRenewals> createState() => _UpcomingRenewalsState();
}

class _UpcomingRenewalsState extends State<_UpcomingRenewals> {
  final _pageController = PageController();
  int _monthOffset = 0;
  DateTime? _selectedDay;
  List<Subscription> _selectedDaySubs = const [];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToMonth(int offset) {
    _pageController.animateToPage(
      offset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Tapping the same day again collapses the panel instead of re-showing
  /// it, so the calendar can act like a simple expand/collapse toggle.
  void _toggleDay(List<Subscription> daySubs, DateTime day) {
    setState(() {
      if (_selectedDay != null && _isSameDay(_selectedDay!, day)) {
        _selectedDay = null;
        _selectedDaySubs = const [];
      } else {
        _selectedDay = day;
        _selectedDaySubs = daySubs;
      }
    });
  }

  void _closePanel() => setState(() {
    _selectedDay = null;
    _selectedDaySubs = const [];
  });

  void _openDetails(Subscription subscription) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SubscriptionViewScreen(subscriptionId: subscription.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Subscription>>(
      valueListenable: SubscriptionsStore.instance.subscriptions,
      builder: (context, subs, _) {
        if (subs.isEmpty) {
          return Text(
            Strings.t('no_subscriptions_yet_short'),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          );
        }
        final now = DateTime.now();
        final displayedMonth = DateTime(now.year, now.month + _monthOffset);
        final selectedDay = _selectedDay;
        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Stack(
            children: [
              const CardLogoWatermark(corner: WatermarkCorner.bottomEnd),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 26,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _CalendarNavButton(
                            icon: Icons.chevron_left_rounded,
                            onTap: _monthOffset > 0
                                ? () => _goToMonth(_monthOffset - 1)
                                : null,
                          ),
                          Text(
                            '${Strings.monthAbbrev(displayedMonth.month)} '
                            '${displayedMonth.year}',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          _CalendarNavButton(
                            icon: Icons.chevron_right_rounded,
                            onTap: () => _goToMonth(_monthOffset + 1),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 230,
                      child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: (i) => setState(() {
                          _monthOffset = i;
                          // A selection belongs to the month it was made in —
                          // swiping away from it would otherwise leave a
                          // stale, mismatched panel open.
                          _selectedDay = null;
                          _selectedDaySubs = const [];
                        }),
                        itemBuilder: (context, index) => _MonthGrid(
                          month: DateTime(now.year, now.month + index),
                          subscriptions: subs,
                          selectedDay: selectedDay,
                          onDayTap: _toggleDay,
                        ),
                      ),
                    ),
                    // Renewal details for the selected day expand from the
                    // bottom of the calendar card itself, instead of a
                    // full-screen modal sheet from the bottom of the screen.
                    AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeInOut,
                      alignment: Alignment.topCenter,
                      child: selectedDay == null
                          ? const SizedBox(width: double.infinity)
                          : _DayRenewalsPanel(
                              day: selectedDay,
                              subscriptions: _selectedDaySubs,
                              onClose: _closePanel,
                              onMoreDetails: _openDetails,
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Expands inline from the bottom of the calendar card when a day with
/// renewals is tapped — one row per subscription due that day, each with
/// an explicit "More details" action into [SubscriptionViewScreen].
class _DayRenewalsPanel extends StatelessWidget {
  const _DayRenewalsPanel({
    required this.day,
    required this.subscriptions,
    required this.onClose,
    required this.onMoreDetails,
  });

  final DateTime day;
  final List<Subscription> subscriptions;
  final VoidCallback onClose;
  final ValueChanged<Subscription> onMoreDetails;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(height: 1, color: AppColors.cardBorder),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${day.day} ${Strings.monthAbbrev(day.month)} ${day.year}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onClose,
                child: const Icon(
                  Icons.close_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final s in subscriptions)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _RenewalTile(
                subscription: s,
                onMoreDetails: () => onMoreDetails(s),
              ),
            ),
        ],
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.subscriptions,
    required this.selectedDay,
    required this.onDayTap,
  });

  final DateTime month;
  final List<Subscription> subscriptions;
  final DateTime? selectedDay;
  final void Function(List<Subscription> daySubs, DateTime day) onDayTap;

  List<Subscription> _subscriptionsOn(int day) => subscriptions
      .where(
        (s) =>
            s.nextBillingDate.year == month.year &&
            s.nextBillingDate.month == month.month &&
            s.nextBillingDate.day == day,
      )
      .toList();

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // DateTime.weekday: Monday=1..Sunday=7. Calendar starts on Sunday, so
    // Sunday needs 0 leading blanks, Monday 1, ... Saturday 6.
    final leading = DateTime(month.year, month.month, 1).weekday % 7;
    final totalCells = leading + daysInMonth;
    final rows = (totalCells / 7).ceil();
    final today = DateTime.now();

    return Column(
      children: [
        Row(
          children: [
            for (var w = 0; w < 7; w++)
              Expanded(
                child: Center(
                  child: Text(
                    Strings.weekdayAbbrev(w),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 2),
        for (var r = 0; r < rows; r++)
          Expanded(
            child: Row(
              children: [
                for (var c = 0; c < 7; c++)
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final dayNum = r * 7 + c - leading + 1;
                        if (dayNum < 1 || dayNum > daysInMonth) {
                          return const SizedBox.shrink();
                        }
                        final daySubs = _subscriptionsOn(dayNum);
                        final isToday =
                            today.year == month.year &&
                            today.month == month.month &&
                            today.day == dayNum;
                        final isSelected =
                            selectedDay != null &&
                            selectedDay!.year == month.year &&
                            selectedDay!.month == month.month &&
                            selectedDay!.day == dayNum;
                        return GestureDetector(
                          onTap: daySubs.isEmpty
                              ? null
                              : () => onDayTap(
                                  daySubs,
                                  DateTime(month.year, month.month, dayNum),
                                ),
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 1,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.gold.withValues(alpha: 0.28)
                                  : isToday
                                  ? AppColors.gold.withValues(alpha: 0.15)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: isSelected || isToday
                                  ? Border.all(color: AppColors.gold)
                                  : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '$dayNum',
                                  style: TextStyle(
                                    color: isSelected || isToday
                                        ? AppColors.gold
                                        : AppColors.textPrimary,
                                    fontSize: 10,
                                    fontWeight: isSelected || isToday
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                                if (daySubs.isNotEmpty) ...[
                                  const SizedBox(height: 1),
                                  _DayLogos(subscriptions: daySubs),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Up to 2 overlapping circular logos for a calendar day, plus a "+N"
/// circle if more subscriptions renew that same day.
class _DayLogos extends StatelessWidget {
  const _DayLogos({required this.subscriptions});

  final List<Subscription> subscriptions;

  static const _logoSize = 20.0;
  static const _overlap = 13.0;

  @override
  Widget build(BuildContext context) {
    final shown = subscriptions.take(2).toList();
    final overflow = subscriptions.length - shown.length;
    final width =
        _logoSize + _overlap * (shown.length - 1 + (overflow > 0 ? 1 : 0));

    return SizedBox(
      height: _logoSize,
      width: width,
      child: Stack(
        children: [
          for (var i = 0; i < shown.length; i++)
            Positioned(
              left: i * _overlap,
              child: LogoImage(
                assetPath: shown[i].logoAsset,
                size: _logoSize,
                radius: _logoSize / 2,
              ),
            ),
          if (overflow > 0)
            Positioned(
              left: shown.length * _overlap,
              child: Container(
                width: _logoSize,
                height: _logoSize,
                decoration: const BoxDecoration(
                  color: AppColors.trackBackground,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '+$overflow',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CalendarNavButton extends StatelessWidget {
  const _CalendarNavButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Icon(
        icon,
        size: 22,
        color: enabled
            ? AppColors.gold
            : AppColors.textSecondary.withValues(alpha: 0.3),
      ),
    );
  }
}

class _RenewalTile extends StatelessWidget {
  const _RenewalTile({required this.subscription, required this.onMoreDetails});

  final Subscription subscription;
  final VoidCallback onMoreDetails;

  @override
  Widget build(BuildContext context) {
    final s = subscription;
    return GestureDetector(
      onTap: onMoreDetails,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                LogoImage(assetPath: s.logoAsset, size: 44),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        Strings.renewsIn(s.renewsInDays),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '⃁${s.amount.toStringAsFixed(0)}',
                  style: AppTypography.amount(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1, color: AppColors.cardBorder),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: onMoreDetails,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    Strings.t('more_details_action'),
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.gold,
                    size: 16,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
