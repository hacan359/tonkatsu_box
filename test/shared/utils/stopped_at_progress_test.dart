import 'package:core/models/audio_kind.dart';
import 'package:core/models/book_kind.dart';
import 'package:core/models/collection_item.dart';
import 'package:core/models/custom_media.dart';
import 'package:core/models/data_source.dart';
import 'package:core/models/media_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/l10n/app_localizations.dart';
import 'package:tonkatsu_box/shared/utils/stopped_at_progress.dart';

import '../../helpers/test_helpers.dart';

void main() {
  final S l = lookupS(const Locale('en'));

  StoppedAtProgress? forItem(
    CollectionItem item, {
    (int, int)? lastWatchedEpisode,
    (int, int)? lastListenedTrack,
  }) =>
      StoppedAtProgress.forItem(
        item,
        l,
        lastWatchedEpisode: lastWatchedEpisode,
        lastListenedTrack: lastListenedTrack,
      );

  group('StoppedAtProgress', () {
    group('forItem', () {
      test('skips games, movies and visual novels', () {
        for (final MediaType type in <MediaType>[
          MediaType.game,
          MediaType.movie,
          MediaType.visualNovel,
        ]) {
          expect(
            forItem(createTestCollectionItem(mediaType: type, currentEpisode: 3)),
            isNull,
            reason: type.name,
          );
        }
      });

      group('book', () {
        test('shows the page with the total', () {
          final CollectionItem item = createTestCollectionItem(
            mediaType: MediaType.book,
            currentEpisode: 120,
            book: createTestBook(pageCount: 350),
          );

          expect(forItem(item)?.value, 'Page 120 / 350');
        });

        test('drops the total when unknown', () {
          final CollectionItem item = createTestCollectionItem(
            mediaType: MediaType.book,
            currentEpisode: 7,
            book: createTestBook(),
          );

          expect(forItem(item)?.value, 'Page 7');
        });

        test('labels comics by issue', () {
          final CollectionItem item = createTestCollectionItem(
            mediaType: MediaType.book,
            currentEpisode: 4,
            book: createTestBook(pageCount: 12).copyWith(kind: BookKind.comic),
          );

          expect(forItem(item)?.value, 'Issue 4 / 12');
        });

        test('has no value at page zero', () {
          final CollectionItem item = createTestCollectionItem(
            mediaType: MediaType.book,
            book: createTestBook(pageCount: 350),
          );

          final StoppedAtProgress? result = forItem(item);
          expect(result, isNotNull);
          expect(result?.value, isNull);
        });
      });

      group('manga', () {
        test('joins chapter and volume', () {
          final CollectionItem item = createTestCollectionItem(
            mediaType: MediaType.manga,
            currentEpisode: 40,
            currentSeason: 3,
            manga: createTestManga(chapters: 120, volumes: 10),
          );

          expect(forItem(item)?.value, 'Chapter 40 / 120 · Volume 3 / 10');
        });

        test('shows a volume alone when no chapter is set', () {
          final CollectionItem item = createTestCollectionItem(
            mediaType: MediaType.manga,
            currentSeason: 2,
            manga: createTestManga(),
          );

          expect(forItem(item)?.value, 'Chapter 0 · Volume 2');
        });

        test('has no value when both axes are zero', () {
          final CollectionItem item = createTestCollectionItem(
            mediaType: MediaType.manga,
            manga: createTestManga(chapters: 120),
          );

          expect(forItem(item)?.value, isNull);
        });
      });

      test('anime on the counter shows the episode', () {
        final CollectionItem item = createTestCollectionItem(
          mediaType: MediaType.anime,
          source: DataSource.anilist,
          currentEpisode: 5,
          anime: createTestAnime(episodes: 12),
        );

        expect(forItem(item)?.value, 'Episode 5 / 12');
      });

      group('episode tracker', () {
        test('formats the last watched episode with a long tooltip', () {
          final CollectionItem item = createTestCollectionItem(
            mediaType: MediaType.tvShow,
            source: DataSource.tmdb,
          );

          final StoppedAtProgress? result =
              forItem(item, lastWatchedEpisode: (2, 5));
          expect(result?.value, 'S2·E5');
          expect(result?.tooltip, 'Season 2 · Episode 5');
        });

        test('has no value while nothing is watched', () {
          final CollectionItem item = createTestCollectionItem(
            mediaType: MediaType.tvShow,
            source: DataSource.tmdb,
          );

          final StoppedAtProgress? result = forItem(item);
          expect(result, isNotNull);
          expect(result?.value, isNull);
        });

        test('Kitsu anime uses the tracker, not the counter', () {
          final CollectionItem item = createTestCollectionItem(
            mediaType: MediaType.anime,
            source: DataSource.kitsu,
            currentEpisode: 9,
            anime: createTestAnime(episodes: 12, source: DataSource.kitsu),
          );

          expect(forItem(item, lastWatchedEpisode: (1, 3))?.value, 'S1·E3');
        });
      });

      group('audio', () {
        test('album shows the track with the total', () {
          final CollectionItem item = createTestCollectionItem(
            mediaType: MediaType.audio,
            audioItem: createTestAudioItem(trackCount: 12),
          );

          expect(forItem(item, lastListenedTrack: (1, 5))?.value, 'Track 5 / 12');
        });

        test('multi-disc position names the disc and drops the total', () {
          final CollectionItem item = createTestCollectionItem(
            mediaType: MediaType.audio,
            audioItem: createTestAudioItem(trackCount: 24),
          );

          expect(
            forItem(item, lastListenedTrack: (2, 3))?.value,
            'Track 3 · Disc 2',
          );
        });

        test('has no value while nothing is listened', () {
          final CollectionItem item = createTestCollectionItem(
            mediaType: MediaType.audio,
            audioItem: createTestAudioItem(),
          );

          expect(forItem(item)?.value, isNull);
          expect(forItem(item), isNotNull);
        });

        test('skips podcasts', () {
          final CollectionItem item = createTestCollectionItem(
            mediaType: MediaType.audio,
            audioItem: createTestAudioItem(kind: AudioKind.podcast),
          );

          expect(forItem(item, lastListenedTrack: (0, 99)), isNull);
        });
      });

      group('custom', () {
        CollectionItem custom({
          MediaType? displayType,
          int? unitTotal,
          int? unitGroupTotal,
          int currentEpisode = 0,
          int currentSeason = 0,
        }) =>
            createTestCollectionItem(
              mediaType: MediaType.custom,
              currentEpisode: currentEpisode,
              currentSeason: currentSeason,
              customMedia: CustomMedia(
                id: 1,
                title: 'Custom',
                displayType: displayType,
                unitTotal: unitTotal,
                unitGroupTotal: unitGroupTotal,
              ),
            );

        test('skips items without any totals', () {
          expect(forItem(custom(currentEpisode: 3)), isNull);
        });

        test('series borrow episodes and seasons', () {
          final CollectionItem item = custom(
            displayType: MediaType.tvShow,
            unitTotal: 12,
            unitGroupTotal: 3,
            currentEpisode: 5,
            currentSeason: 2,
          );

          expect(forItem(item)?.value, 'Episode 5 / 12 · Season 2 / 3');
        });

        test('manga borrows chapters and volumes', () {
          final CollectionItem item = custom(
            displayType: MediaType.manga,
            unitTotal: 100,
            currentEpisode: 40,
            currentSeason: 4,
          );

          expect(forItem(item)?.value, 'Chapter 40 / 100 · Volume 4');
        });

        test('books borrow pages', () {
          final CollectionItem item = custom(
            displayType: MediaType.book,
            unitTotal: 300,
            currentEpisode: 10,
          );

          expect(forItem(item)?.value, 'Page 10 / 300');
        });

        test('types without a group axis ignore current_season', () {
          final CollectionItem item = custom(
            unitTotal: 8,
            currentEpisode: 2,
            currentSeason: 5,
          );

          expect(forItem(item)?.value, 'Part 2 / 8');
        });
      });
    });
  });
}
