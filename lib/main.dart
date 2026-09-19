import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';
import 'data/account_session.dart';
import 'data/app_settings.dart';
import 'data/budget_store.dart';
import 'data/monthly_review.dart';
import 'data/subscriptions_store.dart';
import 'data/supabase_config.dart';
import 'data/user_bank_accounts_store.dart';
import 'l10n/app_locale.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load();
  } catch (error) {
    debugPrint('.env load failed: $error');
  }
  try {
    await AppSettings.instance.load().timeout(const Duration(seconds: 3));
  } catch (error) {
    debugPrint('Settings load failed: $error');
  }
  try {
    await AccountSession.instance.load().timeout(const Duration(seconds: 3));
  } catch (error) {
    debugPrint('Session load failed: $error');
  }
  try {
    await MonthlyReviewStore.instance.initialize().timeout(
      const Duration(seconds: 3),
    );
  } catch (error) {
    debugPrint('Monthly review load failed: $error');
  }
  try {
    await SupabaseConfig.initialize().timeout(const Duration(seconds: 5));
    await SubscriptionsStore.instance.load().timeout(
      const Duration(seconds: 5),
    );
    await UserBankAccountsStore.instance.load().timeout(
      const Duration(seconds: 5),
    );
  } catch (error) {
    debugPrint('Supabase init/load failed: $error');
  }
  try {
    await BudgetStore.instance.load().timeout(const Duration(seconds: 3));
  } catch (error) {
    debugPrint('Budget load failed: $error');
  }
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: AppLocale.locale,
      builder: (context, locale, _) => MaterialApp(
        title: 'Riyal',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(languageCode: locale.languageCode),
        locale: locale,
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const SplashScreen(),
      ),
    );
  }
}
