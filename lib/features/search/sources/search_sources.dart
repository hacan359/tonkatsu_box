// Реестр источников поиска.

import 'package:flutter/widgets.dart';

import '../models/search_source.dart';
import 'anilist_anime_source.dart';
import 'anilist_manga_source.dart';
import 'igdb_games_source.dart';
import 'tmdb_anime_source.dart';
import 'tmdb_movies_source.dart';
import 'tmdb_tv_source.dart';
import 'vndb_source.dart';

/// Все зарегистрированные источники поиска.
///
/// Порядок = порядок в popup. Источники одной группы идут подряд.
/// Добавление нового источника — добавить в этот список рядом с группой.
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
    // VNDB
    VndbSource(),
  ],
);

/// Возвращает источник по ID или первый по умолчанию.
SearchSource getSearchSourceById(String id) {
  return searchSources.firstWhere(
    (SearchSource s) => s.id == id,
    orElse: () => searchSources.first,
  );
}

/// Одна группа источников для отображения в popup.
typedef SourceGroupEntry = ({
  String groupId,
  String groupName,
  IconData groupIcon,
  String? groupIconAsset,
  List<SearchSource> sources,
});

/// Группирует источники по [SearchSource.groupId], сохраняя порядок.
///
/// Используется в [SourceDropdown] для построения popup с секциями.
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
