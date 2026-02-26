import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/services/image_cache_service.dart';
import 'exportable.dart';
import 'game.dart';
import 'media_type.dart';
import 'movie.dart';
import 'tv_show.dart';

/// Тип элемента на канвасе.
enum CanvasItemType {
  /// Карточка игры.
  game('game'),

  /// Карточка фильма.
  movie('movie'),

  /// Карточка сериала.
  tvShow('tv_show'),

  /// Карточка анимации.
  animation('animation'),

  /// Текстовый блок.
  text('text'),

  /// Изображение.
  image('image'),

  /// Ссылка.
  link('link');

  const CanvasItemType(this.value);

  /// Строковое значение для базы данных.
  final String value;

  /// Создаёт [CanvasItemType] из строки.
  static CanvasItemType fromString(String value) {
    return CanvasItemType.values.firstWhere(
      (CanvasItemType type) => type.value == value,
      orElse: () => CanvasItemType.game,
    );
  }

  /// Создаёт [CanvasItemType] из [MediaType].
  static CanvasItemType fromMediaType(MediaType mediaType) {
    switch (mediaType) {
      case MediaType.game:
        return CanvasItemType.game;
      case MediaType.movie:
        return CanvasItemType.movie;
      case MediaType.tvShow:
        return CanvasItemType.tvShow;
      case MediaType.animation:
        return CanvasItemType.animation;
    }
  }

  /// Является ли тип медиа-элементом (game, movie, tvShow).
  bool get isMediaItem =>
      this == game || this == movie || this == tvShow || this == animation;
}

/// Модель элемента на канвасе коллекции.
///
/// Представляет любой объект, размещённый на канвасе:
/// игровую карточку, текст, изображение или ссылку.
class CanvasItem with Exportable {
  /// Создаёт экземпляр [CanvasItem].
  const CanvasItem({
    required this.id,
    required this.collectionId,
    required this.itemType,
    required this.x,
    required this.y,
    required this.createdAt,
    this.collectionItemId,
    this.itemRefId,
    this.width,
    this.height,
    this.zIndex = 0,
    this.data,
    this.game,
    this.movie,
    this.tvShow,
  });

  /// Создаёт [CanvasItem] из записи базы данных.
  factory CanvasItem.fromDb(Map<String, dynamic> row) {
    final String? dataString = row['data'] as String?;
    Map<String, dynamic>? parsedData;
    if (dataString != null && dataString.isNotEmpty) {
      parsedData =
          json.decode(dataString) as Map<String, dynamic>;
    }

    return CanvasItem(
      id: row['id'] as int,
      collectionId: row['collection_id'] as int,
      collectionItemId: row['collection_item_id'] as int?,
      itemType: CanvasItemType.fromString(row['item_type'] as String),
      itemRefId: row['item_ref_id'] as int?,
      x: (row['x'] as num).toDouble(),
      y: (row['y'] as num).toDouble(),
      width: (row['width'] as num?)?.toDouble(),
      height: (row['height'] as num?)?.toDouble(),
      zIndex: row['z_index'] as int? ?? 0,
      data: parsedData,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (row['created_at'] as int) * 1000,
      ),
    );
  }

  /// Создаёт [CanvasItem] из экспортных данных.
  factory CanvasItem.fromExport(
    Map<String, dynamic> json, {
    int collectionId = 0,
  }) {
    return CanvasItem(
      id: json['id'] as int? ?? 0,
      collectionId: collectionId,
      collectionItemId: json['collection_item_id'] as int?,
      itemType: CanvasItemType.fromString(json['type'] as String? ?? 'game'),
      itemRefId: json['refId'] as int?,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      width: (json['width'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
      zIndex: json['z_index'] as int? ?? 0,
      data: json['data'] as Map<String, dynamic>?,
      createdAt: json['created_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (json['created_at'] as int) * 1000,
            )
          : DateTime.now(),
    );
  }

  /// Уникальный идентификатор элемента.
  final int id;

  /// ID коллекции.
  final int collectionId;

  /// ID элемента коллекции (для per-game canvas, null для коллекционного).
  final int? collectionItemId;

  /// Тип элемента.
  final CanvasItemType itemType;

  /// ID связанного объекта (igdb_id для game, tmdb_id для movie/tvShow).
  final int? itemRefId;

  /// Позиция X на канвасе.
  final double x;

  /// Позиция Y на канвасе.
  final double y;

  /// Ширина элемента.
  final double? width;

  /// Высота элемента.
  final double? height;

  /// Слой отображения (z-index).
  final int zIndex;

  /// Дополнительные данные (JSON).
  final Map<String, dynamic>? data;

  /// Дата создания.
  final DateTime createdAt;

  /// Данные игры (joined, не сохраняются в БД).
  final Game? game;

  /// Данные фильма (joined, не сохраняются в БД).
  final Movie? movie;

  /// Данные сериала (joined, не сохраняются в БД).
  final TvShow? tvShow;

  // -- Unified media accessors (для медиа-типов) --

  /// Название медиа-элемента (game/movie/tvShow).
  String? get mediaTitle {
    return switch (itemType) {
      CanvasItemType.game => game?.name,
      CanvasItemType.movie => movie?.title,
      CanvasItemType.tvShow => tvShow?.title,
      CanvasItemType.animation => movie?.title ?? tvShow?.title,
      _ => null,
    };
  }

  /// URL thumbnail-а медиа-элемента.
  String? get mediaThumbnailUrl {
    return switch (itemType) {
      CanvasItemType.game => game?.coverUrl,
      CanvasItemType.movie => movie?.posterThumbUrl,
      CanvasItemType.tvShow => tvShow?.posterThumbUrl,
      CanvasItemType.animation => tvShow != null
          ? tvShow?.posterThumbUrl
          : movie?.posterThumbUrl,
      _ => null,
    };
  }

  /// ImageType для кэширования.
  ImageType get mediaImageType {
    return switch (itemType) {
      CanvasItemType.game => ImageType.gameCover,
      CanvasItemType.movie => ImageType.moviePoster,
      CanvasItemType.tvShow => ImageType.tvShowPoster,
      CanvasItemType.animation => tvShow != null
          ? ImageType.tvShowPoster
          : ImageType.moviePoster,
      _ => ImageType.gameCover,
    };
  }

  /// ID для кэширования изображения.
  String get mediaCacheId {
    return switch (itemType) {
      CanvasItemType.game => (game?.id ?? 0).toString(),
      CanvasItemType.movie => (movie?.tmdbId ?? 0).toString(),
      CanvasItemType.tvShow => (tvShow?.tmdbId ?? 0).toString(),
      CanvasItemType.animation => tvShow != null
          ? (tvShow?.tmdbId ?? 0).toString()
          : (movie?.tmdbId ?? 0).toString(),
      _ => '0',
    };
  }

  /// Иконка-заглушка для медиа-элемента.
  IconData get mediaPlaceholderIcon {
    return switch (itemType) {
      CanvasItemType.game => Icons.videogame_asset,
      CanvasItemType.movie => Icons.movie_outlined,
      CanvasItemType.tvShow => Icons.tv_outlined,
      CanvasItemType.animation => Icons.animation,
      _ => Icons.note,
    };
  }

  /// MediaType для медиа-элемента (null для text/image/link).
  MediaType? get asMediaType {
    return switch (itemType) {
      CanvasItemType.game => MediaType.game,
      CanvasItemType.movie => MediaType.movie,
      CanvasItemType.tvShow => MediaType.tvShow,
      CanvasItemType.animation => MediaType.animation,
      _ => null,
    };
  }

  // -- Exportable контракт --

  @override
  Set<String> get internalDbFields => const <String>{'collection_id'};

  @override
  Map<String, String> get dbToExportKeyMapping =>
      const <String, String>{'item_type': 'type', 'item_ref_id': 'refId'};

  /// Преобразует в Map для сохранения в базу данных.
  @override
  Map<String, dynamic> toDb() {
    return <String, dynamic>{
      if (id != 0) 'id': id,
      'collection_id': collectionId,
      'collection_item_id': collectionItemId,
      'item_type': itemType.value,
      'item_ref_id': itemRefId,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'z_index': zIndex,
      'data': data != null ? json.encode(data) : null,
      'created_at': createdAt.millisecondsSinceEpoch ~/ 1000,
    };
  }

  /// Преобразует в Map для экспорта.
  @override
  Map<String, dynamic> toExport() {
    return <String, dynamic>{
      'id': id,
      'collection_item_id': collectionItemId,
      'type': itemType.value,
      'refId': itemRefId,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'z_index': zIndex,
      'data': data,
      'created_at': createdAt.millisecondsSinceEpoch ~/ 1000,
    };
  }

  /// Создаёт копию с изменёнными полями.
  CanvasItem copyWith({
    int? id,
    int? collectionId,
    int? collectionItemId,
    CanvasItemType? itemType,
    int? itemRefId,
    double? x,
    double? y,
    double? width,
    double? height,
    int? zIndex,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    Game? game,
    Movie? movie,
    TvShow? tvShow,
  }) {
    return CanvasItem(
      id: id ?? this.id,
      collectionId: collectionId ?? this.collectionId,
      collectionItemId: collectionItemId ?? this.collectionItemId,
      itemType: itemType ?? this.itemType,
      itemRefId: itemRefId ?? this.itemRefId,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      zIndex: zIndex ?? this.zIndex,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      game: game ?? this.game,
      movie: movie ?? this.movie,
      tvShow: tvShow ?? this.tvShow,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CanvasItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'CanvasItem(id: $id, type: ${itemType.value}, x: $x, y: $y)';
}
