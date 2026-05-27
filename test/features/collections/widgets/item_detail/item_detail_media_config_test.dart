import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/collections/widgets/item_detail/item_detail_media_config.dart';
import 'package:xerabora/shared/constants/media_type_theme.dart';
import 'package:xerabora/shared/models/collection_item.dart';
import 'package:xerabora/shared/models/media_type.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  Future<ItemDetailMediaConfig> buildConfig(
    WidgetTester tester,
    CollectionItem item,
  ) async {
    late ItemDetailMediaConfig config;
    await tester.pumpApp(
      Builder(
        builder: (BuildContext context) {
          config = ItemDetailMediaConfig.from(item, context);
          return const SizedBox();
        },
      ),
    );
    return config;
  }

  group('ItemDetailMediaConfig.from', () {
    testWidgets('game: no trackers, external url and accent resolved',
        (WidgetTester t) async {
      final CollectionItem item = createTestCollectionItem(
        mediaType: MediaType.game,
        externalId: 100,
        game: createTestGame(id: 100, externalUrl: 'https://igdb/g'),
      );

      final ItemDetailMediaConfig c = await buildConfig(t, item);

      expect(c.hasEpisodeTracker, isFalse);
      expect(c.hasMangaProgress, isFalse);
      expect(c.hasAnimeProgress, isFalse);
      expect(c.externalUrl, 'https://igdb/g');
      expect(c.accentColor, MediaTypeTheme.colorFor(item.displayMediaType));
      expect(c.coverUrl, item.thumbnailUrl);
    });

    testWidgets('tv show enables the episode tracker', (WidgetTester t) async {
      final CollectionItem item = createTestCollectionItem(
        mediaType: MediaType.tvShow,
        externalId: 200,
      );

      final ItemDetailMediaConfig c = await buildConfig(t, item);

      expect(c.hasEpisodeTracker, isTrue);
      expect(c.hasMangaProgress, isFalse);
      expect(c.hasAnimeProgress, isFalse);
    });

    testWidgets('animation tracks episodes only for the TV-show source',
        (WidgetTester t) async {
      final ItemDetailMediaConfig tv = await buildConfig(
        t,
        createTestCollectionItem(
          mediaType: MediaType.animation,
          externalId: 1,
          platformId: AnimationSource.tvShow,
        ),
      );
      expect(tv.hasEpisodeTracker, isTrue);

      final ItemDetailMediaConfig movie = await buildConfig(
        t,
        createTestCollectionItem(
          mediaType: MediaType.animation,
          externalId: 2,
          platformId: AnimationSource.movie,
        ),
      );
      expect(movie.hasEpisodeTracker, isFalse);
    });

    testWidgets('manga enables only manga progress', (WidgetTester t) async {
      final ItemDetailMediaConfig c = await buildConfig(
        t,
        createTestCollectionItem(mediaType: MediaType.manga, externalId: 5),
      );

      expect(c.hasMangaProgress, isTrue);
      expect(c.hasAnimeProgress, isFalse);
      expect(c.hasEpisodeTracker, isFalse);
    });

    testWidgets('anime enables only anime progress', (WidgetTester t) async {
      final ItemDetailMediaConfig c = await buildConfig(
        t,
        createTestCollectionItem(mediaType: MediaType.anime, externalId: 6),
      );

      expect(c.hasAnimeProgress, isTrue);
      expect(c.hasMangaProgress, isFalse);
      expect(c.hasEpisodeTracker, isFalse);
    });
  });
}
