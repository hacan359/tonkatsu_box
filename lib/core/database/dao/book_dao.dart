// DAO for books from OpenLibrary / Fantlab.

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../shared/models/book.dart';
import '../../../shared/models/data_source.dart';
import '../query_chunk.dart';

/// DAO for `books_cache`. Row identity is the pair `(id, source)`, so the same
/// numeric `id` from OpenLibrary and Fantlab can coexist. `id` is stored as
/// `TEXT` but always holds digits, so id-list lookups match on
/// `CAST(id AS INTEGER)` against `collection_items.external_id`.
class BookDao {
  const BookDao(this._getDatabase);

  final Future<Database> Function() _getDatabase;

  Future<void> upsertBook(Book book) async {
    final Database db = await _getDatabase();
    await db.insert(
      'books_cache',
      book.toDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> upsertBooks(List<Book> books) async {
    if (books.isEmpty) return;
    final Database db = await _getDatabase();
    final Batch batch = db.batch();
    for (final Book book in books) {
      batch.insert(
        'books_cache',
        book.toDb(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<Book?> getBook(
    String id, {
    required DataSource source,
  }) async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'books_cache',
      where: 'id = ? AND source = ?',
      whereArgs: <Object?>[id, source.name],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Book.fromDb(rows.first);
  }

  /// Returns matches across all sources for the given numeric `external_id`s;
  /// callers disambiguate by [Book.source] (two rows can share a numeric id).
  Future<List<Book>> getBooksByIds(List<int> externalIds) async {
    final Database db = await _getDatabase();
    return queryByIdsInChunks(externalIds, (List<int> chunk) async {
      final String placeholders =
          List<String>.filled(chunk.length, '?').join(',');
      final List<Map<String, dynamic>> rows = await db.rawQuery(
        'SELECT * FROM books_cache WHERE CAST(id AS INTEGER) IN ($placeholders)',
        chunk,
      );
      return rows.map(Book.fromDb).toList();
    });
  }

  Future<void> clearBooks() async {
    final Database db = await _getDatabase();
    await db.delete('books_cache');
  }
}
