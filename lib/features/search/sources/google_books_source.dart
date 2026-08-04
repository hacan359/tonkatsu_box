import 'package:core/models/book.dart';
import 'package:core/models/data_source.dart';
import 'package:core/models/media_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/google_books_api.dart';
import '../../../l10n/app_localizations.dart';
import '../filters/google_books_language_filter.dart';
import '../filters/google_books_print_type_filter.dart';
import '../models/search_source.dart';

const int _googleBooksPageSize = 20;

// Google Books tolerates short queries, but a 1-char `q` is mostly noise.
const int _googleBooksMinQuery = 2;

/// SearchSource backed by Google Books, Google's global book catalog. Items are
/// stamped [MediaType.book] and carry `DataSource.googleBooks` (set inside
/// [Book.fromGoogleBooksVolume]). `volumes.list` has no filter-only browse, so a
/// text query is always required. The optional user API key (raised quota) is
/// wired by [googleBooksApiProvider]; anonymous search works without one.
class GoogleBooksSource extends SearchSource {
  @override
  String get id => 'googlebooks';

  @override
  MediaType get outputMediaType => MediaType.book;

  @override
  DataSource get dataSource => DataSource.googleBooks;

  @override
  IconData get groupIcon => Icons.book;

  @override
  String label(S l) => l.collectionFilterBooks;

  @override
  IconData get icon => Icons.book;

  // Google Books has no filter-only browse: `volumes.list` rejects a missing
  // `q`, so a text query is always required.
  @override
  bool get supportsBrowse => false;

  @override
  List<SearchFilter> get filters => <SearchFilter>[
        GoogleBooksPrintTypeFilter(),
        GoogleBooksLanguageFilter(),
      ];

  // `volumes.list` honours `orderBy` + `startIndex` during a query, so the sort
  // dropdown stays active while searching.
  @override
  bool get supportsSortDuringSearch => true;

  @override
  List<BrowseSortOption> get sortOptions => const <BrowseSortOption>[
        BrowseSortOption(id: 'relevance', apiValue: 'relevance'),
        BrowseSortOption(id: 'newest', apiValue: 'newest'),
      ];

  @override
  String searchHint(S l) => l.searchHintBooks;

  @override
  Future<BrowseResult> fetch(
    Ref ref, {
    String? query,
    required Map<String, Object?> filterValues,
    required String sortBy,
    required int page,
  }) async {
    final String? trimmed = query?.trim();
    if (trimmed == null || trimmed.length < _googleBooksMinQuery) {
      return const BrowseResult(items: <Object>[], mediaType: MediaType.book);
    }

    final GoogleBooksApi api = ref.read(googleBooksApiProvider);
    // An untouched printType filter defaults to `books` so magazines don't
    // flood a plain book search; an explicit "All" reset re-enables them.
    final (List<Book> books, bool hasMore) = await api.searchVolumes(
      trimmed,
      startIndex: (page - 1) * _googleBooksPageSize,
      maxResults: _googleBooksPageSize,
      orderBy: sortBy.isEmpty ? 'relevance' : sortBy,
      langRestrict: filterValues['language'] as String?,
      printType: (filterValues['printType'] as String?) ?? 'books',
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
