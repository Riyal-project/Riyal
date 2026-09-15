import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riyal/screens/login_screen.dart';
import 'package:riyal/screens/onboarding_screen.dart';

void main() {
  testWidgets('language choice drives four onboarding slides then login', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));

    expect(find.text('Welcome to Riyal'), findsOneWidget);
    expect(find.text('مرحبًا بك في ريال'), findsOneWidget);

    await tester.tap(find.text('English'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.text('Every commitment in one place'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.text('Know before every payment'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.text('Review what you need and save'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.text('Understand your spending with Riyal'), findsOneWidget);

    await tester.tap(find.text('Start with Riyal'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
