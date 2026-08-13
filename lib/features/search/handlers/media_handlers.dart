import 'package:core/models/audio_item.dart';
import 'package:core/models/audio_track.dart';
import 'package:core/models/anime.dart';
import 'package:core/models/book.dart';
import 'package:core/models/data_source.dart';
import 'package:core/models/game.dart';
import 'package:core/models/manga.dart';
import 'package:core/models/media_type.dart';
import 'package:core/models/movie.dart';
import 'package:core/models/platform.dart';
import 'package:core/models/tv_show.dart';
import 'package:core/models/visual_novel.dart';
import 'package:core/utils/cover_image_id.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/comicvine_api.dart';
import '../../../core/api/google_books_api.dart';
import '../../../core/api/musicbrainz_api.dart';
import '../../../core/api/podcast_index_api.dart';
import '../../../core/api/hardcover_api.dart';
import '../../../core/api/fantlab_api.dart';
import '../../../core/api/openlibrary_api.dart';
import '../../../core/database/database_service.dart';
import '../../../core/services/image_cache_service.dart';
import '../../collections/providers/collections_provider.dart';
import '../../settings/providers/settings_provider.dart';
import '../../collections/widgets/fantlab_edition_picker.dart';
import '../../collections/widgets/hardcover_edition_picker.dart';
import '../services/search_collection_adder.dart';
import '../widgets/fantlab_book_sheet.dart';
import '../widgets/hardcover_book_sheet.dart';
import '../widgets/podcast_index_sheet.dart';
import '../widgets/musicbrainz_album_sheet.dart';
import '../widgets/google_books_more_by_author_section.dart';
import '../widgets/item_details_sheet.dart';
import 'game_handler.dart';
import 'media_action_handler.dart';
import 'movie_handler.dart';
import 'simple_media_handler.dart';
import 'tv_show_handler.dart';

/// Registry that maps search results to their per-source handlers.
///
/// Resolution is two-level:
/// 1. by `sourceId` — for the case when the same model type comes from
///    multiple sources (e.g. `Game` from IGDB *and* a future RAWG) and
///    needs source-specific logic;
/// 2. fallback by `runtimeType` — the default when no source override is
///    registered.
class MediaHandlers {
  MediaHandlers({
    required WidgetRef ref,
    required Map<int, Platform> Function() platformMap,
    required Set<int> Function() targetCollections,
    void Function(Game game)? onGameSelected,
  }) {
    final SearchCollectionAdder adder = SearchCollectionAdder(ref);
    _byType[Game] = GameHandler(
      ref: ref,
      adder: adder,
      platformMap: platformMap,
      targetCollections: targetCollections,
      onGameSelected: onGameSelected,
    );
    _byType[Movie] = MovieHandler(
      ref: ref,
      adder: adder,
      targetCollections: targetCollections,
    );
    _byType[TvShow] = TvShowHandler(
      ref: ref,
      adder: adder,
      targetCollections: targetCollections,
    );
    _byType[VisualNovel] = SimpleMediaHandler<VisualNovel>(
      ref: ref,
      adder: adder,
      targetCollections: targetCollections,
      mediaType: MediaType.visualNovel,
      imageType: ImageType.vnCover,
      collectedProvider: collectedVisualNovelIdsProvider,
      externalIdOf: (VisualNovel vn) => vn.numericId,
      imageIdOf: (VisualNovel vn) => vn.numericId.toString(),
      titleOf: (VisualNovel vn) => vn.title,
      imageUrlOf: (VisualNovel vn) => vn.imageUrl,
      upsert: (VisualNovel vn) =>
          ref.read(visualNovelDaoProvider).upsertVisualNovel(vn),
      sheetBuilder: (VisualNovel vn, VoidCallback onAdd) =>
          ItemDetailsSheet.visualNovel(vn, onAddToCollection: onAdd),
    );
    _byType[Manga] = SimpleMediaHandler<Manga>(
      ref: ref,
      adder: adder,
      targetCollections: targetCollections,
      mediaType: MediaType.manga,
      imageType: ImageType.mangaCover,
      collectedProvider: collectedMangaIdsProvider,
      externalIdOf: (Manga m) => m.id,
      imageIdOf: (Manga m) => coverImageId(
        mediaType: MediaType.manga,
        externalId: m.id,
        source: m.source,
      ),
      titleOf: (Manga m) => m.titleByLanguage(
        ref.read(settingsNotifierProvider).animeMangaTitleLanguage,
      ),
      imageUrlOf: (Manga m) => m.coverUrl,
      upsert: (Manga m) => ref.read(mangaDaoProvider).upsertManga(m),
      sourceOf: (Manga m) => m.source,
      sheetBuilder: (Manga m, VoidCallback onAdd) => ItemDetailsSheet.manga(
        m,
        onAddToCollection: onAdd,
        animeMangaTitleLanguage:
            ref.read(settingsNotifierProvider).animeMangaTitleLanguage,
      ),
    );
    _byType[Anime] = SimpleMediaHandler<Anime>(
      ref: ref,
      adder: adder,
      targetCollections: targetCollections,
      mediaType: MediaType.anime,
      imageType: ImageType.animeCover,
      collectedProvider: collectedAnimeIdsProvider,
      externalIdOf: (Anime a) => a.id,
      imageIdOf: (Anime a) => coverImageId(
        mediaType: MediaType.anime,
        externalId: a.id,
        source: a.source,
      ),
      titleOf: (Anime a) => a.titleByLanguage(
        ref.read(settingsNotifierProvider).animeMangaTitleLanguage,
      ),
      imageUrlOf: (Anime a) => a.coverUrl,
      upsert: (Anime a) => ref.read(animeDaoProvider).upsertAnime(a),
      sourceOf: (Anime a) => a.source,
      sheetBuilder: (Anime a, VoidCallback onAdd) => ItemDetailsSheet.anime(
        a,
        onAddToCollection: onAdd,
        animeMangaTitleLanguage:
            ref.read(settingsNotifierProvider).animeMangaTitleLanguage,
      ),
    );
    // Edition the user picked in the Fantlab / Hardcover editions strip,
    // tagged with its work id so it only applies to that book; consumed by
    // `enrich`. Reset each time a book sheet opens.
    ({String workId, FantlabEdition edition})? pendingBookEdition;
    ({String bookId, HardcoverEdition edition})? pendingHardcoverEdition;
    _byType[Book] = SimpleMediaHandler<Book>(
      ref: ref,
      adder: adder,
      targetCollections: targetCollections,
      mediaType: MediaType.book,
      imageType: ImageType.bookCover,
      collectedProvider: collectedBookIdsProvider,
      externalIdOf: (Book b) => b.externalIdInt,
      imageIdOf: (Book b) => coverImageId(
        mediaType: MediaType.book,
        externalId: b.externalIdInt,
        source: b.source,
        coverUrl: b.coverUrl,
      ),
      titleOf: (Book b) => b.title,
      imageUrlOf: (Book b) => b.coverUrl,
      upsert: (Book b) => ref.read(bookDaoProvider).upsertBook(b),
      sourceOf: (Book b) => b.source,
      sheetBuilder: (Book b, VoidCallback onAdd) {
        final Future<String?> Function()? overviewLoader =
            b.description != null ? null : () => _loadBookDescription(ref, b);
        // Fantlab books get an inline editions strip; the picked edition is
        // captured here and applied to the saved record by `enrich`.
        if (b.source == DataSource.fantlab) {
          return FantlabBookSheet(
            work: b,
            onAddToCollection: onAdd,
            onEditionChanged: (String workId, FantlabEdition? ed) =>
                pendingBookEdition =
                    ed == null ? null : (workId: workId, edition: ed),
            overviewLoader: overviewLoader,
          );
        }
        if (b.source == DataSource.hardcover) {
          return HardcoverBookSheet(
            book: b,
            onAddToCollection: onAdd,
            onEditionChanged: (String bookId, HardcoverEdition? ed) =>
                pendingHardcoverEdition =
                    ed == null ? null : (bookId: bookId, edition: ed),
            overviewLoader: overviewLoader,
          );
        }
        return ItemDetailsSheet.book(
          b,
          onAddToCollection: onAdd,
          // Search rows omit the description — load the full work inside the
          // open sheet (spinner), so the tap itself stays instant.
          overviewLoader: overviewLoader,
          // Google Books volumes carry an author — show a lazily-paged
          // "more by this author" strip at the bottom of the sheet.
          moreByAuthorSection: (b.source == DataSource.googleBooks &&
                  b.authors.isNotEmpty)
              ? GoogleBooksMoreByAuthorSection(
                  author: b.authors.first,
                  excludeNativeId: b.nativeId,
                )
              : null,
        );
      },
      // On add, cache the full work so the collected item's detail page also
      // carries the rich fields, then overlay the picked Fantlab edition (if
      // any). Runs on the deliberate add, not on open.
      enrich: (Book b) async {
        Book enriched = await _enrichBook(ref, b);
        final ({String workId, FantlabEdition edition})? pending =
            pendingBookEdition;
        if (pending != null && pending.workId == b.nativeId) {
          enriched = applyFantlabEdition(enriched, pending.edition);
        }
        final ({String bookId, HardcoverEdition edition})? pendingHc =
            pendingHardcoverEdition;
        if (pendingHc != null && pendingHc.bookId == b.nativeId) {
          enriched = applyHardcoverEdition(enriched, pendingHc.edition);
        }
        return enriched;
      },
      // Fantlab search rows are sparse (no cover / genres / description), so
      // fetch the full work before opening the sheet. OpenLibrary rows are
      // already rich, so they stay instant and lazy-load only the description.
      enrichBeforeDetails: (Book b) => b.source == DataSource.fantlab,
    );
    // Consumed by `enrich` so an add straight from the sheet re-fetches
    // nothing; reset on each sheet open.
    _PendingAlbumRelease? pendingAlbumRelease;
    _byType[AudioItem] = SimpleMediaHandler<AudioItem>(
      ref: ref,
      adder: adder,
      targetCollections: targetCollections,
      mediaType: MediaType.audio,
      imageType: ImageType.audioCover,
      collectedProvider: collectedAudioIdsProvider,
      externalIdOf: (AudioItem a) => a.id,
      imageIdOf: (AudioItem a) => coverImageId(
        mediaType: MediaType.audio,
        externalId: a.id,
        source: a.source,
      ),
      titleOf: (AudioItem a) => a.title,
      imageUrlOf: (AudioItem a) => a.coverUrl,
      upsert: (AudioItem a) => ref.read(audioDaoProvider).upsertAudioItem(a),
      sourceOf: (AudioItem a) => a.source,
      sheetBuilder: (AudioItem a, VoidCallback onAdd) => a.isPodcast
          ? PodcastIndexSheet(podcast: a, onAddToCollection: onAdd)
          : MusicBrainzAlbumSheet(
              album: a,
              onAddToCollection: onAdd,
              onReleaseChanged: (
                String mbid,
                MusicBrainzRelease? release,
                List<AudioTrack>? tracks,
              ) =>
                  pendingAlbumRelease = release == null
                      ? null
                      : (albumMbid: mbid, release: release, tracks: tracks),
            ),
      // On add: lookup extras plus the track/episode list, cached so the
      // collection tracker works offline.
      enrich: (AudioItem a) {
        if (a.isPodcast) return _enrichPodcast(ref, a);
        final _PendingAlbumRelease? pending = pendingAlbumRelease;
        return _enrichAlbum(
          ref,
          a,
          pending != null && pending.albumMbid == a.nativeId ? pending : null,
        );
      },
    );
  }

  final Map<Type, MediaActionHandler> _byType =
      <Type, MediaActionHandler>{};
  final Map<String, MediaActionHandler> _bySource =
      <String, MediaActionHandler>{};

  /// Register a source-specific handler. Takes precedence over the
  /// type-based default for items dispatched with this [sourceId].
  void registerForSource(String sourceId, MediaActionHandler handler) {
    _bySource[sourceId] = handler;
  }

  MediaActionHandler? forItem(Object item, {String? sourceId}) {
    if (sourceId != null) {
      final MediaActionHandler? bySource = _bySource[sourceId];
      if (bySource != null) return bySource;
    }
    return _byType[item.runtimeType];
  }

  Future<void> onTap(
    BuildContext context,
    Object item,
    MediaType mediaType, {
    String? sourceId,
  }) async {
    final MediaActionHandler? handler =
        forItem(item, sourceId: sourceId);
    if (handler == null) return;
    await handler.onTap(context, item, mediaType);
  }

  Future<void> addToAnyCollection(
    BuildContext context,
    Object item,
    MediaType mediaType, {
    String? sourceId,
  }) async {
    final MediaActionHandler? handler =
        forItem(item, sourceId: sourceId);
    if (handler == null) return;
    await handler.addToAnyCollection(context, item, mediaType);
  }
}

/// Release picked in the sheet (auto or by hand) with its loaded tracks,
/// tagged by the group MBID it belongs to.
typedef _PendingAlbumRelease = ({
  String albumMbid,
  MusicBrainzRelease release,
  List<AudioTrack>? tracks,
});

/// Full lookup + picked/default release + cached track list for an album on
/// its way into a collection. Any failure keeps what the search row had.
Future<AudioItem> _enrichAlbum(
  WidgetRef ref,
  AudioItem album,
  _PendingAlbumRelease? pending,
) async {
  final MusicBrainzApi api = ref.read(musicBrainzApiProvider);
  AudioItem enriched = album;
  try {
    final AudioItem? full = await api.getReleaseGroup(album.nativeId);
    if (full != null) enriched = enriched.withLookupDetails(full);
  } on Exception {
    // Lookup extras are optional; the search row is already a valid album.
  }
  try {
    final MusicBrainzRelease? release =
        pending?.release ?? await api.getDefaultRelease(album.nativeId);
    if (release == null) return enriched;

    // The sheet already fetched this release's tracks — don't pay the
    // rate-limited round-trip twice on the same add.
    final List<AudioTrack> tracks = pending?.tracks ??
        await api.getReleaseTracks(release.mbid, audioId: album.id);
    await ref
        .read(audioDaoProvider)
        .replaceAudioTracks(album.id, album.source, tracks);

    int? totalLengthMs;
    for (final AudioTrack track in tracks) {
      if (track.lengthMs != null) {
        totalLengthMs = (totalLengthMs ?? 0) + track.lengthMs!;
      }
    }
    return enriched.copyWith(
      releaseMbid: release.mbid,
      releaseTitle: release.title,
      label: release.label,
      format: release.format,
      trackCount: tracks.isNotEmpty ? tracks.length : release.trackCount,
      discCount: release.discCount,
      totalLengthMs: totalLengthMs,
    );
  } on Exception {
    return enriched;
  }
}

/// Full feed record plus the newest episodes (≤1000), cached so the episode
/// tracker works offline. Any failure keeps what the search row had.
Future<AudioItem> _enrichPodcast(WidgetRef ref, AudioItem podcast) async {
  final PodcastIndexApi api = ref.read(podcastIndexApiProvider);
  // Independent calls — fail-soft individually, no reason to pay two RTTs.
  final (AudioItem? full, List<AudioTrack> episodes) = await (
    api.getPodcast(podcast.id).onError((_, _) => null),
    api
        .getEpisodes(podcast.id)
        .onError((_, _) => const <AudioTrack>[]),
  ).wait;

  AudioItem enriched =
      full != null ? podcast.withLookupDetails(full) : podcast;
  if (episodes.isEmpty) return enriched;
  try {
    // Upsert, never replace: episodes older than the API's 1000-newest
    // window must survive in the cache once seen.
    await ref.read(audioDaoProvider).upsertTracks(episodes);
    enriched = enriched.copyWith(
      trackCount: enriched.trackCount ?? episodes.length,
    );
  } on Exception {
    // Cache write is best-effort; the tracker refetches on first open.
  }
  return enriched;
}

/// Loads the full-work description for [book] from its provider. Used by the
/// details sheet's lazy overview loader.
Future<String?> _loadBookDescription(WidgetRef ref, Book book) async {
  try {
    final Book? full = await _fetchFullBook(ref, book);
    return full?.description;
  } on Exception {
    return null;
  }
}

/// Returns the full-work version of [book] for caching on add. OpenLibrary
/// search rows are overlaid (`withWorkDetails`) so their year / pages survive;
/// Fantlab returns a complete record, so it replaces the search row outright.
/// On any failure the original [book] is kept.
Future<Book> _enrichBook(WidgetRef ref, Book book) async {
  try {
    final Book? full = await _fetchFullBook(ref, book);
    if (full == null) return book;
    return book.source == DataSource.openLibrary
        ? book.withWorkDetails(full)
        : full;
  } on Exception {
    return book;
  }
}

/// Per-provider full-work fetch by native id. Null for sources without a work
/// endpoint (or on a soft 404).
Future<Book?> _fetchFullBook(WidgetRef ref, Book book) async {
  switch (book.source) {
    case DataSource.openLibrary:
      return ref.read(openLibraryApiProvider).getWork(book.nativeId);
    case DataSource.fantlab:
      return ref.read(fantlabApiProvider).getWork(book.nativeId);
    case DataSource.comicVine:
      return ref.read(comicVineApiProvider).getVolume(book.nativeId);
    case DataSource.googleBooks:
      return ref.read(googleBooksApiProvider).getVolume(book.nativeId);
    case DataSource.hardcover:
      return ref.read(hardcoverApiProvider).getBook(book.nativeId);
    default:
      return null;
  }
}
