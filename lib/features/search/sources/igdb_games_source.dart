// Источник данных: игры из IGDB.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/igdb_api.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/game.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/theme/app_assets.dart';
import '../filters/igdb_game_mode_filter.dart';
import '../filters/igdb_genre_filter.dart';
import '../filters/igdb_min_rating_filter.dart';
import '../filters/igdb_platform_filter.dart';
import '../filters/year_filter.dart';
import '../models/search_source.dart';

/// Источник данных — игры из IGDB.
class IgdbGamesSource extends SearchSource {
  @override
  String get id => 'games';

  @override
  String get groupId => 'igdb';

  @override
  String get groupName => 'IGDB';

  @override
  IconData get groupIcon => Icons.videogame_asset_outlined;

  @override
  String label(S l) => l.mediaTypeGame;

  @override
  IconData get icon => Icons.videogame_asset_outlined;

  @override
  String? get iconAsset => AppAssets.iconIgdbColor;

  @override
  bool get supportsBrowse => true;

  @override
  List<SearchFilter> get filters => <SearchFilter>[
        IgdbGenreFilter(),
        IgdbPlatformFilter(),
        YearFilter(),
        IgdbMinRatingFilter(),
        IgdbGameModeFilter(),
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
  Future<BrowseResult> fetch(
    Ref ref, {
    String? query,
    required Map<String, Object?> filterValues,
    required String sortBy,
    required int page,
  }) async {
    final IgdbApi igdb = ref.read(igdbApiProvider);

    final List<int>? genreIds = _readIntList(filterValues['genre']);
    final List<int>? platformIds = _readIntList(filterValues['platform']);
    final List<int>? gameModeIds = _readIntList(filterValues['gameMode']);
    // UI хранит 1–10 (как TMDB), IGDB API — 0–100, поэтому ×10.
    final int? minRatingUi = filterValues['minRating'] as int?;
    final int? minRating = minRatingUi == null ? null : minRatingUi * 10;
    final Object? yearValue = filterValues['year'];

    int? year;
    (int, int)? decade;
    if (yearValue is int) {
      year = yearValue;
    } else if (yearValue is (int, int)) {
      decade = yearValue;
    }

    if (query != null && query.isNotEmpty) {
      const int pageSize = 50;
      final int offset = (page - 1) * pageSize;

      final List<Game> games = await igdb.searchGames(
        query: query,
        genreIds: genreIds,
        platformIds: platformIds,
        gameModeIds: gameModeIds,
        minRating: minRating,
        year: year,
        decade: decade,
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

    // Browse mode: фильтры без текста
    const int pageSize = 20;
    final int offset = (page - 1) * pageSize;

    final List<Game> games = await igdb.browseGames(
      genreIds: genreIds,
      platformIds: platformIds,
      gameModeIds: gameModeIds,
      minRating: minRating,
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
  Widget? buildDiscoverFeed(BuildContext context, WidgetRef ref) => null;
}

/// Нормализует значение фильтра (multi-select или single) в [List] of int.
List<int>? _readIntList(Object? value) {
  return switch (value) {
    final List<Object?> list => list.whereType<int>().toList(),
    final int id => <int>[id],
    _ => null,
  };
}
