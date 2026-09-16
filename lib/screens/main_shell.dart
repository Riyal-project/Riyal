import 'package:flutter/material.dart';

import '../l10n/locale_refresh_mixin.dart';
import '../theme/app_theme.dart';
import 'bottom_nav.dart';
import 'home_screen.dart';
import 'people_screen.dart';
import 'subscriptions_screen.dart';
import 'utilities_screen.dart';
import 'riyal_bot_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with LocaleRefreshState {
  int _index = 0;
  final _homeKey = GlobalKey<HomeBodyState>();

  @override
  void initState() {
    super.initState();
    // BottomNav's labels (nav_home/nav_subscriptions/...) would otherwise
    // stay stale until the next tab tap — MainShell only rebuilds on its
    // own tab-switch setState, same underlying issue as the tab bodies.
    addLocaleRefreshListener();
  }

  void _goToTab(int index) {
    // Re-tapping Home while already there resets its Overview/Analytics/
    // Accounts sub-tab back to Overview, instead of leaving whichever one
    // was last selected (IndexedStack keeps HomeBody's state alive).
    if (index == 0 && _index == 0) {
      _homeKey.currentState?.resetToOverview();
      return;
    }
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: IndexedStack(
        index: _index,
        children: [
          HomeBody(key: _homeKey),
          const SubscriptionsBody(),
          const UtilitiesBody(),
          const PeopleBody(),
        ],
      ),
      floatingActionButton: NavFab(
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const RiyalBotScreen())),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNav(index: _index, onTap: _goToTab),
    );
  }
}
