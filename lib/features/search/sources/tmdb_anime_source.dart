// Источник данных: анимация из TMDB.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/tmdb_api.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/models/movie.dart';
import '../../../shared/models/tv_show.dart';
import '../filters/anime_type_filter.dart';
import '../filters/tmdb_genre_filter.dart';
import '../filters/year_filter.dart';
import '../models/search_source.dart';
import '../providers/genre_provider.dart';
import '../utils/genre_utils.dart';

/// Источник данных — анимация из TMDB (фильмы и сериалы с жанром Animation).
class TmdbAnimeSource extends SearchSource {
  @override
  String get id => 'anime';

  @override
  String label(S l) => l.mediaTypeAnimation;

  @override
  IconData get icon => Icons.animation_outlined;

  @override
  bool get supportsBrowse => true;

  @override
  List<SearchFilter> get filters => <SearchFilter>[
        TmdbGenreFilter(type: 'tv'),
        YearFilter(),
        AnimeTypeFilter(),
      ];

  @override
  List<BrowseSortOption> get sortOptions => const <BrowseSortOption>[
        BrowseSortOption(id: 'popular', apiValue: 'popularity.desc'),
        BrowseSortOption(id: 'top_rated', apiValue: 'vote_average.desc'),
        BrowseSortOption(id: 'newest', apiValue: 'first_air_date.desc'),
      ];

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
    final TmdbApi tmdb = ref.read(tmdbApiProvider);
    final String? animeType = filterValues['animeType'] as String?;

    final Object? yearValue = filterValues['year'];
    int? year;
    String? dateGte;
    String? dateLte;

    if (yearValue is int) {
      year = yearValue;
    } else if (yearValue is (int, int)) {
      dateGte = '${yearValue.$1}-01-01';
      dateLte = '${yearValue.$2}-12-31';
    }

    final int? extraGenreId = filterValues['genre'] as int?;

    if (query != null && query.isNotEmpty) {
      // Текстовый поиск + клиентская фильтрация по animation genre
      return _searchWithFilters(
        tmdb,
        ref,
        query: query,
        animeType: animeType,
        extraGenreId: extraGenreId,
        year: year,
        page: page,
      );
    }

    // Browse mode: Discover с фильтрами
    final int? voteCountGte =
        sortBy == 'vote_average.desc' ? 100 : null;

    if (animeType == 'movies') {
      return _browseMovies(
        tmdb,
        ref,
        extraGenreId: extraGenreId,
        year: year,
        releaseDateGte: dateGte,
        releaseDateLte: dateLte,
        voteCountGte: voteCountGte,
        sortBy: sortBy,
        page: page,
      );
    }

    if (animeType == 'series') {
      return _browseTvShows(
        tmdb,
        ref,
        extraGenreId: extraGenreId,
        year: year,
        firstAirDateGte: dateGte,
        firstAirDateLte: dateLte,
        voteCountGte: voteCountGte,
        sortBy: sortBy,
        page: page,
      );
    }

    // animeType == null → показываем и сериалы, и фильмы
    final List<BrowseResult> results =
        await Future.wait(<Future<BrowseResult>>[
      _browseTvShows(
        tmdb,
        ref,
        extraGenreId: extraGenreId,
        year: year,
        firstAirDateGte: dateGte,
        firstAirDateLte: dateLte,
        voteCountGte: voteCountGte,
        sortBy: sortBy,
        page: page,
      ),
      _browseMovies(
        tmdb,
        ref,
        extraGenreId: extraGenreId,
        year: year,
        releaseDateGte: dateGte,
        releaseDateLte: dateLte,
        voteCountGte: voteCountGte,
        sortBy: sortBy,
        page: page,
      ),
    ]);

    final List<Object> combined = <Object>[
      ...results[0].items,
      ...results[1].items,
    ];

    return BrowseResult(
      items: combined,
      mediaType: MediaType.animation,
      hasMore: results[0].hasMore || results[1].hasMore,
      currentPage: page,
    );
  }

  Future<BrowseResult> _browseMovies(
    TmdbApi tmdb,
    Ref ref, {
    int? extraGenreId,
    int? year,
    String? releaseDateGte,
    String? releaseDateLte,
    int? voteCountGte,
    required String sortBy,
    required int page,
  }) async {
    final Map<String, String> genreMap =
        await ref.read(movieGenreMapProvider.future);

    // Жанр Animation + дополнительный жанр
    final String genreString = extraGenreId != null
        ? '$tmdbAnimationGenreId,$extraGenreId'
        : '$tmdbAnimationGenreId';

    final List<Movie> movies = await tmdb.discoverMovies(
      genreIds: genreString,
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
      mediaType: MediaType.animation,
      hasMore: movies.length >= 20,
      currentPage: page,
    );
  }

  Future<BrowseResult> _browseTvShows(
    TmdbApi tmdb,
    Ref ref, {
    int? extraGenreId,
    int? year,
    String? firstAirDateGte,
    String? firstAirDateLte,
    int? voteCountGte,
    required String sortBy,
    required int page,
  }) async {
    final Map<String, String> genreMap =
        await ref.read(tvGenreMapProvider.future);

    final String genreString = extraGenreId != null
        ? '$tmdbAnimationGenreId,$extraGenreId'
        : '$tmdbAnimationGenreId';

    final List<TvShow> shows = await tmdb.discoverTvShows(
      genreIds: genreString,
      year: year,
      firstAirDateGte: firstAirDateGte,
      firstAirDateLte: firstAirDateLte,
      voteCountGte: voteCountGte,
      sortBy: sortBy,
      page: page,
    );

    final List<TvShow> resolved = resolveTvGenres(shows, genreMap);

    return BrowseResult(
      items: resolved,
      mediaType: MediaType.animation,
      hasMore: shows.length >= 20,
      currentPage: page,
    );
  }

  Future<BrowseResult> _searchWithFilters(
    TmdbApi tmdb,
    Ref ref, {
    required String query,
    String? animeType,
    int? extraGenreId,
    int? year,
    required int page,
  }) async {
    final Map<String, String> tvGenreMap =
        await ref.read(tvGenreMapProvider.future);
    final Map<String, String> movieGenreMap =
        await ref.read(movieGenreMapProvider.future);

    // Ищем сериалы и фильмы параллельно
    final List<Object> results = await Future.wait(<Future<Object>>[
      if (animeType != 'movies')
        tmdb.searchTvShowsPaged(query, page: page, firstAirDateYear: year),
      if (animeType != 'series')
        tmdb.searchMoviesPaged(query, page: page, year: year),
    ]);

    List<TvShow> animeTv = const <TvShow>[];
    List<Movie> animeMovies = const <Movie>[];

    int resultIdx = 0;
    if (animeType != 'movies') {
      final TmdbPagedResult<TvShow> tvResult =
          results[resultIdx++] as TmdbPagedResult<TvShow>;
      animeTv = tvResult.results
          .where(
            (TvShow s) =>
                s.genres != null && s.genres!.any(isAnimationGenre),
          )
          .toList();
    }
    if (animeType != 'series') {
      final TmdbPagedResult<Movie> movieResult =
          results[resultIdx] as TmdbPagedResult<Movie>;
      animeMovies = movieResult.results
          .where(
            (Movie m) =>
                m.genres != null && m.genres!.any(isAnimationGenre),
          )
          .toList();
    }

    // Клиентская фильтрация по дополнительному жанру
    if (extraGenreId != null) {
      final String? tvGenreName = tvGenreMap[extraGenreId.toString()];
      final String? movieGenreName = movieGenreMap[extraGenreId.toString()];
      if (tvGenreName != null) {
        animeTv = animeTv
            .where((TvShow s) =>
                s.genres != null && s.genres!.contains(tvGenreName))
            .toList();
      }
      if (movieGenreName != null) {
        animeMovies = animeMovies
            .where((Movie m) =>
                m.genres != null && m.genres!.contains(movieGenreName))
            .toList();
      }
    }

    final List<TvShow> resolvedTv =
        resolveTvGenres(animeTv, tvGenreMap);
    final List<Movie> resolvedMovies =
        resolveMovieGenres(animeMovies, movieGenreMap);

    final List<Object> combined = <Object>[
      ...resolvedTv,
      ...resolvedMovies,
    ];

    final bool hasMore = results.any((Object r) {
      if (r is TmdbPagedResult<TvShow>) return r.hasMore;
      if (r is TmdbPagedResult<Movie>) return r.hasMore;
      return false;
    });

    return BrowseResult(
      items: combined,
      mediaType: MediaType.animation,
      hasMore: hasMore,
      currentPage: page,
    );
  }

  @override
  Widget? buildDiscoverFeed(BuildContext context, WidgetRef ref) => null;
}
