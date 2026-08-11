import 'package:core/models/data_source.dart';
import 'package:core/models/media_type.dart';
import 'package:core/models/visual_novel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/vndb_api.dart';
import '../../../l10n/app_localizations.dart';
import '../filters/vndb_has_anime_filter.dart';
import '../filters/vndb_language_filter.dart';
import '../filters/vndb_length_filter.dart';
import '../filters/vndb_min_rating_filter.dart';
import '../filters/vndb_tag_filter.dart';
import '../filters/year_filter.dart';
import '../models/search_source.dart';
import '../utils/filter_value_utils.dart';

/// Page size for VNDB API requests.
const int _vndbPageSize = 20;

/// Search source for visual novels from VNDB.
class VndbSource extends SearchSource {
  @override
  String get id => 'visual_novels';

  @override
  MediaType get outputMediaType => MediaType.visualNovel;

  @override
  DataSource get dataSource => DataSource.vndb;

  @override
  String label(S l) => l.searchSourceVisualNovels;

  @override
  IconData get icon => Icons.menu_book_outlined;

  @override
  bool get supportsBrowse => true;

  @override
  List<SearchFilter> get filters => <SearchFilter>[
        VndbTagFilter(),
        VndbLengthFilter(),
        VndbLanguageFilter(),
        YearFilter(),
        VndbMinRatingFilter(),
        VndbHasAnimeFilter(),
      ];

  @override
  List<BrowseSortOption> get sortOptions => const <BrowseSortOption>[
        BrowseSortOption(id: 'rating', apiValue: 'rating'),
        BrowseSortOption(id: 'newest', apiValue: 'released'),
        BrowseSortOption(id: 'most_voted', apiValue: 'votecount'),
      ];

  @override
  bool get supportsSortDuringSearch => true;

  @override
  String searchHint(S l) => l.searchHintVisualNovels;

  @override
  Future<BrowseResult> fetch(
    Ref ref, {
    String? query,
    required Map<String, Object?> filterValues,
    required String sortBy,
    required int page,
  }) async {
    final VndbApi vndb = ref.read(vndbApiProvider);

    final List<String>? tagIds = readFilterStringList(filterValues['genre']);
    final int? length = filterValues['length'] as int?;
    final List<String>? langs =
        readFilterStringList(filterValues['language']);
    final int? minRating = filterValues['minRating'] as int?;
    final bool hasAnime = filterValues['hasAnime'] == true;

    int? startYear;
    int? endYear;
    switch (filterValues['year']) {
      case final int y:
        startYear = y;
        endYear = y;
      case final (int, int) range:
        startYear = range.$1;
        endYear = range.$2;
      default:
        break;
    }

    const int pageSize = _vndbPageSize;

    try {
      // VNDB natively combines search + filters via ['and', ...].
      final (List<VisualNovel> novels, bool hasMore, int totalPages) =
          await vndb.browseVn(
        query: query,
        tagIds: tagIds,
        length: length,
        langs: langs,
        startYear: startYear,
        endYear: endYear,
        minRating: minRating,
        hasAnime: hasAnime ? true : null,
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
    } on VndbApiException {
      rethrow;
    }
  }

  @override
  Widget? buildDiscoverFeed(BuildContext context, WidgetRef ref) => null;
}
