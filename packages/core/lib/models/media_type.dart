import 'data_source.dart';

/// Media content type of a collection item.
enum MediaType {
  /// Game (IGDB).
  game('game'),

  /// Movie (TMDB).
  movie('movie'),

  /// TV show (TMDB).
  tvShow('tv_show'),

  /// Animated movies and series (Pixar, Disney). Uses [Movie] / [TvShow] with
  /// an [AnimationSource] platformId — not [anime], which is AniList.
  animation('animation'),

  /// Visual novel (VNDB).
  visualNovel('visual_novel'),

  /// Manga (AniList).
  manga('manga'),

  /// Japanese anime on its own [Anime] model backed by AniList — not
  /// [animation], which is TMDB cartoons.
  anime('anime'),

  /// Book (OpenLibrary / Fantlab).
  book('book'),

  /// Music album — a MusicBrainz release-group.
  music('music'),

  /// Custom user-created item.
  custom('custom');

  const MediaType(this.value);

  /// Whether episode tracking applies (tv show or tv-based animation).
  bool get isTvBacked =>
      this == MediaType.tvShow || this == MediaType.animation;

  /// Coarse, type-only answer for things like cache invalidation; the source
  /// decides per item (see `CollectionItem.usesEpisodeTracker`).
  bool get mayUseEpisodeTracker => isTvBacked || this == MediaType.anime;

  /// Several providers serve this type and their numeric ids collide. Animation
  /// is excluded on purpose — it only ever comes from TMDB.
  bool get isMultiSource =>
      this == MediaType.manga ||
      this == MediaType.anime ||
      this == MediaType.tvShow ||
      this == MediaType.movie ||
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
        MediaType.music => DataSource.musicBrainz,
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
      case MediaType.music:
        return 'Music';
      case MediaType.custom:
        return 'Custom';
    }
  }

  /// Movies and TV shows only (Blu-ray template); game overlays come from
  /// [Platform.overlayAsset] instead.
  String? get overlayAsset => switch (this) {
        MediaType.movie || MediaType.tvShow =>
          'assets/images/platform_overlays/blu-ray.png',
        _ => null,
      };
}

/// Stored in `collection_items.platform_id`: [movie] = 0, [tvShow] = 1.
abstract final class AnimationSource {
  /// Animated movie.
  static const int movie = 0;

  /// Animated series.
  static const int tvShow = 1;
}
