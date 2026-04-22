// Источник данных: фильмы из TMDB.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/tmdb_api.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/models/movie.dart';
import '../filters/min_rating_filter.dart';
import '../filters/min_votes_filter.dart';
import '../filters/tmdb_genre_filter.dart';
import '../filters/tmdb_language_filter.dart';
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
        MinRatingFilter(),
        MinVotesFilter(),
        TmdbLanguageFilter(),
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

    final List<int>? genreIds = _readGenreIds(filterValues['genre']);
    final double? minRating =
        (filterValues['minRating'] as num?)?.toDouble();
    final int? minVotes = filterValues['minVotes'] as int?;
    final String? originalLanguage =
        filterValues['originalLanguage'] as String?;

    if (query != null && query.isNotEmpty) {
      // Текстовый поиск: TMDB search + клиентская фильтрация по жанру
      final TmdbPagedResult<Movie> result =
          await tmdb.searchMoviesPaged(query, page: page, year: year);

      List<Movie> movies = result.results;

      // Клиентская фильтрация по жанрам (TMDB search не поддерживает genre).
      // Multi-select → совпадение хотя бы по одному из выбранных жанров (OR).
      if (genreIds != null && genreIds.isNotEmpty) {
        final Set<String> genreNames = genreIds
            .map((int id) => genreMap[id.toString()])
            .whereType<String>()
            .toSet();
        if (genreNames.isNotEmpty) {
          movies = movies
              .where((Movie m) =>
                  m.genres != null &&
                  m.genres!.any(genreNames.contains))
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
    final List<Movie> movies = await tmdb.discoverMovies(
      genreIds: _genreIdsToParam(genreIds),
      year: year,
      releaseDateGte: releaseDateGte,
      releaseDateLte: releaseDateLte,
      voteCountGte: minVotes,
      voteAverageGte: minRating,
      originalLanguage: originalLanguage,
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

/// Нормализует значение фильтра `genre` в список ID (multi-select или single).
List<int>? _readGenreIds(Object? value) {
  return switch (value) {
    final List<Object?> list => list.whereType<int>().toList(),
    final int id => <int>[id],
    _ => null,
  };
}

/// Склеивает ID в строку для `with_genres`. null если список пуст.
String? _genreIdsToParam(List<int>? ids) {
  if (ids == null || ids.isEmpty) return null;
  return ids.join(',');
}
