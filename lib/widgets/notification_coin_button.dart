import 'dart:async';
import 'package:flutter/material.dart';
import '../data/notifications_store.dart';
import '../data/budget_store.dart';
import '../l10n/strings.dart';
import '../screens/notifications_screen.dart';
import '../theme/app_theme.dart';
import 'flipping_coin_icon.dart';

class NotificationCoinButton extends StatefulWidget {
  const NotificationCoinButton({super.key});
  @override
  State<NotificationCoinButton> createState() => _NotificationCoinButtonState();
}

class _NotificationCoinButtonState extends State<NotificationCoinButton>
    with WidgetsBindingObserver {
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    NotificationsStore.instance.refresh();
    unawaited(NotificationsStore.instance.readState.initialize());
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      BudgetStore.instance.recalculate();
      NotificationsStore.instance.refresh();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      BudgetStore.instance.recalculate();
      NotificationsStore.instance.refresh();
      unawaited(NotificationsStore.instance.readState.initialize());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: Strings.t('notifications_title'),
    onPressed: () => showNotificationsPreview(context),
    padding: EdgeInsets.zero,
    icon: ValueListenableBuilder<bool>(
      valueListenable: NotificationsStore.instance.readState.hasUnread,
      builder: (context, unread, _) => Semantics(
        label: unread
            ? Strings.t('unread_notifications')
            : Strings.t('notifications_title'),
        child: SizedBox(
          width: 47,
          height: 47,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Positioned.fill(
                child: FlippingCoinIcon(
                  frontIcon: Icons.notifications_none_rounded,
                  backIcon: Icons.notifications_active_outlined,
                ),
              ),
              if (unread)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: AppColors.statusCancelled,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.background,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
