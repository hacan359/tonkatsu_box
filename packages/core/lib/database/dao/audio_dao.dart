import '../query_chunk.dart';
import '../sparse_upsert.dart';
import '../../models/audio_item.dart';
import '../../models/audio_track.dart';
import '../../models/data_source.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Audio items (albums / podcasts), their track lists and the listened-track
/// marks. Row identity is `(id, source)`.
class AudioDao {
  const AudioDao(this._getDatabase);

  final Future<Database> Function() _getDatabase;

  // Search rows carry no lookup extras (genres, rating) and no picked release;
  // an upsert from the grid must not wipe what the detail flow already saved.
  static ({String sql, List<Object?> args}) _audioUpsert(AudioItem item) =>
      buildPreservingUpsert(
        table: 'audio_cache',
        row: item.toDb(),
        conflictKey: const <String>['id', 'source'],
        preserveWhenNull: const <String>{
          'description',
          'language',
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

  Future<void> upsertAudioItem(AudioItem item) async {
    final Database db = await _getDatabase();
    final ({String sql, List<Object?> args}) upsert = _audioUpsert(item);
    await db.rawInsert(upsert.sql, upsert.args);
  }

  Future<void> upsertAudioItems(List<AudioItem> items) async {
    if (items.isEmpty) return;
    final Database db = await _getDatabase();
    final Batch batch = db.batch();
    for (final AudioItem item in items) {
      final ({String sql, List<Object?> args}) upsert = _audioUpsert(item);
      batch.rawInsert(upsert.sql, upsert.args);
    }
    await batch.commit(noResult: true);
  }

  Future<AudioItem?> getAudioItem(int id, {required DataSource source}) async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'audio_cache',
      where: 'id = ? AND source = ?',
      whereArgs: <Object?>[id, source.name],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return AudioItem.fromDb(rows.first);
  }

  Future<List<AudioItem>> getAudioItemsByIds(List<int> externalIds) async {
    final Database db = await _getDatabase();
    return queryByIdsInChunks(externalIds, (List<int> chunk) async {
      final String placeholders =
          List<String>.filled(chunk.length, '?').join(',');
      final List<Map<String, dynamic>> rows = await db.rawQuery(
        'SELECT * FROM audio_cache WHERE id IN ($placeholders)',
        chunk,
      );
      return rows.map(AudioItem.fromDb).toList();
    });
  }

  Future<void> clearAudioItems() async {
    final Database db = await _getDatabase();
    await db.delete('audio_cache');
    await db.delete('audio_tracks_cache');
  }

  /// Replaces the cached track list — the picked release changed, so leftovers
  /// from the previous edition must not survive. Albums only; podcast episode
  /// lists grow incrementally via [upsertTracks].
  Future<void> replaceAudioTracks(
    int audioId,
    DataSource source,
    List<AudioTrack> tracks,
  ) async {
    final Database db = await _getDatabase();
    await db.transaction((Transaction txn) async {
      await txn.delete(
        'audio_tracks_cache',
        where: 'audio_id = ? AND source = ?',
        whereArgs: <Object?>[audioId, source.name],
      );
      final Batch batch = txn.batch();
      for (final AudioTrack track in tracks) {
        batch.insert(
          'audio_tracks_cache',
          track.toDb(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  /// Bulk-inserts tracks across many items in one batch (import / restore /
  /// podcast episode refresh). The natural UNIQUE key makes it idempotent.
  Future<void> upsertTracks(List<AudioTrack> tracks) async {
    if (tracks.isEmpty) return;
    final Database db = await _getDatabase();
    final Batch batch = db.batch();
    for (final AudioTrack track in tracks) {
      batch.insert(
        'audio_tracks_cache',
        track.toDb(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<AudioTrack>> getAudioTracks(
    int audioId, {
    required DataSource source,
  }) async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'audio_tracks_cache',
      where: 'audio_id = ? AND source = ?',
      whereArgs: <Object?>[audioId, source.name],
      orderBy: 'disc_number ASC, position ASC',
    );
    return rows.map(AudioTrack.fromDb).toList();
  }

  /// Keyed by (discNumber, trackNumber).
  Future<Map<(int, int), DateTime?>> getListenedTracks(
    int collectionId,
    DataSource source,
    int audioId,
  ) async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'listened_tracks',
      columns: <String>['disc_number', 'track_number', 'listened_at'],
      where: 'collection_id = ? AND source = ? AND audio_id = ?',
      whereArgs: <Object?>[collectionId, source.name, audioId],
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

  /// All listened marks deduped by source/item/disc/track
  /// (collection-agnostic), for backup. Keeps the latest `listened_at`.
  Future<List<Map<String, Object?>>> getAllListenedTracks() async {
    final Database db = await _getDatabase();
    return db.rawQuery(
      'SELECT source, audio_id, disc_number, track_number, '
      'MAX(listened_at) AS listened_at FROM listened_tracks '
      'GROUP BY source, audio_id, disc_number, track_number',
    );
  }

  Future<void> markTrackListened(
    int collectionId,
    DataSource source,
    int audioId,
    int discNumber,
    int trackNumber,
  ) async {
    final Database db = await _getDatabase();
    await db.insert(
      'listened_tracks',
      <String, dynamic>{
        'collection_id': collectionId,
        'source': source.name,
        'audio_id': audioId,
        'disc_number': discNumber,
        'track_number': trackNumber,
        'listened_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// One transaction for the whole item — an import of a completed album
  /// would otherwise pay a commit per track.
  Future<void> markTracksListenedAt(
    int collectionId,
    DataSource source,
    int audioId,
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
            'audio_id': audioId,
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

  /// One transaction for a whole span (a podcast year, a full album) — the
  /// mirror of [markTracksListenedAt] for unmarking.
  Future<void> markTracksUnlistened(
    int collectionId,
    DataSource source,
    int audioId,
    List<(int discNumber, int trackNumber)> tracks,
  ) async {
    if (tracks.isEmpty) return;

    final Database db = await _getDatabase();
    await db.transaction((Transaction txn) async {
      final Batch batch = txn.batch();
      for (final (int disc, int track) in tracks) {
        batch.delete(
          'listened_tracks',
          where: 'collection_id = ? AND source = ? AND audio_id = ? '
              'AND disc_number = ? AND track_number = ?',
          whereArgs: <Object?>[collectionId, source.name, audioId, disc, track],
        );
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> markTrackUnlistened(
    int collectionId,
    DataSource source,
    int audioId,
    int discNumber,
    int trackNumber,
  ) async {
    final Database db = await _getDatabase();
    await db.delete(
      'listened_tracks',
      where: 'collection_id = ? AND source = ? AND audio_id = ? '
          'AND disc_number = ? AND track_number = ?',
      whereArgs: <Object?>[
        collectionId,
        source.name,
        audioId,
        discNumber,
        trackNumber,
      ],
    );
  }
}
