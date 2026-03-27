// DAO для работы с кастомными элементами.

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../shared/models/custom_media.dart';

/// DAO для таблицы `custom_items`.
class CustomMediaDao {
  /// Создаёт DAO с функцией получения базы данных.
  const CustomMediaDao(this._getDatabase);

  final Future<Database> Function() _getDatabase;

  /// Создаёт кастомный элемент. Возвращает ID.
  Future<int> create(CustomMedia item) async {
    final Database db = await _getDatabase();
    final Map<String, dynamic> data = item.toDb();
    data.remove('id'); // autoincrement
    return db.insert('custom_items', data);
  }

  /// Обновляет кастомный элемент.
  Future<void> update(CustomMedia item) async {
    final Database db = await _getDatabase();
    await db.update(
      'custom_items',
      item.toDb(),
      where: 'id = ?',
      whereArgs: <Object?>[item.id],
    );
  }

  /// Получает кастомный элемент по ID.
  Future<CustomMedia?> getById(int id) async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'custom_items',
      where: 'id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return CustomMedia.fromDb(rows.first);
  }

  /// Получает кастомные элементы по списку ID.
  Future<List<CustomMedia>> getByIds(List<int> ids) async {
    if (ids.isEmpty) return <CustomMedia>[];
    final Database db = await _getDatabase();
    final String placeholders =
        List<String>.filled(ids.length, '?').join(',');
    final List<Map<String, dynamic>> rows = await db.rawQuery(
      'SELECT * FROM custom_items WHERE id IN ($placeholders)',
      ids,
    );
    return rows.map(CustomMedia.fromDb).toList();
  }

  /// Сохраняет или обновляет кастомный элемент (для импорта).
  Future<void> upsert(CustomMedia item) async {
    final Database db = await _getDatabase();
    await db.insert(
      'custom_items',
      item.toDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Сохраняет или обновляет список кастомных элементов (для импорта).
  Future<void> upsertAll(List<CustomMedia> items) async {
    if (items.isEmpty) return;
    final Database db = await _getDatabase();
    final Batch batch = db.batch();
    for (final CustomMedia item in items) {
      batch.insert(
        'custom_items',
        item.toDb(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// Удаляет кастомный элемент по ID.
  Future<void> delete(int id) async {
    final Database db = await _getDatabase();
    await db.delete(
      'custom_items',
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }
}
