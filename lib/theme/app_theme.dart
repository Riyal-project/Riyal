import 'package:flutter/material.dart';

import 'app_typography.dart';

/// Colors match the Riyal App Design (Claude Design project), converted
/// from their source OKLCH values to sRGB. Dark forest-green surfaces with
/// a warm gold accent.
class AppColors {
  AppColors._();

  // Surfaces — darkest to lightest: elevated/nav sits below the page
  // background on purpose (a grounded nav bar), cards sit above it.
  static const background = Color(0xFF031108);
  static const surface = Color(0xFF0A1B11);
  static const surfaceElevated = Color(0xFF020C05);

  // Borders/dividers — alpha baked in, matching the source design's
  // translucent oklch() values.
  static const cardBorder = Color(0x9918281E);
  static const dividerStrong = Color(0x8027382C);

  static const gold = Color(0xFFCBA960);
  static const goldDark = Color(0xFF9C7C3D);

  static const textPrimary = Color(0xFFF7F1E9);
  static const textSecondary = Color(0xFF9B998B);
  static const textTertiary = Color(0xFF747265);

  static const trackBackground = Color(0xFF23281F);

  // Category accents.
  static const subscriptions = Color(0xFFCBA960);
  static const utilities = Color(0xFF2CB3B3);
  static const people = Color(0xFFBD7D60);

  // Subscription/tracked-item status accents.
  static const statusActive = Color(0xFF6CC581);
  static const statusTrial = Color(0xFFD8B260);
  static const statusCancelled = Color(0xFFE2726B);
  static const statusPaused = Color(0xFF908F89);

  // Gold-filled chrome (buttons, chips) needs a dark foreground; a lighter
  // gold shows up in one button's border gradient (signup).
  static const goldForeground = Color(0xFF1B1F16);
  static const goldLight = Color(0xFFD9C68A);

  /// Black at the alpha values used behind modal sheets/dialogs and under
  /// small floating buttons — baked into the alpha channel so both stay
  /// compile-time constants instead of a `.withValues()` call.
  static const dialogBarrier = Color(0x2E000000); // 18%
  static const softShadow = Color(0x40000000); // 25%

  static const errorText = Color(0xFFECA5A5);

  /// The fourth onboarding slide's accent — the other three reuse the
  /// category colors above; this one has no existing counterpart.
  static const onboardingAnalyticsAccent = Color(0xFF82C7A8);

  // People catalog/seed role accents — named once here instead of the same
  // hex repeated across people_catalog.dart and people_store.dart.
  static const peopleDriving = Color(0xFF37474F);
  static const peopleHousekeeping = Color(0xFF6B7A3A);
  static const peopleChildcare = Color(0xFFC2637A);
  static const peopleGardening = Color(0xFF4C7A3A);
  static const peopleSecurity = Color(0xFF7A3A3A);
  static const peopleTutoring = Color(0xFF3A5A7A);
  static const peopleAssistant = Color(0xFF6A5A8A);

  // Utility catalog/seed role accents.
  static const utilityGas = Color(0xFFB44622);
  static const utilityOther = Color(0xFF546E7A);
  static const utilityWater = Color(0xFF2B6CB0);
}

/// Builds the app theme for the given language — body/UI text renders in
/// Inter for English or IBM Plex Sans Arabic for Arabic (see
/// [AppTypography]), so this should be rebuilt whenever the app's locale
/// changes rather than built once at startup.
ThemeData buildAppTheme({String languageCode = 'en'}) {
  const baseTextTheme = TextTheme(
    bodyMedium: TextStyle(color: AppColors.textPrimary),
  );
  final textTheme = AppTypography.textTheme(languageCode, baseTextTheme).apply(
    bodyColor: AppColors.textPrimary,
    displayColor: AppColors.textPrimary,
  );

  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.background,
    brightness: Brightness.dark,
    fontFamily: textTheme.bodyMedium?.fontFamily,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.gold,
      brightness: Brightness.dark,
      surface: AppColors.surface,
    ),
    textTheme: textTheme,
  );
}
