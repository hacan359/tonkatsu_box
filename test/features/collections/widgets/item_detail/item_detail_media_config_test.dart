import 'package:core/models/collection_item.dart';
import 'package:core/models/data_source.dart';
import 'package:core/models/media_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/collections/widgets/item_detail/item_detail_media_config.dart';
import 'package:tonkatsu_box/shared/constants/media_type_theme.dart';
import 'package:tonkatsu_box/shared/navigation/search_providers.dart';
import 'package:tonkatsu_box/shared/widgets/media_detail/media_detail_chip.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    testWidgets('anilist anime keeps the flat counter', (WidgetTester t) async {
      final ItemDetailMediaConfig c = await buildConfig(
        t,
        createTestCollectionItem(
          mediaType: MediaType.anime,
          externalId: 6,
          anime: createTestAnime(id: 6, episodes: 24),
        ),
      );

      expect(c.hasAnimeProgress, isTrue);
      expect(c.hasEpisodeTracker, isFalse);
    });

    testWidgets('kitsu anime swaps the counter for the episode tracker',
        (WidgetTester t) async {
      final ItemDetailMediaConfig c = await buildConfig(
        t,
        createTestCollectionItem(
          mediaType: MediaType.anime,
          externalId: 7442,
          anime: createTestAnime(
            id: 7442,
            source: DataSource.kitsu,
            episodes: 25,
          ),
        ),
      );

      expect(c.hasEpisodeTracker, isTrue);
      expect(c.hasAnimeProgress, isFalse);
    });
  });

  group('ItemDetailMediaConfig.from studio chips', () {
    testWidgets('each studio is its own chip that opens the studio search',
        (WidgetTester t) async {
      final CollectionItem item = createTestCollectionItem(
        mediaType: MediaType.anime,
        externalId: 6,
        anime: createTestAnime(
          id: 6,
          studios: <String>['Kyoto Animation', 'Animation Do'],
        ),
      );
      late ItemDetailMediaConfig config;
      late BuildContext ctx;
      await t.pumpApp(
        Builder(
          builder: (BuildContext context) {
            ctx = context;
            config = ItemDetailMediaConfig.from(item, context);
            return const SizedBox();
          },
        ),
      );

      final List<MediaDetailChip> studioChips = config.infoChips
          .where((MediaDetailChip c) => c.onTap != null)
          .toList();
      expect(
        studioChips.map((MediaDetailChip c) => c.text),
        <String>['Kyoto Animation', 'Animation Do'],
      );

      studioChips.last.onTap!();
      final SearchTabRequest? request = ProviderScope.containerOf(ctx)
          .read(searchTabRequestProvider);
      expect(request?.sourceId, 'anilist_anime');
      expect(request?.filterValues?['studio'], 'Animation Do');
    });

    testWidgets('anime without studios has no tappable chip',
        (WidgetTester t) async {
      final CollectionItem item = createTestCollectionItem(
        mediaType: MediaType.anime,
        externalId: 7,
        anime: createTestAnime(id: 7),
      );
      final ItemDetailMediaConfig c = await buildConfig(t, item);

      expect(c.infoChips.where((MediaDetailChip x) => x.onTap != null), isEmpty);
    });
  });
}
