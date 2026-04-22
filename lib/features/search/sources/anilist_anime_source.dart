// Источник данных: аниме из AniList.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/anilist_api.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/anime.dart';
import '../../../shared/models/media_type.dart';
import '../filters/anilist_anime_format_filter.dart';
import '../filters/anilist_anime_genre_filter.dart';
import '../filters/anilist_anime_status_filter.dart';
import '../filters/anilist_season_filter.dart';
import '../filters/year_filter.dart';
import '../models/search_source.dart';

/// Размер страницы для запросов к AniList API.
const int _aniListPageSize = 20;

/// Источник данных — аниме из AniList.
class AniListAnimeSource extends SearchSource {
  @override
  String get id => 'anilist_anime';

  @override
  String get groupId => 'anilist';

  @override
  String get groupName => 'AniList';

  @override
  IconData get groupIcon => Icons.auto_stories_outlined;

  @override
  String label(S l) => l.searchSourceAnime;

  @override
  IconData get icon => Icons.play_circle_outline;

  @override
  bool get supportsBrowse => true;

  @override
  List<SearchFilter> get filters => <SearchFilter>[
        AniListAnimeGenreFilter(),
        AniListAnimeStatusFilter(),
        AniListAnimeFormatFilter(),
        YearFilter(),
        AniListSeasonFilter(),
      ];

  @override
  List<BrowseSortOption> get sortOptions => const <BrowseSortOption>[
        BrowseSortOption(id: 'score', apiValue: 'SCORE_DESC'),
        BrowseSortOption(id: 'popularity', apiValue: 'POPULARITY_DESC'),
        BrowseSortOption(id: 'trending', apiValue: 'TRENDING_DESC'),
        BrowseSortOption(id: 'newest', apiValue: 'START_DATE_DESC'),
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
    final AniListApi api = ref.read(aniListApiProvider);

    final List<String>? genres = _readStringList(filterValues['genre']);
    final String? status = filterValues['status'] as String?;
    final String? format = filterValues['format'] as String?;
    final String? season = filterValues['season'] as String?;
    // YearFilter может вернуть int (конкретный год) или (int,int) (декада).
    // AniList `seasonYear` принимает только одно значение; для декады берём
    // нижнюю границу, т.к. AniList fuzzy-search по году более узкий.
    final Object? yearValue = filterValues['year'];
    final int? seasonYear = switch (yearValue) {
      final int y => y,
      final (int start, int _) tuple => tuple.$1,
      _ => null,
    };

    try {
      final (List<Anime> animes, bool hasMore, int totalPages) =
          await api.browseAnime(
        query: query,
        genres: genres,
        status: status,
        format: format,
        season: season,
        seasonYear: seasonYear,
        sort: sortBy,
        page: page,
        perPage: _aniListPageSize,
      );

      return BrowseResult(
        items: animes,
        mediaType: MediaType.anime,
        hasMore: hasMore,
        totalPages: totalPages,
        currentPage: page,
      );
    } on AniListApiException {
      rethrow;
    }
  }

  @override
  Widget? buildDiscoverFeed(BuildContext context, WidgetRef ref) => null;
}

/// Нормализует multi-select значение фильтра в список строк.
List<String>? _readStringList(Object? value) {
  return switch (value) {
    final List<Object?> list => list.whereType<String>().toList(),
    final String single => <String>[single],
    _ => null,
  };
}
