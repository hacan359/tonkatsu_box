import 'dart:io';

import 'package:core/models/book.dart';
import 'package:core/models/data_source.dart';
import 'package:core/models/collection_item.dart';
import 'package:core/models/game.dart';
import 'package:core/models/media_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/core/api/fantlab_api.dart';
import 'package:tonkatsu_box/core/api/igdb_api.dart';
import 'package:tonkatsu_box/core/database/database_service.dart';
import 'package:tonkatsu_box/core/services/image_cache_service.dart';
import 'package:tonkatsu_box/features/collections/helpers/item_refresh.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    registerAllFallbacks();
    registerFallbackValue(createTestBook());
  });

  group('canRefreshFromSource', () {
    test('should accept every type that has a source API', () {
      for (final MediaType type in <MediaType>[
        MediaType.game,
        MediaType.movie,
        MediaType.tvShow,
        MediaType.animation,
        MediaType.anime,
        MediaType.manga,
        MediaType.visualNovel,
      ]) {
        expect(
          canRefreshFromSource(createTestCollectionItem(mediaType: type)),
          isTrue,
          reason: type.name,
        );
      }
    });

    test('should reject custom cards', () {
      expect(
        canRefreshFromSource(
          createTestCollectionItem(mediaType: MediaType.custom),
        ),
        isFalse,
      );
    });

    test('should accept audio only when the cached row is loaded', () {
      expect(
        canRefreshFromSource(createTestCollectionItem(
          mediaType: MediaType.audio,
          audioItem: createTestAudioItem(),
        )),
        isTrue,
      );
      expect(
        canRefreshFromSource(
          createTestCollectionItem(mediaType: MediaType.audio),
        ),
        isFalse,
      );
    });

    test('should accept books only from sources with a refresh path', () {
      for (final DataSource source in <DataSource>[
        DataSource.openLibrary,
        DataSource.fantlab,
        DataSource.comicVine,
        DataSource.googleBooks,
        DataSource.hardcover,
      ]) {
        expect(
          canRefreshFromSource(createTestCollectionItem(
            mediaType: MediaType.book,
            source: source,
            book: createTestBook(source: source),
          )),
          isTrue,
          reason: source.name,
        );
      }
      expect(
        canRefreshFromSource(createTestCollectionItem(
          mediaType: MediaType.book,
          source: DataSource.tmdb,
          book: createTestBook(),
        )),
        isFalse,
      );
      expect(
        canRefreshFromSource(createTestCollectionItem(
          mediaType: MediaType.book,
          source: DataSource.openLibrary,
        )),
        isFalse,
      );
    });
  });

  group('refreshItemFromSource', () {
    late MockDatabaseService db;
    late MockGameDao gameDao;
    late MockBookDao bookDao;
    late MockImageCacheService cache;
    late MockIgdbApi igdb;
    late MockFantlabApi fantlab;
    WidgetRef? capturedRef;

    setUp(() {
      db = MockDatabaseService();
      gameDao = MockGameDao();
      bookDao = MockBookDao();
      cache = MockImageCacheService();
      igdb = MockIgdbApi();
      fantlab = MockFantlabApi();
      when(() => db.gameDao).thenReturn(gameDao);
      when(() => db.bookDao).thenReturn(bookDao);
      when(() => gameDao.upsertGame(any())).thenAnswer((_) async {});
      when(() => bookDao.upsertBook(any())).thenAnswer((_) async {});
      when(() => cache.deleteImage(any(), any())).thenAnswer((_) async {});
      when(() => cache.evictDecodedImage(any(), any()))
          .thenAnswer((_) async {});
      capturedRef = null;
    });

    Future<WidgetRef> pumpRef(WidgetTester tester) async {
      await tester.pumpApp(
        Consumer(
          builder: (BuildContext context, WidgetRef ref, Widget? _) {
            capturedRef = ref;
            return const SizedBox.shrink();
          },
        ),
        overrides: <Override>[
          databaseServiceProvider.overrideWithValue(db),
          imageCacheServiceProvider.overrideWithValue(cache),
          igdbApiProvider.overrideWithValue(igdb),
          fantlabApiProvider.overrideWithValue(fantlab),
        ],
      );
      return capturedRef!;
    }

    testWidgets('should upsert and drop the cached cover on success',
        (WidgetTester tester) async {
      final WidgetRef ref = await pumpRef(tester);
      final Game game = createTestGame();
      when(() => igdb.getGameById(100)).thenAnswer((_) async => game);
      final CollectionItem item = createTestCollectionItem();

      final RefreshOutcome outcome = await refreshItemFromSource(ref, item);

      expect(outcome.kind, RefreshOutcomeKind.success);
      verify(() => gameDao.upsertGame(game)).called(1);
      verify(() => cache.deleteImage(
            item.cachedImageType,
            item.cachedCoverImageId,
          )).called(1);
      verify(() => cache.evictDecodedImage(
            item.cachedImageType,
            item.cachedCoverImageId,
          )).called(1);
    });

    testWidgets('should keep the cover when the source has no row',
        (WidgetTester tester) async {
      final WidgetRef ref = await pumpRef(tester);
      when(() => igdb.getGameById(100)).thenAnswer((_) async => null);

      final RefreshOutcome outcome =
          await refreshItemFromSource(ref, createTestCollectionItem());

      expect(outcome.kind, RefreshOutcomeKind.notFound);
      verifyNever(() => gameDao.upsertGame(any()));
      verifyNever(() => cache.deleteImage(any(), any()));
    });

    testWidgets('should report a thrown request as failed without touching the cover',
        (WidgetTester tester) async {
      final WidgetRef ref = await pumpRef(tester);
      when(() => igdb.getGameById(100)).thenThrow(Exception('boom'));

      final RefreshOutcome outcome =
          await refreshItemFromSource(ref, createTestCollectionItem());

      expect(outcome.kind, RefreshOutcomeKind.failed);
      expect(outcome.error, contains('boom'));
      verifyNever(() => cache.deleteImage(any(), any()));
    });

    testWidgets('should report a failing cover cleanup as failed, not throw',
        (WidgetTester tester) async {
      final WidgetRef ref = await pumpRef(tester);
      when(() => igdb.getGameById(100))
          .thenAnswer((_) async => createTestGame());
      when(() => cache.deleteImage(any(), any()))
          .thenThrow(const FileSystemException('locked'));

      final RefreshOutcome outcome =
          await refreshItemFromSource(ref, createTestCollectionItem());

      expect(outcome.kind, RefreshOutcomeKind.failed);
    });

    testWidgets('should refuse a custom card without any request',
        (WidgetTester tester) async {
      final WidgetRef ref = await pumpRef(tester);

      final RefreshOutcome outcome = await refreshItemFromSource(
        ref,
        createTestCollectionItem(mediaType: MediaType.custom),
      );

      expect(outcome.kind, RefreshOutcomeKind.unsupported);
      verifyNever(() => cache.deleteImage(any(), any()));
    });

    testWidgets('should keep a Fantlab cover in a bulk run and drop it otherwise',
        (WidgetTester tester) async {
      final WidgetRef ref = await pumpRef(tester);
      final Book fresh = createTestBook(source: DataSource.fantlab);
      when(() => fantlab.getWork(any())).thenAnswer((_) async => fresh);
      final CollectionItem item = createTestCollectionItem(
        mediaType: MediaType.book,
        source: DataSource.fantlab,
        book: createTestBook(source: DataSource.fantlab),
      );

      final RefreshOutcome bulk =
          await refreshItemFromSource(ref, item, bulk: true);
      expect(bulk.kind, RefreshOutcomeKind.success);
      verify(() => bookDao.upsertBook(fresh)).called(1);
      verifyNever(() => cache.deleteImage(any(), any()));

      final RefreshOutcome single = await refreshItemFromSource(ref, item);
      expect(single.kind, RefreshOutcomeKind.success);
      verify(() => cache.deleteImage(any(), any())).called(1);
    });
  });
}
