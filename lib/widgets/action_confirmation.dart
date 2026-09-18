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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      title: Text(title, style: const TextStyle(color: AppColors.textPrimary)),
      content: Text(
        message,
        style: const TextStyle(color: AppColors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
          ),
          child: Text(Strings.t('cancel')),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.statusCancelled,
          ),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
}
