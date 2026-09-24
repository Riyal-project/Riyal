import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:riyal/data/account_session.dart';
import 'package:riyal/screens/main_shell.dart';
import 'package:riyal/screens/onboarding_screen.dart';
import 'package:riyal/screens/splash_screen.dart';

/// Plays the splash through: its animation, the short pause after it, then the
/// fade to the next screen. Restoring the saved login reads storage, which
/// resumes on the real event loop, so each fake-time step is preceded by a
/// short real-time wait.
Future<void> runSplash(WidgetTester tester) async {
  await tester.pumpWidget(const MaterialApp(home: SplashScreen()));
  for (var i = 0; i < 12; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 400));
  }
}

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('someone who is logged out sees onboarding after the splash', (
    tester,
  ) async {
    await runSplash(tester);

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.byType(MainShell), findsNothing);
  });

  testWidgets('someone who is logged in goes from the splash to the app', (
    tester,
  ) async {
    await tester.runAsync(
      () => AccountSession.instance.signUp('back@x.com', 'correct horse'),
    );
    await runSplash(tester);

    expect(find.byType(MainShell), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsNothing);
  });

  testWidgets('after logging out the splash leads to onboarding again', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await AccountSession.instance.signUp('back@x.com', 'correct horse');
      await AccountSession.instance.signOut();
    });
    await runSplash(tester);

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.byType(MainShell), findsNothing);
  });
}
