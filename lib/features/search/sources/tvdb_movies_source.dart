import 'package:core/models/data_source.dart';
import 'package:core/models/media_type.dart';
import 'package:core/models/movie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/tvdb_api.dart';
import '../../../l10n/app_localizations.dart';
import '../filters/tvdb_genre_filter.dart';
import '../filters/tvdb_status_filter.dart';
import '../filters/year_filter.dart';
import '../models/search_source.dart';

/// SearchSource backed by TheTVDB (movies). Search has no filters upstream, so
/// the genre / year filters only apply in browse mode.
class TvdbMoviesSource extends SearchSource {
  /// `/search` takes limit + offset, so pages are real requests.
  static const int _pageSize = 25;

  @override
  String get id => 'tvdb_movies';

  @override
  MediaType get outputMediaType => MediaType.movie;

  @override
  DataSource get dataSource => DataSource.tvdb;

  @override
  String label(S l) => l.collectionFilterMovies;

  @override
  IconData get icon => Icons.movie_outlined;

  @override
  bool get supportsBrowse => true;

  @override
  List<SearchFilter> get filters => <SearchFilter>[
        TvdbGenreFilter(),
        TvdbStatusFilter(mediaType: MediaType.movie),
        YearFilter(),
      ];

  @override
  List<BrowseSortOption> get sortOptions => const <BrowseSortOption>[
        BrowseSortOption(id: 'popularity', apiValue: 'score'),
        BrowseSortOption(id: 'newest', apiValue: 'firstAired'),
        BrowseSortOption(id: 'name_asc', apiValue: 'name'),
      ];

  @override
  String searchHint(S l) => l.searchHintMovies;

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
      // `/search` honours year but ignores genre in every spelling. Movie hits
      // carry their genre names, so the narrowing happens here instead.
      final List<Movie> hits = await api.searchMovies(
        query,
        limit: _pageSize,
        offset: (page - 1) * _pageSize,
        year: _year(filterValues['year']),
      );
      return BrowseResult(
        items: await _narrowByGenre(ref, hits, filterValues['genre']),
        mediaType: MediaType.movie,
        // Counted before narrowing: a short raw page is the last one, and the
        // endpoint reports no total.
        hasMore: hits.length == _pageSize,
        currentPage: page,
      );
    }

    final List<Movie> movies = await api.browseMovies(
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
      items: movies,
      mediaType: MediaType.movie,
      hasMore: movies.isNotEmpty,
      currentPage: page,
    );
  }

  @override
  Widget? buildDiscoverFeed(BuildContext context, WidgetRef ref) => null;

  /// The filter stores the genre id, while a search hit names its genres.
  Future<List<Movie>> _narrowByGenre(
    Ref ref,
    List<Movie> hits,
    Object? genreValue,
  ) async {
    if (genreValue is! int) return hits;
    final List<({int id, String name})> genres =
        await ref.read(tvdbGenresProvider.future);
    final String? name = genres
        .where((({int id, String name}) g) => g.id == genreValue)
        .map((({int id, String name}) g) => g.name)
        .firstOrNull;
    if (name == null) return hits;
    return hits
        .where((Movie m) => m.genres?.contains(name) ?? false)
        .toList();
  }

  static int? _year(Object? value) => switch (value) {
        final int year => year,
        (final int from, int _) => from,
        _ => null,
      };
}
