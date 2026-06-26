import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/collections/providers/collections_provider.dart';
import 'package:tonkatsu_box/features/recommendations/providers/recommendations_provider.dart';
import 'package:tonkatsu_box/features/recommendations/screens/recommendations_screen.dart';
import 'package:tonkatsu_box/features/recommendations/widgets/recommendation_row.dart';
import 'package:tonkatsu_box/shared/models/collection.dart';
import 'package:tonkatsu_box/shared/models/media_type.dart';

import '../../../helpers/test_helpers.dart';

class _FakeCollectionsNotifier extends CollectionsNotifier {
  _FakeCollectionsNotifier(this._collections);

  final List<Collection> _collections;

  @override
  Future<List<Collection>> build() async => _collections;
}

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

RecommendationRowUi _row(String header) => RecommendationRowUi(
      becauseTitles: <String>[header],
      genres: const <String>['Action'],
      items: <RecommendedItem>[_item('$header-1'), _item('$header-2')],
    );

List<Override> _overrides(RecommendationResult result) => <Override>[
      collectionsProvider
          .overrideWith(() => _FakeCollectionsNotifier(<Collection>[])),
      recommendationsProvider.overrideWith((Ref ref) async => result),
      collectedRecommendationIdsProvider
          .overrideWith((Ref ref) async => <String>{}),
    ];

void main() {
  group('RecommendationsScreen', () {
    testWidgets('shows the empty panel and no rows when there is no taste', (
      WidgetTester tester,
    ) async {
      await tester.pumpApp(
        const RecommendationsScreen(),
        overrides: _overrides(
          const RecommendationResult.state(RecommendationStatus.empty),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(RecommendationsEmptyState), findsOneWidget);
      expect(find.byType(RecommendationRowWidget), findsNothing);
    });

    testWidgets('shows the empty panel when no candidates came back', (
      WidgetTester tester,
    ) async {
      await tester.pumpApp(
        const RecommendationsScreen(),
        overrides: _overrides(
          const RecommendationResult.state(RecommendationStatus.noCandidates),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(RecommendationsEmptyState), findsOneWidget);
      expect(find.byType(RecommendationRowWidget), findsNothing);
    });

    testWidgets('shows the empty panel when the TMDB key is missing', (
      WidgetTester tester,
    ) async {
      await tester.pumpApp(
        const RecommendationsScreen(),
        overrides: _overrides(
          const RecommendationResult.state(RecommendationStatus.noApiKey),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(RecommendationsEmptyState), findsOneWidget);
      expect(find.byType(RecommendationRowWidget), findsNothing);
    });

    testWidgets('renders one row widget per ready row', (
      WidgetTester tester,
    ) async {
      await tester.pumpApp(
        const RecommendationsScreen(),
        overrides: _overrides(
          RecommendationResult(
            status: RecommendationStatus.ready,
            rows: <RecommendationRowUi>[_row('A'), _row('B')],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(RecommendationsEmptyState), findsNothing);
      expect(find.byType(RecommendationRowWidget), findsNWidgets(2));
    });
  });
}
