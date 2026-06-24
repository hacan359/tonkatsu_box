import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/comicvine_api.dart';
import '../../../core/api/google_books_api.dart';
import '../../../core/api/fantlab_api.dart';
import '../../../core/api/openlibrary_api.dart';
import '../../../core/database/database_service.dart';
import '../../../core/services/image_cache_service.dart';
import '../../../shared/models/anime.dart';
import '../../../shared/models/book.dart';
import '../../../shared/models/data_source.dart';
import '../../../shared/models/game.dart';
import '../../../shared/models/manga.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/utils/cover_image_id.dart';
import '../../../shared/models/movie.dart';
import '../../../shared/models/platform.dart';
import '../../../shared/models/tv_show.dart';
import '../../../shared/models/visual_novel.dart';
import '../../collections/providers/collections_provider.dart';
import '../../settings/providers/settings_provider.dart';
import '../../collections/widgets/fantlab_edition_picker.dart';
import '../services/search_collection_adder.dart';
import '../widgets/fantlab_book_sheet.dart';
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
      imageIdOf: (Anime a) => a.id.toString(),
      titleOf: (Anime a) => a.titleByLanguage(
        ref.read(settingsNotifierProvider).animeMangaTitleLanguage,
      ),
      imageUrlOf: (Anime a) => a.coverUrl,
      upsert: (Anime a) => ref.read(animeDaoProvider).upsertAnime(a),
      sheetBuilder: (Anime a, VoidCallback onAdd) => ItemDetailsSheet.anime(
        a,
        onAddToCollection: onAdd,
        animeMangaTitleLanguage:
            ref.read(settingsNotifierProvider).animeMangaTitleLanguage,
      ),
    );
    // Edition the user picked in the Fantlab editions strip, tagged with its
    // work id so it only applies to that book; consumed by `enrich`. Reset
    // each time a book sheet opens.
    ({String workId, FantlabEdition edition})? pendingBookEdition;
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
        final Book enriched = await _enrichBook(ref, b);
        final ({String workId, FantlabEdition edition})? pending =
            pendingBookEdition;
        return pending != null && pending.workId == b.nativeId
            ? applyFantlabEdition(enriched, pending.edition)
            : enriched;
      },
      // Fantlab search rows are sparse (no cover / genres / description), so
      // fetch the full work before opening the sheet. OpenLibrary rows are
      // already rich, so they stay instant and lazy-load only the description.
      enrichBeforeDetails: (Book b) => b.source == DataSource.fantlab,
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
    default:
      return null;
  }
}
