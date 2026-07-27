import 'data_source.dart';

/// Media content type of a collection item.
enum MediaType {
  /// Game (IGDB).
  game('game'),

  /// Movie (TMDB).
  movie('movie'),

  /// TV show (TMDB).
  tvShow('tv_show'),

  /// Animation (TMDB) — animated movies and series (Pixar, Disney, etc.).
  ///
  /// Uses the [Movie]/[TvShow] models with an [AnimationSource] platformId.
  /// Not to be confused with [anime] — Japanese anime from AniList.
  animation('animation'),

  /// Visual novel (VNDB).
  visualNovel('visual_novel'),

  /// Manga (AniList).
  manga('manga'),

  /// Anime (AniList) — Japanese anime with full metadata.
  ///
  /// Uses its own [Anime] model backed by the AniList API.
  /// Not to be confused with [animation] — TMDB animation (cartoons).
  anime('anime'),

  /// Book (OpenLibrary / Fantlab).
  book('book'),

  /// Custom user-created item.
  custom('custom');

  const MediaType(this.value);

  /// Whether episode tracking applies (tv show or tv-based animation).
  bool get isTvBacked =>
      this == MediaType.tvShow || this == MediaType.animation;

  /// Whether items of this type *may* carry episode-tracker marks — the source
  /// decides per item (see `CollectionItem.usesEpisodeTracker`). For coarse
  /// decisions like cache invalidation, where only the type is known.
  bool get mayUseEpisodeTracker => isTvBacked || this == MediaType.anime;

  /// Whether identity is `(externalId, source)` rather than `externalId`
  /// alone: several providers serve this type and their numeric ids collide.
  /// Animation is excluded on purpose — it only ever comes from TMDB.
  bool get isMultiSource =>
      this == MediaType.manga ||
      this == MediaType.anime ||
      this == MediaType.tvShow ||
      this == MediaType.book;

  /// Fallback source for rows whose `source` column is NULL.
  DataSource get defaultSource => switch (this) {
        MediaType.game => DataSource.igdb,
        MediaType.movie => DataSource.tmdb,
        MediaType.tvShow => DataSource.tmdb,
        MediaType.animation => DataSource.tmdb,
        MediaType.visualNovel => DataSource.vndb,
        MediaType.manga => DataSource.anilist,
        MediaType.anime => DataSource.anilist,
        MediaType.book => DataSource.openLibrary,
        MediaType.custom => DataSource.local,
      };

  /// String value stored in the database.
  final String value;

  /// Creates a [MediaType] from a string; falls back to [game] when
  /// unrecognised.
  static MediaType fromString(String value) =>
      tryFromString(value) ?? MediaType.game;

  /// Creates a [MediaType] from a string; `null` when unrecognised.
  static MediaType? tryFromString(String value) {
    for (final MediaType type in MediaType.values) {
      if (type.value == value) {
        return type;
      }
    }
    return null;
  }

  /// English display name.
  String get displayLabel {
    switch (this) {
      case MediaType.game:
        return 'Game';
      case MediaType.movie:
        return 'Movie';
      case MediaType.tvShow:
        return 'TV Show';
      case MediaType.animation:
        return 'Animation';
      case MediaType.visualNovel:
        return 'Visual Novel';
      case MediaType.manga:
        return 'Manga';
      case MediaType.anime:
        return 'Anime';
      case MediaType.book:
        return 'Book';
      case MediaType.custom:
        return 'Custom';
    }
  }

  /// Overlay asset path for this media type, or `null`.
  ///
  /// Used for movies and TV shows (Blu-ray template); game overlays come
  /// from [Platform.overlayAsset] instead.
  String? get overlayAsset => switch (this) {
        MediaType.movie || MediaType.tvShow =>
          'assets/images/platform_overlays/blu-ray.png',
        _ => null,
      };
}

/// Animation source kind (movie or series).
///
/// Stored in `collection_items.platform_id`:
/// - [movie] = 0 → animated movie
/// - [tvShow] = 1 → animated series
abstract final class AnimationSource {
  /// Animated movie.
  static const int movie = 0;

  /// Animated series.
  static const int tvShow = 1;
}
