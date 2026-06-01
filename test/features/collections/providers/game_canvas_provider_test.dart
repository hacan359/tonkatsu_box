import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/data/repositories/canvas_repository.dart';
import 'package:tonkatsu_box/features/collections/providers/canvas_state.dart';
import 'package:tonkatsu_box/features/collections/providers/collections_provider.dart';
import 'package:tonkatsu_box/features/collections/providers/game_canvas_provider.dart';
import 'package:tonkatsu_box/shared/models/anime.dart';
import 'package:tonkatsu_box/shared/models/canvas_item.dart';
import 'package:tonkatsu_box/shared/models/collection_item.dart';
import 'package:tonkatsu_box/shared/models/custom_media.dart';
import 'package:tonkatsu_box/shared/models/game.dart';
import 'package:tonkatsu_box/shared/models/item_status.dart';
import 'package:tonkatsu_box/shared/models/manga.dart';
import 'package:tonkatsu_box/shared/models/media_type.dart';
import 'package:tonkatsu_box/shared/models/movie.dart';
import 'package:tonkatsu_box/shared/models/tv_show.dart';
import 'package:tonkatsu_box/shared/models/visual_novel.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  setUpAll(registerAllFallbacks);

  group('GameCanvasNotifier._initializeWithCollectionItem', () {
    late MockCanvasRepository mockRepository;

    setUp(() {
      mockRepository = MockCanvasRepository();
      when(() => mockRepository.hasGameCanvasItems(any()))
          .thenAnswer((_) async => false);
      when(() => mockRepository.saveGameCanvasViewport(
            any(),
            any(),
          )).thenAnswer((_) async {});
      when(() => mockRepository.createItem(any()))
          .thenAnswer((Invocation inv) async {
        final CanvasItem incoming = inv.positionalArguments.first as CanvasItem;
        return incoming.copyWith(id: 42);
      });
    });

    ProviderContainer createContainer({
      required CollectionItem collectionItem,
    }) {
      return ProviderContainer(
        overrides: <Override>[
          canvasRepositoryProvider.overrideWithValue(mockRepository),
          collectionItemsNotifierProvider.overrideWith(
            () => MockCollectionItemsNotifier(
              AsyncData<List<CollectionItem>>(<CollectionItem>[collectionItem]),
            ),
          ),
        ],
      );
    }

    Future<CanvasItem> initAndGetFirstItem(CollectionItem ci) async {
      final ProviderContainer container =
          createContainer(collectionItem: ci);
      addTearDown(container.dispose);

      container.read(gameCanvasNotifierProvider(
        (collectionId: 10, collectionItemId: ci.id),
      ));

      for (int i = 0; i < 50; i++) {
        await Future<void>.delayed(Duration.zero);
        final CanvasState s = container.read(gameCanvasNotifierProvider(
          (collectionId: 10, collectionItemId: ci.id),
        ));
        if (s.isInitialized && s.items.isNotEmpty) return s.items.first;
      }
      fail('Canvas did not initialise within 50 microtasks');
    }

    // Regression: the per-item canvas (opened from a single collection item)
    // must copy every media-type-specific field through to its CanvasItem.
    // Anime was historically forgotten in the copyWith call and the canvas
    // opened with an empty card (no cover image, no title). When a new media
    // type is added, mirror it here so the same regression can't slip in.

    test('should propagate game data', () async {
      const Game testGame = Game(id: 100, name: 'Hades');
      final CanvasItem item = await initAndGetFirstItem(CollectionItem(
        id: 1,
        collectionId: 10,
        mediaType: MediaType.game,
        externalId: 100,
        status: ItemStatus.notStarted,
        addedAt: DateTime(2024),
        game: testGame,
      ));
      expect(item.game?.id, testGame.id);
    });

    test('should propagate movie data', () async {
      const Movie testMovie = Movie(tmdbId: 200, title: 'Spirited Away');
      final CanvasItem item = await initAndGetFirstItem(CollectionItem(
        id: 2,
        collectionId: 10,
        mediaType: MediaType.movie,
        externalId: 200,
        status: ItemStatus.notStarted,
        addedAt: DateTime(2024),
        movie: testMovie,
      ));
      expect(item.movie?.tmdbId, testMovie.tmdbId);
    });

    test('should propagate tvShow data', () async {
      const TvShow testTv = TvShow(tmdbId: 300, title: 'Breaking Bad');
      final CanvasItem item = await initAndGetFirstItem(CollectionItem(
        id: 3,
        collectionId: 10,
        mediaType: MediaType.tvShow,
        externalId: 300,
        status: ItemStatus.notStarted,
        addedAt: DateTime(2024),
        tvShow: testTv,
      ));
      expect(item.tvShow?.tmdbId, testTv.tmdbId);
    });

    test('should propagate visualNovel data', () async {
      const VisualNovel testVn = VisualNovel(id: 'v17', title: 'Ever17');
      final CanvasItem item = await initAndGetFirstItem(CollectionItem(
        id: 4,
        collectionId: 10,
        mediaType: MediaType.visualNovel,
        externalId: 17,
        status: ItemStatus.notStarted,
        addedAt: DateTime(2024),
        visualNovel: testVn,
      ));
      expect(item.visualNovel?.id, testVn.id);
    });

    test('should propagate manga data', () async {
      const Manga testManga = Manga(id: 500, title: 'Berserk');
      final CanvasItem item = await initAndGetFirstItem(CollectionItem(
        id: 5,
        collectionId: 10,
        mediaType: MediaType.manga,
        externalId: 500,
        status: ItemStatus.notStarted,
        addedAt: DateTime(2024),
        manga: testManga,
      ));
      expect(item.manga?.id, testManga.id);
    });

    test('should propagate anime data', () async {
      const Anime testAnime = Anime(id: 600, title: 'Cowboy Bebop');
      final CanvasItem item = await initAndGetFirstItem(CollectionItem(
        id: 6,
        collectionId: 10,
        mediaType: MediaType.anime,
        externalId: 600,
        status: ItemStatus.notStarted,
        addedAt: DateTime(2024),
        anime: testAnime,
      ));
      expect(item.anime?.id, testAnime.id);
    });

    test('should propagate customMedia data', () async {
      const CustomMedia testCustom =
          CustomMedia(id: 700, title: 'My homebrew');
      final CanvasItem item = await initAndGetFirstItem(CollectionItem(
        id: 7,
        collectionId: 10,
        mediaType: MediaType.custom,
        externalId: 700,
        status: ItemStatus.notStarted,
        addedAt: DateTime(2024),
        customMedia: testCustom,
      ));
      expect(item.customMedia?.id, testCustom.id);
    });
  });
}
