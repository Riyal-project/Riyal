import 'package:flutter/material.dart';
import '../l10n/strings.dart';
import '../theme/app_theme.dart';

Future<bool?> showActionConfirmation(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
}) {
  return showDialog<bool>(
    context: context,
    barrierColor: AppColors.dialogBarrier,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.surface,
      // Material 3 tints elevated surfaces with the theme's primary color by
      // default — without this, the dialog reads as a slightly different,
      // washed-out shade instead of matching the app's flat card surfaces.
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      // Default AlertDialog padding/type scale (titleLarge ~22px) reads as
      // bulky and out of step with the compact 16-18px headers used
      // everywhere else in the app — sized down to match.
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      actionsPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: Text(
          message,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: Text(Strings.t('cancel')),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.statusCancelled,
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
}
