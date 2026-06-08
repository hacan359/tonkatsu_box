import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/services/image_cache_service.dart';
import 'anime.dart';
import 'book.dart';
import 'custom_media.dart';
import 'exportable.dart';
import 'game.dart';
import '../utils/cover_image_id.dart' as cover_id;
import 'manga.dart';
import 'media_type.dart';
import 'movie.dart';
import 'tv_show.dart';
import 'visual_novel.dart';

enum CanvasItemType {
  game('game'),

  movie('movie'),

  tvShow('tv_show'),

  animation('animation'),

  visualNovel('visual_novel'),

  manga('manga'),

  anime('anime'),

  book('book'),

  custom('custom'),

  text('text'),

  image('image'),

  link('link');

  const CanvasItemType(this.value);

  final String value;

  static CanvasItemType fromString(String value) {
    return CanvasItemType.values.firstWhere(
      (CanvasItemType type) => type.value == value,
      orElse: () => CanvasItemType.game,
    );
  }

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
      case MediaType.visualNovel:
        return CanvasItemType.visualNovel;
      case MediaType.manga:
        return CanvasItemType.manga;
      case MediaType.anime:
        return CanvasItemType.anime;
      case MediaType.book:
        return CanvasItemType.book;
      case MediaType.custom:
        return CanvasItemType.custom;
    }
  }

  bool get isMediaItem =>
      this == game ||
      this == movie ||
      this == tvShow ||
      this == animation ||
      this == visualNovel ||
      this == manga ||
      this == anime ||
      this == book ||
      this == custom;
}

class CanvasItem with Exportable {
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
    this.visualNovel,
    this.anime,
    this.manga,
    this.book,
    this.customMedia,
    this.overrideName,
  });

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
      overrideName: row['override_name'] as String?,
    );
  }

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

  final int id;

  final int collectionId;

  /// Set on per-item (game) canvas rows; null for collection-canvas rows.
  final int? collectionItemId;

  final CanvasItemType itemType;

  /// External media id (igdb_id for game, tmdb_id for movie / tvShow, …).
  final int? itemRefId;

  final double x;

  final double y;

  final double? width;

  final double? height;

  final int zIndex;

  final Map<String, dynamic>? data;

  final DateTime createdAt;

  /// Joined, not persisted in `canvas_items`.
  final Game? game;

  /// Joined, not persisted in `canvas_items`.
  final Movie? movie;

  /// Joined, not persisted in `canvas_items`.
  final TvShow? tvShow;

  /// Joined, not persisted in `canvas_items`.
  final VisualNovel? visualNovel;

  /// Joined, not persisted in `canvas_items`.
  final Anime? anime;

  /// Joined, not persisted in `canvas_items`.
  final Manga? manga;

  /// Joined, not persisted in `canvas_items`.
  final Book? book;

  /// Joined, not persisted in `canvas_items`.
  final CustomMedia? customMedia;

  /// Joined `collection_items.override_name` for the matching media entry in
  /// the same collection — transient, never written back to `canvas_items`.
  final String? overrideName;

  String? get mediaTitle {
    if (overrideName != null) return overrideName;
    return switch (itemType) {
      CanvasItemType.game => game?.name,
      CanvasItemType.movie => movie?.title,
      CanvasItemType.tvShow => tvShow?.title,
      CanvasItemType.animation => movie?.title ?? tvShow?.title,
      CanvasItemType.visualNovel => visualNovel?.title,
      CanvasItemType.manga => manga?.title,
      CanvasItemType.anime => anime?.title,
      CanvasItemType.book => book?.title,
      CanvasItemType.custom => customMedia?.title,
      _ => null,
    };
  }

  String? get mediaThumbnailUrl {
    return switch (itemType) {
      CanvasItemType.game => game?.coverUrl,
      CanvasItemType.movie => movie?.posterThumbUrl,
      CanvasItemType.tvShow => tvShow?.posterThumbUrl,
      CanvasItemType.animation => tvShow != null
          ? tvShow?.posterThumbUrl
          : movie?.posterThumbUrl,
      CanvasItemType.visualNovel => visualNovel?.imageUrl,
      CanvasItemType.manga => manga?.coverUrl,
      CanvasItemType.anime => anime?.coverUrl,
      CanvasItemType.book => book?.coverUrl,
      CanvasItemType.custom => customMedia?.coverUrl,
      _ => null,
    };
  }

  ImageType get mediaImageType {
    return switch (itemType) {
      CanvasItemType.game => ImageType.gameCover,
      CanvasItemType.movie => ImageType.moviePoster,
      CanvasItemType.tvShow => ImageType.tvShowPoster,
      CanvasItemType.animation => tvShow != null
          ? ImageType.tvShowPoster
          : ImageType.moviePoster,
      CanvasItemType.visualNovel => ImageType.vnCover,
      CanvasItemType.manga => ImageType.mangaCover,
      CanvasItemType.anime => ImageType.animeCover,
      CanvasItemType.book => ImageType.bookCover,
      CanvasItemType.custom => ImageType.customCover,
      _ => ImageType.gameCover,
    };
  }

  String get mediaCacheId {
    return switch (itemType) {
      CanvasItemType.game => (game?.id ?? 0).toString(),
      CanvasItemType.movie => (movie?.tmdbId ?? 0).toString(),
      CanvasItemType.tvShow => (tvShow?.tmdbId ?? 0).toString(),
      CanvasItemType.animation => tvShow != null
          ? (tvShow?.tmdbId ?? 0).toString()
          : (movie?.tmdbId ?? 0).toString(),
      CanvasItemType.visualNovel =>
        (itemRefId ?? 0).toString(),
      CanvasItemType.manga => cover_id.coverImageId(
          mediaType: MediaType.manga,
          externalId: manga?.id ?? 0,
          source: manga?.source,
        ),
      CanvasItemType.anime => (anime?.id ?? 0).toString(),
      CanvasItemType.book => cover_id.coverImageId(
          mediaType: MediaType.book,
          externalId: book?.externalIdInt ?? 0,
          source: book?.source,
        ),
      CanvasItemType.custom => (customMedia?.id ?? 0).toString(),
      _ => '0',
    };
  }

  IconData get mediaPlaceholderIcon {
    return switch (itemType) {
      CanvasItemType.game => Icons.videogame_asset,
      CanvasItemType.movie => Icons.movie_outlined,
      CanvasItemType.tvShow => Icons.tv_outlined,
      CanvasItemType.animation => Icons.animation,
      CanvasItemType.visualNovel => Icons.menu_book,
      CanvasItemType.manga => Icons.auto_stories,
      CanvasItemType.anime => Icons.play_circle_outline,
      CanvasItemType.book => Icons.menu_book,
      CanvasItemType.custom => switch (customMedia?.displayType) {
        MediaType.game => Icons.videogame_asset,
        MediaType.movie => Icons.movie_outlined,
        MediaType.tvShow => Icons.tv_outlined,
        MediaType.animation => Icons.animation,
        MediaType.visualNovel => Icons.menu_book,
        MediaType.manga => Icons.auto_stories,
        MediaType.anime => Icons.play_circle_outline,
        MediaType.book => Icons.menu_book,
        _ => Icons.dashboard_customize,
      },
      _ => Icons.note,
    };
  }

  /// Null for non-media item types (text / image / link).
  MediaType? get asMediaType {
    return switch (itemType) {
      CanvasItemType.game => MediaType.game,
      CanvasItemType.movie => MediaType.movie,
      CanvasItemType.tvShow => MediaType.tvShow,
      CanvasItemType.animation => MediaType.animation,
      CanvasItemType.visualNovel => MediaType.visualNovel,
      CanvasItemType.manga => MediaType.manga,
      CanvasItemType.anime => MediaType.anime,
      CanvasItemType.book => MediaType.book,
      CanvasItemType.custom => customMedia?.displayType ?? MediaType.custom,
      _ => null,
    };
  }

  @override
  Set<String> get internalDbFields => const <String>{'collection_id'};

  @override
  Map<String, String> get dbToExportKeyMapping =>
      const <String, String>{'item_type': 'type', 'item_ref_id': 'refId'};

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
    VisualNovel? visualNovel,
    Anime? anime,
    Manga? manga,
    Book? book,
    CustomMedia? customMedia,
    String? overrideName,
    bool clearOverrideName = false,
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
      visualNovel: visualNovel ?? this.visualNovel,
      anime: anime ?? this.anime,
      manga: manga ?? this.manga,
      book: book ?? this.book,
      customMedia: customMedia ?? this.customMedia,
      overrideName:
          clearOverrideName ? null : (overrideName ?? this.overrideName),
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
