import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/kitsu_api.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/data_source.dart';
import '../../../shared/models/manga.dart';
import '../../../shared/models/media_type.dart';
import '../filters/kitsu_manga_status_filter.dart';
import '../filters/kitsu_manga_subtype_filter.dart';
import '../models/search_source.dart';

const int _kitsuPageSize = 20;

/// SearchSource backed by Kitsu (manga).
class KitsuMangaSource extends SearchSource {
  @override
  String get id => 'kitsu_manga';

  @override
  MediaType get outputMediaType => MediaType.manga;

  @override
  DataSource get dataSource => DataSource.kitsu;

  @override
  IconData get groupIcon => Icons.auto_stories_outlined;

  @override
  String label(S l) => l.mediaTypeManga;

  @override
  IconData get icon => Icons.auto_stories_outlined;

  @override
  bool get supportsBrowse => true;

  @override
  List<SearchFilter> get filters => <SearchFilter>[
        KitsuMangaSubtypeFilter(),
        KitsuMangaStatusFilter(),
      ];

  @override
  List<BrowseSortOption> get sortOptions => const <BrowseSortOption>[
        BrowseSortOption(id: 'relevance', apiValue: ''),
        BrowseSortOption(id: 'popular', apiValue: 'popularityRank'),
        BrowseSortOption(id: 'top_rated', apiValue: '-averageRating'),
        BrowseSortOption(id: 'newest', apiValue: '-startDate'),
      ];

  @override
  bool get supportsSortDuringSearch => true;

  @override
  String searchHint(S l) => l.searchHintManga;

  @override
  Future<BrowseResult> fetch(
    Ref ref, {
    String? query,
    required Map<String, Object?> filterValues,
    required String sortBy,
    required int page,
  }) async {
    final KitsuApi api = ref.read(kitsuApiProvider);

    final BrowseSortOption sort = sortOptions.firstWhere(
      (BrowseSortOption o) => o.id == sortBy,
      orElse: () => sortOptions.first,
    );
    final (List<Manga> mangas, bool hasMore, int totalPages) =
        await api.browseManga(
      query: query,
      subtype: filterValues['subtype'] as String?,
      status: filterValues['status'] as String?,
      sort: sort.apiValue.isEmpty ? null : sort.apiValue,
      page: page,
      perPage: _kitsuPageSize,
    );

    return BrowseResult(
      items: mangas,
      mediaType: MediaType.manga,
      hasMore: hasMore,
      totalPages: totalPages,
      currentPage: page,
    );
  }

  @override
  Widget? buildDiscoverFeed(BuildContext context, WidgetRef ref) => null;
}
