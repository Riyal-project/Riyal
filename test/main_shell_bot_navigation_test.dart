import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riyal/screens/main_shell.dart';
import 'package:riyal/screens/riyal_bot_screen.dart';

void main() {
  testWidgets('the center coin opens Riyal Bot', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MainShell()));
    await tester.pump();

    expect(find.byType(FloatingActionButton), findsOneWidget);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.byType(RiyalBotScreen), findsOneWidget);
    expect(find.text('Riyal'), findsWidgets);
  });
}
