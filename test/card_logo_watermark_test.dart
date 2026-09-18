import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riyal/widgets/card_logo_watermark.dart';

void main() {
  // CardLogoWatermark sizes itself by card width only (not height), so it
  // can be bigger than a card that shrink-wraps short content — callers are
  // expected to pair it with `Stack(clipBehavior: Clip.none)` and a
  // clipping ancestor. These tests only check the width-based sizing
  // contract and that nothing throws, not full containment.
  for (final size in [
    const Size(320, 100),
    const Size(375, 180),
    const Size(430, 280),
  ]) {
    testWidgets('scales with card width for a ${size.width}-wide card', (
      tester,
    ) async {
      final cardKey = UniqueKey();
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox.fromSize(
              key: cardKey,
              size: size,
              child: const Stack(
                clipBehavior: Clip.none,
                children: [
                  CardLogoWatermark(corner: WatermarkCorner.bottomEnd),
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Responsive card content'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final cardRect = tester.getRect(find.byKey(cardKey));
      final imageRect = tester.getRect(find.byType(Image));
      expect(imageRect.width, lessThanOrEqualTo(size.width * 0.52));
      expect(imageRect.right, lessThanOrEqualTo(cardRect.right));
      expect(imageRect.right, greaterThan(cardRect.right - size.width * 0.6));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a negative inset can push the coin past its content bounds', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: SizedBox(
            width: 300,
            height: 90,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                CardLogoWatermark(corner: WatermarkCorner.topEnd, inset: -10),
                Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('Short card content'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
