import 'package:core/models/anime.dart';
import 'package:core/models/data_source.dart';
import 'package:core/models/media_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/kitsu_api.dart';
import '../../../l10n/app_localizations.dart';
import '../filters/kitsu_anime_status_filter.dart';
import '../filters/kitsu_anime_subtype_filter.dart';
import '../models/search_source.dart';

const int _kitsuPageSize = 20;

/// SearchSource backed by Kitsu (anime).
class KitsuAnimeSource extends SearchSource {
  @override
  String get id => 'kitsu_anime';

  @override
  MediaType get outputMediaType => MediaType.anime;

  @override
  DataSource get dataSource => DataSource.kitsu;

  @override
  String label(S l) => l.mediaTypeAnime;

  @override
  IconData get icon => Icons.play_circle_outline;

  @override
  bool get supportsBrowse => true;

  @override
  List<SearchFilter> get filters => <SearchFilter>[
        KitsuAnimeSubtypeFilter(),
        KitsuAnimeStatusFilter(),
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
  String searchHint(S l) => l.searchHintAnime;

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
    final (List<Anime> anime, bool hasMore, int totalPages) =
        await api.browseAnime(
      query: query,
      subtype: filterValues['subtype'] as String?,
      status: filterValues['status'] as String?,
      sort: sort.apiValue.isEmpty ? null : sort.apiValue,
      page: page,
      perPage: _kitsuPageSize,
    );

    return BrowseResult(
      items: anime,
      mediaType: MediaType.anime,
      hasMore: hasMore,
      totalPages: totalPages,
      currentPage: page,
    );
  }

  @override
  Widget? buildDiscoverFeed(BuildContext context, WidgetRef ref) => null;
}
