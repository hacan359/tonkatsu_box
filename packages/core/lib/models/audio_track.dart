import 'dart:convert';

import '../utils/json_list.dart';
import 'audio_item.dart';
import 'data_source.dart';

/// One track of a cached album release, or one podcast episode. Identity is
/// `(source, audioId, discNumber, position)`; the DB id never leaves it.
///
/// Podcast episodes store `discNumber = 0` and the Podcast Index episode id
/// as [position] — RSS season/episode numbers are unreliable, the id is not.
class AudioTrack {
  const AudioTrack({
    required this.audioId,
    required this.discNumber,
    required this.position,
    required this.title,
    this.nativeId,
    this.lengthMs,
    this.artists = const <String>[],
    this.datePublished,
    this.source = DataSource.musicBrainz,
  });

  factory AudioTrack.fromDb(Map<String, dynamic> row) {
    return AudioTrack(
      audioId: row['audio_id'] as int,
      discNumber: row['disc_number'] as int,
      position: row['position'] as int,
      title: row['title'] as String? ?? '',
      nativeId: row['native_id'] as String?,
      lengthMs: row['length_ms'] as int?,
      artists: decodeJsonStringList(row['artists']),
      datePublished: row['date_published'] as int?,
      source: DataSource.fromNameOr(
        row['source'] as String?,
        DataSource.musicBrainz,
      ),
    );
  }

  /// From a `media[].tracks[]` entry of a release lookup. Track-level
  /// artists exist only on splits / compilations; plain albums leave none.
  factory AudioTrack.fromMusicBrainzTrack(
    Map<String, dynamic> json, {
    required int audioId,
    required int discNumber,
  }) {
    final Object? recording = json['recording'];
    final Map<String, dynamic> rec = recording is Map<String, dynamic>
        ? recording
        : const <String, dynamic>{};
    return AudioTrack(
      audioId: audioId,
      discNumber: discNumber,
      position: (json['position'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? rec['title'] as String? ?? '',
      nativeId: rec['id'] as String?,
      lengthMs: ((json['length'] ?? rec['length']) as num?)?.toInt(),
      artists: AudioItem.artistCredit(
        json['artist-credit'] ?? rec['artist-credit'],
      ).$1,
    );
  }

  /// From a Podcast Index `/episodes/byfeedid` item.
  factory AudioTrack.fromPodcastIndexEpisode(
    Map<String, dynamic> json, {
    required int audioId,
  }) {
    final int? durationS = (json['duration'] as num?)?.toInt();
    return AudioTrack(
      audioId: audioId,
      discNumber: 0,
      position: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      nativeId: json['guid'] as String?,
      lengthMs: durationS != null && durationS > 0 ? durationS * 1000 : null,
      datePublished: (json['datePublished'] as num?)?.toInt(),
      source: DataSource.podcastIndex,
    );
  }

  /// Audio cache id ([AudioItem.id]), not the provider-native id.
  final int audioId;

  /// Medium position, 1-based — "disc 2" of a multi-disc release. Always 0
  /// for podcast episodes.
  final int discNumber;

  /// Track position on its disc (1-based), or the Podcast Index episode id.
  final int position;

  final String title;

  /// Recording MBID (stable across releases) or the episode's RSS guid.
  final String? nativeId;

  final int? lengthMs;

  /// Track-level credit; empty when it matches the album artist.
  final List<String> artists;

  /// Episode publish time, unix seconds — podcasts only, orders the list.
  final int? datePublished;

  DateTime? get publishedAt => datePublished != null
      ? DateTime.fromMillisecondsSinceEpoch(datePublished! * 1000)
      : null;

  final DataSource source;

  Map<String, dynamic> toDb() {
    return <String, dynamic>{
      'audio_id': audioId,
      'source': source.name,
      'disc_number': discNumber,
      'position': position,
      'title': title,
      'native_id': nativeId,
      'length_ms': lengthMs,
      'artists': artists.isEmpty ? null : jsonEncode(artists),
      'date_published': datePublished,
      'cached_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    };
  }

  AudioTrack copyWith({
    int? audioId,
    int? discNumber,
    int? position,
    String? title,
    String? nativeId,
    int? lengthMs,
    List<String>? artists,
    int? datePublished,
    DataSource? source,
  }) {
    return AudioTrack(
      audioId: audioId ?? this.audioId,
      discNumber: discNumber ?? this.discNumber,
      position: position ?? this.position,
      title: title ?? this.title,
      nativeId: nativeId ?? this.nativeId,
      lengthMs: lengthMs ?? this.lengthMs,
      artists: artists ?? this.artists,
      datePublished: datePublished ?? this.datePublished,
      source: source ?? this.source,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AudioTrack &&
        other.source == source &&
        other.audioId == audioId &&
        other.discNumber == discNumber &&
        other.position == position;
  }

  @override
  int get hashCode => Object.hash(source, audioId, discNumber, position);

  @override
  String toString() =>
      'AudioTrack(audioId: $audioId, d$discNumber t$position: $title)';
}
