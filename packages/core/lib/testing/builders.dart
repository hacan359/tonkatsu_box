import 'package:core/models/album.dart';
import 'package:core/models/album_track.dart';
import 'package:core/models/anime.dart';
import 'package:core/models/book.dart';
import 'package:core/models/canvas_connection.dart';
import 'package:core/models/canvas_item.dart';
import 'package:core/models/collection.dart';
import 'package:core/models/collection_item.dart';
import 'package:core/models/custom_media.dart';
import 'package:core/models/data_source.dart';
import 'package:core/models/game.dart';
import 'package:core/models/item_status.dart';
import 'package:core/models/manga.dart';
import 'package:core/models/media_type.dart';
import 'package:core/models/movie.dart';
import 'package:core/models/platform.dart';
import 'package:core/models/profile.dart';
import 'package:core/models/ra_game_progress.dart';
import 'package:core/models/ra_user_profile.dart';
import 'package:core/models/tag.dart';
import 'package:core/models/tier_definition.dart';
import 'package:core/models/tier_list.dart';
import 'package:core/models/tier_list_entry.dart';
import 'package:core/models/tv_show.dart';
import 'package:core/models/visual_novel.dart';
import 'package:core/models/wishlist_item.dart';

// Shared with the app's own test/helpers/builders.dart, which re-exports this
// file — the app cannot import packages/core/test/, only its lib/.
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
  bool isHidden = false,
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
    isHidden: isHidden,
  );
}

List<Collection> createTestCollections({int count = 3}) {
  return List<Collection>.generate(
    count,
    (int i) => createTestCollection(id: i + 1, name: 'Collection ${i + 1}'),
  );
}

CollectionItem createTestCollectionItem({
  int id = 1,
  int? collectionId = 1,
  MediaType mediaType = MediaType.game,
  int externalId = 100,
  int? platformId,
  DataSource? source,
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
  int? rewatchCount,
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
  Album? album,
  Platform? platform,
  CustomMedia? customMedia,
}) {
  return CollectionItem(
    id: id,
    collectionId: collectionId,
    mediaType: mediaType,
    externalId: externalId,
    platformId: platformId,
    source: source,
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
    rewatchCount: rewatchCount,
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
    album: album,
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
  DataSource source = DataSource.anilist,
  String title = 'Test Manga',
  String? description,
  String? coverUrl,
  int? averageScore,
  int? chapters,
  int? volumes,
  String? format,
  List<String>? genres,
  String? externalUrl,
}) {
  return Manga(
    id: id,
    source: source,
    title: title,
    description: description,
    coverUrl: coverUrl,
    averageScore: averageScore,
    chapters: chapters,
    volumes: volumes,
    format: format,
    genres: genres,
    externalUrl: externalUrl,
  );
}

Anime createTestAnime({
  int id = 600,
  DataSource source = DataSource.anilist,
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
    source: source,
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

Album createTestAlbum({
  int id = 12345,
  DataSource source = DataSource.musicBrainz,
  String mbid = 'f5093c06-23e3-404f-aeaa-40f72885ee3a',
  String title = 'Test Album',
  List<String> artists = const <String>['Test Artist'],
  List<String> artistMbids = const <String>[],
  String? primaryType = 'Album',
  List<String> secondaryTypes = const <String>[],
  int? releaseYear = 1973,
  String? firstReleaseDate,
  List<String> genres = const <String>[],
  List<String> tags = const <String>[],
  double? rating,
  int? ratingCount,
  int? listenCount,
  String? releaseMbid,
  int? trackCount,
  int? discCount,
  String? coverUrl,
  String? externalUrl,
  int? cachedAt,
}) {
  return Album(
    id: id,
    source: source,
    mbid: mbid,
    title: title,
    artists: artists,
    artistMbids: artistMbids,
    primaryType: primaryType,
    secondaryTypes: secondaryTypes,
    releaseYear: releaseYear,
    firstReleaseDate: firstReleaseDate,
    genres: genres,
    tags: tags,
    rating: rating,
    ratingCount: ratingCount,
    listenCount: listenCount,
    releaseMbid: releaseMbid,
    trackCount: trackCount,
    discCount: discCount,
    coverUrl: coverUrl,
    externalUrl: externalUrl,
    cachedAt: cachedAt,
  );
}

AlbumTrack createTestAlbumTrack({
  int albumId = 12345,
  int discNumber = 1,
  int position = 1,
  String title = 'Test Track',
  String? recordingMbid,
  int? lengthMs,
  List<String> artists = const <String>[],
  DataSource source = DataSource.musicBrainz,
}) {
  return AlbumTrack(
    albumId: albumId,
    discNumber: discNumber,
    position: position,
    title: title,
    recordingMbid: recordingMbid,
    lengthMs: lengthMs,
    artists: artists,
    source: source,
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
    colorValue: colorValue,
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

Tag createTestTag({
  int id = 1,
  String name = 'RPG',
  int? color,
  int? textColor,
  int sortOrder = 0,
  int createdAt = 1700000000,
}) {
  return Tag(
    id: id,
    name: name,
    color: color,
    textColor: textColor,
    sortOrder: sortOrder,
    createdAt: createdAt,
  );
}
