import '../query_chunk.dart';
import '../sparse_upsert.dart';
import '../../models/book.dart';
import '../../models/data_source.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Row identity is `(id, source)`, so one numeric `id` can exist for both
/// OpenLibrary and Fantlab. `id` is `TEXT` but always digits, hence the CAST.
class BookDao {
  const BookDao(this._getDatabase);

  final Future<Database> Function() _getDatabase;

  // Fantlab/Google Books similars and search-list rows carry no page count;
  // the column keeps the cached detail-endpoint value instead of being wiped.
  static ({String sql, List<Object?> args}) _bookUpsert(Book book) =>
      buildPreservingUpsert(
        table: 'books_cache',
        row: book.toDb(),
        conflictKey: const <String>['id', 'source'],
        preserveWhenNull: const <String>{'page_count'},
      );

  Future<void> upsertBook(Book book) async {
    final Database db = await _getDatabase();
    final ({String sql, List<Object?> args}) upsert = _bookUpsert(book);
    await db.rawInsert(upsert.sql, upsert.args);
  }

  Future<void> upsertBooks(List<Book> books) async {
    if (books.isEmpty) return;
    final Database db = await _getDatabase();
    final Batch batch = db.batch();
    for (final Book book in books) {
      final ({String sql, List<Object?> args}) upsert = _bookUpsert(book);
      batch.rawInsert(upsert.sql, upsert.args);
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
