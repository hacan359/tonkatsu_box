// Источник данных: игры из IGDB.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/igdb_api.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/game.dart';
import '../../../shared/models/media_type.dart';
import '../filters/igdb_genre_filter.dart';
import '../filters/igdb_platform_filter.dart';
import '../filters/year_filter.dart';
import '../models/search_source.dart';

/// Источник данных — игры из IGDB.
class IgdbGamesSource extends SearchSource {
  @override
  String get id => 'games';

  @override
  String label(S l) => l.mediaTypeGame;

  @override
  IconData get icon => Icons.videogame_asset_outlined;

  @override
  bool get supportsBrowse => true;

  @override
  List<SearchFilter> get filters => <SearchFilter>[
        IgdbGenreFilter(),
        IgdbPlatformFilter(),
        YearFilter(),
      ];

  @override
  List<BrowseSortOption> get sortOptions => const <BrowseSortOption>[
        BrowseSortOption(id: 'rating', apiValue: 'rating desc'),
        BrowseSortOption(id: 'newest', apiValue: 'first_release_date desc'),
        BrowseSortOption(id: 'popular', apiValue: 'total_rating_count desc'),
      ];

  @override
  String searchHint(S l) => l.searchHintGames;

  @override
  Future<BrowseResult> browse(
    Ref ref, {
    required Map<String, Object?> filterValues,
    required String sortBy,
    required int page,
  }) async {
    final IgdbApi igdb = ref.read(igdbApiProvider);

    final int? genreId = filterValues['genre'] as int?;
    final int? platformId = filterValues['platform'] as int?;
    final Object? yearValue = filterValues['year'];

    int? year;
    (int, int)? decade;
    if (yearValue is int) {
      year = yearValue;
    } else if (yearValue is (int, int)) {
      decade = yearValue;
    }

    const int pageSize = 20;
    final int offset = (page - 1) * pageSize;

    final List<Game> games = await igdb.browseGames(
      genreId: genreId,
      platformId: platformId,
      year: year,
      decade: decade,
      sortBy: sortBy,
      limit: pageSize,
      offset: offset,
    );

    return BrowseResult(
      items: games,
      mediaType: MediaType.game,
      hasMore: games.length >= pageSize,
      currentPage: page,
    );
  }

  @override
  Future<BrowseResult> search(
    Ref ref, {
    required String query,
    required int page,
  }) async {
    final IgdbApi igdb = ref.read(igdbApiProvider);

    const int pageSize = 50;
    final int offset = (page - 1) * pageSize;

    final List<Game> games = await igdb.searchGames(
      query: query,
      limit: pageSize,
      offset: offset,
    );

    return BrowseResult(
      items: games,
      mediaType: MediaType.game,
      hasMore: games.length >= pageSize,
      currentPage: page,
    );
  }

  @override
  Widget? buildDiscoverFeed(BuildContext context, WidgetRef ref) => null;
}
