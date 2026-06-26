import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/recommendations/providers/recommendations_provider.dart';
import 'package:tonkatsu_box/features/recommendations/widgets/recommendation_row.dart';
import 'package:tonkatsu_box/shared/models/media_type.dart';
import 'package:tonkatsu_box/shared/widgets/media_poster_card.dart';

import '../../../helpers/test_helpers.dart';

RecommendedItem _item(String title) => RecommendedItem(
  tasteId: 'movie:$title',
  media: Object(),
  mediaType: MediaType.movie,
  tmdbId: 1,
  title: title,
  posterUrl: null,
  year: 2000,
  apiRating: 7,
  score: 0.5,
  predictedRating: 8,
);

void main() {
  group('RecommendationRowWidget', () {
    testWidgets('renders one card per item', (WidgetTester tester) async {
      await tester.pumpApp(
        RecommendationRowWidget(
          eyebrow: 'Because you liked',
          headline: 'A',
          genres: const <String>['Action', 'War'],
          items: <RecommendedItem>[_item('One'), _item('Two')],
          onTap: (_) {},
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(MediaPosterCard), findsNWidgets(2));
    });

    testWidgets('renders the rationale genres', (WidgetTester tester) async {
      await tester.pumpApp(
        RecommendationRowWidget(
          eyebrow: 'Because you liked',
          headline: 'A',
          genres: const <String>['Action', 'War'],
          items: <RecommendedItem>[_item('One')],
          onTap: (_) {},
        ),
      );

      expect(find.textContaining('Action'), findsOneWidget);
    });

    testWidgets('renders nothing when there are no items', (
      WidgetTester tester,
    ) async {
      await tester.pumpApp(
        RecommendationRowWidget(
          eyebrow: 'Because you liked',
          headline: 'A',
          genres: const <String>['Action'],
          items: const <RecommendedItem>[],
          onTap: (_) {},
        ),
      );

      expect(find.byType(MediaPosterCard), findsNothing);
    });

    testWidgets('fires onTap with the tapped item', (
      WidgetTester tester,
    ) async {
      RecommendedItem? tapped;
      final RecommendedItem first = _item('One');
      await tester.pumpApp(
        RecommendationRowWidget(
          eyebrow: 'Because you liked',
          headline: 'A',
          genres: const <String>['Action'],
          items: <RecommendedItem>[first, _item('Two')],
          onTap: (RecommendedItem item) => tapped = item,
        ),
      );

      await tester.tap(find.byType(MediaPosterCard).first);
      await tester.pumpAndSettle();

      expect(tapped, same(first));
    });

    testWidgets('does not fire onTap for an item already added', (
      WidgetTester tester,
    ) async {
      RecommendedItem? tapped;
      await tester.pumpApp(
        RecommendationRowWidget(
          eyebrow: 'Because you liked',
          headline: 'A',
          genres: const <String>['Action'],
          items: <RecommendedItem>[_item('One'), _item('Two')],
          ownedIds: const <String>{'movie:One'},
          onTap: (RecommendedItem item) => tapped = item,
        ),
      );

      // 'One' is owned -> its card is non-interactive, so the tap misses by
      // design (warnIfMissed: false) and no callback fires.
      await tester.tap(find.byType(MediaPosterCard).first, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(tapped, isNull);
    });
  });
}
