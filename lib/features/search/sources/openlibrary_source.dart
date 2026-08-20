import 'package:core/models/book.dart';
import 'package:core/models/data_source.dart';
import 'package:core/models/media_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/openlibrary_api.dart';
import '../../../l10n/app_localizations.dart';
import '../filters/openlibrary_language_filter.dart';
import '../filters/openlibrary_scope_filter.dart';
import '../models/search_source.dart';

const int _openLibraryPageSize = 20;

// OpenLibrary rejects `q` shorter than 3 chars with a 422.
const int _openLibraryMinQuery = 3;

class OpenLibrarySource extends SearchSource {
  @override
  String get id => 'openlibrary';

  @override
  MediaType get outputMediaType => MediaType.book;

  @override
  DataSource get dataSource => DataSource.openLibrary;

  @override
  String label(S l) => l.collectionFilterBooks;

  @override
  IconData get icon => Icons.menu_book;

  // OpenLibrary search needs a query — there is no clean "popular" feed.
  @override
  bool get supportsBrowse => false;

  @override
  List<SearchFilter> get filters => <SearchFilter>[
        OpenLibraryScopeFilter(),
        OpenLibraryLanguageFilter(),
      ];

  // OpenLibrary accepts `sort` on search responses, so the dropdown stays
  // active while a query is present.
  @override
  bool get supportsSortDuringSearch => true;

  @override
  List<BrowseSortOption> get sortOptions => const <BrowseSortOption>[
        BrowseSortOption(id: 'relevance', apiValue: ''),
        BrowseSortOption(id: 'rating', apiValue: 'rating'),
        BrowseSortOption(id: 'newest', apiValue: 'new'),
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
    if (query == null || query.trim().length < _openLibraryMinQuery) {
      return const BrowseResult(items: <Object>[], mediaType: MediaType.book);
    }

    final OpenLibraryApi api = ref.read(openLibraryApiProvider);
    final (List<Book> books, bool hasMore, int totalPages) = await api.search(
      query: query,
      scope: (filterValues['scope'] as String?) ?? 'q',
      page: page,
      perPage: _openLibraryPageSize,
      language: filterValues['language'] as String?,
      sort: sortBy.isEmpty ? null : sortBy,
    );

    return BrowseResult(
      items: books,
      mediaType: MediaType.book,
      hasMore: hasMore,
      totalPages: totalPages,
      currentPage: page,
    );
  }

  @override
  Widget? buildDiscoverFeed(BuildContext context, WidgetRef ref) => null;
}
