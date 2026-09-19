import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:riyal/screens/home_screen.dart';
import 'package:riyal/theme/app_theme.dart';
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

  testWidgets('pulling down on Home shows the coin and refreshes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: const Scaffold(body: HomeBody()),
      ),
    );
    await tester.pump();
    expect(find.byType(RiyalLoader), findsNothing); // nothing while idle

    await tester.drag(
      find.byType(CustomScrollView).first,
      const Offset(0, 260),
    );
    await tester.pump();
    expect(find.byType(RiyalLoader), findsOneWidget);

    // Let the refresh run (offline here, so its steps are skipped) and settle.
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });
}
