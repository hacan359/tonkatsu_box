// Источник данных: сериалы из TMDB.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/tmdb_api.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/models/tv_show.dart';
import '../filters/tmdb_genre_filter.dart';
import '../filters/year_filter.dart';
import '../models/search_source.dart';
import '../providers/genre_provider.dart';
import '../utils/genre_utils.dart';

/// Источник данных — сериалы из TMDB (без анимации).
class TmdbTvSource extends SearchSource {
  @override
  String get id => 'tv';

  @override
  String label(S l) => l.mediaTypeTvShow;

  @override
  IconData get icon => Icons.tv_outlined;

  @override
  bool get supportsBrowse => true;

  @override
  List<SearchFilter> get filters => <SearchFilter>[
        TmdbGenreFilter(type: 'tv'),
        YearFilter(),
      ];

  @override
  List<BrowseSortOption> get sortOptions => const <BrowseSortOption>[
        BrowseSortOption(id: 'popular', apiValue: 'popularity.desc'),
        BrowseSortOption(id: 'top_rated', apiValue: 'vote_average.desc'),
        BrowseSortOption(id: 'newest', apiValue: 'first_air_date.desc'),
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
    final TmdbApi tmdb = ref.read(tmdbApiProvider);
    final Map<String, String> genreMap =
        await ref.read(tvGenreMapProvider.future);

    final Object? yearValue = filterValues['year'];
    int? year;
    String? firstAirDateGte;
    String? firstAirDateLte;

    if (yearValue is int) {
      year = yearValue;
    } else if (yearValue is (int, int)) {
      firstAirDateGte = '${yearValue.$1}-01-01';
      firstAirDateLte = '${yearValue.$2}-12-31';
    }

    final int? genreId = filterValues['genre'] as int?;

    if (query != null && query.isNotEmpty) {
      // Текстовый поиск + клиентская фильтрация
      final TmdbPagedResult<TvShow> result = await tmdb.searchTvShowsPaged(
        query,
        page: page,
        firstAirDateYear: year,
      );

      // Фильтруем анимацию из результатов поиска
      List<TvShow> filtered = result.results
          .where(
            (TvShow s) =>
                s.genres == null || !s.genres!.any(isAnimationGenre),
          )
          .toList();

      // Клиентская фильтрация по жанру
      if (genreId != null) {
        final String? genreName = genreMap[genreId.toString()];
        if (genreName != null) {
          filtered = filtered
              .where((TvShow s) =>
                  s.genres != null && s.genres!.contains(genreName))
              .toList();
        }
      }

      final List<TvShow> resolved = resolveTvGenres(filtered, genreMap);

      return BrowseResult(
        items: resolved,
        mediaType: MediaType.tvShow,
        hasMore: result.hasMore,
        currentPage: result.page,
        totalPages: result.totalPages,
      );
    }

    // Browse mode: Discover с фильтрами
    final int? voteCountGte =
        sortBy == 'vote_average.desc' ? 200 : null;

    final List<TvShow> tvShows = await tmdb.discoverTvShows(
      genreId: genreId,
      year: year,
      firstAirDateGte: firstAirDateGte,
      firstAirDateLte: firstAirDateLte,
      voteCountGte: voteCountGte,
      withoutGenreIds: <int>[tmdbAnimationGenreId],
      sortBy: sortBy,
      page: page,
    );

    final List<TvShow> resolved = resolveTvGenres(tvShows, genreMap);

    return BrowseResult(
      items: resolved,
      mediaType: MediaType.tvShow,
      hasMore: tvShows.length >= 20,
      currentPage: page,
    );
  }

  @override
  Widget? buildDiscoverFeed(BuildContext context, WidgetRef ref) => null;
}
