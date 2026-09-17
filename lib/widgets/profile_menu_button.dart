import 'action_confirmation.dart';
import 'package:flutter/material.dart';
import '../data/auth_store.dart';
import '../data/user_bank_accounts_store.dart';
import '../l10n/strings.dart';
import '../screens/profile_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/contact_us_screen.dart';
import '../screens/about_us_screen.dart';
import '../screens/login_screen.dart';
import '../theme/app_theme.dart';
import 'flipping_coin_icon.dart';
import 'hero_tags.dart';

class ProfileMenuButton extends StatelessWidget {
  const ProfileMenuButton({super.key});

  Future<void> _open(BuildContext context) async {
    final anchor = context.findRenderObject() as RenderBox;
    final action = await showDialog<String>(
      context: context,
      useSafeArea: false,
      barrierColor: AppColors.dialogBarrier,
      builder: (dialogContext) => LayoutBuilder(
        builder: (context, constraints) {
          final media = MediaQuery.of(context);
          final position = anchor.attached
              ? anchor.localToGlobal(Offset.zero)
              : Offset(12, media.padding.top);
          final width = (constraints.maxWidth - 24).clamp(0.0, 440.0);
          final left = position.dx.clamp(
            12.0,
            (constraints.maxWidth - width - 12).clamp(12.0, double.infinity),
          );
          final bottom =
              constraints.maxHeight -
              media.padding.bottom -
              media.viewInsets.bottom -
              12;
          final top =
              (position.dy + (anchor.attached ? anchor.size.height : 48) + 8)
                  .clamp(
                    media.padding.top + 8,
                    bottom.clamp(media.padding.top + 8, double.infinity),
                  );
          return Stack(
            children: [
              Positioned(
                left: left,
                top: top,
                width: width,
                child: Material(
                  color: AppColors.background,
                  elevation: 12,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                    side: const BorderSide(color: AppColors.cardBorder),
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: (bottom - top).clamp(0.0, 480.0),
                    ),
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 6),
                                    child: Text(
                                      Strings.t('account'),
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: Strings.t('close'),
                                  onPressed: () => Navigator.pop(dialogContext),
                                  icon: const Icon(
                                    Icons.close,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            for (final entry in const [
                              ('Profile', Icons.person_outline_rounded),
                              ('Settings', Icons.settings_outlined),
                              ('Help', Icons.help_outline_rounded),
                              ('About us', Icons.info_outline_rounded),
                            ])
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Material(
                                  color: AppColors.surface,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: const BorderSide(
                                      color: AppColors.cardBorder,
                                    ),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    leading: Icon(
                                      entry.$2,
                                      color: AppColors.gold,
                                    ),
                                    title: Text(
                                      switch (entry.$1) {
                                        'Profile' => Strings.t(
                                          'profile_menu_item',
                                        ),
                                        'Settings' => Strings.t(
                                          'settings_menu_item',
                                        ),
                                        'Help' => Strings.t(
                                          'contact_us_menu_item',
                                        ),
                                        _ => Strings.t('about_us_menu_item'),
                                      },
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    trailing: const Icon(
                                      Icons.chevron_right_rounded,
                                      color: AppColors.textSecondary,
                                    ),
                                    onTap: () =>
                                        Navigator.pop(dialogContext, entry.$1),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 16),
                            Center(
                              child: TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.statusCancelled,
                                ),
                                onPressed: () =>
                                    Navigator.pop(dialogContext, 'logout'),
                                icon: const Icon(
                                  Icons.logout_rounded,
                                  size: 20,
                                ),
                                label: Text(Strings.t('log_out')),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
    if (!context.mounted || action == null) return;
    if (action == 'logout') {
      final confirmed = await showActionConfirmation(
        context,
        title: Strings.t('logout_confirm_title'),
        message: Strings.t('logout_confirm_message'),
        confirmLabel: Strings.t('log_out'),
      );
      if (confirmed != true || !context.mounted) return;
      await AuthStore.instance.signOut();
      UserBankAccountsStore.instance.clear();
      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
        (_) => false,
      );
      return;
    }
    final Widget page = switch (action) {
      'Profile' => const ProfileScreen(),
      'Settings' => const SettingsScreen(),
      'Help' => const ContactUsScreen(),
      _ => const AboutUsScreen(),
    };
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: Strings.t('account_menu'),
    padding: EdgeInsets.zero,
    onPressed: () => _open(context),
    icon: const Hero(tag: heroAppCoinTag, child: FlippingCoinIcon()),
  );
}
