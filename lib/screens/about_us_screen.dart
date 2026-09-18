import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/strings.dart';
import '../theme/app_theme.dart';
import '../widgets/account_section.dart';
import '../widgets/coin_back_button.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      backgroundColor: AppColors.background,
      leading: const CoinBackButton(),
      title: Text(Strings.t('about_us_title')),
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
                icon: Icons.account_balance_wallet_outlined,
                title: Strings.t('about_header_title'),
                subtitle: Strings.t('about_header_subtitle'),
              ),
              AccountSection(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Strings.t('about_our_purpose'),
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      Strings.t('about_our_purpose_body'),
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
                    _AboutFeature(
                      icon: Icons.repeat_rounded,
                      title: Strings.t('about_track_title'),
                      body: Strings.t('about_track_body'),
                    ),
                    const Divider(color: AppColors.cardBorder, height: 32),
                    _AboutFeature(
                      icon: Icons.donut_large_rounded,
                      title: Strings.t('about_plan_title'),
                      body: Strings.t('about_plan_body'),
                    ),
                    const Divider(color: AppColors.cardBorder, height: 32),
                    _AboutFeature(
                      icon: Icons.notifications_none_rounded,
                      title: Strings.t('about_reminders_title'),
                      body: Strings.t('about_reminders_body'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AccountSection(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Strings.t('about_developers_title'),
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _DeveloperName(
                              arabicName: 'فلوة اليحيى',
                              englishName: 'Fulwah Alyahya',
                              linkedInUrl:
                                  'https://www.linkedin.com/in/fulwah-alyahya-7037a9293',
                            ),
                          ),
                          VerticalDivider(
                            color: AppColors.cardBorder,
                            width: 24,
                          ),
                          Expanded(
                            child: _DeveloperName(
                              arabicName: 'دانه التميمي',
                              englishName: 'Danah Altamimi',
                              linkedInUrl:
                                  'https://www.linkedin.com/in/danah-altamimi-b2912141a',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    Text(
                      Strings.t('about_made_for_you'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'RIYAL  •  0.1.0',
                      style: TextStyle(
                        color: AppColors.gold,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _DeveloperName extends StatelessWidget {
  const _DeveloperName({
    required this.arabicName,
    required this.englishName,
    required this.linkedInUrl,
  });

  final String arabicName;
  final String englishName;
  final String linkedInUrl;

  Future<void> _openLinkedIn() =>
      launchUrl(Uri.parse(linkedInUrl), mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(16),
    onTap: _openLinkedIn,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.code_rounded,
              color: AppColors.gold,
              size: 22,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            arabicName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            englishName,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.link_rounded,
                color: AppColors.gold,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                Strings.t('linkedin_profile'),
                style: const TextStyle(
                  color: AppColors.gold,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _AboutFeature extends StatelessWidget {
  const _AboutFeature({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.gold.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: AppColors.gold, size: 23),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              body,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
