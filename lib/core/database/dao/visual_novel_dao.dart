// DAO для работы с визуальными новеллами и тегами VNDB.

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../shared/models/visual_novel.dart';

/// DAO для таблиц `visual_novels_cache` и `vndb_tags`.
class VisualNovelDao {
  /// Создаёт DAO с функцией получения базы данных.
  const VisualNovelDao(this._getDatabase);

  final Future<Database> Function() _getDatabase;

  /// Сохраняет или обновляет визуальную новеллу в кэше.
  Future<void> upsertVisualNovel(VisualNovel vn) async {
    final Database db = await _getDatabase();
    await db.insert(
      'visual_novels_cache',
      vn.toDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Сохраняет или обновляет список визуальных новелл.
  Future<void> upsertVisualNovels(List<VisualNovel> vns) async {
    if (vns.isEmpty) return;
    final Database db = await _getDatabase();
    final Batch batch = db.batch();
    for (final VisualNovel vn in vns) {
      batch.insert(
        'visual_novels_cache',
        vn.toDb(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// Получает визуальную новеллу по числовому ID.
  Future<VisualNovel?> getVisualNovel(int numericId) async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'visual_novels_cache',
      where: 'numeric_id = ?',
      whereArgs: <Object?>[numericId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return VisualNovel.fromDb(rows.first);
  }

  /// Получает визуальные новеллы по списку числовых ID.
  Future<List<VisualNovel>> getVisualNovelsByNumericIds(
    List<int> numericIds,
  ) async {
    if (numericIds.isEmpty) return <VisualNovel>[];
    final Database db = await _getDatabase();
    final String placeholders =
        List<String>.filled(numericIds.length, '?').join(',');
    final List<Map<String, dynamic>> rows = await db.rawQuery(
      'SELECT * FROM visual_novels_cache WHERE numeric_id IN ($placeholders)',
      numericIds,
    );
    return rows.map(VisualNovel.fromDb).toList();
  }

  /// Получает кэшированные теги VNDB.
  Future<List<VndbTag>> getVndbTags() async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'vndb_tags',
      orderBy: 'name ASC',
    );
    return rows.map(VndbTag.fromDb).toList();
  }
}
