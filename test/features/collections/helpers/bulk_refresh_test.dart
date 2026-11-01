import 'package:core/models/collection_item.dart';
import 'package:core/models/media_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/core/api/igdb_api.dart';
import 'package:tonkatsu_box/core/database/database_service.dart';
import 'package:tonkatsu_box/core/import/import_progress.dart';
import 'package:tonkatsu_box/core/services/image_cache_service.dart';
import 'package:tonkatsu_box/features/collections/helpers/bulk_refresh.dart';
import 'package:tonkatsu_box/features/collections/helpers/item_refresh.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  setUpAll(registerAllFallbacks);

  late MockDatabaseService db;
  late MockGameDao gameDao;
  late MockImageCacheService cache;
  late MockIgdbApi igdb;
  WidgetRef? capturedRef;

  setUp(() {
    db = MockDatabaseService();
    gameDao = MockGameDao();
    cache = MockImageCacheService();
    igdb = MockIgdbApi();
    when(() => db.gameDao).thenReturn(gameDao);
    when(() => gameDao.upsertGame(any())).thenAnswer((_) async {});
    when(() => cache.deleteImage(any(), any())).thenAnswer((_) async {});
    when(() => cache.evictDecodedImage(any(), any())).thenAnswer((_) async {});
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
      ],
    );
    return capturedRef!;
  }

  /// One of each outcome: a hit, a miss, a throw, and a custom card.
  List<CollectionItem> mixedSelection() {
    when(() => igdb.getGameById(1))
        .thenAnswer((_) async => createTestGame(id: 1));
    when(() => igdb.getGameById(2)).thenAnswer((_) async => null);
    when(() => igdb.getGameById(3)).thenThrow(Exception('offline'));
    return <CollectionItem>[
      createTestCollectionItem(id: 1, externalId: 1),
      createTestCollectionItem(id: 2, externalId: 2),
      createTestCollectionItem(id: 3, externalId: 3),
      createTestCollectionItem(id: 4, mediaType: MediaType.custom),
    ];
  }

  group('runBulkRefresh', () {
    testWidgets('should tally every outcome and keep going past a failure',
        (WidgetTester tester) async {
      final WidgetRef ref = await pumpRef(tester);
      final List<ImportProgress> snapshots = <ImportProgress>[];

      final BulkRefreshResult result = await runBulkRefresh(
        ref,
        mixedSelection(),
        onProgress: snapshots.add,
      );

      expect(result.updated, 1);
      expect(result.notFound, 1);
      expect(result.failed, 1);
      expect(result.skipped, 1);
      expect(result.cancelled, isFalse);
      expect(
        result.problems.map((BulkRefreshProblem p) => p.kind),
        <RefreshOutcomeKind>[
          RefreshOutcomeKind.notFound,
          RefreshOutcomeKind.failed,
        ],
      );
      expect(result.problems.last.error, contains('offline'));
      verify(() => gameDao.upsertGame(any())).called(1);
      verify(() => cache.deleteImage(any(), any())).called(1);
    });

    testWidgets('should report skipped cards before the first request',
        (WidgetTester tester) async {
      final WidgetRef ref = await pumpRef(tester);
      final List<ImportProgress> snapshots = <ImportProgress>[];

      await runBulkRefresh(ref, mixedSelection(), onProgress: snapshots.add);

      expect(snapshots.first.skipped, 1);
      expect(snapshots.first.current, 0);
      expect(snapshots.first.total, 3);
      expect(snapshots.last.stage, ImportStage.completed);
      expect(snapshots.last.current, 3);
    });

    testWidgets('should finish the current item and stop after a cancel',
        (WidgetTester tester) async {
      final WidgetRef ref = await pumpRef(tester);
      final BulkRefreshCancellation cancellation = BulkRefreshCancellation();
      final List<CollectionItem> items = mixedSelection();

      final BulkRefreshResult result = await runBulkRefresh(
        ref,
        items,
        cancellation: cancellation,
        onProgress: (ImportProgress p) {
          if (p.currentItem != null) cancellation.request();
        },
      );

      expect(result.cancelled, isTrue);
      expect(result.updated, 1);
      expect(result.notFound, 0);
      expect(result.failed, 0);
      verify(() => igdb.getGameById(any())).called(1);
    });

    testWidgets('should not ask the source for a selection of custom cards',
        (WidgetTester tester) async {
      final WidgetRef ref = await pumpRef(tester);

      final BulkRefreshResult result = await runBulkRefresh(
        ref,
        <CollectionItem>[
          createTestCollectionItem(id: 1, mediaType: MediaType.custom),
          createTestCollectionItem(id: 2, mediaType: MediaType.custom),
        ],
        onProgress: (_) {},
      );

      expect(result.skipped, 2);
      expect(result.updated, 0);
      verifyNever(() => igdb.getGameById(any()));
      verifyNever(() => cache.deleteImage(any(), any()));
    });
  });
}
