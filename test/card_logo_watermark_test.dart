import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riyal/widgets/card_logo_watermark.dart';

void main() {
  for (final size in [
    const Size(320, 100),
    const Size(375, 180),
    const Size(430, 280),
  ]) {
    testWidgets(
      'watermark fits fully inside a ${size.width} x ${size.height} card',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Center(
              child: SizedBox.fromSize(
                size: size,
                child: const Stack(
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

        final cardRect = tester.getRect(find.byType(Stack));
        final imageRect = tester.getRect(find.byType(Image));
        expect(cardRect.contains(imageRect.topLeft), isTrue);
        expect(cardRect.contains(imageRect.bottomRight), isTrue);
        expect(imageRect.width, lessThanOrEqualTo(size.width * 0.34));
        expect(imageRect.height, lessThanOrEqualTo(size.height - 20));
        expect(tester.takeException(), isNull);
      },
    );
  }
}
