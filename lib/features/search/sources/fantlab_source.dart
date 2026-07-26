import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/fantlab_api.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/book.dart';
import '../../../shared/models/data_source.dart';
import '../../../shared/models/media_type.dart';
import '../filters/fantlab_work_type_filter.dart';
import '../models/search_source.dart';

// Short Cyrillic titles are common; keep the floor low but non-empty. The page
// size is server-fixed at 25 and handled inside FantlabApi.
const int _fantlabMinQuery = 2;

/// SearchSource backed by Fantlab, a community book catalog with detailed
/// metadata (ratings, awards, series, editions). Its own provider group (like
/// the other sources); items are stamped [MediaType.book] and carry
/// `DataSource.fantlab` (set inside the `Book.fromFantlab*` factories).
///
/// `/search-works` accepts only `q` / `page`, so ordering is relevance-only and
/// the one filter (work type) is applied client-side by matching `name_eng` —
/// see `core/api/fantlab/README.md`.
class FantlabSource extends SearchSource {
  @override
  String get id => 'fantlab';

  @override
  MediaType get outputMediaType => MediaType.book;

  @override
  DataSource get dataSource => DataSource.fantlab;

  @override
  IconData get groupIcon => Icons.menu_book;

  @override
  String label(S l) => l.collectionFilterBooks;

  @override
  IconData get icon => Icons.menu_book;

  // Fantlab search needs a query — there is no clean "popular" feed.
  @override
  bool get supportsBrowse => false;

  @override
  List<SearchFilter> get filters => <SearchFilter>[FantlabWorkTypeFilter()];

  @override
  List<BrowseSortOption> get sortOptions => const <BrowseSortOption>[
        BrowseSortOption(id: 'relevance', apiValue: ''),
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
    if (query == null || query.trim().length < _fantlabMinQuery) {
      return const BrowseResult(items: <Object>[], mediaType: MediaType.book);
    }

    final FantlabApi api = ref.read(fantlabApiProvider);
    final (List<Book> books, bool hasMore, int totalPages) =
        await api.searchWorks(
      query: query.trim(),
      page: page,
      workType: filterValues['work_type'] as String?,
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
