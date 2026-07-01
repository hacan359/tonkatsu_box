import 'dart:ui';

import 'package:tonkatsu_box/data/repositories/collection_repository.dart';
import 'package:tonkatsu_box/shared/models/book.dart';
import 'package:tonkatsu_box/shared/models/canvas_connection.dart';
import 'package:tonkatsu_box/shared/models/canvas_item.dart';
import 'package:tonkatsu_box/shared/models/data_source.dart';
import 'package:tonkatsu_box/shared/models/collection.dart';
import 'package:tonkatsu_box/shared/models/collection_item.dart';
import 'package:tonkatsu_box/shared/models/collection_tag.dart';
import 'package:tonkatsu_box/shared/models/custom_media.dart';
import 'package:tonkatsu_box/shared/models/anime.dart';
import 'package:tonkatsu_box/shared/models/game.dart';
import 'package:tonkatsu_box/shared/models/item_status.dart';
import 'package:tonkatsu_box/shared/models/media_type.dart';
import 'package:tonkatsu_box/shared/models/movie.dart';
import 'package:tonkatsu_box/shared/models/platform.dart';
import 'package:tonkatsu_box/shared/models/tv_show.dart';
import 'package:tonkatsu_box/shared/models/manga.dart';
import 'package:tonkatsu_box/shared/models/visual_novel.dart';
import 'package:tonkatsu_box/shared/models/tier_definition.dart';
import 'package:tonkatsu_box/shared/models/tier_list.dart';
import 'package:tonkatsu_box/shared/models/tier_list_entry.dart';
import 'package:tonkatsu_box/core/api/steam_api.dart';
import 'package:tonkatsu_box/shared/models/profile.dart';
import 'package:tonkatsu_box/shared/models/ra_game_progress.dart';
import 'package:tonkatsu_box/shared/models/ra_user_profile.dart';
import 'package:tonkatsu_box/shared/models/wishlist_item.dart';

final DateTime testDate = DateTime(2024, 1, 15, 12, 0, 0);

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

List<Collection> createTestCollections({int count = 3}) {
  return List<Collection>.generate(
    count,
    (int i) => createTestCollection(id: i + 1, name: 'Collection ${i + 1}'),
  );
}

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

CollectionItem createTestCollectionItem({
  int id = 1,
  int? collectionId = 1,
  MediaType mediaType = MediaType.game,
  int externalId = 100,
  int? platformId,
  int? tagId,
  ItemStatus status = ItemStatus.notStarted,
  String? authorComment,
  String? userComment,
  double? userRating,
  bool isFavorite = false,
  String? overrideName,
  int currentSeason = 0,
  int currentEpisode = 0,
  int sortOrder = 0,
  int timeSpentMinutes = 0,
  DateTime? addedAt,
  DateTime? startedAt,
  DateTime? completedAt,
  DateTime? lastActivityAt,
  Game? game,
  Movie? movie,
  TvShow? tvShow,
  VisualNovel? visualNovel,
  Manga? manga,
  Anime? anime,
  Book? book,
  Platform? platform,
  CustomMedia? customMedia,
}) {
  return CollectionItem(
    id: id,
    collectionId: collectionId,
    mediaType: mediaType,
    externalId: externalId,
    platformId: platformId,
    tagId: tagId,
    status: status,
    authorComment: authorComment,
    userComment: userComment,
    userRating: userRating,
    isFavorite: isFavorite,
    overrideName: overrideName,
    currentSeason: currentSeason,
    currentEpisode: currentEpisode,
    sortOrder: sortOrder,
    timeSpentMinutes: timeSpentMinutes,
    addedAt: addedAt ?? testDate,
    startedAt: startedAt,
    completedAt: completedAt,
    lastActivityAt: lastActivityAt,
    game: game,
    movie: movie,
    tvShow: tvShow,
    visualNovel: visualNovel,
    manga: manga,
    anime: anime,
    book: book,
    platform: platform,
    customMedia: customMedia,
  );
}

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

Anime createTestAnime({
  int id = 600,
  String title = 'Test Anime',
  String? description,
  String? coverUrl,
  int? averageScore,
  int? episodes,
  String? format,
  List<String>? genres,
  List<String>? tags,
  String? status,
  int? startYear,
}) {
  return Anime(
    id: id,
    title: title,
    description: description,
    coverUrl: coverUrl,
    averageScore: averageScore,
    episodes: episodes,
    format: format,
    genres: genres,
    tags: tags,
    status: status,
    startYear: startYear,
  );
}

Book createTestBook({
  String id = '27448',
  DataSource source = DataSource.openLibrary,
  String? nativeId,
  String title = 'Test Book',
  String? originalTitle,
  List<String> authors = const <String>['Test Author'],
  String? description,
  String? coverUrl,
  int? pageCount,
  int? publishYear = 2000,
  List<String> subjects = const <String>[],
  double? rating,
  int? ratingCount,
  String? externalUrl,
  int? cachedAt,
}) {
  return Book(
    id: id,
    source: source,
    nativeId: nativeId ?? 'OL${id}W',
    title: title,
    originalTitle: originalTitle,
    authors: authors,
    description: description,
    coverUrl: coverUrl,
    pageCount: pageCount,
    publishYear: publishYear,
    subjects: subjects,
    rating: rating,
    ratingCount: ratingCount,
    externalUrl: externalUrl,
    cachedAt: cachedAt,
  );
}

WishlistItem createTestWishlistItem({
  int id = 1,
  String text = 'Chrono Trigger',
  MediaType? mediaTypeHint,
  String? note,
  bool isResolved = false,
  DateTime? createdAt,
  DateTime? resolvedAt,
  String? tag,
}) {
  return WishlistItem(
    id: id,
    text: text,
    mediaTypeHint: mediaTypeHint,
    note: note,
    isResolved: isResolved,
    createdAt: createdAt ?? testDate,
    resolvedAt: resolvedAt,
    tag: tag,
  );
}

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

RaGameProgress createTestRaGameProgress({
  int gameId = 1234,
  String title = 'Super Mario World',
  String consoleName = 'SNES',
  int consoleId = 3,
  int numAwarded = 50,
  int numAwardedHardcore = 50,
  int maxPossible = 96,
  bool hardcoreMode = true,
  String? highestAwardKind,
  DateTime? highestAwardDate,
  DateTime? lastPlayedAt,
}) {
  return RaGameProgress(
    gameId: gameId,
    title: title,
    consoleName: consoleName,
    consoleId: consoleId,
    numAwarded: numAwarded,
    numAwardedHardcore: numAwardedHardcore,
    maxPossible: maxPossible,
    hardcoreMode: hardcoreMode,
    highestAwardKind: highestAwardKind,
    highestAwardDate: highestAwardDate,
    lastPlayedAt: lastPlayedAt,
  );
}

RaUserProfile createTestRaUserProfile({
  String user = 'TestUser',
  int totalPoints = 5000,
  String memberSince = '2024-03-15 11:27:24',
  String? userPic,
  String? richPresenceMsg,
  int totalTruePoints = 8000,
}) {
  return RaUserProfile(
    user: user,
    totalPoints: totalPoints,
    memberSince: memberSince,
    userPic: userPic,
    richPresenceMsg: richPresenceMsg,
    totalTruePoints: totalTruePoints,
  );
}

Profile createTestProfile({
  String id = 'test-profile',
  String name = 'Test Player',
  String color = '#EF7B44',
  DateTime? createdAt,
}) {
  return Profile(
    id: id,
    name: name,
    color: color,
    createdAt: createdAt ?? testDate,
  );
}

ProfilesData createTestProfilesData({
  int version = 1,
  String currentProfileId = 'test-profile',
  List<Profile>? profiles,
}) {
  return ProfilesData(
    version: version,
    currentProfileId: currentProfileId,
    profiles: profiles ??
        <Profile>[
          createTestProfile(),
        ],
  );
}

ProfileStats createTestProfileStats({
  int collectionsCount = 3,
  int itemsCount = 15,
}) {
  return ProfileStats(
    collectionsCount: collectionsCount,
    itemsCount: itemsCount,
  );
}

CollectionTag createTestCollectionTag({
  int id = 1,
  int collectionId = 1,
  String name = 'RPG',
  int? color,
  int sortOrder = 0,
  int createdAt = 1700000000,
}) {
  return CollectionTag(
    id: id,
    collectionId: collectionId,
    name: name,
    color: color,
    sortOrder: sortOrder,
    createdAt: createdAt,
  );
}
