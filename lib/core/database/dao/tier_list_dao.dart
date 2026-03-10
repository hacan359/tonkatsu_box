// DAO для работы с тир-листами.

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../shared/models/tier_definition.dart';
import '../../../shared/models/tier_list.dart';
import '../../../shared/models/tier_list_entry.dart';

/// DAO для таблиц `tier_lists`, `tier_definitions`, `tier_list_entries`.
class TierListDao {
  /// Создаёт DAO с функцией получения базы данных.
  const TierListDao(this._getDatabase);

  final Future<Database> Function() _getDatabase;

  // ==================== Tier Lists ====================

  /// Возвращает все тир-листы, отсортированные по дате создания (новые первые).
  Future<List<TierList>> getAllTierLists() async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'tier_lists',
      orderBy: 'created_at DESC',
    );
    return rows.map(TierList.fromDb).toList();
  }

  /// Возвращает тир-листы привязанные к коллекции.
  Future<List<TierList>> getTierListsByCollection(int collectionId) async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'tier_lists',
      where: 'collection_id = ?',
      whereArgs: <Object?>[collectionId],
      orderBy: 'created_at DESC',
    );
    return rows.map(TierList.fromDb).toList();
  }

  /// Возвращает тир-лист по ID.
  Future<TierList?> getTierListById(int id) async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'tier_lists',
      where: 'id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return TierList.fromDb(rows.first);
  }

  /// Создаёт тир-лист и возвращает его.
  Future<TierList> createTierList(
    String name, {
    int? collectionId,
  }) async {
    final Database db = await _getDatabase();
    final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final int id = await db.insert(
      'tier_lists',
      <String, dynamic>{
        'name': name,
        'collection_id': collectionId,
        'created_at': now,
      },
    );

    return TierList(
      id: id,
      name: name,
      collectionId: collectionId,
      createdAt: DateTime.fromMillisecondsSinceEpoch(now * 1000),
    );
  }

  /// Переименовывает тир-лист.
  Future<void> renameTierList(int id, String name) async {
    final Database db = await _getDatabase();
    await db.update(
      'tier_lists',
      <String, dynamic>{'name': name},
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  /// Удаляет тир-лист (CASCADE удалит definitions и entries).
  Future<void> deleteTierList(int id) async {
    final Database db = await _getDatabase();
    await db.delete(
      'tier_lists',
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  // ==================== Definitions ====================

  /// Возвращает определения тиров для тир-листа.
  Future<List<TierDefinition>> getTierDefinitions(int tierListId) async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'tier_definitions',
      where: 'tier_list_id = ?',
      whereArgs: <Object?>[tierListId],
      orderBy: 'sort_order ASC',
    );
    return rows.map(TierDefinition.fromDb).toList();
  }

  /// Сохраняет определения тиров (удаляет старые, вставляет новые).
  Future<void> saveTierDefinitions(
    int tierListId,
    List<TierDefinition> definitions,
  ) async {
    final Database db = await _getDatabase();
    await db.transaction((Transaction txn) async {
      await txn.delete(
        'tier_definitions',
        where: 'tier_list_id = ?',
        whereArgs: <Object?>[tierListId],
      );
      for (final TierDefinition def in definitions) {
        await txn.insert('tier_definitions', def.toDb(tierListId));
      }
    });
  }

  // ==================== Entries ====================

  /// Возвращает все записи тир-листа.
  Future<List<TierListEntry>> getTierListEntries(int tierListId) async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'tier_list_entries',
      where: 'tier_list_id = ?',
      whereArgs: <Object?>[tierListId],
      orderBy: 'sort_order ASC',
    );
    return rows.map(TierListEntry.fromDb).toList();
  }

  /// Устанавливает тир для элемента (INSERT OR REPLACE).
  Future<void> setItemTier(
    int tierListId,
    int collectionItemId,
    String tierKey,
    int sortOrder,
  ) async {
    final Database db = await _getDatabase();
    // Удалить старую запись, если есть
    await db.delete(
      'tier_list_entries',
      where: 'tier_list_id = ? AND collection_item_id = ?',
      whereArgs: <Object?>[tierListId, collectionItemId],
    );
    // Вставить новую
    await db.insert(
      'tier_list_entries',
      <String, dynamic>{
        'tier_list_id': tierListId,
        'collection_item_id': collectionItemId,
        'tier_key': tierKey,
        'sort_order': sortOrder,
      },
    );
  }

  /// Удаляет элемент из тира (возвращает в Unranked).
  Future<void> removeItemFromTier(
    int tierListId,
    int collectionItemId,
  ) async {
    final Database db = await _getDatabase();
    await db.delete(
      'tier_list_entries',
      where: 'tier_list_id = ? AND collection_item_id = ?',
      whereArgs: <Object?>[tierListId, collectionItemId],
    );
  }

  /// Переупорядочивает элементы в тире.
  Future<void> reorderTierItems(
    int tierListId,
    String tierKey,
    List<int> itemIds,
  ) async {
    final Database db = await _getDatabase();
    await db.transaction((Transaction txn) async {
      for (int i = 0; i < itemIds.length; i++) {
        await txn.update(
          'tier_list_entries',
          <String, dynamic>{'sort_order': i},
          where:
              'tier_list_id = ? AND collection_item_id = ? AND tier_key = ?',
          whereArgs: <Object?>[tierListId, itemIds[i], tierKey],
        );
      }
    });
  }

  /// Очищает все записи тир-листа (все элементы возвращаются в Unranked).
  Future<void> clearTierListEntries(int tierListId) async {
    final Database db = await _getDatabase();
    await db.delete(
      'tier_list_entries',
      where: 'tier_list_id = ?',
      whereArgs: <Object?>[tierListId],
    );
  }

  /// Возвращает количество распределённых элементов в тир-листе.
  Future<int> getRankedCount(int tierListId) async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM tier_list_entries WHERE tier_list_id = ?',
      <Object?>[tierListId],
    );
    return result.first['count'] as int;
  }
}
