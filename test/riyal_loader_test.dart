import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:riyal/widgets/riyal_loader.dart';

void main() {
  Matrix4 flip(WidgetTester tester) => tester
      .widget<Transform>(
        find.descendant(
          of: find.byType(RiyalLoader),
          matching: find.byType(Transform),
        ),
      )
      .transform;

  testWidgets('a small coin with the Riyal logo that keeps flipping', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: RiyalLoader())),
      ),
    );
    expect(find.byType(SvgPicture), findsOneWidget); // the Riyal logo
    expect(tester.getSize(find.byType(RiyalLoader)), const Size(34, 34));

    final seen = <double>{};
    for (var i = 0; i < 12; i++) {
      seen.add(flip(tester).getRow(0).x);
      await tester.pump(const Duration(milliseconds: 100));
    }
    // The coin turns through face-on and edge-on positions, repeatedly.
    expect(seen.length, greaterThan(4));
    expect(seen.reduce((a, b) => a < b ? a : b), lessThan(0.5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('stays still with reduce-motion on', (tester) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: MaterialApp(
          home: Scaffold(body: Center(child: RiyalLoader(size: 20))),
        ),
      ),
    );
    final first = flip(tester).storage.toList();
    await tester.pump(const Duration(milliseconds: 400));
    expect(flip(tester).storage.toList(), first);
  });
}
