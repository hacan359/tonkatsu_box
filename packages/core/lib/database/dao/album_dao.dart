import '../query_chunk.dart';
import '../sparse_upsert.dart';
import '../../models/album.dart';
import '../../models/album_track.dart';
import '../../models/data_source.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Albums, their track lists and the listened-track marks. Row identity is
/// `(id, source)` where `id` is fnv1a64 of the release-group MBID.
class AlbumDao {
  const AlbumDao(this._getDatabase);

  final Future<Database> Function() _getDatabase;

  // Search rows carry no lookup extras (genres, rating) and no picked release;
  // an upsert from the grid must not wipe what the detail flow already saved.
  static ({String sql, List<Object?> args}) _albumUpsert(Album album) =>
      buildPreservingUpsert(
        table: 'music_albums_cache',
        row: album.toDb(),
        conflictKey: const <String>['id', 'source'],
        preserveWhenNull: const <String>{
          'genres',
          'rating',
          'rating_count',
          'listen_count',
          'release_mbid',
          'release_title',
          'label',
          'format',
          'track_count',
          'disc_count',
          'total_length_ms',
        },
      );

  Future<void> upsertAlbum(Album album) async {
    final Database db = await _getDatabase();
    final ({String sql, List<Object?> args}) upsert = _albumUpsert(album);
    await db.rawInsert(upsert.sql, upsert.args);
  }

  Future<void> upsertAlbums(List<Album> albums) async {
    if (albums.isEmpty) return;
    final Database db = await _getDatabase();
    final Batch batch = db.batch();
    for (final Album album in albums) {
      final ({String sql, List<Object?> args}) upsert = _albumUpsert(album);
      batch.rawInsert(upsert.sql, upsert.args);
    }
    await batch.commit(noResult: true);
  }

  Future<Album?> getAlbum(int id, {required DataSource source}) async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'music_albums_cache',
      where: 'id = ? AND source = ?',
      whereArgs: <Object?>[id, source.name],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Album.fromDb(rows.first);
  }

  Future<List<Album>> getAlbumsByIds(List<int> externalIds) async {
    final Database db = await _getDatabase();
    return queryByIdsInChunks(externalIds, (List<int> chunk) async {
      final String placeholders =
          List<String>.filled(chunk.length, '?').join(',');
      final List<Map<String, dynamic>> rows = await db.rawQuery(
        'SELECT * FROM music_albums_cache WHERE id IN ($placeholders)',
        chunk,
      );
      return rows.map(Album.fromDb).toList();
    });
  }

  Future<void> clearAlbums() async {
    final Database db = await _getDatabase();
    await db.delete('music_albums_cache');
    await db.delete('music_tracks_cache');
  }

  /// Replaces the cached track list — the picked release changed, so leftovers
  /// from the previous edition must not survive.
  Future<void> replaceAlbumTracks(
    int albumId,
    DataSource source,
    List<AlbumTrack> tracks,
  ) async {
    final Database db = await _getDatabase();
    await db.transaction((Transaction txn) async {
      await txn.delete(
        'music_tracks_cache',
        where: 'album_id = ? AND source = ?',
        whereArgs: <Object?>[albumId, source.name],
      );
      final Batch batch = txn.batch();
      for (final AlbumTrack track in tracks) {
        batch.insert(
          'music_tracks_cache',
          track.toDb(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  /// Bulk-inserts tracks across many albums in one batch (import / restore).
  /// The natural UNIQUE key makes it idempotent.
  Future<void> upsertTracks(List<AlbumTrack> tracks) async {
    if (tracks.isEmpty) return;
    final Database db = await _getDatabase();
    final Batch batch = db.batch();
    for (final AlbumTrack track in tracks) {
      batch.insert(
        'music_tracks_cache',
        track.toDb(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<AlbumTrack>> getAlbumTracks(
    int albumId, {
    required DataSource source,
  }) async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'music_tracks_cache',
      where: 'album_id = ? AND source = ?',
      whereArgs: <Object?>[albumId, source.name],
      orderBy: 'disc_number ASC, position ASC',
    );
    return rows.map(AlbumTrack.fromDb).toList();
  }

  /// Keyed by (discNumber, trackNumber).
  Future<Map<(int, int), DateTime?>> getListenedTracks(
    int collectionId,
    DataSource source,
    int albumId,
  ) async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'listened_tracks',
      columns: <String>['disc_number', 'track_number', 'listened_at'],
      where: 'collection_id = ? AND source = ? AND album_id = ?',
      whereArgs: <Object?>[collectionId, source.name, albumId],
    );
    final Map<(int, int), DateTime?> result = <(int, int), DateTime?>{};
    for (final Map<String, dynamic> row in rows) {
      final int? listenedAtMs = row['listened_at'] as int?;
      result[(
        row['disc_number'] as int,
        row['track_number'] as int,
      )] = listenedAtMs != null
          ? DateTime.fromMillisecondsSinceEpoch(listenedAtMs)
          : null;
    }
    return result;
  }

  /// All listened marks deduped by source/album/disc/track
  /// (collection-agnostic), for backup. Keeps the latest `listened_at`.
  Future<List<Map<String, Object?>>> getAllListenedTracks() async {
    final Database db = await _getDatabase();
    return db.rawQuery(
      'SELECT source, album_id, disc_number, track_number, '
      'MAX(listened_at) AS listened_at FROM listened_tracks '
      'GROUP BY source, album_id, disc_number, track_number',
    );
  }

  Future<void> markTrackListened(
    int collectionId,
    DataSource source,
    int albumId,
    int discNumber,
    int trackNumber,
  ) async {
    final Database db = await _getDatabase();
    await db.insert(
      'listened_tracks',
      <String, dynamic>{
        'collection_id': collectionId,
        'source': source.name,
        'album_id': albumId,
        'disc_number': discNumber,
        'track_number': trackNumber,
        'listened_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// One transaction for the whole album — an import of a completed album
  /// would otherwise pay a commit per track.
  Future<void> markTracksListenedAt(
    int collectionId,
    DataSource source,
    int albumId,
    List<(int discNumber, int trackNumber, int? listenedAtMs)> tracks,
  ) async {
    if (tracks.isEmpty) return;

    final Database db = await _getDatabase();
    await db.transaction((Transaction txn) async {
      final Batch batch = txn.batch();
      for (final (int disc, int track, int? listenedAtMs) in tracks) {
        batch.insert(
          'listened_tracks',
          <String, dynamic>{
            'collection_id': collectionId,
            'source': source.name,
            'album_id': albumId,
            'disc_number': disc,
            'track_number': track,
            'listened_at': listenedAtMs,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> markTrackUnlistened(
    int collectionId,
    DataSource source,
    int albumId,
    int discNumber,
    int trackNumber,
  ) async {
    final Database db = await _getDatabase();
    await db.delete(
      'listened_tracks',
      where: 'collection_id = ? AND source = ? AND album_id = ? '
          'AND disc_number = ? AND track_number = ?',
      whereArgs: <Object?>[
        collectionId,
        source.name,
        albumId,
        discNumber,
        trackNumber,
      ],
    );
  }

}
