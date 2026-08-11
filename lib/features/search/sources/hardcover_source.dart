import 'package:core/models/book.dart';
import 'package:core/models/data_source.dart';
import 'package:core/models/media_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/hardcover_api.dart';
import '../../../l10n/app_localizations.dart';
import '../models/search_source.dart';

const int _hardcoverMinQuery = 2;

/// SearchSource backed by Hardcover, a community book catalog. Items are
/// stamped [MediaType.book] and carry `DataSource.hardcover` (set inside
/// [Book.fromHardcoverDocument]). The Typesense search has no parameter
/// filters and no query-less browse, but any numeric document field works as
/// a sort. Requires the personal token wired by [hardcoverApiProvider].
class HardcoverSource extends SearchSource {
  @override
  String get id => 'hardcover';

  @override
  MediaType get outputMediaType => MediaType.book;

  @override
  DataSource get dataSource => DataSource.hardcover;

  @override
  String label(S l) => l.collectionFilterBooks;

  @override
  IconData get icon => Icons.book;

  // Typesense rejects a query-less search, so a text query is always required.
  @override
  bool get supportsBrowse => false;

  @override
  List<SearchFilter> get filters => const <SearchFilter>[];

  @override
  bool get supportsSortDuringSearch => true;

  @override
  List<BrowseSortOption> get sortOptions => const <BrowseSortOption>[
        BrowseSortOption(id: 'relevance', apiValue: ''),
        BrowseSortOption(id: 'popular', apiValue: 'users_count:desc'),
        BrowseSortOption(id: 'top_rated', apiValue: 'rating:desc'),
        BrowseSortOption(id: 'most_voted', apiValue: 'ratings_count:desc'),
        BrowseSortOption(id: 'most_read', apiValue: 'users_read_count:desc'),
        BrowseSortOption(id: 'newest', apiValue: 'release_year:desc'),
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
    if (trimmed == null || trimmed.length < _hardcoverMinQuery) {
      return const BrowseResult(items: <Object>[], mediaType: MediaType.book);
    }

    final HardcoverApi api = ref.read(hardcoverApiProvider);
    final (List<Book> books, bool hasMore) = await api.searchBooks(
      trimmed,
      page: page,
      sort: sortBy.isEmpty ? null : sortBy,
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
