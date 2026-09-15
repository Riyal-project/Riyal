import 'package:flutter/material.dart';

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

class _MainShellState extends State<MainShell> {
  int _index = 0;
  final _homeKey = GlobalKey<HomeBodyState>();

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
