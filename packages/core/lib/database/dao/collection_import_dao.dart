import 'package:sqflite_common/sqlite_api.dart';

import '../../models/collection_import.dart';
import '../../models/import_source_kind.dart';

class CollectionImportDao {
  const CollectionImportDao(this._getDatabase);

  final Future<Database> Function() _getDatabase;

  /// Newest run first. Rows from a source this build does not know are
  /// skipped rather than failing the whole list.
  Future<List<CollectionImport>> getForCollection(int collectionId) async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'collection_imports',
      where: 'collection_id = ?',
      whereArgs: <Object?>[collectionId],
      orderBy: 'last_run_at DESC',
    );
    return <CollectionImport>[
      for (final Map<String, dynamic> row in rows)
        if (ImportSourceKind.tryFromKey(row['source'] as String?) != null)
          CollectionImport.fromDb(row),
    ];
  }

  /// The newest run of [source] over every collection, so a form opened from
  /// settings can start on the collection it filled last time.
  Future<CollectionImport?> getLatestForSource(ImportSourceKind source) async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'collection_imports',
      where: 'source = ?',
      whereArgs: <Object?>[source.key],
      orderBy: 'last_run_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return CollectionImport.fromDb(rows.first);
  }

  Future<void> upsert(CollectionImport record) async {
    final Database db = await _getDatabase();
    await db.insert(
      'collection_imports',
      record.toDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> delete({
    required int collectionId,
    required ImportSourceKind source,
  }) async {
    final Database db = await _getDatabase();
    await db.delete(
      'collection_imports',
      where: 'collection_id = ? AND source = ?',
      whereArgs: <Object?>[collectionId, source.key],
    );
  }
}
