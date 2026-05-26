import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../shared/models/anilist_tag.dart';

/// DAO for the `anilist_tags` catalog table.
class AniListTagDao {
  const AniListTagDao(this._getDatabase);

  final Future<Database> Function() _getDatabase;

  Future<List<AniListTag>> getAll() async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'anilist_tags',
      orderBy: 'category ASC, name ASC',
    );
    return rows.map(AniListTag.fromDb).toList();
  }

  /// Atomically replaces the catalog — truncate + bulk insert in one tx.
  Future<void> replaceAll(List<AniListTag> tags) async {
    final Database db = await _getDatabase();
    await db.transaction((Transaction txn) async {
      await txn.delete('anilist_tags');
      final Batch batch = txn.batch();
      for (final AniListTag tag in tags) {
        batch.insert('anilist_tags', tag.toDb());
      }
      await batch.commit(noResult: true);
    });
  }
}
