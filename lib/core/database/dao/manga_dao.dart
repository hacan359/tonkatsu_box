// DAO для работы с мангой из AniList.

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../shared/models/manga.dart';

/// DAO для таблицы `manga_cache`.
class MangaDao {
  /// Создаёт DAO с функцией получения базы данных.
  const MangaDao(this._getDatabase);

  final Future<Database> Function() _getDatabase;

  /// Сохраняет или обновляет мангу в кэше.
  Future<void> upsertManga(Manga manga) async {
    final Database db = await _getDatabase();
    await db.insert(
      'manga_cache',
      manga.toDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Сохраняет или обновляет список манг.
  Future<void> upsertMangas(List<Manga> mangas) async {
    if (mangas.isEmpty) return;
    final Database db = await _getDatabase();
    final Batch batch = db.batch();
    for (final Manga manga in mangas) {
      batch.insert(
        'manga_cache',
        manga.toDb(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// Получает мангу по AniList ID.
  Future<Manga?> getManga(int id) async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'manga_cache',
      where: 'id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Manga.fromDb(rows.first);
  }

  /// Получает манги по списку ID.
  Future<List<Manga>> getMangaByIds(List<int> ids) async {
    if (ids.isEmpty) return <Manga>[];
    final Database db = await _getDatabase();
    final String placeholders =
        List<String>.filled(ids.length, '?').join(',');
    final List<Map<String, dynamic>> rows = await db.rawQuery(
      'SELECT * FROM manga_cache WHERE id IN ($placeholders)',
      ids,
    );
    return rows.map(Manga.fromDb).toList();
  }
}
