// Фабрики тестовых данных.
//
// Все параметры опциональны с разумными дефолтами. Это позволяет
// в тестах указывать только релевантные поля.

import 'dart:ui';

import 'package:xerabora/data/repositories/collection_repository.dart';
import 'package:xerabora/shared/models/canvas_connection.dart';
import 'package:xerabora/shared/models/canvas_item.dart';
import 'package:xerabora/shared/models/collection.dart';
import 'package:xerabora/shared/models/collection_item.dart';
import 'package:xerabora/shared/models/game.dart';
import 'package:xerabora/shared/models/item_status.dart';
import 'package:xerabora/shared/models/media_type.dart';
import 'package:xerabora/shared/models/movie.dart';
import 'package:xerabora/shared/models/platform.dart';
import 'package:xerabora/shared/models/tv_show.dart';
import 'package:xerabora/shared/models/manga.dart';
import 'package:xerabora/shared/models/visual_novel.dart';
import 'package:xerabora/shared/models/tier_definition.dart';
import 'package:xerabora/shared/models/tier_list.dart';
import 'package:xerabora/shared/models/tier_list_entry.dart';
import 'package:xerabora/core/api/steam_api.dart';
import 'package:xerabora/shared/models/wishlist_item.dart';

/// Стандартная тестовая дата для единообразия.
final DateTime testDate = DateTime(2024, 1, 15, 12, 0, 0);

// ---------------------------------------------------------------------------
// Collection
// ---------------------------------------------------------------------------

Collection createTestCollection({
  int id = 1,
  String name = 'Test Collection',
  String author = 'Test Author',
  CollectionType type = CollectionType.own,
  DateTime? createdAt,
  String? originalSnapshot,
  String? forkedFromAuthor,
  String? forkedFromName,
}) {
  return Collection(
    id: id,
    name: name,
    author: author,
    type: type,
    createdAt: createdAt ?? testDate,
    originalSnapshot: originalSnapshot,
    forkedFromAuthor: forkedFromAuthor,
    forkedFromName: forkedFromName,
  );
}

/// Генерирует [count] коллекций с последовательными id и именами.
List<Collection> createTestCollections({int count = 3}) {
  return List<Collection>.generate(
    count,
    (int i) => createTestCollection(id: i + 1, name: 'Collection ${i + 1}'),
  );
}

// ---------------------------------------------------------------------------
// CollectionStats
// ---------------------------------------------------------------------------

CollectionStats createTestStats({
  int total = 5,
  int completed = 2,
  int inProgress = 1,
  int notStarted = 1,
  int dropped = 0,
  int planned = 1,
  int gameCount = 0,
  int movieCount = 0,
  int tvShowCount = 0,
  int animationCount = 0,
  int visualNovelCount = 0,
  int mangaCount = 0,
}) {
  return CollectionStats(
    total: total,
    completed: completed,
    inProgress: inProgress,
    notStarted: notStarted,
    dropped: dropped,
    planned: planned,
    gameCount: gameCount,
    movieCount: movieCount,
    tvShowCount: tvShowCount,
    animationCount: animationCount,
    visualNovelCount: visualNovelCount,
    mangaCount: mangaCount,
  );
}

// ---------------------------------------------------------------------------
// CollectionItem
// ---------------------------------------------------------------------------

CollectionItem createTestCollectionItem({
  int id = 1,
  int? collectionId = 1,
  MediaType mediaType = MediaType.game,
  int externalId = 100,
  int? platformId,
  ItemStatus status = ItemStatus.notStarted,
  String? authorComment,
  String? userComment,
  int? userRating,
  int currentSeason = 0,
  int currentEpisode = 0,
  int sortOrder = 0,
  DateTime? addedAt,
  DateTime? startedAt,
  DateTime? completedAt,
  DateTime? lastActivityAt,
  Game? game,
  Movie? movie,
  TvShow? tvShow,
  VisualNovel? visualNovel,
  Manga? manga,
  Platform? platform,
}) {
  return CollectionItem(
    id: id,
    collectionId: collectionId,
    mediaType: mediaType,
    externalId: externalId,
    platformId: platformId,
    status: status,
    authorComment: authorComment,
    userComment: userComment,
    userRating: userRating,
    currentSeason: currentSeason,
    currentEpisode: currentEpisode,
    sortOrder: sortOrder,
    addedAt: addedAt ?? testDate,
    startedAt: startedAt,
    completedAt: completedAt,
    lastActivityAt: lastActivityAt,
    game: game,
    movie: movie,
    tvShow: tvShow,
    visualNovel: visualNovel,
    manga: manga,
    platform: platform,
  );
}

// ---------------------------------------------------------------------------
// Game
// ---------------------------------------------------------------------------

Game createTestGame({
  int id = 100,
  String name = 'Test Game',
  String? summary,
  String? coverUrl,
  DateTime? releaseDate,
  double? rating,
  int? ratingCount,
  List<String>? genres,
  List<int>? platformIds,
  String? externalUrl,
}) {
  return Game(
    id: id,
    name: name,
    summary: summary,
    coverUrl: coverUrl,
    releaseDate: releaseDate,
    rating: rating,
    ratingCount: ratingCount,
    genres: genres,
    platformIds: platformIds,
    externalUrl: externalUrl,
  );
}

// ---------------------------------------------------------------------------
// Movie
// ---------------------------------------------------------------------------

Movie createTestMovie({
  int tmdbId = 550,
  String title = 'Test Movie',
  String? originalTitle,
  String? posterUrl,
  String? backdropUrl,
  String? overview,
  List<String>? genres,
  int? releaseYear,
  double? rating,
  int? runtime,
  String? externalUrl,
}) {
  return Movie(
    tmdbId: tmdbId,
    title: title,
    originalTitle: originalTitle,
    posterUrl: posterUrl,
    backdropUrl: backdropUrl,
    overview: overview,
    genres: genres,
    releaseYear: releaseYear,
    rating: rating,
    runtime: runtime,
    externalUrl: externalUrl,
  );
}

// ---------------------------------------------------------------------------
// TvShow
// ---------------------------------------------------------------------------

TvShow createTestTvShow({
  int tmdbId = 200,
  String title = 'Test Show',
  String? originalTitle,
  String? posterUrl,
  String? backdropUrl,
  String? overview,
  List<String>? genres,
  int? firstAirYear,
  int? totalSeasons,
  int? totalEpisodes,
  double? rating,
  String? status,
  String? externalUrl,
}) {
  return TvShow(
    tmdbId: tmdbId,
    title: title,
    originalTitle: originalTitle,
    posterUrl: posterUrl,
    backdropUrl: backdropUrl,
    overview: overview,
    genres: genres,
    firstAirYear: firstAirYear,
    totalSeasons: totalSeasons,
    totalEpisodes: totalEpisodes,
    rating: rating,
    status: status,
    externalUrl: externalUrl,
  );
}

// ---------------------------------------------------------------------------
// VisualNovel
// ---------------------------------------------------------------------------

VisualNovel createTestVisualNovel({
  String id = 'v500',
  String title = 'Test VN',
  String? altTitle,
  String? description,
  String? imageUrl,
  double? rating,
  int? voteCount,
  String? released,
  int? lengthMinutes,
  int? length,
  List<String>? tags,
  List<String>? developers,
  List<String>? platforms,
  String? externalUrl,
}) {
  return VisualNovel(
    id: id,
    title: title,
    altTitle: altTitle,
    description: description,
    imageUrl: imageUrl,
    rating: rating,
    voteCount: voteCount,
    released: released,
    lengthMinutes: lengthMinutes,
    length: length,
    tags: tags,
    developers: developers,
    platforms: platforms,
    externalUrl: externalUrl,
  );
}

// ---------------------------------------------------------------------------
// Manga
// ---------------------------------------------------------------------------

Manga createTestManga({
  int id = 500,
  String title = 'Test Manga',
  String? description,
  String? coverUrl,
  int? averageScore,
  int? chapters,
  int? volumes,
  String? format,
  List<String>? genres,
}) {
  return Manga(
    id: id,
    title: title,
    description: description,
    coverUrl: coverUrl,
    averageScore: averageScore,
    chapters: chapters,
    volumes: volumes,
    format: format,
    genres: genres,
  );
}

// ---------------------------------------------------------------------------
// WishlistItem
// ---------------------------------------------------------------------------

WishlistItem createTestWishlistItem({
  int id = 1,
  String text = 'Chrono Trigger',
  MediaType? mediaTypeHint,
  String? note,
  bool isResolved = false,
  DateTime? createdAt,
  DateTime? resolvedAt,
}) {
  return WishlistItem(
    id: id,
    text: text,
    mediaTypeHint: mediaTypeHint,
    note: note,
    isResolved: isResolved,
    createdAt: createdAt ?? testDate,
    resolvedAt: resolvedAt,
  );
}

// ---------------------------------------------------------------------------
// CanvasItem
// ---------------------------------------------------------------------------

CanvasItem createTestCanvasItem({
  int id = 1,
  int collectionId = 1,
  CanvasItemType itemType = CanvasItemType.game,
  double x = 100.0,
  double y = 100.0,
  double? width = 160.0,
  double? height = 220.0,
  int? collectionItemId,
  int? itemRefId = 100,
  int zIndex = 0,
  Map<String, dynamic>? data,
  DateTime? createdAt,
  Game? game,
  Movie? movie,
  TvShow? tvShow,
  VisualNovel? visualNovel,
}) {
  return CanvasItem(
    id: id,
    collectionId: collectionId,
    itemType: itemType,
    x: x,
    y: y,
    width: width,
    height: height,
    collectionItemId: collectionItemId,
    itemRefId: itemRefId,
    zIndex: zIndex,
    data: data,
    createdAt: createdAt ?? testDate,
    game: game,
    movie: movie,
    tvShow: tvShow,
    visualNovel: visualNovel,
  );
}

// ---------------------------------------------------------------------------
// CanvasConnection
// ---------------------------------------------------------------------------

CanvasConnection createTestCanvasConnection({
  int id = 1,
  int collectionId = 1,
  int? collectionItemId,
  int fromItemId = 100,
  int toItemId = 200,
  String? label,
  String color = '#FF0000',
  ConnectionStyle style = ConnectionStyle.solid,
  DateTime? createdAt,
}) {
  return CanvasConnection(
    id: id,
    collectionId: collectionId,
    collectionItemId: collectionItemId,
    fromItemId: fromItemId,
    toItemId: toItemId,
    label: label,
    color: color,
    style: style,
    createdAt: createdAt ?? testDate,
  );
}

// ---------------------------------------------------------------------------
// Tier List
// ---------------------------------------------------------------------------

TierList createTestTierList({
  int id = 1,
  String name = 'Test Tier List',
  int? collectionId,
  DateTime? createdAt,
}) {
  return TierList(
    id: id,
    name: name,
    collectionId: collectionId,
    createdAt: createdAt ?? testDate,
  );
}

TierDefinition createTestTierDefinition({
  String tierKey = 'S',
  String label = 'S',
  int colorValue = 0xFFFF4444,
  int sortOrder = 0,
}) {
  return TierDefinition(
    tierKey: tierKey,
    label: label,
    color: Color(colorValue),
    sortOrder: sortOrder,
  );
}

TierListEntry createTestTierListEntry({
  int collectionItemId = 1,
  String tierKey = 'S',
  int sortOrder = 0,
}) {
  return TierListEntry(
    collectionItemId: collectionItemId,
    tierKey: tierKey,
    sortOrder: sortOrder,
  );
}

// ---------------------------------------------------------------------------
// Steam
// ---------------------------------------------------------------------------

SteamOwnedGame createTestSteamOwnedGame({
  int appId = 440,
  String name = 'Team Fortress 2',
  int playtimeMinutes = 1250,
  DateTime? lastPlayed,
}) {
  return SteamOwnedGame(
    appId: appId,
    name: name,
    playtimeMinutes: playtimeMinutes,
    lastPlayed: lastPlayed,
  );
}
