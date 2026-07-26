import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/tvmaze_api.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/data_source.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/models/tv_show.dart';
import '../models/search_source.dart';

const int _tvMazePageSize = 20;

/// SearchSource backed by TVmaze (TV series, keyless). Title search only —
/// no filters, no browse.
class TvMazeTvSource extends SearchSource {
  @override
  String get id => 'tvmaze_tv';

  @override
  MediaType get outputMediaType => MediaType.tvShow;

  @override
  DataSource get dataSource => DataSource.tvmaze;

  @override
  IconData get groupIcon => Icons.tv_outlined;

  @override
  String label(S l) => l.collectionFilterTvShows;

  @override
  IconData get icon => Icons.tv_outlined;

  @override
  bool get supportsBrowse => false;

  @override
  List<SearchFilter> get filters => const <SearchFilter>[];

  @override
  List<BrowseSortOption> get sortOptions => const <BrowseSortOption>[
        BrowseSortOption(id: 'relevance', apiValue: ''),
      ];

  @override
  String searchHint(S l) => l.searchHintTv;

  @override
  Future<BrowseResult> fetch(
    Ref ref, {
    String? query,
    required Map<String, Object?> filterValues,
    required String sortBy,
    required int page,
  }) async {
    if (query == null || query.isEmpty) {
      return BrowseResult(
        items: const <Object>[],
        mediaType: MediaType.tvShow,
        currentPage: page,
      );
    }

    final TvMazeApi api = ref.read(tvMazeApiProvider);
    final List<TvShow> shows = await api.searchShows(query);

    final int start = (page - 1) * _tvMazePageSize;
    if (start >= shows.length) {
      return BrowseResult(
        items: const <Object>[],
        mediaType: MediaType.tvShow,
        currentPage: page,
      );
    }
    final int end = (start + _tvMazePageSize).clamp(0, shows.length);

    return BrowseResult(
      items: shows.sublist(start, end),
      mediaType: MediaType.tvShow,
      hasMore: end < shows.length,
      currentPage: page,
    );
  }

  @override
  Widget? buildDiscoverFeed(BuildContext context, WidgetRef ref) => null;
}
