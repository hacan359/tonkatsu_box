import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/collections/widgets/collection_table/cells/rating_cell.dart';
import 'package:tonkatsu_box/shared/widgets/fractional_star_rating.dart';

import '../../../../../helpers/test_helpers.dart';

void main() {
  group('RatingCell', () {
    testWidgets('shows a dash when rating is null', (WidgetTester t) async {
      await t.pumpApp(const RatingCell(rating: null), wrapInScaffold: true);
      expect(find.text('—'), findsOneWidget);
    });

    testWidgets('shows one-decimal value when rating is set',
        (WidgetTester t) async {
      await t.pumpApp(const RatingCell(rating: 8.5), wrapInScaffold: true);
      expect(find.text('8.5'), findsOneWidget);
    });

    Future<void> openPopup(WidgetTester t, ValueChanged<double?> onChanged,
        {double? rating}) async {
      await t.pumpApp(
        SizedBox(
          width: 60,
          child: RatingCell(rating: rating, onRatingChanged: onChanged),
        ),
        wrapInScaffold: true,
      );
      await t.tap(find.byType(RatingCell));
      await t.pumpAndSettle();
    }

    testWidgets('tapping a star edits live without closing or committing',
        (WidgetTester t) async {
      int calls = 0;
      await openPopup(t, (double? _) => calls++);

      await t.tap(find.byType(FractionalStarRating));
      await t.pumpAndSettle();

      expect(find.byType(FractionalStarRating), findsOneWidget); // still open
      expect(calls, 0); // not committed yet
    });

    testWidgets('OK commits the picked value once and closes',
        (WidgetTester t) async {
      int calls = 0;
      double? captured = -1;
      await openPopup(t, (double? v) {
        calls++;
        captured = v;
      });

      await t.tap(find.byType(FractionalStarRating));
      await t.pumpAndSettle();
      await t.tap(find.text('OK'));
      await t.pumpAndSettle();

      expect(calls, 1);
      expect(captured, isNotNull);
      expect(find.byType(FractionalStarRating), findsNothing);
    });

    testWidgets('tapping outside applies the current value', (WidgetTester t) async {
      int calls = 0;
      double? captured = -1;
      await openPopup(t, (double? v) {
        calls++;
        captured = v;
      });

      await t.tap(find.byType(FractionalStarRating));
      await t.pumpAndSettle();
      await t.tapAt(const Offset(5, 5)); // dismiss via barrier
      await t.pumpAndSettle();

      expect(calls, 1);
      expect(captured, isNotNull);
      expect(find.byType(FractionalStarRating), findsNothing);
    });

    testWidgets('closing without changes does not commit',
        (WidgetTester t) async {
      int calls = 0;
      await openPopup(t, (double? _) => calls++);

      await t.tapAt(const Offset(5, 5)); // dismiss without editing
      await t.pumpAndSettle();

      expect(calls, 0);
    });
  });
}
