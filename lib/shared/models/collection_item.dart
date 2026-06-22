import 'package:flutter/material.dart';

import '../../core/services/image_cache_service.dart';
import 'book.dart';
import 'custom_media.dart';
import 'data_source.dart';
import 'exportable.dart';
import 'game.dart';
import 'item_status.dart';
import 'item_status_logic.dart';
import 'media_type.dart';
import 'movie.dart';
import 'platform.dart';
import 'anime.dart';
import 'manga.dart';
import 'tv_show.dart';
import 'visual_novel.dart';
import '../utils/cover_image_id.dart' as cover_id;

/// Universal collection entry — games, movies, TV, anime, manga, visual
/// novels and custom items share one row type, switched on [mediaType].
class CollectionItem with Exportable {
  const CollectionItem({
    required this.id,
    required this.collectionId,
    required this.mediaType,
    required this.externalId,
    required this.status,
    required this.addedAt,
    this.startedAt,
    this.completedAt,
    this.lastActivityAt,
    this.platformId,
    this.source,
    this.tagId,
    this.currentSeason = 0,
    this.currentEpisode = 0,
    this.sortOrder = 0,
    this.timeSpentMinutes = 0,
    this.authorComment,
    this.userComment,
    this.userRating,
    this.overrideName,
    this.game,
    this.movie,
    this.tvShow,
    this.visualNovel,
    this.anime,
    this.manga,
    this.book,
    this.customMedia,
    this.platform,
  });

  factory CollectionItem.fromDb(Map<String, dynamic> row) {
    return CollectionItem.fromDbWithJoins(row);
  }

  /// Builds a [CollectionItem] from a row that joined the cached media tables
  /// (games / movies / tv_shows / etc.) for hydrating media metadata in one pass.
  factory CollectionItem.fromDbWithJoins(
    Map<String, dynamic> row, {
    Game? game,
    Movie? movie,
    TvShow? tvShow,
    VisualNovel? visualNovel,
    Anime? anime,
    Manga? manga,
    Book? book,
    CustomMedia? customMedia,
    Platform? platform,
  }) {
    return CollectionItem(
      id: row['id'] as int,
      collectionId: row['collection_id'] as int?,
      mediaType: MediaType.fromString(row['media_type'] as String),
      externalId: row['external_id'] as int,
      platformId: row['platform_id'] as int?,
      source: row['source'] != null
          ? DataSource.fromName(row['source'] as String?)
          : null,
      tagId: row['tag_id'] as int?,
      currentSeason: (row['current_season'] as int?) ?? 0,
      currentEpisode: (row['current_episode'] as int?) ?? 0,
      sortOrder: (row['sort_order'] as int?) ?? 0,
      timeSpentMinutes: (row['time_spent_minutes'] as int?) ?? 0,
      status: ItemStatus.fromString(row['status'] as String),
      authorComment: row['author_comment'] as String?,
      userComment: row['user_comment'] as String?,
      userRating: (row['user_rating'] as num?)?.toDouble(),
      overrideName: row['override_name'] as String?,
      addedAt: DateTime.fromMillisecondsSinceEpoch(
        (row['added_at'] as int) * 1000,
      ),
      startedAt: row['started_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (row['started_at'] as int) * 1000,
            )
          : null,
      completedAt: row['completed_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (row['completed_at'] as int) * 1000,
            )
          : null,
      lastActivityAt: row['last_activity_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (row['last_activity_at'] as int) * 1000,
            )
          : null,
      game: game,
      movie: movie,
      tvShow: tvShow,
      visualNovel: visualNovel,
      anime: anime,
      manga: manga,
      book: book,
      customMedia: customMedia,
      platform: platform,
    );
  }

  factory CollectionItem.fromExport(
    Map<String, dynamic> json, {
    int id = 0,
    int? collectionId,
    DateTime? addedAt,
  }) {
    return CollectionItem(
      id: id,
      collectionId: collectionId,
      mediaType: MediaType.fromString(json['media_type'] as String),
      externalId: json['external_id'] as int,
      platformId: json['platform_id'] as int?,
      source: json['source'] != null
          ? DataSource.fromName(json['source'] as String?)
          : null,
      currentSeason: (json['current_season'] as int?) ?? 0,
      currentEpisode: (json['current_episode'] as int?) ?? 0,
      timeSpentMinutes: (json['time_spent_minutes'] as int?) ?? 0,
      status: json['status'] != null
          ? ItemStatus.fromString(json['status'] as String)
          : ItemStatus.notStarted,
      authorComment: json['comment'] as String?,
      userComment: json['user_comment'] as String?,
      userRating: (json['user_rating'] as num?)?.toDouble(),
      overrideName: json['override_name'] as String?,
      sortOrder: (json['sort_order'] as int?) ?? 0,
      addedAt: json['added_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (json['added_at'] as int) * 1000,
            )
          : addedAt ?? DateTime.now(),
      startedAt: json['started_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (json['started_at'] as int) * 1000,
            )
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (json['completed_at'] as int) * 1000,
            )
          : null,
      lastActivityAt: json['last_activity_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (json['last_activity_at'] as int) * 1000,
            )
          : null,
    );
  }

  final int id;

  /// `null` for "uncategorised" items — owned by the user but outside any
  /// collection.
  final int? collectionId;

  bool get isUncategorized => collectionId == null;

  final MediaType mediaType;

  /// Provider-side id — IGDB id for games, TMDB id for movies/TV, AniList id
  /// for anime/manga, VNDB id for visual novels.
  final int externalId;

  /// Platform id from the local `platforms` table — only meaningful for
  /// games and for [MediaType.animation] (Movie vs TV via [AnimationSource]).
  final int? platformId;

  /// External provider this item came from. Only meaningful for manga
  /// ([DataSource.anilist] / [DataSource.mangabaka]); `null` for other media
  /// types. Part of the manga identity so the same `external_id` from two
  /// providers stays distinct.
  final DataSource? source;

  /// Optional grouping tag inside a collection.
  final int? tagId;

  final int currentSeason;
  final int currentEpisode;

  /// Drag-and-drop order; lower comes first. Re-sequenced on manual reorder.
  final int sortOrder;

  /// Manual playtime in minutes — separate from any provider-side stats.
  final int timeSpentMinutes;

  final ItemStatus status;

  /// Author note attached when the collection was shared (read-only on
  /// import).
  final String? authorComment;

  /// Private note the current user wrote on this item.
  final String? userComment;

  /// User rating 1.0–10.0 (step 0.1). `null` means "not rated", not zero.
  final double? userRating;

  /// User-set display name that overrides the cached API title. `null` means
  /// "no override" — UI falls back to the joined media's name.
  final String? overrideName;

  final DateTime addedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? lastActivityAt;

  /// Joined media payloads — exactly one of the eight fields is non-null,
  /// picked by [mediaType] (game / movie / tvShow / visualNovel / anime /
  /// manga / book / customMedia).
  final Game? game;
  final Movie? movie;
  final TvShow? tvShow;
  final VisualNovel? visualNovel;
  final Anime? anime;
  final Manga? manga;
  final Book? book;
  final CustomMedia? customMedia;

  /// Joined platform metadata for games / animation.
  final Platform? platform;

  /// Legacy alias kept for older callers that hard-coded `igdbId`.
  int get igdbId => externalId;

  /// Per-[mediaType] view used by every UI getter to avoid duplicating the
  /// switch. IGDB rating (0–100) is normalised here to 0–10 to match TMDB.
  ({
    String? name,
    String? coverUrl,
    String? thumbUrl,
    String? description,
    double? rating,
    String? formattedRating,
    int? releaseYear,
    int? runtime,
    int? totalSeasons,
    int? totalEpisodes,
    String? genresString,
    List<String>? genres,
    String? mediaStatus,
    DataSource source,
    ImageType imageType,
    IconData placeholderIcon,
  }) get _resolvedMedia {
    switch (mediaType) {
      case MediaType.game:
        return (
          name: game?.name,
          coverUrl: game?.coverUrl,
          thumbUrl: game?.coverUrl,
          description: game?.summary,
          rating: game?.rating != null ? game!.rating! / 10 : null,
          formattedRating: game?.formattedRating,
          releaseYear: game?.releaseYear,
          runtime: null,
          totalSeasons: null,
          totalEpisodes: null,
          genresString: game?.genresString,
          genres: game?.genres,
          mediaStatus: null,
          source: DataSource.igdb,
          imageType: ImageType.gameCover,
          placeholderIcon: Icons.videogame_asset,
        );
      case MediaType.movie:
        return (
          name: movie?.title,
          coverUrl: movie?.posterUrl,
          thumbUrl: movie?.posterThumbUrl,
          description: movie?.overview,
          rating: movie?.rating,
          formattedRating: movie?.formattedRating,
          releaseYear: movie?.releaseYear,
          runtime: movie?.runtime,
          totalSeasons: null,
          totalEpisodes: null,
          genresString: movie?.genresString,
          genres: movie?.genres,
          mediaStatus: null,
          source: DataSource.tmdb,
          imageType: ImageType.moviePoster,
          placeholderIcon: Icons.movie_outlined,
        );
      case MediaType.tvShow:
        return (
          name: tvShow?.title,
          coverUrl: tvShow?.posterUrl,
          thumbUrl: tvShow?.posterThumbUrl,
          description: tvShow?.overview,
          rating: tvShow?.rating,
          formattedRating: tvShow?.formattedRating,
          releaseYear: tvShow?.firstAirYear,
          runtime: null,
          totalSeasons: tvShow?.totalSeasons,
          totalEpisodes: tvShow?.totalEpisodes,
          genresString: tvShow?.genresString,
          genres: tvShow?.genres,
          mediaStatus: tvShow?.status,
          source: DataSource.tmdb,
          imageType: ImageType.tvShowPoster,
          placeholderIcon: Icons.tv_outlined,
        );
      case MediaType.animation:
        final bool isTvBased = platformId == AnimationSource.tvShow;
        if (isTvBased) {
          return (
            name: tvShow?.title,
            coverUrl: tvShow?.posterUrl,
            thumbUrl: tvShow?.posterThumbUrl,
            description: tvShow?.overview,
            rating: tvShow?.rating,
            formattedRating: tvShow?.formattedRating,
            releaseYear: tvShow?.firstAirYear,
            runtime: null,
            totalSeasons: tvShow?.totalSeasons,
            totalEpisodes: tvShow?.totalEpisodes,
            genresString: tvShow?.genresString,
            genres: tvShow?.genres,
            mediaStatus: tvShow?.status,
            source: DataSource.tmdb,
            imageType: ImageType.tvShowPoster,
            placeholderIcon: Icons.animation,
          );
        }
        return (
          name: movie?.title,
          coverUrl: movie?.posterUrl,
          thumbUrl: movie?.posterThumbUrl,
          description: movie?.overview,
          rating: movie?.rating,
          formattedRating: movie?.formattedRating,
          releaseYear: movie?.releaseYear,
          runtime: movie?.runtime,
          totalSeasons: null,
          totalEpisodes: null,
          genresString: movie?.genresString,
          genres: movie?.genres,
          mediaStatus: null,
          source: DataSource.tmdb,
          imageType: ImageType.moviePoster,
          placeholderIcon: Icons.animation,
        );
      case MediaType.visualNovel:
        return (
          name: visualNovel?.title,
          coverUrl: visualNovel?.imageUrl,
          thumbUrl: visualNovel?.imageUrl,
          description: visualNovel?.description,
          rating: visualNovel?.rating10,
          formattedRating: visualNovel?.formattedRating,
          releaseYear: visualNovel?.releaseYear,
          runtime: visualNovel?.lengthMinutes,
          totalSeasons: null,
          totalEpisodes: null,
          genresString: visualNovel?.genresString,
          genres: visualNovel?.tags,
          mediaStatus: null,
          source: DataSource.vndb,
          imageType: ImageType.vnCover,
          placeholderIcon: Icons.menu_book,
        );
      case MediaType.manga:
        return (
          name: manga?.title,
          coverUrl: manga?.coverUrl,
          thumbUrl: manga?.coverUrl ?? manga?.coverUrlMedium,
          description: manga?.description,
          rating: manga?.rating10,
          formattedRating: manga?.formattedRating,
          releaseYear: manga?.releaseYear,
          runtime: null,
          totalSeasons: null,
          totalEpisodes: null,
          genresString: manga?.genresString,
          genres: manga?.genres,
          mediaStatus: manga?.statusLabel,
          source: manga?.source ?? DataSource.anilist,
          imageType: ImageType.mangaCover,
          placeholderIcon: Icons.auto_stories,
        );
      case MediaType.book:
        return (
          name: book?.title,
          coverUrl: book?.coverUrl,
          thumbUrl: book?.coverUrl,
          description: book?.description,
          rating: book?.rating,
          formattedRating: book?.formattedRating,
          releaseYear: book?.releaseYear,
          runtime: null,
          totalSeasons: null,
          totalEpisodes: null,
          genresString: book?.subjectsString,
          genres: book?.subjects,
          mediaStatus: null,
          source: book?.source ?? DataSource.openLibrary,
          imageType: ImageType.bookCover,
          placeholderIcon: Icons.menu_book,
        );
      case MediaType.anime:
        return (
          name: anime?.title,
          coverUrl: anime?.coverUrl,
          thumbUrl: anime?.coverUrl ?? anime?.coverUrlMedium,
          description: anime?.description,
          rating: anime?.rating10,
          formattedRating: anime?.formattedRating,
          releaseYear: anime?.releaseYear,
          runtime: null,
          totalSeasons: null,
          totalEpisodes: anime?.episodes,
          genresString: anime?.genresString,
          genres: anime?.genres,
          mediaStatus: anime?.statusLabel,
          source: DataSource.anilist,
          imageType: ImageType.animeCover,
          placeholderIcon: Icons.play_circle_outline,
        );
      case MediaType.custom:
        final MediaType displayType =
            customMedia?.displayType ?? MediaType.custom;
        return (
          name: customMedia?.title,
          coverUrl: customMedia?.coverUrl,
          thumbUrl: customMedia?.coverUrl,
          description: customMedia?.description,
          rating: null,
          formattedRating: null,
          releaseYear: customMedia?.year,
          runtime: null,
          totalSeasons: null,
          totalEpisodes: null,
          genresString: customMedia?.genres,
          genres: customMedia?.genreList,
          mediaStatus: null,
          source: DataSource.local,
          imageType: ImageType.customCover,
          placeholderIcon: displayType == MediaType.custom
              ? Icons.dashboard_customize
              : _placeholderIconFor(displayType),
        );
    }
  }

  /// Title from the joined media, falling back to a typed "Unknown X" so the
  /// UI never renders an empty row.
  String get itemName {
    final String fallback = switch (mediaType) {
      MediaType.game => 'Unknown Game',
      MediaType.movie => 'Unknown Movie',
      MediaType.tvShow => 'Unknown TV Show',
      MediaType.animation => 'Unknown Animation',
      MediaType.visualNovel => 'Unknown Visual Novel',
      MediaType.manga => 'Unknown Manga',
      MediaType.anime => 'Unknown Anime',
      MediaType.book => 'Unknown Book',
      MediaType.custom => 'Unknown Custom Item',
    };
    return overrideName ?? _resolvedMedia.name ?? fallback;
  }

  /// AniList-aware display name. `overrideName` wins; for anime/manga the
  /// preferred language from settings drives the title, with a fallback to
  /// romaji.
  String displayName(String animeMangaTitleLanguage) {
    if (overrideName != null) return overrideName!;
    switch (mediaType) {
      case MediaType.anime:
        return anime?.titleByLanguage(animeMangaTitleLanguage) ?? itemName;
      case MediaType.manga:
        return manga?.titleByLanguage(animeMangaTitleLanguage) ?? itemName;
      default:
        return itemName;
    }
  }

  /// Cached API title (joined media name), without applying [overrideName].
  /// Used by the rename UI to show the original next to the editable field.
  String? get cachedName => _resolvedMedia.name;

  /// Effective media type for display — custom items can carry an
  /// overriding `displayType` so they masquerade as games / movies / …
  MediaType get displayMediaType =>
      mediaType == MediaType.custom && customMedia?.displayType != null
          ? customMedia!.displayType!
          : mediaType;

  /// Format label for manga / anime (e.g. "Manhwa", "OVA"). `null` for other
  /// media types or when the source did not report a format — callers fall
  /// back to the generic media-type caption in that case.
  String? get formatLabel => switch (mediaType) {
        MediaType.manga => manga?.formatLabel,
        MediaType.anime => anime?.formatLabel,
        _ => null,
      };

  String get platformName => platform?.displayName ?? 'Unknown Platform';

  static IconData _placeholderIconFor(MediaType type) => switch (type) {
        MediaType.game => Icons.videogame_asset,
        MediaType.movie => Icons.movie_outlined,
        MediaType.tvShow => Icons.tv_outlined,
        MediaType.animation => Icons.animation,
        MediaType.visualNovel => Icons.menu_book,
        MediaType.manga => Icons.auto_stories,
        MediaType.anime => Icons.play_circle_outline,
        MediaType.book => Icons.menu_book,
        MediaType.custom => Icons.dashboard_customize,
      };

  bool get hasAuthorComment =>
      authorComment != null && authorComment!.isNotEmpty;

  bool get hasUserComment => userComment != null && userComment!.isNotEmpty;

  /// Wall-clock time between [startedAt] and [completedAt]; `null` when
  /// either bound is missing or the diff is negative (clock skew on import).
  Duration? get completionTime {
    if (startedAt == null || completedAt == null) return null;
    final Duration diff = completedAt!.difference(startedAt!);
    return diff.isNegative ? null : diff;
  }

  bool get isCompleted => status == ItemStatus.completed;

  String? get coverUrl => _resolvedMedia.coverUrl;

  /// Provider rating normalised to a 0–10 scale (IGDB stores 0–100).
  double? get apiRating => _resolvedMedia.rating;

  String? get itemDescription => _resolvedMedia.description;
  String? get thumbnailUrl => _resolvedMedia.thumbUrl;
  int? get releaseYear => _resolvedMedia.releaseYear;
  int? get runtime => _resolvedMedia.runtime;
  int? get totalSeasons => _resolvedMedia.totalSeasons;
  int? get totalEpisodes => _resolvedMedia.totalEpisodes;
  String? get genresString => _resolvedMedia.genresString;
  List<String>? get genres => _resolvedMedia.genres;
  String? get formattedRating => _resolvedMedia.formattedRating;
  String? get mediaStatus => _resolvedMedia.mediaStatus;
  DataSource get dataSource => _resolvedMedia.source;
  ImageType get imageType => _resolvedMedia.imageType;
  IconData get placeholderIcon => _resolvedMedia.placeholderIcon;

  /// Source-aware image-cache id (manga is namespaced by provider). Use this
  /// everywhere a cover is read from / written to the image cache.
  String get coverImageId => cover_id.coverImageId(
        mediaType: mediaType,
        externalId: externalId,
        source: source,
        coverUrl: thumbnailUrl,
      );

  @override
  Set<String> get internalDbFields =>
      const <String>{
        'id', 'collection_id', 'user_comment',
        'added_at', 'sort_order',
        'started_at', 'completed_at', 'last_activity_at',
        'status', 'current_season', 'current_episode',
        'tag_id', 'time_spent_minutes', 'override_name',
      };

  @override
  Map<String, String> get dbToExportKeyMapping =>
      const <String, String>{'author_comment': 'comment'};

  @override
  Map<String, dynamic> toDb() {
    return <String, dynamic>{
      'id': id,
      'collection_id': collectionId,
      'media_type': mediaType.value,
      'external_id': externalId,
      'platform_id': platformId,
      'source': source?.name,
      'tag_id': tagId,
      'current_season': currentSeason,
      'current_episode': currentEpisode,
      'status': status.value,
      'author_comment': authorComment,
      'user_comment': userComment,
      'user_rating': userRating,
      'time_spent_minutes': timeSpentMinutes,
      'override_name': overrideName,
      'added_at': addedAt.millisecondsSinceEpoch ~/ 1000,
      'sort_order': sortOrder,
      'started_at': startedAt != null
          ? startedAt!.millisecondsSinceEpoch ~/ 1000
          : null,
      'completed_at': completedAt != null
          ? completedAt!.millisecondsSinceEpoch ~/ 1000
          : null,
      'last_activity_at': lastActivityAt != null
          ? lastActivityAt!.millisecondsSinceEpoch ~/ 1000
          : null,
    };
  }

  /// When [includeUserData] is true the export carries personal fields
  /// (status, dates, notes, season/episode progress, sort order) on top of
  /// the bare media reference suitable for sharing.
  @override
  Map<String, dynamic> toExport({bool includeUserData = false}) {
    final Map<String, dynamic> data = <String, dynamic>{
      'media_type': mediaType.value,
      'external_id': externalId,
      'platform_id': platformId,
      'source': source?.name,
      'comment': authorComment,
      'user_rating': userRating,
    };
    if (includeUserData) {
      if (overrideName != null) {
        data['override_name'] = overrideName;
      }
      data['status'] = status.value;
      data['user_comment'] = userComment;
      data['current_season'] = currentSeason;
      data['current_episode'] = currentEpisode;
      data['time_spent_minutes'] = timeSpentMinutes;
      data['added_at'] = addedAt.millisecondsSinceEpoch ~/ 1000;
      data['sort_order'] = sortOrder;
      data['started_at'] = startedAt != null
          ? startedAt!.millisecondsSinceEpoch ~/ 1000
          : null;
      data['completed_at'] = completedAt != null
          ? completedAt!.millisecondsSinceEpoch ~/ 1000
          : null;
      data['last_activity_at'] = lastActivityAt != null
          ? lastActivityAt!.millisecondsSinceEpoch ~/ 1000
          : null;
    }
    return data;
  }

  CollectionItem copyWith({
    int? id,
    int? collectionId,
    bool clearCollectionId = false,
    MediaType? mediaType,
    int? externalId,
    int? platformId,
    DataSource? source,
    int? tagId,
    bool clearTagId = false,
    int? currentSeason,
    int? currentEpisode,
    int? sortOrder,
    int? timeSpentMinutes,
    ItemStatus? status,
    String? authorComment,
    bool clearAuthorComment = false,
    String? userComment,
    bool clearUserComment = false,
    double? userRating,
    bool clearUserRating = false,
    String? overrideName,
    bool clearOverrideName = false,
    DateTime? addedAt,
    DateTime? startedAt,
    bool clearStartedAt = false,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    DateTime? lastActivityAt,
    Game? game,
    Movie? movie,
    TvShow? tvShow,
    VisualNovel? visualNovel,
    Anime? anime,
    Manga? manga,
    Book? book,
    CustomMedia? customMedia,
    Platform? platform,
  }) {
    return CollectionItem(
      id: id ?? this.id,
      collectionId:
          clearCollectionId ? null : (collectionId ?? this.collectionId),
      mediaType: mediaType ?? this.mediaType,
      externalId: externalId ?? this.externalId,
      platformId: platformId ?? this.platformId,
      source: source ?? this.source,
      tagId: clearTagId ? null : (tagId ?? this.tagId),
      currentSeason: currentSeason ?? this.currentSeason,
      currentEpisode: currentEpisode ?? this.currentEpisode,
      sortOrder: sortOrder ?? this.sortOrder,
      timeSpentMinutes: timeSpentMinutes ?? this.timeSpentMinutes,
      status: status ?? this.status,
      authorComment:
          clearAuthorComment ? null : (authorComment ?? this.authorComment),
      userComment:
          clearUserComment ? null : (userComment ?? this.userComment),
      userRating: clearUserRating ? null : (userRating ?? this.userRating),
      overrideName:
          clearOverrideName ? null : (overrideName ?? this.overrideName),
      addedAt: addedAt ?? this.addedAt,
      startedAt: clearStartedAt ? null : (startedAt ?? this.startedAt),
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      game: game ?? this.game,
      movie: movie ?? this.movie,
      tvShow: tvShow ?? this.tvShow,
      visualNovel: visualNovel ?? this.visualNovel,
      anime: anime ?? this.anime,
      manga: manga ?? this.manga,
      book: book ?? this.book,
      customMedia: customMedia ?? this.customMedia,
      platform: platform ?? this.platform,
    );
  }

  /// Returns a copy with the new status and recomputed activity dates.
  /// All date math goes through [computeDatesForStatus] so UI, importers and
  /// external syncs stay in lockstep.
  CollectionItem withStatus(ItemStatus newStatus, {DateTime? now}) {
    final StatusDatesUpdate update = computeDatesForStatus(
      newStatus: newStatus,
      currentStartedAt: startedAt,
      currentCompletedAt: completedAt,
      now: now ?? DateTime.now(),
    );
    return copyWith(
      status: update.status,
      startedAt: update.startedAt,
      completedAt: update.completedAt,
      lastActivityAt: update.lastActivityAt,
      clearStartedAt: update.clearStartedAt,
      clearCompletedAt: update.clearCompletedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CollectionItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'CollectionItem(id: $id, type: ${mediaType.value}, '
      'externalId: $externalId, status: ${status.value})';
}
