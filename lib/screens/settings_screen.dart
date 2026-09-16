import 'package:flutter/material.dart';
import '../data/app_settings.dart';
import '../data/notifications_store.dart';
import '../l10n/app_locale.dart';
import '../l10n/strings.dart';
import '../theme/app_theme.dart';
import '../widgets/account_section.dart';
import '../widgets/coin_back_button.dart';
import 'accounts_screen.dart';
import 'profile_screen.dart';
import 'contact_us_screen.dart';
import 'about_us_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _settings = AppSettings.instance;
  bool _saving = false;
  bool _changingLanguage = false;

  Future<void> _save(bool enabled, int days) async {
    setState(() => _saving = true);
    try {
      await _settings
          .save(enabled: enabled, days: days)
          .timeout(const Duration(seconds: 5));
      NotificationsStore.instance.refresh();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(Strings.t('settings_saved'))));
      }
    } catch (error) {
      debugPrint('Settings save failed: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(Strings.t('settings_save_failed'))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _setLanguage(String code) async {
    if (_settings.languageCode == code) return;
    setState(() => _changingLanguage = true);
    try {
      await AppLocale.set(Locale(code)).timeout(const Duration(seconds: 5));
    } catch (error) {
      debugPrint('Language change failed: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(Strings.t('settings_save_failed'))),
        );
      }
    } finally {
      if (mounted) setState(() => _changingLanguage = false);
    }
  }

  Future<void> _saveMonthlyReview(bool enabled, int day) async {
    setState(() => _saving = true);
    try {
      await _settings
          .saveMonthlyReview(enabled: enabled, day: day)
          .timeout(const Duration(seconds: 5));
      NotificationsStore.instance.refresh();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(Strings.t('settings_saved'))));
      }
    } catch (error) {
      debugPrint('Monthly review setting save failed: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(Strings.t('settings_save_failed'))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      backgroundColor: AppColors.background,
      leading: const CoinBackButton(),
      title: Text(Strings.t('settings_title')),
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AccountPageHeader(
                icon: Icons.settings_outlined,
                title: Strings.t('settings_header_title'),
                subtitle: Strings.t('settings_header_subtitle'),
              ),
              AccountSection(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Strings.t('payment_reminders_section'),
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      activeTrackColor: AppColors.gold,
                      title: Text(
                        Strings.t('upcoming_payments'),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        Strings.t('upcoming_payments_sub'),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      value: _settings.paymentReminders,
                      onChanged: _saving
                          ? null
                          : (value) => _save(value, _settings.reminderDays),
                    ),
                    const Divider(color: AppColors.cardBorder, height: 28),
                    Text(
                      Strings.t('remind_before_payment'),
                      style: const TextStyle(color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final days in [1, 3, 5, 7])
                          ChoiceChip(
                            label: Text(
                              '$days ${days == 1 ? Strings.t('day_singular') : Strings.t('day_plural')}',
                            ),
                            selected: _settings.reminderDays == days,
                            selectedColor: AppColors.gold,
                            labelStyle: TextStyle(
                              color: _settings.reminderDays == days
                                  ? AppColors.background
                                  : AppColors.textSecondary,
                            ),
                            onSelected: _saving || !_settings.paymentReminders
                                ? null
                                : (_) => _save(true, days),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      Strings.t('reminder_note'),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.6,
                      ),
                    ),
                    const Divider(color: AppColors.cardBorder, height: 32),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      activeTrackColor: AppColors.gold,
                      title: Text(
                        Strings.t('monthly_review_setting'),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        Strings.t('monthly_review_setting_sub'),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      value: _settings.monthlyReviewReminders,
                      onChanged: _saving
                          ? null
                          : (value) => _saveMonthlyReview(
                              value,
                              _settings.monthlyReviewDay,
                            ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      Strings.t('monthly_review_day'),
                      style: const TextStyle(color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final day in [1, 15, 28])
                          ChoiceChip(
                            label: Text(Strings.f('day_of_month', '$day')),
                            selected: _settings.monthlyReviewDay == day,
                            selectedColor: AppColors.gold,
                            labelStyle: TextStyle(
                              color: _settings.monthlyReviewDay == day
                                  ? AppColors.background
                                  : AppColors.textSecondary,
                            ),
                            onSelected:
                                _saving || !_settings.monthlyReviewReminders
                                ? null
                                : (_) => _saveMonthlyReview(true, day),
                          ),
                      ],
                    ),
                    if (_saving)
                      const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: LinearProgressIndicator(color: AppColors.gold),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AccountSection(
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.person_outline,
                        color: AppColors.gold,
                      ),
                      title: Text(Strings.t('personal_details')),
                      subtitle: Text(Strings.t('personal_details_sub')),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: AppColors.gold,
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const ProfileScreen(),
                        ),
                      ),
                    ),
                    const Divider(color: AppColors.cardBorder),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.account_balance_outlined,
                        color: AppColors.gold,
                      ),
                      title: Text(Strings.t('accounts_title')),
                      subtitle: Text(Strings.t('accounts_sub')),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: AppColors.gold,
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const AccountsScreen(),
                        ),
                      ),
                    ),
                    const Divider(color: AppColors.cardBorder),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.payments_outlined,
                        color: AppColors.gold,
                      ),
                      title: Text(Strings.t('currency')),
                      subtitle: Text(Strings.t('currency_sub')),
                      trailing: const Text(
                        '⃁',
                        style: TextStyle(
                          color: AppColors.gold,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Divider(color: AppColors.cardBorder),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.dark_mode_outlined,
                        color: AppColors.gold,
                      ),
                      title: Text(Strings.t('appearance')),
                      subtitle: Text(Strings.t('appearance_sub')),
                      trailing: const Icon(
                        Icons.check_circle_outline,
                        color: AppColors.gold,
                      ),
                    ),
                    const Divider(color: AppColors.cardBorder),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.language_outlined,
                        color: AppColors.gold,
                      ),
                      title: Text(Strings.t('language')),
                      subtitle: Text(Strings.t('language_sub')),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            label: Text(Strings.t('language_english')),
                            selected: _settings.languageCode == 'en',
                            selectedColor: AppColors.gold,
                            labelStyle: TextStyle(
                              color: _settings.languageCode == 'en'
                                  ? AppColors.background
                                  : AppColors.textSecondary,
                            ),
                            onSelected: _changingLanguage
                                ? null
                                : (_) => _setLanguage('en'),
                          ),
                          ChoiceChip(
                            label: Text(Strings.t('language_arabic')),
                            selected: _settings.languageCode == 'ar',
                            selectedColor: AppColors.gold,
                            labelStyle: TextStyle(
                              color: _settings.languageCode == 'ar'
                                  ? AppColors.background
                                  : AppColors.textSecondary,
                            ),
                            onSelected: _changingLanguage
                                ? null
                                : (_) => _setLanguage('ar'),
                          ),
                        ],
                      ),
                    ),
                    if (_changingLanguage)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: LinearProgressIndicator(color: AppColors.gold),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AccountSection(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.shield_outlined,
                          color: AppColors.gold,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          Strings.t('data_on_device_title'),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      Strings.t('data_on_device_body'),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AccountSection(
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.help_outline,
                        color: AppColors.gold,
                      ),
                      title: Text(Strings.t('help_feedback')),
                      subtitle: Text(Strings.t('help_feedback_sub')),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: AppColors.gold,
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const ContactUsScreen(),
                        ),
                      ),
                    ),
                    const Divider(color: AppColors.cardBorder),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.gold,
                      ),
                      title: Text(Strings.t('about_us_menu_item')),
                      subtitle: Text(Strings.t('about_us_menu_subtitle')),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: AppColors.gold,
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const AboutUsScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  Strings.t('settings_footer'),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    letterSpacing: 1.5,
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
