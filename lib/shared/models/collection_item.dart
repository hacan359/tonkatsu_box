// Универсальный элемент коллекции (игра, фильм или сериал).

import 'exportable.dart';
import 'game.dart';
import 'item_status.dart';
import 'media_type.dart';
import 'movie.dart';
import 'platform.dart';
import 'tv_show.dart';

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
    this.game,
    this.movie,
    this.tvShow,
    this.platform,
  });

  /// Создаёт [CollectionItem] из записи базы данных.
  factory CollectionItem.fromDb(Map<String, dynamic> row) {
    return CollectionItem(
      id: row['id'] as int,
      collectionId: row['collection_id'] as int,
      mediaType: MediaType.fromString(row['media_type'] as String),
      externalId: row['external_id'] as int,
      platformId: row['platform_id'] as int?,
      currentSeason: (row['current_season'] as int?) ?? 0,
      currentEpisode: (row['current_episode'] as int?) ?? 0,
      sortOrder: (row['sort_order'] as int?) ?? 0,
      status: ItemStatus.fromString(row['status'] as String),
      authorComment: row['author_comment'] as String?,
      userComment: row['user_comment'] as String?,
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
    );
  }

  /// Создаёт [CollectionItem] из записи БД с join-данными.
  factory CollectionItem.fromDbWithJoins(
    Map<String, dynamic> row, {
    Game? game,
    Movie? movie,
    TvShow? tvShow,
    Platform? platform,
  }) {
    return CollectionItem(
      id: row['id'] as int,
      collectionId: row['collection_id'] as int,
      mediaType: MediaType.fromString(row['media_type'] as String),
      externalId: row['external_id'] as int,
      platformId: row['platform_id'] as int?,
      currentSeason: (row['current_season'] as int?) ?? 0,
      currentEpisode: (row['current_episode'] as int?) ?? 0,
      sortOrder: (row['sort_order'] as int?) ?? 0,
      status: ItemStatus.fromString(row['status'] as String),
      authorComment: row['author_comment'] as String?,
      userComment: row['user_comment'] as String?,
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
      platform: platform,
    );
  }

  /// Создаёт [CollectionItem] из экспортных данных.
  factory CollectionItem.fromExport(
    Map<String, dynamic> json, {
    int id = 0,
    int collectionId = 0,
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
      status: ItemStatus.fromString(json['status'] as String),
      authorComment: json['comment'] as String?,
      addedAt: addedAt ?? DateTime.now(),
    );
  }

  /// Уникальный идентификатор записи.
  final int id;

  /// ID коллекции.
  final int collectionId;

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

  /// Данные платформы (joined).
  final Platform? platform;

  // -- Геттеры совместимости --

  /// ID в IGDB (для игр). Алиас для [externalId].
  int get igdbId => externalId;

  /// Название элемента (игра, фильм, сериал или анимация).
  String get itemName {
    switch (mediaType) {
      case MediaType.game:
        return game?.name ?? 'Unknown Game';
      case MediaType.movie:
        return movie?.title ?? 'Unknown Movie';
      case MediaType.tvShow:
        return tvShow?.title ?? 'Unknown TV Show';
      case MediaType.animation:
        if (platformId == AnimationSource.tvShow) {
          return tvShow?.title ?? 'Unknown Animation';
        }
        return movie?.title ?? 'Unknown Animation';
    }
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
  String? get coverUrl {
    switch (mediaType) {
      case MediaType.game:
        return game?.coverUrl;
      case MediaType.movie:
        return movie?.posterUrl;
      case MediaType.tvShow:
        return tvShow?.posterUrl;
      case MediaType.animation:
        if (platformId == AnimationSource.tvShow) {
          return tvShow?.posterUrl;
        }
        return movie?.posterUrl;
    }
  }

  /// URL маленького постера/обложки для thumbnail-ов.
  String? get thumbnailUrl {
    switch (mediaType) {
      case MediaType.game:
        return game?.coverUrl;
      case MediaType.movie:
        return movie?.posterThumbUrl;
      case MediaType.tvShow:
        return tvShow?.posterThumbUrl;
      case MediaType.animation:
        if (platformId == AnimationSource.tvShow) {
          return tvShow?.posterThumbUrl;
        }
        return movie?.posterThumbUrl;
    }
  }

  // -- Exportable контракт --

  @override
  Set<String> get internalDbFields =>
      const <String>{
        'id', 'collection_id', 'user_comment', 'added_at', 'sort_order',
        'started_at', 'completed_at', 'last_activity_at',
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
      'current_season': currentSeason,
      'current_episode': currentEpisode,
      'status': status.value,
      'comment': authorComment,
    };
  }

  /// Создаёт копию с изменёнными полями.
  CollectionItem copyWith({
    int? id,
    int? collectionId,
    MediaType? mediaType,
    int? externalId,
    int? platformId,
    int? currentSeason,
    int? currentEpisode,
    int? sortOrder,
    ItemStatus? status,
    String? authorComment,
    String? userComment,
    DateTime? addedAt,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? lastActivityAt,
    Game? game,
    Movie? movie,
    TvShow? tvShow,
    Platform? platform,
  }) {
    return CollectionItem(
      id: id ?? this.id,
      collectionId: collectionId ?? this.collectionId,
      mediaType: mediaType ?? this.mediaType,
      externalId: externalId ?? this.externalId,
      platformId: platformId ?? this.platformId,
      currentSeason: currentSeason ?? this.currentSeason,
      currentEpisode: currentEpisode ?? this.currentEpisode,
      sortOrder: sortOrder ?? this.sortOrder,
      status: status ?? this.status,
      authorComment: authorComment ?? this.authorComment,
      userComment: userComment ?? this.userComment,
      addedAt: addedAt ?? this.addedAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      game: game ?? this.game,
      movie: movie ?? this.movie,
      tvShow: tvShow ?? this.tvShow,
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
