import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:xerabora/core/database/dao/game_dao.dart';
import 'package:xerabora/shared/models/game.dart';
import 'package:xerabora/shared/models/platform.dart';

import '../../../helpers/mocks.dart';

void main() {
  late TransactionMockDatabase mockDb;
  late MockTransaction mockTxn;
  late MockBatch mockBatch;
  late GameDao dao;

  setUp(() {
    mockDb = TransactionMockDatabase();
    mockTxn = MockTransaction();
    mockBatch = MockBatch();
    dao = GameDao(() async => mockDb);
  });

  /// Настраивает мок транзакции: вызывает callback с mockTxn.
  void stubTransaction() {
    mockDb.stubTransaction(mockTxn);
    when(() => mockTxn.batch()).thenReturn(mockBatch);
    when(
      () => mockBatch.insert(
        any(),
        any(),
        conflictAlgorithm: any(named: 'conflictAlgorithm'),
      ),
    ).thenReturn(null);
    when(() => mockBatch.commit(noResult: true))
        .thenAnswer((_) async => <Object?>[]);
  }

  group('GameDao', () {
    // ==================== Platforms ====================

    group('getAllPlatforms', () {
      test('returns platforms ordered by name', () async {
        when(() => mockDb.query('platforms', orderBy: 'name ASC')).thenAnswer(
          (_) async => <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 1,
              'name': 'PlayStation',
              'abbreviation': 'PS',
            },
          ],
        );

        final List<Platform> result = await dao.getAllPlatforms();

        expect(result.length, 1);
        expect(result.first.name, 'PlayStation');
      });

      test('returns empty list when no platforms', () async {
        when(() => mockDb.query('platforms', orderBy: 'name ASC'))
            .thenAnswer((_) async => <Map<String, dynamic>>[]);

        final List<Platform> result = await dao.getAllPlatforms();

        expect(result, isEmpty);
      });
    });

    group('getPlatformById', () {
      test('returns null when not found', () async {
        when(
          () => mockDb.query(
            'platforms',
            where: 'id = ?',
            whereArgs: <Object?>[999],
            limit: 1,
          ),
        ).thenAnswer((_) async => <Map<String, dynamic>>[]);

        expect(await dao.getPlatformById(999), isNull);
      });

      test('returns platform when found', () async {
        when(
          () => mockDb.query(
            'platforms',
            where: 'id = ?',
            whereArgs: <Object?>[1],
            limit: 1,
          ),
        ).thenAnswer(
          (_) async => <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 1,
              'name': 'PS5',
              'abbreviation': 'PS5',
            },
          ],
        );

        final Platform? result = await dao.getPlatformById(1);

        expect(result, isNotNull);
        expect(result!.id, 1);
        expect(result.name, 'PS5');
      });
    });

    group('getPlatformCount', () {
      test('returns count from raw query', () async {
        when(() => mockDb.rawQuery('SELECT COUNT(*) as count FROM platforms'))
            .thenAnswer(
          (_) async => <Map<String, dynamic>>[
            <String, dynamic>{'count': 42},
          ],
        );

        expect(await dao.getPlatformCount(), 42);
      });
    });

    group('upsertPlatform', () {
      test('inserts with replace', () async {
        const Platform p = Platform(id: 1, name: 'PS5');
        when(
          () => mockDb.insert(
            'platforms',
            any(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          ),
        ).thenAnswer((_) async => 1);

        await dao.upsertPlatform(p);

        verify(
          () => mockDb.insert(
            'platforms',
            p.toDb(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          ),
        ).called(1);
      });
    });

    group('upsertPlatforms', () {
      test('uses transaction and batch', () async {
        stubTransaction();

        await dao.upsertPlatforms(const <Platform>[
          Platform(id: 1, name: 'PS5'),
          Platform(id: 2, name: 'Xbox'),
        ]);

        verify(
          () => mockBatch.insert(
            'platforms',
            any(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          ),
        ).called(2);
        verify(() => mockBatch.commit(noResult: true)).called(1);
      });
    });

    group('getPlatformsByIds', () {
      test('returns empty list for empty ids', () async {
        final List<Platform> result = await dao.getPlatformsByIds(<int>[]);

        expect(result, isEmpty);
      });

      test('queries with IN clause', () async {
        when(
          () => mockDb.query(
            'platforms',
            where: 'id IN (?,?)',
            whereArgs: <Object?>[1, 2],
          ),
        ).thenAnswer(
          (_) async => <Map<String, dynamic>>[
            <String, dynamic>{'id': 1, 'name': 'PS5', 'abbreviation': null},
          ],
        );

        final List<Platform> result =
            await dao.getPlatformsByIds(<int>[1, 2]);

        expect(result.length, 1);
      });
    });

    // ==================== Games ====================

    group('getGameById', () {
      test('returns null when not found', () async {
        when(
          () => mockDb.query(
            'games',
            where: 'id = ?',
            whereArgs: <Object?>[999],
            limit: 1,
          ),
        ).thenAnswer((_) async => <Map<String, dynamic>>[]);

        expect(await dao.getGameById(999), isNull);
      });

      test('returns game when found', () async {
        final Map<String, dynamic> row = <String, dynamic>{
          'id': 100,
          'name': 'Zelda',
          'summary': null,
          'cover_url': null,
          'release_date': null,
          'rating': null,
          'rating_count': null,
          'genres': null,
          'platform_ids': null,
          'external_url': null,
          'cached_at': 1000,
        };
        when(
          () => mockDb.query(
            'games',
            where: 'id = ?',
            whereArgs: <Object?>[100],
            limit: 1,
          ),
        ).thenAnswer((_) async => <Map<String, dynamic>>[row]);

        final Game? result = await dao.getGameById(100);

        expect(result, isNotNull);
        expect(result!.id, 100);
        expect(result.name, 'Zelda');
      });
    });

    group('getGamesByIds', () {
      test('returns empty list for empty ids', () async {
        expect(await dao.getGamesByIds(<int>[]), isEmpty);
      });

      test('queries with IN clause', () async {
        when(
          () => mockDb.query(
            'games',
            where: 'id IN (?,?)',
            whereArgs: <Object?>[1, 2],
          ),
        ).thenAnswer((_) async => <Map<String, dynamic>>[]);

        final List<Game> result = await dao.getGamesByIds(<int>[1, 2]);

        expect(result, isEmpty);
      });
    });

    group('searchGamesInCache', () {
      test('returns empty list for empty query', () async {
        expect(await dao.searchGamesInCache(''), isEmpty);
      });

      test('returns empty list for whitespace query', () async {
        expect(await dao.searchGamesInCache('  '), isEmpty);
      });

      test('queries with LIKE clause', () async {
        when(
          () => mockDb.query(
            'games',
            where: 'name LIKE ?',
            whereArgs: <Object?>['%zelda%'],
            orderBy: 'name ASC',
            limit: 20,
          ),
        ).thenAnswer((_) async => <Map<String, dynamic>>[]);

        await dao.searchGamesInCache('zelda');

        verify(
          () => mockDb.query(
            'games',
            where: 'name LIKE ?',
            whereArgs: <Object?>['%zelda%'],
            orderBy: 'name ASC',
            limit: 20,
          ),
        ).called(1);
      });

      test('respects custom limit', () async {
        when(
          () => mockDb.query(
            'games',
            where: 'name LIKE ?',
            whereArgs: <Object?>['%test%'],
            orderBy: 'name ASC',
            limit: 5,
          ),
        ).thenAnswer((_) async => <Map<String, dynamic>>[]);

        await dao.searchGamesInCache('test', limit: 5);

        verify(
          () => mockDb.query(
            'games',
            where: 'name LIKE ?',
            whereArgs: <Object?>['%test%'],
            orderBy: 'name ASC',
            limit: 5,
          ),
        ).called(1);
      });
    });

    group('getGameCount', () {
      test('returns count from raw query', () async {
        when(() => mockDb.rawQuery('SELECT COUNT(*) as count FROM games'))
            .thenAnswer(
          (_) async => <Map<String, dynamic>>[
            <String, dynamic>{'count': 10},
          ],
        );

        expect(await dao.getGameCount(), 10);
      });
    });

    group('upsertGame', () {
      test('inserts with replace', () async {
        const Game game = Game(id: 1, name: 'Test');
        when(
          () => mockDb.insert(
            'games',
            any(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          ),
        ).thenAnswer((_) async => 1);

        await dao.upsertGame(game);

        verify(
          () => mockDb.insert(
            'games',
            game.toDb(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          ),
        ).called(1);
      });
    });

    group('upsertGames', () {
      test('skips when list is empty', () async {
        await dao.upsertGames(<Game>[]);

        verifyNever(() => mockTxn.batch());
      });

      test('uses transaction and batch', () async {
        stubTransaction();

        await dao.upsertGames(const <Game>[
          Game(id: 1, name: 'G1'),
          Game(id: 2, name: 'G2'),
        ]);

        verify(
          () => mockBatch.insert(
            'games',
            any(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          ),
        ).called(2);
        verify(() => mockBatch.commit(noResult: true)).called(1);
      });
    });

    group('deleteGame', () {
      test('deletes by id', () async {
        when(
          () => mockDb.delete(
            'games',
            where: 'id = ?',
            whereArgs: <Object?>[42],
          ),
        ).thenAnswer((_) async => 1);

        await dao.deleteGame(42);

        verify(
          () => mockDb.delete(
            'games',
            where: 'id = ?',
            whereArgs: <Object?>[42],
          ),
        ).called(1);
      });
    });

    group('clearGames', () {
      test('deletes all games', () async {
        when(() => mockDb.delete('games')).thenAnswer((_) async => 5);

        await dao.clearGames();

        verify(() => mockDb.delete('games')).called(1);
      });
    });

    // ==================== IGDB Genres ====================

    group('getIgdbGenres', () {
      test('returns genres ordered by name', () async {
        when(() => mockDb.query('igdb_genres', orderBy: 'name ASC'))
            .thenAnswer(
          (_) async => <Map<String, dynamic>>[
            <String, dynamic>{'id': 1, 'name': 'Action'},
            <String, dynamic>{'id': 2, 'name': 'RPG'},
          ],
        );

        final List<Map<String, dynamic>> result = await dao.getIgdbGenres();

        expect(result.length, 2);
        expect(result.first['name'], 'Action');
      });
    });
  });
}
