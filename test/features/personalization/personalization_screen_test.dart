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
import 'package:tonkatsu_box/shared/widgets/flat_tab_bar.dart';

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

    // Scoped to the first bar in tree order — the hub tabs, not any bar the
    // tab below them may render.
    Finder segments() => find.descendant(
          of: find.byWidgetPredicate((Widget w) => w is FlatTabBar).first,
          matching: find.byType(InkWell),
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

    group('tab width', () {
      // Widths of the three tabs, in order.
      List<double> tabWidths(WidgetTester tester) => tester
          .widgetList<InkWell>(segments())
          .map((InkWell w) => tester.getSize(find.byWidget(w)).width)
          .toList();

      testWidgets('should split the header into equal tabs when wide', (
        WidgetTester tester,
      ) async {
        await tester.pumpApp(
          const PersonalizationScreen(),
          overrides: overrides(),
        );

        final List<double> widths = tabWidths(tester);
        expect(widths, hasLength(3));
        expect(widths[1], moreOrLessEquals(widths[0], epsilon: 0.5));
        expect(widths[2], moreOrLessEquals(widths[0], epsilon: 0.5));
        // Together they span the header, not a fragment of it.
        final double logicalWidth =
            tester.view.physicalSize.width / tester.view.devicePixelRatio;
        expect(
          widths.reduce((double a, double b) => a + b),
          greaterThan(logicalWidth * 0.9),
        );
      });

      testWidgets('should still split the header on a phone', (
        WidgetTester tester,
      ) async {
        // Full width holds at every size — the hub tabs never fall back to
        // sizing to content, which is what made them read as a fragment.
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpApp(
          const PersonalizationScreen(),
          overrides: overrides(),
        );

        expect(tester.takeException(), isNull);
        final List<double> widths = tabWidths(tester);
        expect(widths, hasLength(3));
        expect(widths[1], moreOrLessEquals(widths[0], epsilon: 0.5));
        expect(
          widths.reduce((double a, double b) => a + b),
          moreOrLessEquals(360, epsilon: 1),
        );
      });
    });
  });
}
