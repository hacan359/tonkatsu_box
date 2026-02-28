// Источник данных: визуальные новеллы из VNDB.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/vndb_api.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/models/visual_novel.dart';
import '../filters/vndb_tag_filter.dart';
import '../models/search_source.dart';

/// Размер страницы для запросов к VNDB API.
const int _vndbPageSize = 20;

/// Источник данных — визуальные новеллы из VNDB.
class VndbSource extends SearchSource {
  @override
  String get id => 'visual_novels';

  @override
  String label(S l) => l.searchSourceVisualNovels;

  @override
  IconData get icon => Icons.menu_book_outlined;

  @override
  bool get supportsBrowse => true;

  @override
  List<SearchFilter> get filters => <SearchFilter>[
        VndbTagFilter(),
      ];

  @override
  List<BrowseSortOption> get sortOptions => const <BrowseSortOption>[
        BrowseSortOption(id: 'rating', apiValue: 'rating'),
        BrowseSortOption(id: 'newest', apiValue: 'released'),
        BrowseSortOption(id: 'most_voted', apiValue: 'votecount'),
      ];

  @override
  String searchHint(S l) => l.searchHintVisualNovels;

  @override
  Future<BrowseResult> browse(
    Ref ref, {
    required Map<String, Object?> filterValues,
    required String sortBy,
    required int page,
  }) async {
    final VndbApi vndb = ref.read(vndbApiProvider);

    final String? tagId = filterValues['genre'] as String?;

    const int pageSize = _vndbPageSize;

    try {
      final (List<VisualNovel> novels, bool hasMore, int totalPages) =
          await vndb.browseVn(
        tagId: tagId,
        sort: sortBy,
        page: page,
        results: pageSize,
      );

      return BrowseResult(
        items: novels,
        mediaType: MediaType.visualNovel,
        hasMore: hasMore,
        totalPages: totalPages,
        currentPage: page,
      );
    } on VndbApiException catch (e) {
      throw Exception(e.message);
    }
  }

  @override
  Future<BrowseResult> search(
    Ref ref, {
    required String query,
    required int page,
  }) async {
    final VndbApi vndb = ref.read(vndbApiProvider);

    const int pageSize = _vndbPageSize;

    try {
      final (List<VisualNovel> novels, bool hasMore) = await vndb.searchVn(
        query: query,
        page: page,
        results: pageSize,
      );

      return BrowseResult(
        items: novels,
        mediaType: MediaType.visualNovel,
        hasMore: hasMore,
        currentPage: page,
      );
    } on VndbApiException catch (e) {
      throw Exception(e.message);
    }
  }

  @override
  Widget? buildDiscoverFeed(BuildContext context, WidgetRef ref) => null;
}
