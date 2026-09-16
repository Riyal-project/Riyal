import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riyal/screens/connect_bank_screen.dart';
import 'package:riyal/screens/main_shell.dart';

void main() {
  testWidgets('new user can skip bank connection and enter the app', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: ConnectBankScreen(forced: true)),
    );
    expect(find.text('Skip now'), findsOneWidget);
    expect(find.text('Add manually from scratch'), findsOneWidget);

    await tester.tap(find.text('Skip now'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(MainShell), findsOneWidget);
  });

  testWidgets('manual bank connection does not show the signup skip action', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ConnectBankScreen()));
    expect(find.text('Skip now'), findsNothing);
    expect(find.text('Add manually from scratch'), findsNothing);
  });
}
