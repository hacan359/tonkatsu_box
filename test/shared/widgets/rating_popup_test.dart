import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/shared/widgets/fractional_star_rating.dart';
import 'package:tonkatsu_box/shared/widgets/rating_popup.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('showRatingPopup', () {
    Future<void> open(
      WidgetTester tester,
      ValueChanged<double?> onCommit, {
      double? initial,
    }) async {
      await tester.pumpApp(
        Builder(
          builder: (BuildContext context) => TextButton(
            onPressed: () => showRatingPopup(
              context,
              initial: initial,
              onCommit: onCommit,
            ),
            child: const Text('rate'),
          ),
        ),
        wrapInScaffold: true,
      );
      await tester.tap(find.text('rate'));
      await tester.pumpAndSettle();
    }

    testWidgets('opens the star picker under the anchor',
        (WidgetTester tester) async {
      await open(tester, (double? _) {});

      expect(find.byType(FractionalStarRating), findsOneWidget);
      expect(
        tester.getTopLeft(find.byType(FractionalStarRating)).dy,
        greaterThan(tester.getBottomLeft(find.text('rate')).dy - 1),
      );
    });

    testWidgets('does not commit when dismissed unchanged',
        (WidgetTester tester) async {
      int calls = 0;
      await open(tester, (double? _) => calls++, initial: 7.0);

      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      expect(calls, 0);
      expect(find.byType(FractionalStarRating), findsNothing);
    });

    testWidgets('commits the picked value once on OK',
        (WidgetTester tester) async {
      final List<double?> values = <double?>[];
      await open(tester, values.add);

      await tester.tap(find.byType(FractionalStarRating));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(values, hasLength(1));
      expect(values.single, inInclusiveRange(1.0, 10.0));
    });

    testWidgets('the clear cell commits null for a rated unit',
        (WidgetTester tester) async {
      final List<double?> values = <double?>[];
      await open(tester, values.add, initial: 7.0);

      final Rect stars = tester.getRect(find.byType(FractionalStarRating));
      // The leading cell is the clear slot.
      await tester.tapAt(Offset(stars.left + 4, stars.center.dy));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(values, <double?>[null]);
    });
  });
}
