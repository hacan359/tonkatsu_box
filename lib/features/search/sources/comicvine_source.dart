import 'package:core/models/book.dart';
import 'package:core/models/data_source.dart';
import 'package:core/models/media_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/comicvine_api.dart';
import '../../../l10n/app_localizations.dart';
import '../models/search_source.dart';

// Short comic titles are common, so keep the floor at 2 chars.
const int _comicVineMinQuery = 2;

/// SearchSource backed by ComicVine, a comics / graphic-novel catalog. Items
/// are stamped [MediaType.book] and carry `DataSource.comicVine` +
/// `BookKind.comic` (set inside [Book.fromComicVineVolume]), so comics share
/// the books tab while staying separable.
///
/// Two query paths: the default "Relevance" sort hits `/search` (a single
/// relevance-ranked page — `offset` is ignored there), while any other sort
/// hits `/volumes` with a `name` filter, which paginates and reorders. The
/// API ignores `start_year` / `publisher` volume filters, so there is no
/// filter-only browse.
class ComicVineSource extends SearchSource {
  @override
  String get id => 'comicvine';

  @override
  MediaType get outputMediaType => MediaType.book;

  @override
  DataSource get dataSource => DataSource.comicVine;

  @override
  String label(S l) => l.searchSourceComics;

  @override
  IconData get icon => Icons.auto_stories;

  // ComicVine has no filter-only browse: the `/volumes` filters that would
  // drive it (start_year, publisher) are silently ignored by the API, so a
  // text query is always required.
  @override
  bool get supportsBrowse => false;

  @override
  List<SearchFilter> get filters => const <SearchFilter>[];

  // ComicVine ignores `start_year` / `count_of_issues` sorts on `/volumes`, so
  // only the verified-working orders are exposed. "Relevance" routes to
  // `/search` (no sort param); every other order routes to `/volumes`.
  @override
  List<BrowseSortOption> get sortOptions => const <BrowseSortOption>[
        BrowseSortOption(id: 'relevance', apiValue: ''),
        BrowseSortOption(id: 'name_asc', apiValue: 'name:asc'),
        BrowseSortOption(id: 'name_desc', apiValue: 'name:desc'),
        BrowseSortOption(
          id: 'recently_updated',
          apiValue: 'date_last_updated:desc',
        ),
        BrowseSortOption(id: 'recently_added', apiValue: 'date_added:desc'),
      ];

  // `/volumes` (the sorted path) honours `offset` and `sort` during a query,
  // so the sort dropdown stays active while searching.
  @override
  bool get supportsSortDuringSearch => true;

  @override
  String searchHint(S l) => l.searchHintComics;

  @override
  Future<BrowseResult> fetch(
    Ref ref, {
    String? query,
    required Map<String, Object?> filterValues,
    required String sortBy,
    required int page,
  }) async {
    final String? trimmed = query?.trim();
    if (trimmed == null || trimmed.length < _comicVineMinQuery) {
      return const BrowseResult(items: <Object>[], mediaType: MediaType.book);
    }

    final ComicVineApi api = ref.read(comicVineApiProvider);

    // Relevance (default): `/search` is relevance-ranked but ignores `offset`,
    // so it is a single page — later pages come back empty.
    if (sortBy.isEmpty) {
      final List<Book> books =
          page > 1 ? const <Book>[] : await api.searchVolumes(trimmed);
      return BrowseResult(
        items: books,
        mediaType: MediaType.book,
        currentPage: page,
      );
    }

    // Any explicit sort: `/volumes` name-filter — paginated and reorderable.
    final (List<Book> books, bool hasMore) = await api.browseVolumes(
      nameFilter: trimmed,
      sort: sortBy,
      page: page,
    );
    return BrowseResult(
      items: books,
      mediaType: MediaType.book,
      hasMore: hasMore,
      currentPage: page,
    );
  }

  @override
  Widget? buildDiscoverFeed(BuildContext context, WidgetRef ref) => null;
}
