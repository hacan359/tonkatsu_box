import '../models/data_source.dart';
import '../models/media_type.dart';

/// Canonical image-cache id for a media cover.
///
/// Anime, manga, books and TV shows are multi-provider: their providers can
/// share a numeric `externalId`, so covers are namespaced by source
/// (`anilist_1995` / `mangabaka_1995` / `tvmaze_1399`) to avoid one
/// overwriting the other. Every other media type keeps the bare external id.
///
/// Animation stays bare on purpose: it only ever comes from TMDB, and
/// namespacing it would orphan every cached animation poster and split the
/// cache entry an animated film shares with the same film added as a movie.
///
/// MUST be used by both the write side (download/save) and the read side
/// (display) so the keys line up.
String coverImageId({
  required MediaType mediaType,
  required int externalId,
  DataSource? source,
  String? coverUrl,
}) {
  if (!mediaType.isMultiSource) return externalId.toString();

  final String base = '${(source ?? mediaType.defaultSource).name}_$externalId';
  if (mediaType != MediaType.book) return base;

  // A Fantlab cover belongs to a specific edition (its id is embedded in the
  // URL). Key by it so picking a different edition is a distinct cache entry
  // rather than a stale overwrite of the same `work` file.
  final RegExpMatch? edition =
      coverUrl != null ? _fantlabEditionId.firstMatch(coverUrl) : null;
  return edition != null ? '${base}_e${edition.group(1)}' : base;
}

final RegExp _fantlabEditionId = RegExp(r'/images/editions/\w+/(\d+)');
