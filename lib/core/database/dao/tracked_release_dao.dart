import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../shared/models/data_source.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/models/tracked_release.dart';

/// DAO for the `tracked_releases` table — release-tracking subscriptions keyed
/// by `(external_id, source, media_type)`.
class TrackedReleaseDao {
  const TrackedReleaseDao(this._getDatabase);

  final Future<Database> Function() _getDatabase;

  static const String _where =
      'external_id = ? AND source = ? AND media_type = ?';

  List<Object?> _key(int externalId, DataSource source, MediaType mediaType) =>
      <Object?>[externalId, source.name, mediaType.value];

  Future<bool> isTracked(
    int externalId,
    DataSource source,
    MediaType mediaType,
  ) async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'tracked_releases',
      columns: <String>['external_id'],
      where: _where,
      whereArgs: _key(externalId, source, mediaType),
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<void> subscribe(
    int externalId,
    DataSource source,
    MediaType mediaType,
  ) async {
    final Database db = await _getDatabase();
    await db.insert(
      'tracked_releases',
      <String, Object?>{
        'external_id': externalId,
        'source': source.name,
        'media_type': mediaType.value,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> unsubscribe(
    int externalId,
    DataSource source,
    MediaType mediaType,
  ) async {
    final Database db = await _getDatabase();
    await db.delete(
      'tracked_releases',
      where: _where,
      whereArgs: _key(externalId, source, mediaType),
    );
  }

  Future<List<TrackedRelease>> getAll() async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'tracked_releases',
      orderBy: 'created_at DESC',
    );
    return rows.map(TrackedRelease.fromDb).toList();
  }

  /// Returns the identity tuples of every subscription, for cheap membership
  /// checks when highlighting tracked items across collections.
  Future<Set<(int, String, String)>> getTrackedKeys() async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'tracked_releases',
      columns: <String>['external_id', 'source', 'media_type'],
    );
    return <(int, String, String)>{
      for (final Map<String, dynamic> row in rows)
        (
          row['external_id'] as int,
          row['source'] as String,
          row['media_type'] as String,
        ),
    };
  }
}
