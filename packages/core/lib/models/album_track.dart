import 'dart:convert';

import '../utils/json_list.dart';
import 'album.dart';
import 'data_source.dart';

/// One track of a cached album release. Identity is
/// `(source, albumId, discNumber, position)`; the DB id never leaves it.
class AlbumTrack {
  const AlbumTrack({
    required this.albumId,
    required this.discNumber,
    required this.position,
    required this.title,
    this.recordingMbid,
    this.lengthMs,
    this.artists = const <String>[],
    this.source = DataSource.musicBrainz,
  });

  factory AlbumTrack.fromDb(Map<String, dynamic> row) {
    return AlbumTrack(
      albumId: row['album_id'] as int,
      discNumber: row['disc_number'] as int,
      position: row['position'] as int,
      title: row['title'] as String? ?? '',
      recordingMbid: row['recording_mbid'] as String?,
      lengthMs: row['length_ms'] as int?,
      artists: decodeJsonStringList(row['artists']),
      source: DataSource.fromNameOr(
        row['source'] as String?,
        DataSource.musicBrainz,
      ),
    );
  }

  /// From a `media[].tracks[]` entry of a release lookup. Track-level
  /// artists exist only on splits / compilations; plain albums leave none.
  factory AlbumTrack.fromMusicBrainzTrack(
    Map<String, dynamic> json, {
    required int albumId,
    required int discNumber,
  }) {
    final Object? recording = json['recording'];
    final Map<String, dynamic> rec =
        recording is Map<String, dynamic> ? recording : const <String, dynamic>{};
    return AlbumTrack(
      albumId: albumId,
      discNumber: discNumber,
      position: (json['position'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? rec['title'] as String? ?? '',
      recordingMbid: rec['id'] as String?,
      lengthMs: ((json['length'] ?? rec['length']) as num?)?.toInt(),
      artists:
          Album.artistCredit(json['artist-credit'] ?? rec['artist-credit']).$1,
    );
  }

  /// Album cache id ([Album.id]), not the MBID.
  final int albumId;

  /// Medium position, 1-based — "disc 2" of a multi-disc release.
  final int discNumber;

  /// Track position on its disc, 1-based.
  final int position;

  final String title;

  /// Recording MBID — the track as a work, stable across releases.
  final String? recordingMbid;

  final int? lengthMs;

  /// Track-level credit; empty when it matches the album artist.
  final List<String> artists;

  final DataSource source;

  Map<String, dynamic> toDb() {
    return <String, dynamic>{
      'album_id': albumId,
      'source': source.name,
      'disc_number': discNumber,
      'position': position,
      'title': title,
      'recording_mbid': recordingMbid,
      'length_ms': lengthMs,
      'artists': artists.isEmpty ? null : jsonEncode(artists),
      'cached_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    };
  }

  AlbumTrack copyWith({
    int? albumId,
    int? discNumber,
    int? position,
    String? title,
    String? recordingMbid,
    int? lengthMs,
    List<String>? artists,
    DataSource? source,
  }) {
    return AlbumTrack(
      albumId: albumId ?? this.albumId,
      discNumber: discNumber ?? this.discNumber,
      position: position ?? this.position,
      title: title ?? this.title,
      recordingMbid: recordingMbid ?? this.recordingMbid,
      lengthMs: lengthMs ?? this.lengthMs,
      artists: artists ?? this.artists,
      source: source ?? this.source,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AlbumTrack &&
        other.source == source &&
        other.albumId == albumId &&
        other.discNumber == discNumber &&
        other.position == position;
  }

  @override
  int get hashCode => Object.hash(source, albumId, discNumber, position);

  @override
  String toString() =>
      'AlbumTrack(albumId: $albumId, d$discNumber t$position: $title)';
}
