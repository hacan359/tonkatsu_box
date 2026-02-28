// Реестр источников поиска.

import '../models/search_source.dart';
import 'igdb_games_source.dart';
import 'tmdb_anime_source.dart';
import 'tmdb_movies_source.dart';
import 'tmdb_tv_source.dart';

/// Все зарегистрированные источники поиска.
///
/// Порядок = порядок в дропдауне.
/// Добавление нового источника — добавить в этот список.
final List<SearchSource> searchSources = List<SearchSource>.unmodifiable(
  <SearchSource>[
    TmdbMoviesSource(),
    TmdbTvSource(),
    TmdbAnimeSource(),
    IgdbGamesSource(),
  ],
);

/// Возвращает источник по ID или первый по умолчанию.
SearchSource getSearchSourceById(String id) {
  return searchSources.firstWhere(
    (SearchSource s) => s.id == id,
    orElse: () => searchSources.first,
  );
}
