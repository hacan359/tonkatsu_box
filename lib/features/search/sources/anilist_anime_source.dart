// Источник данных: аниме из AniList.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/anilist_api.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/anime.dart';
import '../../../shared/models/media_type.dart';
import '../filters/anilist_anime_genre_filter.dart';
import '../filters/anilist_anime_status_filter.dart';
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

    final String? genre = filterValues['genre'] as String?;
    final String? status = filterValues['status'] as String?;

    try {
      final (List<Anime> animes, bool hasMore, int totalPages) =
          await api.browseAnime(
        query: query,
        genre: genre,
        status: status,
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
