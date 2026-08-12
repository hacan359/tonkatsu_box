import 'dart:convert';

import '../utils/json_list.dart';
import '../utils/stable_id.dart';
import 'data_source.dart';

/// A MusicBrainz release-group ("the album as a work"). [id] is `fnv1a64`
/// of the group MBID so the `external_id: int` contract holds.
class Album {
  const Album({
    required this.id,
    required this.source,
    required this.mbid,
    required this.title,
    this.artists = const <String>[],
    this.artistMbids = const <String>[],
    this.primaryType,
    this.secondaryTypes = const <String>[],
    this.releaseYear,
    this.firstReleaseDate,
    this.genres = const <String>[],
    this.tags = const <String>[],
    this.rating,
    this.ratingCount,
    this.listenCount,
    this.releaseMbid,
    this.releaseTitle,
    this.label,
    this.format,
    this.trackCount,
    this.discCount,
    this.totalLengthMs,
    this.coverUrl,
    this.externalUrl,
    this.cachedAt,
  });

  factory Album.fromDb(Map<String, dynamic> row) {
    return Album(
      id: row['id'] as int,
      source: DataSource.fromNameOr(
        row['source'] as String?,
        DataSource.musicBrainz,
      ),
      mbid: row['mbid'] as String,
      title: row['title'] as String,
      artists: decodeJsonStringList(row['artists']),
      artistMbids: decodeJsonStringList(row['artist_mbids']),
      primaryType: row['primary_type'] as String?,
      secondaryTypes: decodeJsonStringList(row['secondary_types']),
      releaseYear: row['release_year'] as int?,
      firstReleaseDate: row['first_release_date'] as String?,
      genres: decodeJsonStringList(row['genres']),
      tags: decodeJsonStringList(row['tags']),
      rating: (row['rating'] as num?)?.toDouble(),
      ratingCount: row['rating_count'] as int?,
      listenCount: row['listen_count'] as int?,
      releaseMbid: row['release_mbid'] as String?,
      releaseTitle: row['release_title'] as String?,
      label: row['label'] as String?,
      format: row['format'] as String?,
      trackCount: row['track_count'] as int?,
      discCount: row['disc_count'] as int?,
      totalLengthMs: row['total_length_ms'] as int?,
      coverUrl: row['cover_url'] as String?,
      externalUrl: row['external_url'] as String?,
      cachedAt: row['cached_at'] as int?,
    );
  }

  /// Rebuilds an [Album] from a `.xcoll` payload (the output of [toExport]).
  factory Album.fromExport(Map<String, dynamic> json) => Album.fromDb(json);

  /// Shared by `/release-group?query=` search docs and `/release-group/{mbid}`
  /// lookups — the lookup adds `rating` and `genres`, absent in search rows.
  factory Album.fromMusicBrainzReleaseGroup(Map<String, dynamic> json) {
    final String mbid = json['id'] as String? ?? '';
    final String? firstReleaseDate =
        _nonEmpty(json['first-release-date'] as String?);
    final (List<String> artists, List<String> artistMbids) =
        artistCredit(json['artist-credit']);

    double? rating;
    int? ratingCount;
    final Object? ratingObj = json['rating'];
    if (ratingObj is Map<String, dynamic>) {
      // MusicBrainz ratings are 1–5; the app's scale is 1–10.
      final double? value = (ratingObj['value'] as num?)?.toDouble();
      rating = value != null ? value * 2 : null;
      ratingCount = (ratingObj['votes-count'] as num?)?.toInt();
    }

    return Album(
      id: fnv1a64(mbid),
      source: DataSource.musicBrainz,
      mbid: mbid,
      title: json['title'] as String? ?? 'Unknown',
      artists: artists,
      artistMbids: artistMbids,
      primaryType: _nonEmpty(json['primary-type'] as String?),
      secondaryTypes: _stringList(json['secondary-types']),
      releaseYear: yearFromDate(firstReleaseDate),
      firstReleaseDate: firstReleaseDate,
      genres: _namedCounts(json['genres']),
      tags: _namedCounts(json['tags']),
      rating: rating,
      ratingCount: ratingCount,
      coverUrl: coverUrlForReleaseGroup(mbid),
      externalUrl: releaseGroupUrl(mbid),
    );
  }

  final int id;

  /// Part of the cache identity `(id, source)`, [DataSource.musicBrainz] today.
  final DataSource source;

  /// Release-group MBID (UUID) — the provider-native id.
  final String mbid;

  final String title;

  /// Artist-credit names in credit order.
  final List<String> artists;

  final List<String> artistMbids;

  /// Album / Single / EP / Broadcast / Other.
  final String? primaryType;

  /// Compilation / Soundtrack / Live / Remix / …
  final List<String> secondaryTypes;

  final int? releaseYear;

  /// "YYYY-MM-DD", possibly truncated to "YYYY-MM" or "YYYY".
  final String? firstReleaseDate;

  /// Curated genre subset of [tags], vote-ordered.
  final List<String> genres;

  final List<String> tags;

  /// Normalised to a 1.0–10.0 scale.
  final double? rating;

  final int? ratingCount;

  /// ListenBrainz total listen count — best-effort, often null.
  final int? listenCount;

  /// User-picked (or default earliest-official) release of the group.
  final String? releaseMbid;

  final String? releaseTitle;
  final String? label;

  /// Medium format of the picked release: `12" Vinyl` / `CD` / `Digital Media`.
  final String? format;

  final int? trackCount;
  final int? discCount;

  /// Sum of the picked release's track lengths.
  final int? totalLengthMs;

  /// Cover Art Archive front cover, built from [mbid] with no extra request.
  final String? coverUrl;

  final String? externalUrl;

  /// Unix timestamp of when this row was cached; null on fresh / export data.
  final int? cachedAt;

  String? get formattedRating => rating?.toStringAsFixed(1);

  String? get artistsString => artists.isEmpty ? null : artists.join(', ');

  String? get genresString => genres.isEmpty ? null : genres.join(', ');

  /// Total length in whole minutes; null when unknown.
  int? get totalLengthMinutes {
    final int? ms = totalLengthMs;
    return ms == null ? null : ms ~/ Duration.millisecondsPerMinute;
  }

  Map<String, dynamic> toDb() {
    return <String, dynamic>{
      'id': id,
      'source': source.name,
      'mbid': mbid,
      'title': title,
      'artists': artists.isEmpty ? null : jsonEncode(artists),
      'artist_mbids': artistMbids.isEmpty ? null : jsonEncode(artistMbids),
      'primary_type': primaryType,
      'secondary_types':
          secondaryTypes.isEmpty ? null : jsonEncode(secondaryTypes),
      'release_year': releaseYear,
      'first_release_date': firstReleaseDate,
      'genres': genres.isEmpty ? null : jsonEncode(genres),
      'tags': tags.isEmpty ? null : jsonEncode(tags),
      'rating': rating,
      'rating_count': ratingCount,
      'listen_count': listenCount,
      'release_mbid': releaseMbid,
      'release_title': releaseTitle,
      'label': label,
      'format': format,
      'track_count': trackCount,
      'disc_count': discCount,
      'total_length_ms': totalLengthMs,
      'cover_url': coverUrl,
      'external_url': externalUrl,
      'cached_at': cachedAt ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
    };
  }

  /// `toDb` minus the cache timestamp, for `.xcoll` / `.xcollx` payloads.
  Map<String, dynamic> toExport() {
    final Map<String, dynamic> data = toDb();
    data.remove('cached_at');
    return data;
  }

  Album copyWith({
    int? id,
    DataSource? source,
    String? mbid,
    String? title,
    List<String>? artists,
    List<String>? artistMbids,
    String? primaryType,
    List<String>? secondaryTypes,
    int? releaseYear,
    String? firstReleaseDate,
    List<String>? genres,
    List<String>? tags,
    double? rating,
    int? ratingCount,
    int? listenCount,
    String? releaseMbid,
    String? releaseTitle,
    String? label,
    String? format,
    int? trackCount,
    int? discCount,
    int? totalLengthMs,
    String? coverUrl,
    String? externalUrl,
    int? cachedAt,
  }) {
    return Album(
      id: id ?? this.id,
      source: source ?? this.source,
      mbid: mbid ?? this.mbid,
      title: title ?? this.title,
      artists: artists ?? this.artists,
      artistMbids: artistMbids ?? this.artistMbids,
      primaryType: primaryType ?? this.primaryType,
      secondaryTypes: secondaryTypes ?? this.secondaryTypes,
      releaseYear: releaseYear ?? this.releaseYear,
      firstReleaseDate: firstReleaseDate ?? this.firstReleaseDate,
      genres: genres ?? this.genres,
      tags: tags ?? this.tags,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      listenCount: listenCount ?? this.listenCount,
      releaseMbid: releaseMbid ?? this.releaseMbid,
      releaseTitle: releaseTitle ?? this.releaseTitle,
      label: label ?? this.label,
      format: format ?? this.format,
      trackCount: trackCount ?? this.trackCount,
      discCount: discCount ?? this.discCount,
      totalLengthMs: totalLengthMs ?? this.totalLengthMs,
      coverUrl: coverUrl ?? this.coverUrl,
      externalUrl: externalUrl ?? this.externalUrl,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  /// Overlays a `/release-group/{mbid}` lookup onto a lightweight search row,
  /// keeping the row's listen count and any picked release.
  Album withLookupDetails(Album full) => copyWith(
        // Discover-feed rows may lack the credit; the lookup always has it.
        artists: artists.isNotEmpty ? artists : full.artists,
        artistMbids: artistMbids.isNotEmpty ? artistMbids : full.artistMbids,
        primaryType: primaryType ?? full.primaryType,
        releaseYear: releaseYear ?? full.releaseYear,
        firstReleaseDate: firstReleaseDate ?? full.firstReleaseDate,
        genres: full.genres.isNotEmpty ? full.genres : genres,
        tags: full.tags.isNotEmpty ? full.tags : tags,
        rating: rating ?? full.rating,
        ratingCount: ratingCount ?? full.ratingCount,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Album && other.id == id && other.source == source;
  }

  @override
  int get hashCode => Object.hash(id, source);

  @override
  String toString() =>
      'Album(id: $id, mbid: $mbid, title: $title)';

  /// Cover Art Archive front cover for a release group. Deterministic — no
  /// listing request needed; a missing cover just 404s into the placeholder.
  static String coverUrlForReleaseGroup(String mbid, {int size = 500}) =>
      'https://coverartarchive.org/release-group/$mbid/front-$size';

  /// Same shortcut for a concrete release (edition-accurate art).
  static String coverUrlForRelease(String mbid, {int size = 500}) =>
      'https://coverartarchive.org/release/$mbid/front-$size';

  /// The album's page on musicbrainz.org.
  static String releaseGroupUrl(String mbid) =>
      'https://musicbrainz.org/release-group/$mbid';

  /// Names and MBIDs from an `artist-credit` array, in credit order.
  static (List<String>, List<String>) artistCredit(Object? credit) {
    if (credit is! List<dynamic>) {
      return (const <String>[], const <String>[]);
    }
    final List<String> names = <String>[];
    final List<String> mbids = <String>[];
    for (final Object? entry in credit) {
      if (entry is! Map<String, dynamic>) continue;
      final Object? artist = entry['artist'];
      final String? name = _nonEmpty(entry['name'] as String?) ??
          (artist is Map<String, dynamic>
              ? _nonEmpty(artist['name'] as String?)
              : null);
      if (name != null) names.add(name);
      if (artist is Map<String, dynamic>) {
        final String? id = _nonEmpty(artist['id'] as String?);
        if (id != null) mbids.add(id);
      }
    }
    return (names, mbids);
  }

  /// Names from a `[{count, name}]` array (tags / genres), vote-ordered,
  /// capped so a heavily tagged group can't flood the card.
  static List<String> _namedCounts(Object? raw, {int max = 15}) {
    if (raw is! List<dynamic>) return const <String>[];
    final List<({int count, String name})> entries =
        <({int count, String name})>[];
    for (final Object? entry in raw) {
      if (entry is! Map<String, dynamic>) continue;
      final String? name = _nonEmpty(entry['name'] as String?);
      if (name == null) continue;
      entries.add((count: (entry['count'] as num?)?.toInt() ?? 0, name: name));
    }
    entries.sort(
      (({int count, String name}) a, ({int count, String name}) b) =>
          b.count.compareTo(a.count),
    );
    final List<String> names =
        entries.map((({int count, String name}) e) => e.name).toList();
    return names.length > max ? names.sublist(0, max) : names;
  }

  static List<String> _stringList(Object? value) {
    if (value is List<dynamic>) {
      return value
          .whereType<String>()
          .where((String s) => s.isNotEmpty)
          .toList();
    }
    return const <String>[];
  }

  static String? _nonEmpty(String? value) {
    final String? trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  /// Year prefix of a possibly truncated "YYYY-MM-DD" date.
  static int? yearFromDate(String? date) {
    if (date == null || date.length < 4) return null;
    return int.tryParse(date.substring(0, 4));
  }
}
