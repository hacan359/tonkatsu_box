import 'package:core/models/mangabaka_genre.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// DAO for the static `mangabaka_genres` lookup table.
class MangaBakaGenreDao {
  const MangaBakaGenreDao(this._getDatabase);

  final Future<Database> Function() _getDatabase;

  Future<List<MangaBakaGenre>> getAll() async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'mangabaka_genres',
      orderBy: 'sort_order ASC',
    );
    return rows.map(MangaBakaGenre.fromDb).toList();
  }
}
