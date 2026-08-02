import '../../models/mangabaka_tag.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// DAO for the `mangabaka_tags` catalog.
class MangaBakaTagDao {
  const MangaBakaTagDao(this._getDatabase);

  final Future<Database> Function() _getDatabase;

  Future<List<MangaBakaTag>> getAll() async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'mangabaka_tags',
      orderBy: 'name ASC',
    );
    return rows.map(MangaBakaTag.fromDb).toList();
  }

  /// Atomically replaces the catalog — truncate + bulk insert in one tx.
  Future<void> replaceAll(List<MangaBakaTag> tags) async {
    final Database db = await _getDatabase();
    await db.transaction((Transaction txn) async {
      await txn.delete('mangabaka_tags');
      final Batch batch = txn.batch();
      for (final MangaBakaTag tag in tags) {
        batch.insert('mangabaka_tags', tag.toDb());
      }
      await batch.commit(noResult: true);
    });
  }
}
