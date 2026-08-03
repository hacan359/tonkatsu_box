import 'dart:convert';

import 'package:core/database/dao/stats_dao.dart';
import 'package:core/database/migrations/migration.dart';
import 'package:core/database/migrations/migration_registry.dart';
import 'package:core/models/item_status.dart';
import 'package:core/models/media_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late StatsDao dao;

  // Local dates so expectations agree with the DAO's localtime bucketing.
  final DateTime in2024 = DateTime(2024, 5, 15);
  final DateTime in2023 = DateTime(2023, 8, 1);

  int secs(DateTime d) => d.millisecondsSinceEpoch ~/ 1000;
  int ms(DateTime d) => d.millisecondsSinceEpoch;

  setUp(() async {
    db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: MigrationRegistry.all.last.version,
        onCreate: (Database d, int _) async {
          for (final Migration m in MigrationRegistry.all) {
            await m.migrate(d);
          }
        },
      ),
    );
    dao = StatsDao(() async => db);

    for (final int id in <int>[1, 2]) {
      await db.insert('collections', <String, Object?>{
        'id': id,
        'name': 'C$id',
        'author': 'tester',
        'created_at': 1700000000,
      });
    }
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> insertItem({
    required int id,
    String mediaType = 'game',
    int collectionId = 1,
    int externalId = 100,
    String status = 'not_started',
    double? userRating,
    DateTime? addedAt,
    int? rewatchCount,
    int? timeSpentMinutes,
    int? platformId,
    String? source,
    int? currentEpisode,
  }) async {
    // Omit null columns so NOT NULL DEFAULT columns keep their defaults.
    return db.insert(
      'collection_items',
      <String, Object?>{
        'id': id,
        'collection_id': collectionId,
        'media_type': mediaType,
        'external_id': externalId,
        'status': status,
        'user_rating': userRating,
        'added_at': secs(addedAt ?? in2024),
        'rewatch_count': rewatchCount,
        'time_spent_minutes': timeSpentMinutes,
        'platform_id': platformId,
        'source': source,
        'current_episode': currentEpisode,
        'sort_order': id,
      }..removeWhere((String _, Object? v) => v == null),
    );
  }

  group('StatsDao', () {
    group('getTypeStatusCounts', () {
      test('should group counts by media type and status', () async {
        await insertItem(id: 1, status: 'completed');
        await insertItem(id: 2, externalId: 101, status: 'completed');
        await insertItem(
            id: 3, externalId: 102, mediaType: 'movie', status: 'in_progress');

        final Map<MediaType, Map<ItemStatus, int>> counts =
            await dao.getTypeStatusCounts();

        expect(counts[MediaType.game]?[ItemStatus.completed], 2);
        expect(counts[MediaType.movie]?[ItemStatus.inProgress], 1);
        expect(counts[MediaType.game]?[ItemStatus.inProgress], isNull);
      });

      test('should only count items added within the year window', () async {
        await insertItem(id: 1, status: 'completed', addedAt: in2024);
        await insertItem(
            id: 2, externalId: 101, status: 'completed', addedAt: in2023);

        final Map<MediaType, Map<ItemStatus, int>> counts =
            await dao.getTypeStatusCounts(year: 2024);

        expect(counts[MediaType.game]?[ItemStatus.completed], 1);
      });

      test('should attribute a local New Year item to the local year',
          () async {
        await insertItem(id: 1, addedAt: DateTime(2024, 1, 1, 0, 30));
        await insertItem(
            id: 2, externalId: 101, addedAt: DateTime(2023, 12, 31, 23, 30));

        final Map<MediaType, Map<ItemStatus, int>> counts =
            await dao.getTypeStatusCounts(year: 2024);

        expect(counts[MediaType.game]?[ItemStatus.notStarted], 1);
      });
    });

    group('getGamePlatformStatusCounts', () {
      test('should split game statuses per platform, ignoring other types',
          () async {
        await insertItem(id: 1, status: 'completed', platformId: 10);
        await insertItem(
            id: 2, externalId: 101, status: 'in_progress', platformId: 10);
        await insertItem(id: 3, externalId: 102, status: 'completed');
        await insertItem(
            id: 4,
            externalId: 103,
            mediaType: 'movie',
            status: 'completed',
            platformId: 10);

        final Map<int?, Map<ItemStatus, int>> counts =
            await dao.getGamePlatformStatusCounts();

        expect(counts[10]?[ItemStatus.completed], 1);
        expect(counts[10]?[ItemStatus.inProgress], 1);
        expect(counts[null]?[ItemStatus.completed], 1);
      });

      test('should only count games added within the year window', () async {
        await insertItem(
            id: 1, status: 'completed', platformId: 10, addedAt: in2024);
        await insertItem(
            id: 2,
            externalId: 101,
            status: 'completed',
            platformId: 10,
            addedAt: in2023);

        final Map<int?, Map<ItemStatus, int>> counts =
            await dao.getGamePlatformStatusCounts(year: 2024);

        expect(counts[10]?[ItemStatus.completed], 1);
      });
    });

    group('getRewatchSum', () {
      test('should sum rewatch counters treating null as zero', () async {
        await insertItem(id: 1, rewatchCount: 2);
        await insertItem(id: 2, externalId: 101, rewatchCount: null);
        await insertItem(id: 3, externalId: 102, rewatchCount: 1);

        expect(await dao.getRewatchSum(), 3);
      });
    });

    group('getAverageRating', () {
      test('should average only rated items', () async {
        await insertItem(id: 1, userRating: 8);
        await insertItem(id: 2, externalId: 101, userRating: 6);
        await insertItem(id: 3, externalId: 102);

        expect(await dao.getAverageRating(), 7.0);
      });

      test('should return null when nothing is rated', () async {
        await insertItem(id: 1);

        expect(await dao.getAverageRating(), isNull);
      });
    });

    group('getEpisodeSplit', () {
      Future<void> insertWatched({
        required int episode,
        String source = 'tmdb',
        DateTime? watchedAt,
      }) async {
        await db.insert('watched_episodes', <String, Object?>{
          'collection_id': 1,
          'source': source,
          'show_id': 500,
          'season_number': 1,
          'episode_number': episode,
          'watched_at': watchedAt == null ? null : ms(watchedAt),
        });
      }

      test('should split rows into tv and anime including undated ones',
          () async {
        await insertWatched(episode: 1, watchedAt: in2024);
        await insertWatched(episode: 2);
        await insertWatched(episode: 3, source: 'kitsu', watchedAt: in2024);

        final ({int tv, int anime}) split = await dao.getEpisodeSplit();

        expect(split.tv, 2);
        expect(split.anime, 1);
      });

      test('should count only dated rows inside the year window', () async {
        await insertWatched(episode: 1, watchedAt: in2024);
        await insertWatched(episode: 2, watchedAt: in2023);
        await insertWatched(episode: 3);

        final ({int tv, int anime}) split =
            await dao.getEpisodeSplit(year: 2024);

        expect(split.tv, 1);
        expect(split.anime, 0);
      });
    });

    group('getProgressCounterSums', () {
      test('should sum flat counters per medium, skipping kitsu anime',
          () async {
        await insertItem(
            id: 1,
            mediaType: 'anime',
            externalId: 1,
            source: 'anilist',
            currentEpisode: 12);
        await insertItem(
            id: 2, mediaType: 'anime', externalId: 2, currentEpisode: 5);
        await insertItem(
            id: 3,
            mediaType: 'anime',
            externalId: 3,
            source: 'kitsu',
            currentEpisode: 8);
        await insertItem(
            id: 4, mediaType: 'manga', externalId: 4, currentEpisode: 30);
        await insertItem(
            id: 5, mediaType: 'book', externalId: 5, currentEpisode: 200);
        await insertItem(id: 6, externalId: 6, currentEpisode: 3);

        final ({int animeEpisodes, int mangaChapters, int bookPages}) sums =
            await dao.getProgressCounterSums();

        expect(sums.animeEpisodes, 17);
        expect(sums.mangaChapters, 30);
        expect(sums.bookPages, 200);
      });

      test('should scope counters by the item added year', () async {
        await insertItem(
            id: 1,
            mediaType: 'manga',
            externalId: 1,
            currentEpisode: 30,
            addedAt: in2023);

        final ({int animeEpisodes, int mangaChapters, int bookPages}) sums =
            await dao.getProgressCounterSums(year: 2024);

        expect(sums.mangaChapters, 0);
      });
    });

    group('getLikedUnitsByType', () {
      test('should count only favorite marks in the window, per type',
          () async {
        await insertItem(id: 1, mediaType: 'tv_show', externalId: 500);
        for (final (int, int, DateTime?) mark in <(int, int, DateTime?)>[
          (1, 1, in2024),
          (2, 1, in2023),
          (3, 0, in2024),
        ]) {
          await db.insert('item_marks', <String, Object?>{
            'item_id': 1,
            'unit_type': 'episode',
            'parent_number': 1,
            'unit_number': mark.$1,
            'is_favorite': mark.$2,
            'liked_at': mark.$3 == null ? null : ms(mark.$3!),
            'updated_at': 1700000000,
          });
        }

        expect(await dao.getLikedUnitsByType(year: 2024),
            <MediaType, int>{MediaType.tvShow: 1});
      });
    });

    group('getTrackerMinutes', () {
      Future<void> insertTracker({
        required int gameId,
        required int minutes,
        String trackerType = 'retro_achievements',
      }) async {
        await db.insert('tracker_game_data', <String, Object?>{
          'tracker_type': trackerType,
          'game_id': gameId,
          'tracker_game_id': '$gameId',
          'playtime_minutes': minutes,
          'last_synced_at': 1700000000,
        });
      }

      test('should count a game duplicated across collections once', () async {
        await insertItem(id: 1, externalId: 100, collectionId: 1);
        await insertItem(id: 2, externalId: 100, collectionId: 2);
        await insertTracker(gameId: 100, minutes: 90);

        expect(await dao.getTrackerMinutes(), 90);
      });

      test('should ignore tracker rows for games outside the window',
          () async {
        await insertItem(id: 1, externalId: 100, addedAt: in2023);
        await insertTracker(gameId: 100, minutes: 90);

        expect(await dao.getTrackerMinutes(year: 2024), 0);
      });
    });

    group('getEstimatedMinutes', () {
      test('should count only episodes with a known runtime, no averages',
          () async {
        // Two watched episodes: one with a 20-minute runtime, one uncached —
        // the uncached one contributes nothing (fixed data only).
        for (final int episode in <int>[1, 2]) {
          await db.insert('watched_episodes', <String, Object?>{
            'collection_id': 1,
            'source': 'tmdb',
            'show_id': 500,
            'season_number': 1,
            'episode_number': episode,
            'watched_at': ms(in2024),
          });
        }
        await db.insert('tv_episodes_cache', <String, Object?>{
          'tmdb_show_id': 500,
          'season_number': 1,
          'episode_number': 1,
          'source': 'tmdb',
          'runtime': 20,
        });

        expect(await dao.getEstimatedMinutes(), 20);
      });

      test('should treat zero runtimes as unknown', () async {
        await db.insert('watched_episodes', <String, Object?>{
          'collection_id': 1,
          'source': 'tmdb',
          'show_id': 500,
          'season_number': 1,
          'episode_number': 1,
          'watched_at': ms(in2024),
        });
        await db.insert('tv_episodes_cache', <String, Object?>{
          'tmdb_show_id': 500,
          'season_number': 1,
          'episode_number': 1,
          'source': 'tmdb',
          'runtime': 0,
        });

        expect(await dao.getEstimatedMinutes(), 0);
      });

      test('should multiply completed movie runtime by rewatches', () async {
        await insertItem(
          id: 1,
          mediaType: 'movie',
          externalId: 700,
          status: 'completed',
          rewatchCount: 1,
        );
        await db.insert('movies_cache', <String, Object?>{
          'tmdb_id': 700,
          'title': 'Movie',
          'runtime': 100,
          'cached_at': 1700000000,
        });

        expect(await dao.getEstimatedMinutes(), 200);
      });
    });

    group('getAddedByMonth', () {
      test('should bucket by local year-month', () async {
        await insertItem(id: 1, addedAt: DateTime(2024, 1, 10));
        await insertItem(
            id: 2, externalId: 101, addedAt: DateTime(2024, 1, 20));
        await insertItem(id: 3, externalId: 102, addedAt: DateTime(2024, 3, 5));

        final Map<String, int> buckets = await dao.getAddedByMonth(year: 2024);

        expect(buckets['2024-01'], 2);
        expect(buckets['2024-03'], 1);
      });
    });

    group('getBestItemByMonth', () {
      test('should pick the highest-rated item of each month', () async {
        await insertItem(
            id: 1, userRating: 6, addedAt: DateTime(2024, 2, 1));
        await insertItem(
            id: 2, externalId: 101, userRating: 9, addedAt: DateTime(2024, 2, 2));
        await insertItem(
            id: 3, externalId: 102, addedAt: DateTime(2024, 2, 3));

        final Map<String, int> best = await dao.getBestItemByMonth(year: 2024);

        expect(best['2024-02'], 2);
      });
    });

    group('getGamePlatformRows', () {
      test('should group games by platform with name and manual minutes',
          () async {
        await db.insert('platforms', <String, Object?>{
          'id': 10,
          'name': 'PlayStation 5',
          'abbreviation': 'PS5',
        });
        await insertItem(id: 1, platformId: 10, timeSpentMinutes: 120);
        await insertItem(
            id: 2, externalId: 101, platformId: 10, timeSpentMinutes: 30);
        await insertItem(id: 3, externalId: 102, timeSpentMinutes: 999);

        final List<Map<String, dynamic>> rows =
            await dao.getGamePlatformRows();

        expect(rows, hasLength(2));
        // No-platform bucket leads: 999 manual minutes beat 150.
        expect(rows.first['platform_id'], isNull);
        final Map<String, dynamic> ps5 = rows.last;
        expect(ps5['abbreviation'], 'PS5');
        expect(ps5['games'], 2);
        expect(ps5['manual_minutes'], 150);
      });
    });

    group('getTrackerMinutesByPlatform', () {
      test('should not double-count a game present in two collections',
          () async {
        await insertItem(id: 1, externalId: 100, platformId: 10);
        await insertItem(
            id: 2, externalId: 100, platformId: 10, collectionId: 2);
        await db.insert('tracker_game_data', <String, Object?>{
          'tracker_type': 'retro_achievements',
          'game_id': 100,
          'tracker_game_id': '100',
          'playtime_minutes': 60,
          'last_synced_at': 1700000000,
        });

        final Map<int?, int> minutes = await dao.getTrackerMinutesByPlatform();

        expect(minutes[10], 60);
      });
    });

    group('getTopGamesByPlatform', () {
      test('should cap the per-platform list ordered by time spent', () async {
        for (int i = 1; i <= 4; i++) {
          await insertItem(
            id: i,
            externalId: 100 + i,
            platformId: 10,
            timeSpentMinutes: i * 10,
          );
        }

        final Map<int?, List<int>> top =
            await dao.getTopGamesByPlatform(perPlatform: 2);

        expect(top[10], <int>[4, 3]);
      });
    });

    group('getSourceTagCounts', () {
      Future<void> insertAnimeCache({
        required int id,
        String source = 'anilist',
        Object? tags,
      }) async {
        await db.insert('anime_cache', <String, Object?>{
          'id': id,
          'source': source,
          'title': 'A$id',
          'tags': tags is String ? tags : jsonEncode(tags),
          'updated_at': 1700000000,
        });
      }

      test('should count tags across titles, biggest first', () async {
        await insertItem(
            id: 1, mediaType: 'anime', externalId: 1, source: 'anilist');
        await insertItem(
            id: 2, mediaType: 'anime', externalId: 2, source: 'anilist');
        await insertAnimeCache(id: 1, tags: <String>['Isekai', 'Action']);
        await insertAnimeCache(id: 2, tags: <String>['Action']);

        final ({int titles, List<(String, int)> tags}) result =
            await dao.getSourceTagCounts(MediaType.anime);

        expect(result.titles, 2);
        expect(result.tags.first, ('Action', 2));
      });

      test('should match legacy items with a null source to anilist',
          () async {
        await insertItem(
            id: 1, mediaType: 'anime', externalId: 1, source: null);
        await insertAnimeCache(id: 1, tags: <String>['Drama']);

        final ({int titles, List<(String, int)> tags}) result =
            await dao.getSourceTagCounts(MediaType.anime);

        expect(result.titles, 1);
      });

      test('should skip malformed tag payloads without failing', () async {
        await insertItem(
            id: 1, mediaType: 'anime', externalId: 1, source: 'anilist');
        await insertItem(
            id: 2, mediaType: 'anime', externalId: 2, source: 'anilist');
        await insertAnimeCache(id: 1, tags: 'not json');
        await insertAnimeCache(id: 2, tags: <String>['Drama']);

        final ({int titles, List<(String, int)> tags}) result =
            await dao.getSourceTagCounts(MediaType.anime);

        expect(result.titles, 1);
        expect(result.tags, <(String, int)>[('Drama', 1)]);
      });

      test('should cap the tag list at the limit', () async {
        await insertItem(
            id: 1, mediaType: 'anime', externalId: 1, source: 'anilist');
        await insertAnimeCache(
            id: 1, tags: <String>['A', 'B', 'C']);

        final ({int titles, List<(String, int)> tags}) result =
            await dao.getSourceTagCounts(MediaType.anime, limit: 2);

        expect(result.tags, hasLength(2));
      });

      test('should throw for media types without source tags', () {
        expect(
          () => dao.getSourceTagCounts(MediaType.game),
          throwsArgumentError,
        );
      });
    });

    group('source formats', () {
      Future<void> insertAnimeCache({
        required int id,
        String source = 'anilist',
        String? format,
      }) async {
        await db.insert('anime_cache', <String, Object?>{
          'id': id,
          'source': source,
          'title': 'A$id',
          'format': format,
          'updated_at': 1700000000,
        });
      }

      group('getSourceFormatStatusCounts', () {
        test('should split statuses per format, skipping null formats',
            () async {
          await insertItem(
              id: 1, mediaType: 'anime', externalId: 1, status: 'completed');
          await insertItem(
              id: 2, mediaType: 'anime', externalId: 2, status: 'in_progress');
          await insertItem(
              id: 3, mediaType: 'anime', externalId: 3, status: 'completed');
          await insertItem(
              id: 4, mediaType: 'anime', externalId: 4, status: 'completed');
          await insertAnimeCache(id: 1, format: 'TV');
          await insertAnimeCache(id: 2, format: 'TV');
          await insertAnimeCache(id: 3, format: 'MOVIE');
          await insertAnimeCache(id: 4);

          final Map<String, Map<ItemStatus, int>> counts =
              await dao.getSourceFormatStatusCounts(MediaType.anime);

          expect(counts['TV']?[ItemStatus.completed], 1);
          expect(counts['TV']?[ItemStatus.inProgress], 1);
          expect(counts['MOVIE']?[ItemStatus.completed], 1);
          expect(counts, hasLength(2));
        });

        test('should throw for media types without source formats', () {
          expect(
            () => dao.getSourceFormatStatusCounts(MediaType.game),
            throwsArgumentError,
          );
        });
      });

      group('getTopItemsByFormat', () {
        test('should cap the per-format list ordered by rating', () async {
          for (int i = 1; i <= 4; i++) {
            await insertItem(
              id: i,
              mediaType: 'anime',
              externalId: i,
              userRating: i.toDouble(),
            );
            await insertAnimeCache(id: i, format: 'TV');
          }

          final Map<String, List<int>> top =
              await dao.getTopItemsByFormat(MediaType.anime, perFormat: 2);

          expect(top['TV'], <int>[4, 3]);
        });
      });
    });

    group('getRatedItemIds', () {
      test('should return only rated items inside the window', () async {
        await insertItem(id: 1, userRating: 7, addedAt: in2024);
        await insertItem(id: 2, externalId: 101, addedAt: in2024);
        await insertItem(
            id: 3, externalId: 102, userRating: 5, addedAt: in2023);

        expect(await dao.getRatedItemIds(year: 2024), <int>[1]);
      });
    });

    group('getAvailableYears', () {
      test('should list years with items, newest first', () async {
        await insertItem(id: 1, addedAt: in2023);
        await insertItem(id: 2, externalId: 101, addedAt: in2024);

        expect(await dao.getAvailableYears(), <int>[2024, 2023]);
      });
    });

    group('getManualMinutes', () {
      test('should return 0 when nothing carries manual minutes', () async {
        await insertItem(id: 1);

        expect(await dao.getManualMinutes(), 0);
      });

      test('should sum manual minutes across items', () async {
        await insertItem(id: 1, timeSpentMinutes: 30);
        await insertItem(id: 2, externalId: 101, timeSpentMinutes: 45);

        expect(await dao.getManualMinutes(), 75);
      });

      test('should exclude movies, whose time comes from the runtime',
          () async {
        await insertItem(id: 1, timeSpentMinutes: 30);
        await insertItem(
          id: 2,
          externalId: 101,
          mediaType: 'movie',
          timeSpentMinutes: 120,
        );

        expect(await dao.getManualMinutes(), 30);
      });

      test('should only sum items added within the year window', () async {
        await insertItem(id: 1, timeSpentMinutes: 30, addedAt: in2024);
        await insertItem(
          id: 2,
          externalId: 101,
          timeSpentMinutes: 45,
          addedAt: in2023,
        );

        expect(await dao.getManualMinutes(year: 2024), 30);
      });
    });

    group('getEpisodesByMonth', () {
      Future<void> watch(int id, DateTime at) => db.insert(
            'watched_episodes',
            <String, Object?>{
              'id': id,
              'collection_id': 1,
              'show_id': 1,
              'season_number': 1,
              'episode_number': id,
              'watched_at': ms(at),
            },
          );

      test('should return an empty map when nothing was watched', () async {
        expect(await dao.getEpisodesByMonth(), isEmpty);
      });

      test('should bucket episodes by year-month', () async {
        await watch(1, DateTime(2024, 5, 1));
        await watch(2, DateTime(2024, 5, 20));
        await watch(3, DateTime(2024, 6, 2));

        expect(
          await dao.getEpisodesByMonth(),
          <String, int>{'2024-05': 2, '2024-06': 1},
        );
      });

      test('should only count episodes inside the year window', () async {
        await watch(1, DateTime(2024, 5, 1));
        await watch(2, DateTime(2023, 5, 1));

        expect(
          await dao.getEpisodesByMonth(year: 2024),
          <String, int>{'2024-05': 1},
        );
      });
    });

    group('getMonthAddedByDayType', () {
      test('should return empty for a month with no items', () async {
        expect(await dao.getMonthAddedByDayType(2024, 1), isEmpty);
      });

      test('should group by day of month and media type', () async {
        await insertItem(id: 1, addedAt: DateTime(2024, 5, 3));
        await insertItem(
          id: 2,
          externalId: 101,
          addedAt: DateTime(2024, 5, 3),
        );
        await insertItem(
          id: 3,
          externalId: 102,
          mediaType: 'movie',
          addedAt: DateTime(2024, 5, 7),
        );

        final List<(int, MediaType, int)> rows =
            await dao.getMonthAddedByDayType(2024, 5);

        expect(rows, contains((3, MediaType.game, 2)));
        expect(rows, contains((7, MediaType.movie, 1)));
      });

      test('should exclude items from neighbouring months', () async {
        await insertItem(id: 1, addedAt: DateTime(2024, 4, 30));
        await insertItem(id: 2, externalId: 101, addedAt: DateTime(2024, 6, 1));

        expect(await dao.getMonthAddedByDayType(2024, 5), isEmpty);
      });

      test('should handle December, where the window rolls over a year',
          () async {
        await insertItem(id: 1, addedAt: DateTime(2024, 12, 25));
        await insertItem(id: 2, externalId: 101, addedAt: DateTime(2025, 1, 2));

        expect(
          await dao.getMonthAddedByDayType(2024, 12),
          <(int, MediaType, int)>[(25, MediaType.game, 1)],
        );
      });

      test('should skip rows whose media type is not recognised', () async {
        await insertItem(id: 1, addedAt: DateTime(2024, 5, 3));
        await db.insert('collection_items', <String, Object?>{
          'id': 2,
          'collection_id': 1,
          'media_type': 'not_a_type',
          'external_id': 999,
          'status': 'not_started',
          'added_at': secs(DateTime(2024, 5, 4)),
          'sort_order': 2,
        });

        expect(
          await dao.getMonthAddedByDayType(2024, 5),
          <(int, MediaType, int)>[(3, MediaType.game, 1)],
        );
      });
    });

    group('getSourceTagCounts', () {
      Future<void> insertAnime(int id, String? tags) => db.insert(
            'anime_cache',
            <String, Object?>{
              'id': id,
              'source': 'anilist',
              'title': 'Anime $id',
              'tags': tags,
              'updated_at': 1700000000,
            },
          );

      test('should count each tag across the collected titles', () async {
        await insertAnime(1, jsonEncode(<String>['Mecha', 'Space']));
        await insertAnime(2, jsonEncode(<String>['Mecha']));
        await insertItem(id: 1, mediaType: 'anime', externalId: 1);
        await insertItem(id: 2, mediaType: 'anime', externalId: 2);

        final ({int titles, List<(String, int)> tags}) result =
            await dao.getSourceTagCounts(MediaType.anime);

        expect(result.titles, 2);
        expect(result.tags, contains(('Mecha', 2)));
        expect(result.tags, contains(('Space', 1)));
      });

      test('should ignore titles with no tags', () async {
        await insertAnime(1, null);
        await insertAnime(2, '');
        await insertAnime(3, jsonEncode(<String>[]));
        await insertItem(id: 1, mediaType: 'anime', externalId: 1);
        await insertItem(id: 2, mediaType: 'anime', externalId: 2);
        await insertItem(id: 3, mediaType: 'anime', externalId: 3);

        final ({int titles, List<(String, int)> tags}) result =
            await dao.getSourceTagCounts(MediaType.anime);

        expect(result.titles, 0);
        expect(result.tags, isEmpty);
      });

      test('should skip a row whose tags column is not valid JSON', () async {
        await insertAnime(1, 'not json at all');
        await insertAnime(2, jsonEncode(<String>['Mecha']));
        await insertItem(id: 1, mediaType: 'anime', externalId: 1);
        await insertItem(id: 2, mediaType: 'anime', externalId: 2);

        final ({int titles, List<(String, int)> tags}) result =
            await dao.getSourceTagCounts(MediaType.anime);

        expect(result.titles, 1);
        expect(result.tags, <(String, int)>[('Mecha', 1)]);
      });

      test('should skip a row whose tags JSON is not a list', () async {
        await insertAnime(1, jsonEncode(<String, String>{'a': 'b'}));
        await insertItem(id: 1, mediaType: 'anime', externalId: 1);

        final ({int titles, List<(String, int)> tags}) result =
            await dao.getSourceTagCounts(MediaType.anime);

        expect(result.titles, 0);
      });
    });
  });
}
