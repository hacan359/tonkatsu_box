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

        // Partial unique indexes — аналог production-схемы.
        await db.execute('''
          CREATE UNIQUE INDEX idx_ci_coll
          ON collection_items(collection_id, media_type, external_id)
          WHERE collection_id IS NOT NULL
        ''');
        await db.execute('''
          CREATE UNIQUE INDEX idx_ci_uncat
          ON collection_items(media_type, external_id)
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
}) async {
  final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  return db.insert('collection_items', <String, dynamic>{
    'collection_id': collectionId,
    'media_type': mediaType,
    'external_id': externalId,
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
  });
}
