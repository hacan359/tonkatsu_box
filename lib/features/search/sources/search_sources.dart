import 'package:flutter/widgets.dart';

import '../models/search_source.dart';
import 'anilist_anime_source.dart';
import 'anilist_manga_source.dart';
import 'fantlab_source.dart';
import 'igdb_games_source.dart';
import 'mangabaka_source.dart';
import 'openlibrary_source.dart';
import 'tmdb_anime_source.dart';
import 'tmdb_movies_source.dart';
import 'tmdb_tv_source.dart';
import 'vndb_source.dart';

/// All registered search sources.
///
/// List order is the popup order, and sources of one group must be
/// contiguous. Register a new source here, next to its group.
final List<SearchSource> searchSources = List<SearchSource>.unmodifiable(
  <SearchSource>[
    // TMDB
    TmdbMoviesSource(),
    TmdbTvSource(),
    TmdbAnimeSource(),
    // IGDB
    IgdbGamesSource(),
    // AniList
    AniListAnimeSource(),
    AniListMangaSource(),
    // MangaBaka
    MangaBakaSource(),
    // VNDB
    VndbSource(),
    // Books
    OpenLibrarySource(),
    FantlabSource(),
  ],
);

/// Falls back to the first source for an unknown ID.
SearchSource getSearchSourceById(String id) {
  return searchSources.firstWhere(
    (SearchSource s) => s.id == id,
    orElse: () => searchSources.first,
  );
}

typedef SourceGroupEntry = ({
  String groupId,
  String groupName,
  IconData groupIcon,
  String? groupIconAsset,
  List<SearchSource> sources,
});

/// Sources grouped by [SearchSource.groupId], preserving list order.
final List<SourceGroupEntry> groupedSearchSources = () {
  final List<SourceGroupEntry> groups = <SourceGroupEntry>[];
  String? currentGroupId;

  for (final SearchSource source in searchSources) {
    if (source.groupId != currentGroupId) {
      currentGroupId = source.groupId;
      groups.add((
        groupId: source.groupId,
        groupName: source.groupName,
        groupIcon: source.groupIcon,
        groupIconAsset: source.iconAsset,
        sources: <SearchSource>[source],
      ));
    } else {
      groups.last.sources.add(source);
    }
  }

  return List<SourceGroupEntry>.unmodifiable(groups);
}();
