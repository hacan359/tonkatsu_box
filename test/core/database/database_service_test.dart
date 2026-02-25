// Интеграционные тесты для DatabaseService.
//
// Используют in-memory SQLite через sqflite_common_ffi для проверки
// реальной SQL-логики (UNIQUE constraints, sort_order и т.д.).

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Создаёт in-memory базу данных с минимальной схемой для тестов.
///
/// Включает таблицы collections и collection_items с partial unique indexes,
/// аналогичные production-схеме из DatabaseService.
Future<Database> _createTestDatabase() async {
  sqfliteFfiInit();
  final DatabaseFactory factory = databaseFactoryFfi;
  final Database db = await factory.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('PRAGMA foreign_keys = ON');

        await db.execute('''
          CREATE TABLE collections (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            author TEXT NOT NULL,
            type TEXT NOT NULL DEFAULT 'own',
            created_at INTEGER NOT NULL,
            original_snapshot TEXT,
            forked_from_author TEXT,
            forked_from_name TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE collection_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            collection_id INTEGER,
            media_type TEXT NOT NULL DEFAULT 'game',
            external_id INTEGER NOT NULL,
            platform_id INTEGER,
            current_season INTEGER DEFAULT 0,
            current_episode INTEGER DEFAULT 0,
            status TEXT DEFAULT 'not_started',
            author_comment TEXT,
            user_comment TEXT,
            added_at INTEGER NOT NULL,
            sort_order INTEGER NOT NULL DEFAULT 0,
            started_at INTEGER,
            completed_at INTEGER,
            last_activity_at INTEGER,
            user_rating INTEGER,
            FOREIGN KEY (collection_id) REFERENCES collections(id)
              ON DELETE CASCADE
          )
        ''');

        // Partial unique indexes v18 — включают platform_id.
        await db.execute('''
          CREATE UNIQUE INDEX idx_ci_coll
          ON collection_items(
            collection_id, media_type, external_id,
            COALESCE(platform_id, -1)
          )
          WHERE collection_id IS NOT NULL
        ''');
        await db.execute('''
          CREATE UNIQUE INDEX idx_ci_uncat
          ON collection_items(
            media_type, external_id, COALESCE(platform_id, -1)
          )
          WHERE collection_id IS NULL
        ''');
      },
      onConfigure: (Database db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    ),
  );
  return db;
}

/// Вставляет тестовую коллекцию и возвращает её ID.
Future<int> _insertCollection(Database db, String name) async {
  final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  return db.insert('collections', <String, dynamic>{
    'name': name,
    'author': 'Test Author',
    'type': 'own',
    'created_at': now,
  });
}

/// Вставляет элемент коллекции и возвращает его ID.
Future<int> _insertItem(
  Database db, {
  required int? collectionId,
  required int externalId,
  String mediaType = 'game',
  int sortOrder = 0,
  int? platformId,
}) async {
  final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  return db.insert('collection_items', <String, dynamic>{
    'collection_id': collectionId,
    'media_type': mediaType,
    'external_id': externalId,
    'platform_id': platformId,
    'added_at': now,
    'sort_order': sortOrder,
  });
}

/// Возвращает следующий sort_order для коллекции.
///
/// Логика зеркалит DatabaseService.getNextSortOrder().
Future<int> _getNextSortOrder(Database db, int? collectionId) async {
  final String where = collectionId != null
      ? 'WHERE collection_id = ?'
      : 'WHERE collection_id IS NULL';
  final List<Object?> args =
      collectionId != null ? <Object?>[collectionId] : <Object?>[];
  final List<Map<String, dynamic>> result = await db.rawQuery(
    'SELECT MAX(sort_order) AS max_sort FROM collection_items $where',
    args,
  );
  final int maxSort = (result.first['max_sort'] as int?) ?? -1;
  return maxSort + 1;
}

/// Обновляет collection_id элемента (перемещение).
///
/// Логика зеркалит DatabaseService.updateItemCollectionId().
Future<bool> _updateItemCollectionId(
  Database db,
  int id,
  int? collectionId,
) async {
  final int newSortOrder = await _getNextSortOrder(db, collectionId);
  try {
    await db.update(
      'collection_items',
      <String, dynamic>{
        'collection_id': collectionId,
        'sort_order': newSortOrder,
      },
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
    return true;
  } on DatabaseException catch (e) {
    if (e.isUniqueConstraintError()) {
      return false;
    }
    rethrow;
  }
}

/// Читает элемент по ID.
Future<Map<String, dynamic>?> _getItem(Database db, int id) async {
  final List<Map<String, dynamic>> rows = await db.query(
    'collection_items',
    where: 'id = ?',
    whereArgs: <Object?>[id],
    limit: 1,
  );
  if (rows.isEmpty) return null;
  return rows.first;
}

void main() {
  late Database db;

  setUp(() async {
    db = await _createTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  group('DatabaseService', () {
    group('updateItemCollectionId', () {
      test('должен перемещать элемент из одной коллекции в другую', () async {
        final int collA = await _insertCollection(db, 'Collection A');
        final int collB = await _insertCollection(db, 'Collection B');
        final int itemId = await _insertItem(
          db,
          collectionId: collA,
          externalId: 100,
        );

        final bool result = await _updateItemCollectionId(db, itemId, collB);

        expect(result, isTrue);

        final Map<String, dynamic>? item = await _getItem(db, itemId);
        expect(item, isNotNull);
        expect(item!['collection_id'], collB);
      });

      test('должен перемещать элемент в uncategorized (null collectionId)',
          () async {
        final int coll = await _insertCollection(db, 'Collection');
        final int itemId = await _insertItem(
          db,
          collectionId: coll,
          externalId: 200,
        );

        final bool result = await _updateItemCollectionId(db, itemId, null);

        expect(result, isTrue);

        final Map<String, dynamic>? item = await _getItem(db, itemId);
        expect(item, isNotNull);
        expect(item!['collection_id'], isNull);
      });

      test('должен перемещать uncategorized элемент в коллекцию', () async {
        final int coll = await _insertCollection(db, 'Collection');
        final int itemId = await _insertItem(
          db,
          collectionId: null,
          externalId: 300,
        );

        final bool result = await _updateItemCollectionId(db, itemId, coll);

        expect(result, isTrue);

        final Map<String, dynamic>? item = await _getItem(db, itemId);
        expect(item, isNotNull);
        expect(item!['collection_id'], coll);
      });

      test('должен обновлять sort_order для целевой коллекции', () async {
        final int coll = await _insertCollection(db, 'Collection');
        // Создаём существующий элемент в целевой коллекции (sort_order = 0).
        await _insertItem(
          db,
          collectionId: coll,
          externalId: 400,
          sortOrder: 0,
        );

        // Создаём элемент в uncategorized и перемещаем.
        final int movingItemId = await _insertItem(
          db,
          collectionId: null,
          externalId: 500,
          sortOrder: 0,
        );

        final bool result =
            await _updateItemCollectionId(db, movingItemId, coll);

        expect(result, isTrue);

        final Map<String, dynamic>? item = await _getItem(db, movingItemId);
        expect(item, isNotNull);
        // sort_order должен быть 1 (MAX(0) + 1).
        expect(item!['sort_order'], 1);
      });

      test(
          'должен возвращать false при UNIQUE constraint violation '
          '(элемент уже есть в целевой коллекции)', () async {
        final int coll = await _insertCollection(db, 'Collection');

        // Создаём элемент в коллекции: game, external_id=600.
        await _insertItem(
          db,
          collectionId: coll,
          externalId: 600,
          mediaType: 'game',
        );

        // Создаём такой же элемент в uncategorized и пытаемся переместить.
        final int duplicateId = await _insertItem(
          db,
          collectionId: null,
          externalId: 600,
          mediaType: 'game',
        );

        final bool result =
            await _updateItemCollectionId(db, duplicateId, coll);

        expect(result, isFalse);
      });

      test(
          'должен возвращать false при UNIQUE constraint violation '
          'при перемещении в uncategorized', () async {
        final int coll = await _insertCollection(db, 'Collection');

        // Создаём uncategorized элемент: game, external_id=700.
        await _insertItem(
          db,
          collectionId: null,
          externalId: 700,
          mediaType: 'game',
        );

        // Создаём такой же в коллекции и пытаемся переместить в uncategorized.
        final int duplicateId = await _insertItem(
          db,
          collectionId: coll,
          externalId: 700,
          mediaType: 'game',
        );

        final bool result =
            await _updateItemCollectionId(db, duplicateId, null);

        expect(result, isFalse);
      });

      test(
          'должен разрешать одинаковые элементы в разных коллекциях', () async {
        final int collA = await _insertCollection(db, 'Collection A');
        final int collB = await _insertCollection(db, 'Collection B');

        // Создаём элемент в коллекции B: game, external_id=800.
        await _insertItem(
          db,
          collectionId: collB,
          externalId: 800,
          mediaType: 'game',
        );

        // Создаём такой же в коллекции A — НЕ дубликат, разные коллекции.
        final int itemId = await _insertItem(
          db,
          collectionId: collA,
          externalId: 900,
          mediaType: 'game',
        );

        // Перемещаем из A в B (другой external_id) — должно работать.
        final bool result = await _updateItemCollectionId(db, itemId, collB);

        expect(result, isTrue);
      });
    });

    // ==================== Multi-platform UNIQUE ====================

    group('multi-platform UNIQUE index (v18)', () {
      test(
          'должен разрешать одну игру с разными платформами в одной коллекции',
          () async {
        final int coll = await _insertCollection(db, 'Games');

        // Castlevania на SNES (platformId=19)
        final int item1 = await _insertItem(
          db,
          collectionId: coll,
          externalId: 1000,
          platformId: 19,
        );
        // Castlevania на GBA (platformId=24)
        final int item2 = await _insertItem(
          db,
          collectionId: coll,
          externalId: 1000,
          platformId: 24,
        );

        expect(item1, isNot(item2));

        // Оба элемента существуют.
        final Map<String, dynamic>? row1 = await _getItem(db, item1);
        final Map<String, dynamic>? row2 = await _getItem(db, item2);
        expect(row1, isNotNull);
        expect(row2, isNotNull);
        expect(row1!['platform_id'], 19);
        expect(row2!['platform_id'], 24);
      });

      test(
          'должен запрещать дубль одной игры с той же платформой в коллекции',
          () async {
        final int coll = await _insertCollection(db, 'Games');

        await _insertItem(
          db,
          collectionId: coll,
          externalId: 2000,
          platformId: 19,
        );

        // Повторная вставка с тем же external_id + platform_id → ошибка.
        expect(
          () => _insertItem(
            db,
            collectionId: coll,
            externalId: 2000,
            platformId: 19,
          ),
          throwsA(isA<DatabaseException>()),
        );
      });

      test(
          'должен разрешать одну игру с NULL и не-NULL платформами',
          () async {
        final int coll = await _insertCollection(db, 'Games');

        // Элемент без платформы (фильм, например).
        final int item1 = await _insertItem(
          db,
          collectionId: coll,
          externalId: 3000,
          mediaType: 'movie',
        );
        // Тот же external_id, но как game с платформой.
        final int item2 = await _insertItem(
          db,
          collectionId: coll,
          externalId: 3000,
          mediaType: 'game',
          platformId: 19,
        );

        expect(item1, isNot(item2));
      });

      test(
          'должен запрещать дубль с NULL платформой (фильмы) в коллекции',
          () async {
        final int coll = await _insertCollection(db, 'Movies');

        await _insertItem(
          db,
          collectionId: coll,
          externalId: 4000,
          mediaType: 'movie',
        );

        // Повторная вставка: тот же movie, null platform → ошибка.
        expect(
          () => _insertItem(
            db,
            collectionId: coll,
            externalId: 4000,
            mediaType: 'movie',
          ),
          throwsA(isA<DatabaseException>()),
        );
      });

      test(
          'должен разрешать одну игру с разными платформами в uncategorized',
          () async {
        final int item1 = await _insertItem(
          db,
          collectionId: null,
          externalId: 5000,
          platformId: 19,
        );
        final int item2 = await _insertItem(
          db,
          collectionId: null,
          externalId: 5000,
          platformId: 24,
        );

        expect(item1, isNot(item2));
      });

      test(
          'должен запрещать дубль с той же платформой в uncategorized',
          () async {
        await _insertItem(
          db,
          collectionId: null,
          externalId: 6000,
          platformId: 19,
        );

        expect(
          () => _insertItem(
            db,
            collectionId: null,
            externalId: 6000,
            platformId: 19,
          ),
          throwsA(isA<DatabaseException>()),
        );
      });

      test(
          'должен корректно перемещать multi-platform элемент между коллекциями',
          () async {
        final int collA = await _insertCollection(db, 'Collection A');
        final int collB = await _insertCollection(db, 'Collection B');

        // Игра SNES в коллекции A.
        final int itemId = await _insertItem(
          db,
          collectionId: collA,
          externalId: 7000,
          platformId: 19,
        );

        // Перемещаем в B.
        final bool result = await _updateItemCollectionId(db, itemId, collB);
        expect(result, isTrue);

        final Map<String, dynamic>? item = await _getItem(db, itemId);
        expect(item!['collection_id'], collB);
        expect(item['platform_id'], 19);
      });
    });

    // ==================== getUniquePlatformIds ====================

    group('getUniquePlatformIds', () {
      test('должен возвращать уникальные platform_id из игр', () async {
        final int coll = await _insertCollection(db, 'Games');
        await _insertItem(
          db,
          collectionId: coll,
          externalId: 100,
          platformId: 19,
        );
        await _insertItem(
          db,
          collectionId: coll,
          externalId: 200,
          platformId: 24,
        );
        await _insertItem(
          db,
          collectionId: coll,
          externalId: 300,
          platformId: 19, // дубль платформы
        );

        final List<Map<String, dynamic>> rows = await db.rawQuery('''
          SELECT DISTINCT platform_id FROM collection_items
          WHERE media_type = 'game'
            AND platform_id IS NOT NULL
            AND platform_id != -1
            AND collection_id = ?
          ORDER BY platform_id
        ''', <Object?>[coll]);
        final List<int> ids =
            rows.map((Map<String, dynamic> r) => r['platform_id'] as int).toList();

        expect(ids, <int>[19, 24]);
      });

      test('должен игнорировать элементы с NULL platform_id', () async {
        final int coll = await _insertCollection(db, 'Mixed');
        // Фильм без платформы.
        await _insertItem(
          db,
          collectionId: coll,
          externalId: 400,
          mediaType: 'movie',
        );
        // Игра с платформой.
        await _insertItem(
          db,
          collectionId: coll,
          externalId: 500,
          platformId: 33,
        );

        final List<Map<String, dynamic>> rows = await db.rawQuery('''
          SELECT DISTINCT platform_id FROM collection_items
          WHERE media_type = 'game'
            AND platform_id IS NOT NULL
            AND platform_id != -1
            AND collection_id = ?
          ORDER BY platform_id
        ''', <Object?>[coll]);
        final List<int> ids =
            rows.map((Map<String, dynamic> r) => r['platform_id'] as int).toList();

        expect(ids, <int>[33]);
      });

      test('должен возвращать пустой список для пустой коллекции', () async {
        final int coll = await _insertCollection(db, 'Empty');

        final List<Map<String, dynamic>> rows = await db.rawQuery('''
          SELECT DISTINCT platform_id FROM collection_items
          WHERE media_type = 'game'
            AND platform_id IS NOT NULL
            AND platform_id != -1
            AND collection_id = ?
          ORDER BY platform_id
        ''', <Object?>[coll]);

        expect(rows, isEmpty);
      });

      test('должен возвращать платформы из всех коллекций без фильтра',
          () async {
        final int collA = await _insertCollection(db, 'Collection A');
        final int collB = await _insertCollection(db, 'Collection B');

        await _insertItem(
          db,
          collectionId: collA,
          externalId: 600,
          platformId: 19,
        );
        await _insertItem(
          db,
          collectionId: collB,
          externalId: 700,
          platformId: 24,
        );

        final List<Map<String, dynamic>> rows = await db.rawQuery('''
          SELECT DISTINCT platform_id FROM collection_items
          WHERE media_type = 'game'
            AND platform_id IS NOT NULL
            AND platform_id != -1
          ORDER BY platform_id
        ''');
        final List<int> ids =
            rows.map((Map<String, dynamic> r) => r['platform_id'] as int).toList();

        expect(ids, <int>[19, 24]);
      });
    });
  });

  group('Wishlist CRUD', () {
    late Database db;

    setUp(() async {
      sqfliteFfiInit();
      final DatabaseFactory factory = databaseFactoryFfi;
      db = await factory.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 1,
          singleInstance: false,
          onCreate: (Database db, int version) async {
            await db.execute('''
              CREATE TABLE wishlist (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                text TEXT NOT NULL,
                media_type_hint TEXT,
                note TEXT,
                is_resolved INTEGER NOT NULL DEFAULT 0,
                created_at INTEGER NOT NULL,
                resolved_at INTEGER
              )
            ''');
          },
        ),
      );
    });

    tearDown(() async {
      await db.close();
    });

    Future<int> insertWishlistItem(
      String text, {
      String? mediaTypeHint,
      String? note,
      int isResolved = 0,
      int? resolvedAt,
    }) async {
      final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return db.insert('wishlist', <String, dynamic>{
        'text': text,
        'media_type_hint': mediaTypeHint,
        'note': note,
        'is_resolved': isResolved,
        'created_at': now,
        'resolved_at': resolvedAt,
      });
    }

    test('добавляет элемент в wishlist', () async {
      final int id = await insertWishlistItem('Chrono Trigger');

      expect(id, greaterThan(0));

      final List<Map<String, dynamic>> rows = await db.query('wishlist');
      expect(rows.length, 1);
      expect(rows.first['text'], 'Chrono Trigger');
      expect(rows.first['is_resolved'], 0);
      expect(rows.first['media_type_hint'], null);
    });

    test('добавляет элемент с типом медиа и заметкой', () async {
      await insertWishlistItem(
        'The Matrix',
        mediaTypeHint: 'movie',
        note: 'Классика',
      );

      final List<Map<String, dynamic>> rows = await db.query('wishlist');
      expect(rows.first['text'], 'The Matrix');
      expect(rows.first['media_type_hint'], 'movie');
      expect(rows.first['note'], 'Классика');
    });

    test('возвращает все элементы (включая resolved)', () async {
      await insertWishlistItem('Game 1');
      await insertWishlistItem('Game 2', isResolved: 1);
      await insertWishlistItem('Game 3');

      final List<Map<String, dynamic>> rows = await db.query('wishlist');
      expect(rows.length, 3);
    });

    test('фильтрует только активные элементы', () async {
      await insertWishlistItem('Active 1');
      await insertWishlistItem('Resolved', isResolved: 1);
      await insertWishlistItem('Active 2');

      final List<Map<String, dynamic>> rows = await db.query(
        'wishlist',
        where: 'is_resolved = 0',
      );
      expect(rows.length, 2);
    });

    test('считает активные элементы', () async {
      await insertWishlistItem('Active 1');
      await insertWishlistItem('Resolved', isResolved: 1);
      await insertWishlistItem('Active 2');

      final List<Map<String, dynamic>> result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM wishlist WHERE is_resolved = 0',
      );
      expect(result.first['count'], 2);
    });

    test('считает все элементы', () async {
      await insertWishlistItem('Item 1');
      await insertWishlistItem('Item 2', isResolved: 1);

      final List<Map<String, dynamic>> result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM wishlist',
      );
      expect(result.first['count'], 2);
    });

    test('обновляет текст элемента', () async {
      final int id = await insertWishlistItem('Old Title');

      await db.update(
        'wishlist',
        <String, dynamic>{'text': 'New Title'},
        where: 'id = ?',
        whereArgs: <Object?>[id],
      );

      final List<Map<String, dynamic>> rows = await db.query(
        'wishlist',
        where: 'id = ?',
        whereArgs: <Object?>[id],
      );
      expect(rows.first['text'], 'New Title');
    });

    test('обновляет тип медиа', () async {
      final int id = await insertWishlistItem('Test');

      await db.update(
        'wishlist',
        <String, dynamic>{'media_type_hint': 'game'},
        where: 'id = ?',
        whereArgs: <Object?>[id],
      );

      final List<Map<String, dynamic>> rows = await db.query(
        'wishlist',
        where: 'id = ?',
        whereArgs: <Object?>[id],
      );
      expect(rows.first['media_type_hint'], 'game');
    });

    test('помечает элемент как resolved', () async {
      final int id = await insertWishlistItem('Chrono Trigger');
      final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      await db.update(
        'wishlist',
        <String, dynamic>{'is_resolved': 1, 'resolved_at': now},
        where: 'id = ?',
        whereArgs: <Object?>[id],
      );

      final List<Map<String, dynamic>> rows = await db.query(
        'wishlist',
        where: 'id = ?',
        whereArgs: <Object?>[id],
      );
      expect(rows.first['is_resolved'], 1);
      expect(rows.first['resolved_at'], isNotNull);
    });

    test('снимает отметку resolved', () async {
      final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final int id = await insertWishlistItem(
        'Chrono Trigger',
        isResolved: 1,
        resolvedAt: now,
      );

      await db.update(
        'wishlist',
        <String, dynamic>{'is_resolved': 0, 'resolved_at': null},
        where: 'id = ?',
        whereArgs: <Object?>[id],
      );

      final List<Map<String, dynamic>> rows = await db.query(
        'wishlist',
        where: 'id = ?',
        whereArgs: <Object?>[id],
      );
      expect(rows.first['is_resolved'], 0);
      expect(rows.first['resolved_at'], null);
    });

    test('удаляет элемент', () async {
      final int id = await insertWishlistItem('To Delete');

      await db.delete('wishlist', where: 'id = ?', whereArgs: <Object?>[id]);

      final List<Map<String, dynamic>> rows = await db.query('wishlist');
      expect(rows.isEmpty, true);
    });

    test('удаляет все resolved элементы', () async {
      await insertWishlistItem('Active');
      await insertWishlistItem('Resolved 1', isResolved: 1);
      await insertWishlistItem('Resolved 2', isResolved: 1);

      final int deleted = await db.delete(
        'wishlist',
        where: 'is_resolved = 1',
      );

      expect(deleted, 2);
      final List<Map<String, dynamic>> rows = await db.query('wishlist');
      expect(rows.length, 1);
      expect(rows.first['text'], 'Active');
    });

    test('сортирует: активные первыми, по дате создания DESC', () async {
      // Создаём с задержкой для разных created_at
      await insertWishlistItem('Old Active');
      await insertWishlistItem('Resolved', isResolved: 1);
      await insertWishlistItem('New Active');

      final List<Map<String, dynamic>> rows = await db.rawQuery(
        'SELECT * FROM wishlist ORDER BY is_resolved ASC, created_at DESC',
      );

      expect(rows.length, 3);
      // Активные первые (is_resolved=0), resolved в конце
      expect(rows[0]['is_resolved'], 0);
      expect(rows[1]['is_resolved'], 0);
      expect(rows[2]['is_resolved'], 1);
    });
  });

  group('updateItemStatus — логика дат', () {
    late Database db;

    setUp(() async {
      db = await _createTestDatabase();
    });

    tearDown(() async {
      await db.close();
    });

    /// Вставляет item с заданными started_at / completed_at.
    Future<int> insertItemWithDates({
      String status = 'not_started',
      int? startedAt,
      int? completedAt,
    }) async {
      final int collId = await _insertCollection(db, 'Test');
      return db.insert('collection_items', <String, dynamic>{
        'collection_id': collId,
        'media_type': 'tv_show',
        'external_id': 100,
        'added_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'sort_order': 0,
        'status': status,
        'started_at': startedAt,
        'completed_at': completedAt,
      });
    }

    /// Зеркалит DatabaseService.updateItemStatus().
    Future<void> updateItemStatus(int id, String status) async {
      final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      final Map<String, dynamic> updateData = <String, dynamic>{
        'status': status,
        'last_activity_at': now,
      };

      final List<Map<String, dynamic>> rows = await db.query(
        'collection_items',
        columns: <String>['started_at'],
        where: 'id = ?',
        whereArgs: <Object?>[id],
        limit: 1,
      );

      final bool hasStartedAt =
          rows.isNotEmpty && rows.first['started_at'] != null;

      if (status == 'not_started') {
        updateData['started_at'] = null;
        updateData['completed_at'] = null;
      } else if (status == 'in_progress') {
        updateData['completed_at'] = null;
        if (!hasStartedAt) {
          updateData['started_at'] = now;
        }
      } else if (status == 'completed') {
        updateData['completed_at'] = now;
        if (!hasStartedAt) {
          updateData['started_at'] = now;
        }
      }

      await db.update(
        'collection_items',
        updateData,
        where: 'id = ?',
        whereArgs: <Object?>[id],
      );
    }

    Map<String, dynamic> getRow(List<Map<String, dynamic>> rows) => rows.first;

    test('inProgress без started_at → ставит started_at', () async {
      final int id = await insertItemWithDates();
      await updateItemStatus(id, 'in_progress');

      final List<Map<String, dynamic>> rows = await db.query(
        'collection_items',
        where: 'id = ?',
        whereArgs: <Object?>[id],
      );
      final Map<String, dynamic> row = getRow(rows);

      expect(row['status'], 'in_progress');
      expect(row['started_at'], isNotNull);
      expect(row['completed_at'], isNull);
    });

    test('inProgress с started_at → не перезаписывает started_at', () async {
      final int oldStarted = DateTime(2024).millisecondsSinceEpoch ~/ 1000;
      final int id = await insertItemWithDates(
        status: 'in_progress',
        startedAt: oldStarted,
        completedAt: 999999,
      );
      await updateItemStatus(id, 'in_progress');

      final List<Map<String, dynamic>> rows = await db.query(
        'collection_items',
        where: 'id = ?',
        whereArgs: <Object?>[id],
      );
      final Map<String, dynamic> row = getRow(rows);

      expect(row['started_at'], oldStarted);
      expect(row['completed_at'], isNull);
    });

    test('completed → ставит completed_at и started_at (если null)', () async {
      final int id = await insertItemWithDates();
      await updateItemStatus(id, 'completed');

      final List<Map<String, dynamic>> rows = await db.query(
        'collection_items',
        where: 'id = ?',
        whereArgs: <Object?>[id],
      );
      final Map<String, dynamic> row = getRow(rows);

      expect(row['status'], 'completed');
      expect(row['started_at'], isNotNull);
      expect(row['completed_at'], isNotNull);
    });

    test('completed с существующим started_at → не перезаписывает', () async {
      final int oldStarted = DateTime(2024).millisecondsSinceEpoch ~/ 1000;
      final int id = await insertItemWithDates(
        status: 'in_progress',
        startedAt: oldStarted,
      );
      await updateItemStatus(id, 'completed');

      final List<Map<String, dynamic>> rows = await db.query(
        'collection_items',
        where: 'id = ?',
        whereArgs: <Object?>[id],
      );
      final Map<String, dynamic> row = getRow(rows);

      expect(row['started_at'], oldStarted);
      expect(row['completed_at'], isNotNull);
    });

    test('notStarted → сбрасывает started_at и completed_at', () async {
      final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final int id = await insertItemWithDates(
        status: 'completed',
        startedAt: now,
        completedAt: now,
      );
      await updateItemStatus(id, 'not_started');

      final List<Map<String, dynamic>> rows = await db.query(
        'collection_items',
        where: 'id = ?',
        whereArgs: <Object?>[id],
      );
      final Map<String, dynamic> row = getRow(rows);

      expect(row['status'], 'not_started');
      expect(row['started_at'], isNull);
      expect(row['completed_at'], isNull);
    });

    test('inProgress → сбрасывает completed_at, сохраняет started_at', () async {
      final int oldStarted = DateTime(2024).millisecondsSinceEpoch ~/ 1000;
      final int oldCompleted = DateTime(2025).millisecondsSinceEpoch ~/ 1000;
      final int id = await insertItemWithDates(
        status: 'completed',
        startedAt: oldStarted,
        completedAt: oldCompleted,
      );
      await updateItemStatus(id, 'in_progress');

      final List<Map<String, dynamic>> rows = await db.query(
        'collection_items',
        where: 'id = ?',
        whereArgs: <Object?>[id],
      );
      final Map<String, dynamic> row = getRow(rows);

      expect(row['status'], 'in_progress');
      expect(row['started_at'], oldStarted);
      expect(row['completed_at'], isNull);
    });
  });
}
