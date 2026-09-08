import 'package:core/models/collection_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/genre_cloud/providers/genre_cloud_provider.dart';
import 'package:tonkatsu_box/features/genre_cloud/screens/genre_cloud_screen.dart';
import 'package:tonkatsu_box/features/likes/providers/marked_units_provider.dart';
import 'package:tonkatsu_box/features/likes/screens/likes_screen.dart';
import 'package:tonkatsu_box/features/personalization/screens/personalization_hub_screen.dart';
import 'package:tonkatsu_box/features/personalization/screens/personalization_screen.dart';
import 'package:tonkatsu_box/features/personalization/widgets/hub_section_card.dart';
import 'package:tonkatsu_box/features/recommendations/providers/recommendations_provider.dart';
import 'package:tonkatsu_box/features/recommendations/screens/recommendations_screen.dart';
import 'package:tonkatsu_box/features/statistics/providers/statistics_provider.dart';
import 'package:tonkatsu_box/features/statistics/screens/statistics_screen.dart';
import 'package:tonkatsu_box/shared/widgets/sub_screen_title_bar.dart';

import '../../helpers/test_helpers.dart';

class _EmptyMarkedUnits extends MarkedUnitsNotifier {
  @override
  Future<List<MarkedUnitGroup>> build() async => const <MarkedUnitGroup>[];
}

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
          markedUnitsProvider.overrideWith(_EmptyMarkedUnits.new),
        ];

    Finder cards() => find.byType(HubSectionCard);

    testWidgets('opens on the hub landing with one card per section', (
      WidgetTester tester,
    ) async {
      await tester.pumpApp(
        const PersonalizationScreen(),
        overrides: overrides(),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(PersonalizationHubScreen), findsOneWidget);
      expect(cards(), findsNWidgets(3));
      // Sections are routes, not tabs: none is built until opened.
      expect(find.byType(StatisticsScreen), findsNothing);
      expect(find.byType(GenreCloudScreen), findsNothing);
      expect(find.byType(RecommendationsScreen), findsNothing);
    });

    testWidgets('pushes statistics over the hub and pops back', (
      WidgetTester tester,
    ) async {
      final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();
      await tester.pumpApp(
        PersonalizationScreen(navigatorKey: key),
        overrides: overrides(),
      );

      await tester.tap(cards().at(0));
      await tester.pumpAndSettle();
      expect(find.byType(StatisticsScreen), findsOneWidget);
      expect(find.byType(SubScreenTitleBar), findsOneWidget);
      expect(key.currentState?.canPop(), isTrue);

      await tester.tap(
        find.descendant(
          of: find.byType(SubScreenTitleBar),
          matching: find.byType(IconButton),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(StatisticsScreen), findsNothing);
      expect(find.byType(PersonalizationHubScreen), findsOneWidget);
    });

    testWidgets('pushes the likes page from the third card', (
      WidgetTester tester,
    ) async {
      await tester.pumpApp(
        const PersonalizationScreen(),
        overrides: overrides(),
      );

      await tester.tap(cards().at(2));
      await tester.pumpAndSettle();
      expect(find.byType(LikesScreen), findsOneWidget);
      expect(find.byType(StatisticsScreen), findsNothing);
    });

    testWidgets('pushes recommendations from the second card', (
      WidgetTester tester,
    ) async {
      await tester.pumpApp(
        const PersonalizationScreen(),
        overrides: overrides(),
      );

      await tester.tap(cards().at(1));
      await tester.pumpAndSettle();
      expect(find.byType(RecommendationsScreen), findsOneWidget);
      expect(find.byType(StatisticsScreen), findsNothing);
    });

    testWidgets('reaches the genre cloud from the statistics screen', (
      WidgetTester tester,
    ) async {
      await tester.pumpApp(
        const PersonalizationScreen(),
        overrides: overrides(),
      );

      await tester.tap(cards().at(0));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.bubble_chart_outlined));
      await tester.pumpAndSettle();

      expect(find.byType(GenreCloudScreen), findsOneWidget);
      expect(find.byType(StatisticsScreen), findsNothing);
    });

    testWidgets('lays out on a phone without exceptions', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpApp(
        const PersonalizationScreen(),
        overrides: overrides(),
      );

      expect(tester.takeException(), isNull);
      expect(cards(), findsNWidgets(3));

      await tester.tap(cards().at(0));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(StatisticsScreen), findsOneWidget);
    });
  });
}
