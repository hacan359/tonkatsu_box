// Источник данных: фильмы из TMDB.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/tmdb_api.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/models/movie.dart';
import '../filters/tmdb_genre_filter.dart';
import '../filters/year_filter.dart';
import '../models/search_source.dart';
import '../providers/genre_provider.dart';
import '../utils/genre_utils.dart';

/// Источник данных — фильмы из TMDB.
class TmdbMoviesSource extends SearchSource {
  @override
  String get id => 'movies';

  @override
  String get groupId => 'tmdb';

  @override
  String get groupName => 'TMDB';

  @override
  IconData get groupIcon => Icons.movie_outlined;

  @override
  String label(S l) => l.mediaTypeMovie;

  @override
  IconData get icon => Icons.movie_outlined;

  @override
  bool get supportsBrowse => true;

  @override
  List<SearchFilter> get filters => <SearchFilter>[
        TmdbGenreFilter(type: 'movie'),
        YearFilter(),
      ];

  @override
  List<BrowseSortOption> get sortOptions => const <BrowseSortOption>[
        BrowseSortOption(id: 'popular', apiValue: 'popularity.desc'),
        BrowseSortOption(id: 'top_rated', apiValue: 'vote_average.desc'),
        BrowseSortOption(
          id: 'newest',
          apiValue: 'primary_release_date.desc',
        ),
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
    final TmdbApi tmdb = ref.read(tmdbApiProvider);
    final Map<String, String> genreMap =
        await ref.read(movieGenreMapProvider.future);

    final Object? yearValue = filterValues['year'];
    int? year;
    String? releaseDateGte;
    String? releaseDateLte;

    if (yearValue is int) {
      year = yearValue;
    } else if (yearValue is (int, int)) {
      releaseDateGte = '${yearValue.$1}-01-01';
      releaseDateLte = '${yearValue.$2}-12-31';
    }

    final int? genreId = filterValues['genre'] as int?;

    if (query != null && query.isNotEmpty) {
      // Текстовый поиск: TMDB search + клиентская фильтрация по жанру
      final TmdbPagedResult<Movie> result =
          await tmdb.searchMoviesPaged(query, page: page, year: year);

      List<Movie> movies = result.results;

      // Клиентская фильтрация по жанру (TMDB search не поддерживает genre)
      if (genreId != null) {
        final String? genreName = genreMap[genreId.toString()];
        if (genreName != null) {
          movies = movies
              .where((Movie m) =>
                  m.genres != null && m.genres!.contains(genreName))
              .toList();
        }
      }

      final List<Movie> resolved = resolveMovieGenres(movies, genreMap);

      return BrowseResult(
        items: resolved,
        mediaType: MediaType.movie,
        hasMore: result.hasMore,
        currentPage: result.page,
        totalPages: result.totalPages,
      );
    }

    // Browse mode: Discover с фильтрами
    final int? voteCountGte =
        sortBy == 'vote_average.desc' ? 200 : null;

    final List<Movie> movies = await tmdb.discoverMovies(
      genreId: genreId,
      year: year,
      releaseDateGte: releaseDateGte,
      releaseDateLte: releaseDateLte,
      voteCountGte: voteCountGte,
      sortBy: sortBy,
      page: page,
    );

    final List<Movie> resolved = resolveMovieGenres(movies, genreMap);

    return BrowseResult(
      items: resolved,
      mediaType: MediaType.movie,
      hasMore: movies.length >= 20,
      currentPage: page,
    );
  }

  @override
  Widget? buildDiscoverFeed(BuildContext context, WidgetRef ref) {
    // Discover feed переиспользуется через существующий виджет
    return null;
  }
}
