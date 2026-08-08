import 'package:core/models/data_source.dart';
import 'package:core/models/media_type.dart';
import 'package:core/models/tv_show.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/tvdb_api.dart';
import '../../../l10n/app_localizations.dart';
import '../filters/tvdb_genre_filter.dart';
import '../filters/tvdb_status_filter.dart';
import '../filters/year_filter.dart';
import '../models/search_source.dart';

/// SearchSource backed by TheTVDB (TV series). Search has no filters upstream,
/// so the genre / year filters only apply in browse mode.
class TvdbSeriesSource extends SearchSource {
  /// `/search` takes limit + offset, so pages are real requests.
  static const int _pageSize = 25;

  @override
  String get id => 'tvdb_series';

  @override
  MediaType get outputMediaType => MediaType.tvShow;

  @override
  DataSource get dataSource => DataSource.tvdb;

  @override
  String label(S l) => l.collectionFilterTvShows;

  @override
  IconData get icon => Icons.tv_outlined;

  @override
  bool get supportsBrowse => true;

  @override
  List<SearchFilter> get filters => <SearchFilter>[
        TvdbGenreFilter(),
        TvdbStatusFilter(mediaType: MediaType.tvShow),
        YearFilter(),
      ];

  @override
  List<BrowseSortOption> get sortOptions => const <BrowseSortOption>[
        BrowseSortOption(id: 'popularity', apiValue: 'score'),
        BrowseSortOption(id: 'newest', apiValue: 'firstAired'),
        BrowseSortOption(id: 'name_asc', apiValue: 'name'),
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
    final TvdbApi api = ref.read(tvdbApiProvider);

    if (query != null && query.isNotEmpty) {
      // `/search` honours year but ignores genre, and a series hit carries no
      // genre names to narrow by here — genre works in browse only.
      final List<TvShow> hits = await api.searchSeries(
        query,
        limit: _pageSize,
        offset: (page - 1) * _pageSize,
        year: _year(filterValues['year']),
      );
      return BrowseResult(
        items: hits,
        mediaType: MediaType.tvShow,
        // A short page is the last one; the endpoint reports no total.
        hasMore: hits.length == _pageSize,
        currentPage: page,
      );
    }

    final List<TvShow> shows = await api.browseSeries(
      genreId: filterValues['genre'] as int?,
      // The year filter also offers decade buckets as a record; TheTVDB takes
      // a single year, so a decade narrows to its first year.
      year: _year(filterValues['year']),
      statusId: filterValues['status'] as int?,
      sort: sortBy,
      // The API pages from zero.
      page: page - 1,
    );
    return BrowseResult(
      items: shows,
      mediaType: MediaType.tvShow,
      hasMore: shows.isNotEmpty,
      currentPage: page,
    );
  }

  @override
  Widget? buildDiscoverFeed(BuildContext context, WidgetRef ref) => null;

  static int? _year(Object? value) => switch (value) {
        final int year => year,
        (final int from, int _) => from,
        _ => null,
      };
}
