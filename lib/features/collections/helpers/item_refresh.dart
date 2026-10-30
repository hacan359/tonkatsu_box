import 'package:core/models/anime.dart';
import 'package:core/models/audio_item.dart';
import 'package:core/models/book.dart';
import 'package:core/models/collection_item.dart';
import 'package:core/models/data_source.dart';
import 'package:core/models/game.dart';
import 'package:core/models/manga.dart';
import 'package:core/models/media_type.dart';
import 'package:core/models/movie.dart';
import 'package:core/models/tv_show.dart';
import 'package:core/models/visual_novel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/anilist_api.dart';
import '../../../core/api/comicvine_api.dart';
import '../../../core/api/episode_source/tv_episode_source.dart';
import '../../../core/api/fantlab_api.dart';
import '../../../core/api/google_books_api.dart';
import '../../../core/api/hardcover_api.dart';
import '../../../core/api/igdb_api.dart';
import '../../../core/api/kitsu_api.dart';
import '../../../core/api/mangabaka_api.dart';
import '../../../core/api/mangadex_api.dart';
import '../../../core/api/musicbrainz_api.dart';
import '../../../core/api/openlibrary_api.dart';
import '../../../core/api/podcast_index_api.dart';
import '../../../core/api/tmdb_api.dart';
import '../../../core/api/tvdb_api.dart';
import '../../../core/api/vndb_api.dart';
import '../../../core/database/database_service.dart';
import '../../../core/services/image_cache_service.dart';
import '../widgets/fantlab_edition_picker.dart';
import '../widgets/hardcover_edition_picker.dart';

enum RefreshOutcomeKind { success, notFound, unsupported, failed }

class RefreshOutcome {
  const RefreshOutcome._(this.kind, [this.error]);

  factory RefreshOutcome.failed(String error) =>
      RefreshOutcome._(RefreshOutcomeKind.failed, error);

  static const RefreshOutcome success =
      RefreshOutcome._(RefreshOutcomeKind.success);
  static const RefreshOutcome notFound =
      RefreshOutcome._(RefreshOutcomeKind.notFound);
  static const RefreshOutcome unsupported =
      RefreshOutcome._(RefreshOutcomeKind.unsupported);

  final RefreshOutcomeKind kind;
  final String? error;

  bool get isSuccess => kind == RefreshOutcomeKind.success;
}

const Set<DataSource> _bookSourcesWithRefresh = <DataSource>{
  DataSource.openLibrary,
  DataSource.fantlab,
  DataSource.comicVine,
  DataSource.googleBooks,
  DataSource.hardcover,
};

/// Books whose cover is keyed by a picked edition: a refresh that keeps the
/// edition has no reason to drop the file.
bool _keepsCoverOnBulkRefresh(CollectionItem item) =>
    item.mediaType == MediaType.book &&
    (item.source == DataSource.fantlab || item.source == DataSource.hardcover);

/// Whether [refreshItemFromSource] can run for [item] with no user input;
/// the bulk action hides itself when no selected item qualifies.
bool canRefreshFromSource(CollectionItem item) => switch (item.mediaType) {
      MediaType.custom => false,
      MediaType.audio => item.audioItem != null,
      MediaType.book => item.book != null &&
          _bookSourcesWithRefresh.contains(item.source),
      _ => true,
    };

/// Refetches [item] from its source and upserts the cache row. Context-free
/// so both the card button and the bulk run share one per-source path.
Future<RefreshOutcome> refreshItemFromSource(
  WidgetRef ref,
  CollectionItem item, {
  FantlabEdition? pickedFantlabEdition,
  HardcoverEdition? pickedHardcoverEdition,
  bool bulk = false,
}) async {
  // Never throws: a bulk run counts this item as failed and moves on.
  try {
    final DatabaseService db = ref.read(databaseServiceProvider);
    final ImageCacheService cache = ref.read(imageCacheServiceProvider);
    final RefreshOutcome outcome = await _refetch(
      ref,
      db,
      item,
      pickedFantlabEdition: pickedFantlabEdition,
      pickedHardcoverEdition: pickedHardcoverEdition,
    );
    if (!outcome.isSuccess) return outcome;

    // Only after the source answered, or a failed request costs a re-download.
    // The cached getters bypass a user's override file, which must survive.
    if (!(bulk && _keepsCoverOnBulkRefresh(item))) {
      await cache.deleteImage(item.cachedImageType, item.cachedCoverImageId);
      // The refetched cover lands on the same path, which also keys Flutter's
      // decoded-image cache — without this the old art renders until restart.
      await cache.evictDecodedImage(
          item.cachedImageType, item.cachedCoverImageId);
    }
    return outcome;
  } catch (e) {
    return RefreshOutcome.failed(e.toString());
  }
}

Future<RefreshOutcome> _refetch(
  WidgetRef ref,
  DatabaseService db,
  CollectionItem item, {
  required FantlabEdition? pickedFantlabEdition,
  required HardcoverEdition? pickedHardcoverEdition,
}) async {
  switch (item.mediaType) {
    case MediaType.game:
      final Game? game =
          await ref.read(igdbApiProvider).getGameById(item.externalId);
      if (game == null) return RefreshOutcome.notFound;
      await db.gameDao.upsertGame(game);
    case MediaType.movie:
      final Movie? movie = item.source == DataSource.tvdb
          ? await ref.read(tvdbApiProvider).getMovie(item.externalId)
          : await ref.read(tmdbApiProvider).getMovie(item.externalId);
      if (movie == null) return RefreshOutcome.notFound;
      await db.movieDao.upsertMovie(movie);
    case MediaType.tvShow:
    case MediaType.animation:
      final TvEpisodeSource api = ref.read(tvEpisodeSourceResolverProvider)(
        item.source ?? item.mediaType.defaultSource,
      );
      final TvShow? show = await api.getShow(item.externalId);
      if (show == null) return RefreshOutcome.notFound;
      await db.tvShowDao.upsertTvShow(show);
    case MediaType.anime:
      final Anime? anime = switch (item.source) {
        DataSource.kitsu =>
          await ref.read(kitsuApiProvider).getAnimeById(item.externalId),
        _ => await ref.read(aniListApiProvider).getAnimeById(item.externalId),
      };
      if (anime == null) return RefreshOutcome.notFound;
      await db.animeDao.upsertAnime(anime);
    case MediaType.manga:
      final Manga? manga;
      switch (item.source) {
        case DataSource.mangabaka:
          manga = await ref.read(mangaBakaApiProvider).getById(item.externalId);
        case DataSource.kitsu:
          manga = await ref.read(kitsuApiProvider).getMangaById(item.externalId);
        case DataSource.mangadex:
          final String? uuid = item.manga?.mangaDexUuid;
          manga = uuid != null
              ? await ref.read(mangaDexApiProvider).getByUuid(uuid)
              : null;
        default:
          manga = await ref.read(aniListApiProvider).getMangaById(item.externalId);
      }
      if (manga == null) return RefreshOutcome.notFound;
      await db.mangaDao.upsertManga(manga);
    case MediaType.visualNovel:
      final VisualNovel? vn =
          await ref.read(vndbApiProvider).getVnById(item.externalId.toString());
      if (vn == null) return RefreshOutcome.notFound;
      await db.visualNovelDao.upsertVisualNovel(vn);
    case MediaType.audio:
      final AudioItem? cached = item.audioItem;
      if (cached == null) return RefreshOutcome.unsupported;
      final AudioItem? full = cached.isPodcast
          ? await ref.read(podcastIndexApiProvider).getPodcast(cached.id)
          : await ref.read(musicBrainzApiProvider).getReleaseGroup(cached.nativeId);
      if (full == null) return RefreshOutcome.notFound;
      // Overlay so the picked release (label, format, track list totals)
      // survives; the DAO's preserving upsert backs this up.
      await db.audioDao.upsertAudioItem(cached.withLookupDetails(full));
    case MediaType.book:
      return _refetchBook(
        ref,
        db,
        item,
        pickedFantlabEdition: pickedFantlabEdition,
        pickedHardcoverEdition: pickedHardcoverEdition,
      );
    case MediaType.custom:
      return RefreshOutcome.unsupported;
  }
  return RefreshOutcome.success;
}

Future<RefreshOutcome> _refetchBook(
  WidgetRef ref,
  DatabaseService db,
  CollectionItem item, {
  required FantlabEdition? pickedFantlabEdition,
  required HardcoverEdition? pickedHardcoverEdition,
}) async {
  final Book? cached = item.book;
  if (cached == null) return RefreshOutcome.unsupported;
  switch (item.source) {
    case DataSource.openLibrary:
      final Book? full =
          await ref.read(openLibraryApiProvider).getWork(cached.nativeId);
      if (full == null) return RefreshOutcome.notFound;
      // OpenLibrary search rows carry year / pages the work lacks, so
      // overlay rather than replace.
      await db.bookDao.upsertBook(cached.withWorkDetails(full));
    case DataSource.fantlab:
      final FantlabApi api = ref.read(fantlabApiProvider);
      final Book? full = await api.getWork(cached.nativeId);
      if (full == null) return RefreshOutcome.notFound;
      // A freshly picked edition wins; otherwise keep the previously picked
      // one instead of resetting to the default first edition.
      final Book updated = pickedFantlabEdition != null
          ? applyFantlabEdition(full, pickedFantlabEdition)
          : await reapplyFantlabEdition(api, cached: cached, fresh: full);
      await db.bookDao.upsertBook(updated);
    case DataSource.comicVine:
      final Book? full =
          await ref.read(comicVineApiProvider).getVolume(cached.nativeId);
      if (full == null) return RefreshOutcome.notFound;
      await db.bookDao.upsertBook(full);
    case DataSource.googleBooks:
      final Book? full =
          await ref.read(googleBooksApiProvider).getVolume(cached.nativeId);
      if (full == null) return RefreshOutcome.notFound;
      await db.bookDao.upsertBook(full);
    case DataSource.hardcover:
      final HardcoverApi api = ref.read(hardcoverApiProvider);
      final Book? full = await api.getBook(cached.nativeId);
      if (full == null) return RefreshOutcome.notFound;
      final Book updated = pickedHardcoverEdition != null
          ? applyHardcoverEdition(full, pickedHardcoverEdition)
          : await reapplyHardcoverEdition(api, cached: cached, fresh: full);
      await db.bookDao.upsertBook(updated);
    default:
      return RefreshOutcome.unsupported;
  }
  return RefreshOutcome.success;
}
