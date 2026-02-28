// Универсальный элемент коллекции (игра, фильм или сериал).

import 'package:flutter/material.dart';

import '../../core/services/image_cache_service.dart';
import 'data_source.dart';
import 'exportable.dart';
import 'game.dart';
import 'item_status.dart';
import 'media_type.dart';
import 'movie.dart';
import 'platform.dart';
import 'tv_show.dart';
import 'visual_novel.dart';

/// Универсальный элемент коллекции.
///
/// Поддерживает игры, фильмы, сериалы и анимацию в одной коллекции.
class CollectionItem with Exportable {
  /// Создаёт экземпляр [CollectionItem].
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
    this.currentSeason = 0,
    this.currentEpisode = 0,
    this.sortOrder = 0,
    this.authorComment,
    this.userComment,
    this.userRating,
    this.game,
    this.movie,
    this.tvShow,
    this.visualNovel,
    this.platform,
  });

  /// Создаёт [CollectionItem] из записи базы данных.
  factory CollectionItem.fromDb(Map<String, dynamic> row) {
    return CollectionItem.fromDbWithJoins(row);
  }

  /// Создаёт [CollectionItem] из записи БД с join-данными.
  factory CollectionItem.fromDbWithJoins(
    Map<String, dynamic> row, {
    Game? game,
    Movie? movie,
    TvShow? tvShow,
    VisualNovel? visualNovel,
    Platform? platform,
  }) {
    return CollectionItem(
      id: row['id'] as int,
      collectionId: row['collection_id'] as int?,
      mediaType: MediaType.fromString(row['media_type'] as String),
      externalId: row['external_id'] as int,
      platformId: row['platform_id'] as int?,
      currentSeason: (row['current_season'] as int?) ?? 0,
      currentEpisode: (row['current_episode'] as int?) ?? 0,
      sortOrder: (row['sort_order'] as int?) ?? 0,
      status: ItemStatus.fromString(row['status'] as String),
      authorComment: row['author_comment'] as String?,
      userComment: row['user_comment'] as String?,
      userRating: row['user_rating'] as int?,
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
      platform: platform,
    );
  }

  /// Создаёт [CollectionItem] из экспортных данных.
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
      currentSeason: (json['current_season'] as int?) ?? 0,
      currentEpisode: (json['current_episode'] as int?) ?? 0,
      status: json['status'] != null
          ? ItemStatus.fromString(json['status'] as String)
          : ItemStatus.notStarted,
      authorComment: json['comment'] as String?,
      userRating: json['user_rating'] as int?,
      addedAt: addedAt ?? DateTime.now(),
    );
  }

  /// Уникальный идентификатор записи.
  final int id;

  /// ID коллекции (null для элементов без коллекции).
  final int? collectionId;

  /// true если элемент не принадлежит ни одной коллекции.
  bool get isUncategorized => collectionId == null;

  /// Тип медиа-контента.
  final MediaType mediaType;

  /// Внешний ID (igdb_id для игр, tmdb_id для фильмов/сериалов).
  final int externalId;

  /// ID платформы (только для игр).
  final int? platformId;

  /// Текущий сезон (для сериалов).
  final int currentSeason;

  /// Текущий эпизод (для сериалов).
  final int currentEpisode;

  /// Порядок сортировки (для ручной сортировки drag-and-drop).
  final int sortOrder;

  /// Статус прохождения/просмотра.
  final ItemStatus status;

  /// Комментарий автора коллекции.
  final String? authorComment;

  /// Личный комментарий пользователя.
  final String? userComment;

  /// Пользовательский рейтинг (1-10).
  final int? userRating;

  /// Дата добавления в коллекцию.
  final DateTime addedAt;

  /// Дата начала (начал играть/смотреть).
  final DateTime? startedAt;

  /// Дата завершения.
  final DateTime? completedAt;

  /// Дата последней активности.
  final DateTime? lastActivityAt;

  /// Данные игры (joined).
  final Game? game;

  /// Данные фильма (joined).
  final Movie? movie;

  /// Данные сериала (joined).
  final TvShow? tvShow;

  /// Данные визуальной новеллы (joined).
  final VisualNovel? visualNovel;

  /// Данные платформы (joined).
  final Platform? platform;

  // -- Геттеры совместимости --

  /// ID в IGDB (для игр). Алиас для [externalId].
  int get igdbId => externalId;

  /// Унифицированные поля текущего медиа-элемента.
  ///
  /// Позволяет избежать дублирования switch(mediaType) в каждом геттере.
  /// IGDB рейтинг нормализуется к 0–10 (IGDB хранит 0–100).
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
    }
  }

  /// Название элемента (игра, фильм, сериал или анимация).
  String get itemName {
    final String fallback = switch (mediaType) {
      MediaType.game => 'Unknown Game',
      MediaType.movie => 'Unknown Movie',
      MediaType.tvShow => 'Unknown TV Show',
      MediaType.animation => 'Unknown Animation',
      MediaType.visualNovel => 'Unknown Visual Novel',
    };
    return _resolvedMedia.name ?? fallback;
  }

  /// Название платформы или placeholder.
  String get platformName => platform?.displayName ?? 'Unknown Platform';

  /// Есть ли комментарий автора.
  bool get hasAuthorComment =>
      authorComment != null && authorComment!.isNotEmpty;

  /// Есть ли личный комментарий.
  bool get hasUserComment => userComment != null && userComment!.isNotEmpty;

  /// Завершён ли элемент.
  bool get isCompleted => status == ItemStatus.completed;

  /// URL постера/обложки (полный размер).
  String? get coverUrl => _resolvedMedia.coverUrl;

  /// API рейтинг, нормализованный к шкале 0–10.
  ///
  /// IGDB хранит рейтинг 0–100, нормализация выполняется в [_resolvedMedia].
  /// TMDB уже хранит 0–10.
  double? get apiRating => _resolvedMedia.rating;

  /// Описание элемента (summary для игр, overview для фильмов/сериалов).
  String? get itemDescription => _resolvedMedia.description;

  /// URL маленького постера/обложки для thumbnail-ов.
  String? get thumbnailUrl => _resolvedMedia.thumbUrl;

  /// Год выпуска (Game.releaseYear / Movie.releaseYear / TvShow.firstAirYear).
  int? get releaseYear => _resolvedMedia.releaseYear;

  /// Длительность в минутах (только фильмы).
  int? get runtime => _resolvedMedia.runtime;

  /// Количество сезонов (только сериалы).
  int? get totalSeasons => _resolvedMedia.totalSeasons;

  /// Количество эпизодов (только сериалы).
  int? get totalEpisodes => _resolvedMedia.totalEpisodes;

  /// Жанры строкой ("Action, RPG").
  String? get genresString => _resolvedMedia.genresString;

  /// Жанры списком.
  List<String>? get genres => _resolvedMedia.genres;

  /// Форматированный рейтинг ("7.5").
  String? get formattedRating => _resolvedMedia.formattedRating;

  /// Статус медиа ("Returning Series" и т.п.).
  String? get mediaStatus => _resolvedMedia.mediaStatus;

  /// Источник данных (IGDB / TMDB).
  DataSource get dataSource => _resolvedMedia.source;

  /// Тип изображения для кэша.
  ImageType get imageType => _resolvedMedia.imageType;

  /// Иконка-заглушка.
  IconData get placeholderIcon => _resolvedMedia.placeholderIcon;

  // -- Exportable контракт --

  @override
  Set<String> get internalDbFields =>
      const <String>{
        'id', 'collection_id', 'user_comment',
        'added_at', 'sort_order',
        'started_at', 'completed_at', 'last_activity_at',
        'status', 'current_season', 'current_episode',
      };

  @override
  Map<String, String> get dbToExportKeyMapping =>
      const <String, String>{'author_comment': 'comment'};

  /// Преобразует в Map для сохранения в базу данных.
  @override
  Map<String, dynamic> toDb() {
    return <String, dynamic>{
      'id': id,
      'collection_id': collectionId,
      'media_type': mediaType.value,
      'external_id': externalId,
      'platform_id': platformId,
      'current_season': currentSeason,
      'current_episode': currentEpisode,
      'status': status.value,
      'author_comment': authorComment,
      'user_comment': userComment,
      'user_rating': userRating,
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

  /// Преобразует в Map для экспорта.
  @override
  Map<String, dynamic> toExport() {
    return <String, dynamic>{
      'media_type': mediaType.value,
      'external_id': externalId,
      'platform_id': platformId,
      'comment': authorComment,
      'user_rating': userRating,
    };
  }

  /// Создаёт копию с изменёнными полями.
  CollectionItem copyWith({
    int? id,
    int? collectionId,
    bool clearCollectionId = false,
    MediaType? mediaType,
    int? externalId,
    int? platformId,
    int? currentSeason,
    int? currentEpisode,
    int? sortOrder,
    ItemStatus? status,
    String? authorComment,
    bool clearAuthorComment = false,
    String? userComment,
    bool clearUserComment = false,
    int? userRating,
    bool clearUserRating = false,
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
    Platform? platform,
  }) {
    return CollectionItem(
      id: id ?? this.id,
      collectionId:
          clearCollectionId ? null : (collectionId ?? this.collectionId),
      mediaType: mediaType ?? this.mediaType,
      externalId: externalId ?? this.externalId,
      platformId: platformId ?? this.platformId,
      currentSeason: currentSeason ?? this.currentSeason,
      currentEpisode: currentEpisode ?? this.currentEpisode,
      sortOrder: sortOrder ?? this.sortOrder,
      status: status ?? this.status,
      authorComment:
          clearAuthorComment ? null : (authorComment ?? this.authorComment),
      userComment:
          clearUserComment ? null : (userComment ?? this.userComment),
      userRating: clearUserRating ? null : (userRating ?? this.userRating),
      addedAt: addedAt ?? this.addedAt,
      startedAt: clearStartedAt ? null : (startedAt ?? this.startedAt),
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      game: game ?? this.game,
      movie: movie ?? this.movie,
      tvShow: tvShow ?? this.tvShow,
      visualNovel: visualNovel ?? this.visualNovel,
      platform: platform ?? this.platform,
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
