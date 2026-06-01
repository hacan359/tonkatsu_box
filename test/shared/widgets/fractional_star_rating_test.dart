import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/shared/widgets/fractional_star_rating.dart';

void main() {
  // starSize 24 + gap 3 => cellWidth 27. Leading cell occupies [0, 27),
  // then 10 stars map [27, 297) onto integers 1..10.
  const double starSize = 24;
  const double cellWidth = starSize + 3;

  Widget build({
    required double? value,
    required ValueChanged<double?> onChanged,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: FractionalStarRating(
            value: value,
            starSize: starSize,
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  group('FractionalStarRating', () {
    testWidgets('tap on leading cell clears to null', (WidgetTester t) async {
      double? captured = -1;
      await t.pumpWidget(build(
        value: 5,
        onChanged: (double? v) => captured = v,
      ));

      await t.tapAt(const Offset(10, 10));
      expect(captured, isNull);
    });

    testWidgets('tap on the last star yields 10.0', (WidgetTester t) async {
      double? captured;
      await t.pumpWidget(build(
        value: null,
        onChanged: (double? v) => captured = v,
      ));

      await t.tapAt(const Offset(cellWidth * 11 - 1, 10));
      expect(captured, 10.0);
    });

    testWidgets('tap on the first star yields 1.0', (WidgetTester t) async {
      double? captured;
      await t.pumpWidget(build(
        value: null,
        onChanged: (double? v) => captured = v,
      ));

      await t.tapAt(const Offset(cellWidth + 1, 10));
      expect(captured, 1.0);
    });

    testWidgets('tap on a star yields a whole integer', (WidgetTester t) async {
      double? captured;
      await t.pumpWidget(build(
        value: null,
        onChanged: (double? v) => captured = v,
      ));

      // x in the 4th star region -> integer 4.0, never a fraction.
      await t.tapAt(const Offset(cellWidth + cellWidth * 3.5, 10));
      expect(captured, 4.0);
    });

    testWidgets('plus button nudges up by 0.1', (WidgetTester t) async {
      double? captured;
      await t.pumpWidget(build(
        value: 7.0,
        onChanged: (double? v) => captured = v,
      ));

      await t.tap(find.byIcon(Icons.add));
      expect(captured, 7.1);
    });

    testWidgets('minus button nudges down by 0.1', (WidgetTester t) async {
      double? captured;
      await t.pumpWidget(build(
        value: 7.0,
        onChanged: (double? v) => captured = v,
      ));

      await t.tap(find.byIcon(Icons.remove));
      expect(captured, 6.9);
    });

    testWidgets('nudge buttons do nothing while the rating is unset',
        (WidgetTester t) async {
      bool called = false;
      await t.pumpWidget(build(
        value: null,
        onChanged: (double? _) => called = true,
      ));

      await t.tap(find.byIcon(Icons.add));
      await t.tap(find.byIcon(Icons.remove));
      expect(called, isFalse);
    });

    testWidgets('plus does not re-emit at the maximum', (WidgetTester t) async {
      bool called = false;
      await t.pumpWidget(build(
        value: 10.0,
        onChanged: (double? _) => called = true,
      ));

      await t.tap(find.byIcon(Icons.add));
      expect(called, isFalse);
    });

    testWidgets('minus does not re-emit at the minimum',
        (WidgetTester t) async {
      bool called = false;
      await t.pumpWidget(build(
        value: 1.0,
        onChanged: (double? _) => called = true,
      ));

      await t.tap(find.byIcon(Icons.remove));
      expect(called, isFalse);
    });

    testWidgets('renders the leading clear cell', (WidgetTester t) async {
      await t.pumpWidget(build(value: 7.5, onChanged: (_) {}));
      expect(find.byIcon(Icons.do_not_disturb_alt), findsOneWidget);
    });

    testWidgets('does not overflow when the parent is narrower than natural',
        (WidgetTester t) async {
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              // Narrower than the natural width — the phone case.
              child: SizedBox(
                width: 200,
                child: FractionalStarRating(
                  value: 7.5,
                  starSize: starSize,
                  onChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      );

      expect(t.takeException(), isNull);
    });
  });
}
