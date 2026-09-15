import 'package:flutter/material.dart';

import '../data/subscription.dart';
import '../l10n/strings.dart';
import '../theme/app_theme.dart';

String trialDateLabel(DateTime date) =>
    '${date.day}/${date.month}/${date.year}';

class FreeTrialFields extends StatelessWidget {
  const FreeTrialFields({
    super.key,
    required this.enabled,
    required this.duration,
    required this.startDate,
    required this.onEnabledChanged,
    required this.onDurationChanged,
    required this.onStartDateChanged,
  });

  final bool enabled;
  final FreeTrialDuration duration;
  final DateTime startDate;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<FreeTrialDuration> onDurationChanged;
  final ValueChanged<DateTime> onStartDateChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: Text(Strings.t('free_trial')),
        secondary: const Icon(
          Icons.hourglass_top_rounded,
          color: AppColors.gold,
        ),
        value: enabled,
        onChanged: onEnabledChanged,
      ),
      if (enabled) ...[
        Text(
          Strings.t('trial_duration'),
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          children: [
            for (final option in FreeTrialDuration.values)
              ChoiceChip(
                label: Text(
                  Strings.t(
                    option == FreeTrialDuration.week
                        ? 'trial_week'
                        : 'trial_month',
                  ),
                ),
                selected: duration == option,
                onSelected: (_) => onDurationChanged(option),
              ),
          ],
        ),
        const SizedBox(height: 8),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(
            Icons.calendar_today_rounded,
            color: AppColors.gold,
          ),
          title: Text(Strings.t('trial_start_date')),
          subtitle: Text(trialDateLabel(startDate)),
          onTap: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: startDate,
              firstDate: DateTime(now.year - 5),
              lastDate: DateTime(now.year + 5, 12, 31),
            );
            if (picked != null) onStartDateChanged(picked);
          },
        ),
        Text(
          '${Strings.t('trial_end_date')}: '
          '${trialDateLabel(freeTrialEndDate(startDate, duration))}',
          style: const TextStyle(color: AppColors.gold),
        ),
        const SizedBox(height: 8),
        Text(
          Strings.t('trial_reminder_hint'),
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 18),
      ],
    ],
  );
}

class FreeTrialBadge extends StatelessWidget {
  const FreeTrialBadge({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: AppColors.statusTrial.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      Strings.t('free_trial'),
      style: const TextStyle(
        color: AppColors.statusTrial,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
