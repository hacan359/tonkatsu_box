import 'data_source.dart';
import 'media_type.dart';

/// A release-tracking subscription for one title.
///
/// Identity is `(externalId, source, mediaType)`, matching how the app
/// disambiguates entities across providers (e.g. AniList vs MangaBaka ids).
class TrackedRelease {
  const TrackedRelease({
    required this.externalId,
    required this.source,
    required this.mediaType,
    required this.createdAt,
  });

  factory TrackedRelease.fromDb(Map<String, dynamic> row) {
    return TrackedRelease(
      externalId: row['external_id'] as int,
      source: DataSource.fromName(row['source'] as String?),
      mediaType: MediaType.fromString(row['media_type'] as String),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
    );
  }

  /// Provider id (TMDB / AniList / MangaBaka).
  final int externalId;

  /// Provider the id belongs to.
  final DataSource source;

  /// Title type — drives the Releases filter and how dates are read.
  final MediaType mediaType;

  /// When the user subscribed.
  final DateTime createdAt;

  Map<String, dynamic> toDb() {
    return <String, dynamic>{
      'external_id': externalId,
      'source': source.name,
      'media_type': mediaType.value,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }
}
