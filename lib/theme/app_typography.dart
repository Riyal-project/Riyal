import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Riyal's typography system — three fonts, each with one job:
///
/// - **General Sans** (bundled local asset, Bold/Semibold only — it isn't
///   on Google Fonts) for the "Riyal" wordmark and any other large
///   app-name/brand display text. Used explicitly via [wordmark], never
///   as the theme default.
/// - **Inter** (Google Fonts) for Latin body/UI text, and for every
///   amount/price/balance display regardless of locale — see [amount].
/// - **IBM Plex Sans Arabic** (Google Fonts) for Arabic body/UI text,
///   pulled in at the same [TextTheme] weights as Inter so the two
///   scripts read consistently side by side.
class AppTypography {
  AppTypography._();

  static const generalSansFamily = 'GeneralSans';
  static const List<String>? webSymbolFallback = kIsWeb
      ? ['RiyalSymbol']
      : null;

  /// The brand wordmark / large app-name display text (splash, login,
  /// signup, onboarding). Always General Sans, regardless of locale —
  /// it's a logotype, not body copy.
  static TextStyle wordmark({
    double fontSize = 20,
    FontWeight fontWeight = FontWeight.w700,
    Color? color,
    double? letterSpacing,
    double? height,
  }) {
    return TextStyle(
      fontFamily: generalSansFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  /// The full Material [TextTheme] for the app's current language —
  /// Inter for English, IBM Plex Sans Arabic for Arabic. Feed this into
  /// [ThemeData.textTheme] so ordinary `Text(...)` calls throughout the
  /// app pick up the right body font automatically without each one
  /// needing to know about locale.
  static TextTheme textTheme(String languageCode, TextTheme base) {
    return languageCode == 'ar'
        ? GoogleFonts.ibmPlexSansArabicTextTheme(base)
        : GoogleFonts.interTextTheme(base);
  }

  /// The bare font family name for the current language, for the rare
  /// spot that needs a [TextStyle] built by hand rather than pulled from
  /// the theme (e.g. a widget that doesn't have a `BuildContext` handy).
  static String fontFamilyFor(String languageCode) => languageCode == 'ar'
      ? GoogleFonts.ibmPlexSansArabic().fontFamily!
      : GoogleFonts.inter().fontFamily!;

  /// Just the Inter font family name, for the rare case where only the
  /// numeral portion of a larger, mixed-language sentence should switch
  /// fonts (via a [TextSpan]) rather than the whole [Text].
  static String get amountFontFamily => GoogleFonts.inter().fontFamily!;

  /// Every amount/price/balance display — Inter, regardless of locale.
  /// Its numeral shapes stay clearest at the small sizes this app shows
  /// money at, which is the whole point of calling it out separately from
  /// the locale-driven body font.
  static TextStyle amount({
    double? fontSize,
    FontWeight fontWeight = FontWeight.w600,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    ).copyWith(fontFamilyFallback: webSymbolFallback);
  }
}
