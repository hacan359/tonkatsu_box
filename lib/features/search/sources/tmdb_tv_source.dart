// Источник данных: сериалы из TMDB.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/tmdb_api.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/models/tv_show.dart';
import '../../../shared/theme/app_assets.dart';
import '../filters/min_rating_filter.dart';
import '../filters/min_votes_filter.dart';
import '../filters/tmdb_genre_filter.dart';
import '../filters/tmdb_language_filter.dart';
import '../filters/year_filter.dart';
import '../models/search_source.dart';
import '../providers/genre_provider.dart';
import '../utils/genre_utils.dart';

/// Источник данных — сериалы из TMDB (без анимации).
class TmdbTvSource extends SearchSource {
  @override
  String get id => 'tv';

  @override
  String get groupId => 'tmdb';

  @override
  String get groupName => 'TMDB';

  @override
  IconData get groupIcon => Icons.movie_outlined;

  @override
  String label(S l) => l.mediaTypeTvShow;

  @override
  IconData get icon => Icons.tv_outlined;

  @override
  String? get iconAsset => AppAssets.iconTmdbColor;

  @override
  bool get supportsBrowse => true;

  @override
  List<SearchFilter> get filters => <SearchFilter>[
        TmdbGenreFilter(type: 'tv'),
        YearFilter(),
        MinRatingFilter(),
        MinVotesFilter(),
        TmdbLanguageFilter(),
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

    final List<int>? genreIds = _readGenreIds(filterValues['genre']);
    final double? minRating =
        (filterValues['minRating'] as num?)?.toDouble();
    final int? minVotes = filterValues['minVotes'] as int?;
    final String? originalLanguage =
        filterValues['originalLanguage'] as String?;

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

      // Клиентская фильтрация по жанрам (multi-select, OR).
      if (genreIds != null && genreIds.isNotEmpty) {
        final Set<String> genreNames = genreIds
            .map((int id) => genreMap[id.toString()])
            .whereType<String>()
            .toSet();
        if (genreNames.isNotEmpty) {
          filtered = filtered
              .where((TvShow s) =>
                  s.genres != null &&
                  s.genres!.any(genreNames.contains))
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
    final List<TvShow> tvShows = await tmdb.discoverTvShows(
      genreIds: _genreIdsToParam(genreIds),
      year: year,
      firstAirDateGte: firstAirDateGte,
      firstAirDateLte: firstAirDateLte,
      voteCountGte: minVotes,
      voteAverageGte: minRating,
      originalLanguage: originalLanguage,
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
