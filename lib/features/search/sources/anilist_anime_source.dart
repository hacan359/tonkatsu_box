import 'package:core/models/anime.dart';
import 'package:core/models/data_source.dart';
import 'package:core/models/media_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/anilist_api.dart';
import '../../../l10n/app_localizations.dart';
import '../filters/anilist_anime_format_filter.dart';
import '../filters/anilist_anime_status_filter.dart';
import '../filters/anilist_genre_filter.dart';
import '../filters/anilist_tag_filter.dart';
import '../filters/year_filter.dart';
import '../models/search_source.dart';
import '../utils/filter_value_utils.dart';

const int _aniListPageSize = 20;

/// SearchSource backed by AniList, anime tab.
class AniListAnimeSource extends SearchSource {
  @override
  String get id => 'anilist_anime';

  @override
  MediaType get outputMediaType => MediaType.anime;

  @override
  DataSource get dataSource => DataSource.anilist;

  @override
  String label(S l) => l.mediaTypeAnime;

  @override
  IconData get icon => Icons.play_circle_outline;

  @override
  bool get supportsBrowse => true;

  @override
  List<SearchFilter> get filters => <SearchFilter>[
        AniListGenreFilter(forAnime: true),
        AniListTagFilter(forAnime: true),
        AniListAnimeStatusFilter(),
        AniListAnimeFormatFilter(),
        YearFilter(),
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

    final List<String>? genres = readFilterStringList(filterValues['genre']);
    final List<String>? tags = readFilterStringList(filterValues['tag']);
    final String? status = filterValues['status'] as String?;
    final String? format = filterValues['format'] as String?;
    // Year is mapped onto startDate bounds, not seasonYear — the latter
    // is null for many older or cancelled titles.
    final Object? yearValue = filterValues['year'];
    int? startYear;
    int? endYear;
    switch (yearValue) {
      case final int y:
        startYear = y;
        endYear = y;
      case final (int start, int end) tuple:
        startYear = tuple.$1;
        endYear = tuple.$2;
      default:
        break;
    }

    try {
      final (List<Anime> animes, bool hasMore, int totalPages) =
          await api.browseAnime(
        query: query,
        genres: genres,
        tags: tags,
        status: status,
        format: format,
        startYear: startYear,
        endYear: endYear,
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
