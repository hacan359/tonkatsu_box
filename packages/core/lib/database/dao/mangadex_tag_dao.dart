import '../../models/mangadex_tag.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// DAO for the `mangadex_tags` catalog.
class MangaDexTagDao {
  const MangaDexTagDao(this._getDatabase);

  final Future<Database> Function() _getDatabase;

  Future<List<MangaDexTag>> getAll() async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'mangadex_tags',
      orderBy: 'name ASC',
    );
    return rows.map(MangaDexTag.fromDb).toList();
  }

  /// Atomically replaces the catalog — truncate + bulk insert in one tx.
  Future<void> replaceAll(List<MangaDexTag> tags) async {
    final Database db = await _getDatabase();
    await db.transaction((Transaction txn) async {
      await txn.delete('mangadex_tags');
      final Batch batch = txn.batch();
      for (final MangaDexTag tag in tags) {
        batch.insert('mangadex_tags', tag.toDb());
      }
      await batch.commit(noResult: true);
    });
  }
}
