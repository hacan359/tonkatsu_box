import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/shared/models/collection_item.dart';
import 'package:tonkatsu_box/shared/models/custom_media.dart';
import 'package:tonkatsu_box/shared/models/media_type.dart';
import 'package:tonkatsu_box/shared/utils/item_card_progress.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('itemCardProgress', () {
    test('null без записанного прогресса', () {
      final CollectionItem item = createTestCollectionItem(
        mediaType: MediaType.anime,
        anime: createTestAnime(episodes: 24),
      );
      expect(itemCardProgress(item), isNull);
    });

    test('null для типов без прогресса даже с ненулевыми полями', () {
      for (final MediaType type in <MediaType>[
        MediaType.game,
        MediaType.movie,
        MediaType.visualNovel,
      ]) {
        final CollectionItem item = createTestCollectionItem(
          mediaType: type,
          currentEpisode: 5,
        );
        expect(itemCardProgress(item), isNull, reason: type.name);
      }
    });

    test('аниме: эпизод/всего и доля', () {
      final CollectionItem item = createTestCollectionItem(
        mediaType: MediaType.anime,
        currentEpisode: 12,
        anime: createTestAnime(episodes: 24),
      );
      final ItemCardProgress? p = itemCardProgress(item);
      expect(p!.label, '12/24');
      expect(p.fraction, closeTo(0.5, 0.001));
    });

    test('аниме без известного тотала: только текущий, без доли', () {
      final CollectionItem item = createTestCollectionItem(
        mediaType: MediaType.anime,
        currentEpisode: 7,
        anime: createTestAnime(),
      );
      final ItemCardProgress? p = itemCardProgress(item);
      expect(p!.label, '7');
      expect(p.fraction, isNull);
    });

    test('манга: том и главы', () {
      final CollectionItem item = createTestCollectionItem(
        mediaType: MediaType.manga,
        currentEpisode: 45,
        currentSeason: 5,
        manga: createTestManga(chapters: 100),
      );
      expect(itemCardProgress(item)!.label, 'V5 · 45/100');
    });

    test('манга: только том без глав', () {
      final CollectionItem item = createTestCollectionItem(
        mediaType: MediaType.manga,
        currentSeason: 3,
        manga: createTestManga(),
      );
      final ItemCardProgress? p = itemCardProgress(item);
      expect(p!.label, 'V3');
      expect(p.fraction, isNull);
    });

    test('сериалы (TMDB) пока исключены — метки живут в watched_episodes', () {
      final CollectionItem item = createTestCollectionItem(
        mediaType: MediaType.tvShow,
        currentEpisode: 12,
        currentSeason: 2,
        tvShow: createTestTvShow(totalEpisodes: 62),
      );
      expect(itemCardProgress(item), isNull);
    });

    test('книга: страницы', () {
      final CollectionItem item = createTestCollectionItem(
        mediaType: MediaType.book,
        currentEpisode: 150,
        book: createTestBook(pageCount: 300),
      );
      final ItemCardProgress? p = itemCardProgress(item);
      expect(p!.label, '150/300');
      expect(p.fraction, closeTo(0.5, 0.001));
    });

    test('кастомный элемент берёт тоталы и ось из customMedia', () {
      final CollectionItem item = createTestCollectionItem(
        mediaType: MediaType.custom,
        currentEpisode: 4,
        currentSeason: 1,
        customMedia: const CustomMedia(
          id: 1,
          title: 'X',
          displayType: MediaType.tvShow,
          unitTotal: 10,
        ),
      );
      expect(itemCardProgress(item)!.label, 'S1 · 4/10');
    });

    test('кастомный элемент без displayType: без оси сезонов', () {
      final CollectionItem item = createTestCollectionItem(
        mediaType: MediaType.custom,
        currentEpisode: 2,
        currentSeason: 3,
        customMedia: const CustomMedia(id: 1, title: 'X', unitTotal: 8),
      );
      expect(itemCardProgress(item)!.label, '2/8');
    });

    test('доля ограничена 1.0 при перевыполнении', () {
      final CollectionItem item = createTestCollectionItem(
        mediaType: MediaType.anime,
        currentEpisode: 30,
        anime: createTestAnime(episodes: 24),
      );
      expect(itemCardProgress(item)!.fraction, 1.0);
    });
  });
}
