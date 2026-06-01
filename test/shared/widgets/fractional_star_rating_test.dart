import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/shared/widgets/fractional_star_rating.dart';

void main() {
  // starSize 24 + gap 3 => cellWidth 27. Leading cell occupies [0, 27),
  // then 10 stars map [27, 297) onto rating 1.0..10.0.
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

    testWidgets('tap near right edge yields 10.0 (clamped)',
        (WidgetTester t) async {
      double? captured;
      await t.pumpWidget(build(
        value: null,
        onChanged: (double? v) => captured = v,
      ));

      await t.tapAt(const Offset(cellWidth * 11 - 1, 10));
      expect(captured, 10.0);
    });

    testWidgets('tap just past leading cell clamps up to 1.0',
        (WidgetTester t) async {
      double? captured;
      await t.pumpWidget(build(
        value: null,
        onChanged: (double? v) => captured = v,
      ));

      await t.tapAt(const Offset(cellWidth + 1, 10));
      expect(captured, 1.0);
    });

    testWidgets('tap mid-bar yields a fractional value on 0.1 grid',
        (WidgetTester t) async {
      double? captured;
      await t.pumpWidget(build(
        value: null,
        onChanged: (double? v) => captured = v,
      ));

      // x in the 5th star region -> roughly 4.5.
      await t.tapAt(const Offset(cellWidth + cellWidth * 3.5, 10));
      expect(captured, isNotNull);
      // Value is rounded to a 0.1 grid.
      expect((captured! * 10).roundToDouble(), captured! * 10);
      expect(captured, greaterThanOrEqualTo(1.0));
      expect(captured, lessThanOrEqualTo(10.0));
    });

    testWidgets('renders the leading clear cell', (WidgetTester t) async {
      await t.pumpWidget(build(value: 7.5, onChanged: (_) {}));
      expect(find.byIcon(Icons.do_not_disturb_alt), findsOneWidget);
    });

    testWidgets('a drag emits onChanged once on release, not per move',
        (WidgetTester t) async {
      final List<double?> emitted = <double?>[];
      await t.pumpWidget(build(
        value: null,
        onChanged: emitted.add,
      ));

      await t.drag(find.byType(FractionalStarRating), const Offset(120, 0));
      await t.pumpAndSettle();

      expect(emitted.length, 1);
      expect(emitted.single, isNotNull);
    });

    testWidgets('does not overflow when the parent is narrower than natural',
        (WidgetTester t) async {
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              // Narrower than 11 * (starSize + gap) — the phone case.
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
