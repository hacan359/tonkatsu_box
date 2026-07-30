import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/genre_cloud/providers/genre_cloud_provider.dart';
import 'package:tonkatsu_box/features/genre_cloud/screens/genre_cloud_screen.dart';
import 'package:tonkatsu_box/features/personalization/screens/personalization_screen.dart';
import 'package:tonkatsu_box/features/recommendations/providers/recommendations_provider.dart';
import 'package:tonkatsu_box/features/recommendations/screens/recommendations_screen.dart';
import 'package:tonkatsu_box/features/statistics/providers/statistics_provider.dart';
import 'package:tonkatsu_box/features/statistics/screens/statistics_screen.dart';
import 'package:tonkatsu_box/shared/models/collection_item.dart';
import 'package:tonkatsu_box/shared/widgets/segmented_pill.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('PersonalizationScreen', () {
    List<Override> overrides() => <Override>[
          libraryStatsProvider.overrideWith(
            (Ref ref) async => createEmptyLibraryStats(),
          ),
          genreCloudItemsProvider.overrideWith(
            (Ref ref) =>
                const AsyncValue<List<CollectionItem>>.data(<CollectionItem>[]),
          ),
          recommendationsProvider.overrideWith(
            (Ref ref) async =>
                const RecommendationResult.state(RecommendationStatus.empty),
          ),
          collectedRecommendationIdsProvider
              .overrideWith((Ref ref) async => <String>{}),
        ];

    Finder segments() => find.descendant(
          of: find.byWidgetPredicate((Widget w) => w is SegmentedPill),
          matching: find.byType(GestureDetector),
        );

    testWidgets('shows statistics first, without exceptions', (
      WidgetTester tester,
    ) async {
      await tester.pumpApp(
        const PersonalizationScreen(),
        overrides: overrides(),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(StatisticsScreen), findsOneWidget);
      // Hidden views must not be built at all (lazy tabs).
      expect(find.byType(GenreCloudScreen), findsNothing);
      expect(find.byType(RecommendationsScreen), findsNothing);
    });

    testWidgets('switches between all three views via the pill', (
      WidgetTester tester,
    ) async {
      await tester.pumpApp(
        const PersonalizationScreen(),
        overrides: overrides(),
      );

      await tester.tap(segments().at(1));
      await tester.pumpAndSettle();
      expect(find.byType(GenreCloudScreen), findsOneWidget);
      expect(find.byType(StatisticsScreen), findsNothing);

      await tester.tap(segments().at(2));
      await tester.pumpAndSettle();
      expect(find.byType(RecommendationsScreen), findsOneWidget);
      expect(find.byType(GenreCloudScreen), findsNothing);

      await tester.tap(segments().at(0));
      await tester.pumpAndSettle();
      expect(find.byType(StatisticsScreen), findsOneWidget);
      expect(find.byType(RecommendationsScreen), findsNothing);
    });
  });
}
