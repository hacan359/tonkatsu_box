import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/genre_cloud/providers/genre_cloud_provider.dart';
import 'package:tonkatsu_box/features/genre_cloud/screens/genre_cloud_screen.dart';
import 'package:tonkatsu_box/features/genre_cloud/widgets/genre_cloud_export_view.dart';
import 'package:tonkatsu_box/features/genre_cloud/widgets/genre_cloud_view.dart';
import 'package:tonkatsu_box/shared/models/collection_item.dart';
import 'package:tonkatsu_box/shared/models/media_type.dart';

import '../../helpers/test_helpers.dart';

List<CollectionItem> _itemsWithGenres() => <CollectionItem>[
      createTestCollectionItem(
        id: 1,
        mediaType: MediaType.game,
        game: createTestGame(genres: <String>['Action', 'RPG']),
      ),
      createTestCollectionItem(
        id: 2,
        mediaType: MediaType.movie,
        movie: createTestMovie(genres: <String>['Action', 'Drama']),
      ),
    ];

Override _items(List<CollectionItem> items) =>
    genreCloudItemsProvider.overrideWith(
      (Ref ref) => AsyncValue<List<CollectionItem>>.data(items),
    );

void main() {
  group('GenreCloudScreen', () {
    testWidgets('should render the cloud when items carry facets', (
      WidgetTester tester,
    ) async {
      await tester.pumpApp(
        const GenreCloudScreen(),
        overrides: <Override>[_items(_itemsWithGenres())],
        mediaQuerySize: const Size(360, 640),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(GenreCloudView), findsOneWidget);
      // The offscreen export poster re-runs the full layout, so it must not
      // be mounted outside an export.
      expect(
        find.byType(GenreCloudExportView, skipOffstage: false),
        findsNothing,
      );
    });

    testWidgets('should show the empty state when no item carries a facet', (
      WidgetTester tester,
    ) async {
      await tester.pumpApp(
        const GenreCloudScreen(),
        overrides: <Override>[_items(const <CollectionItem>[])],
        mediaQuerySize: const Size(360, 640),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(GenreCloudView), findsNothing);
    });

    testWidgets('should keep the legends on one row as chips are added', (
      WidgetTester tester,
    ) async {
      // The legends used to wrap, so every extra media type stole a line
      // from the cloud on a phone. They scroll now, so the chrome is fixed.
      Future<double> cloudTop(List<CollectionItem> items) async {
        await tester.pumpApp(
          const GenreCloudScreen(),
          overrides: <Override>[_items(items)],
          mediaQuerySize: const Size(360, 640),
        );
        return tester.getTopLeft(find.byType(GenreCloudView)).dy;
      }

      final double twoTypes = await cloudTop(_itemsWithGenres());
      final double manyTypes = await cloudTop(<CollectionItem>[
        ..._itemsWithGenres(),
        createTestCollectionItem(
          id: 3,
          mediaType: MediaType.tvShow,
          tvShow: createTestTvShow(genres: <String>['Comedy']),
        ),
        createTestCollectionItem(
          id: 4,
          mediaType: MediaType.anime,
          anime: createTestAnime(genres: <String>['Fantasy']),
        ),
      ]);

      expect(manyTypes, twoTypes);
    });
  });
}
