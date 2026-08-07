import 'dart:collection';

import 'package:core/models/media_type.dart';

import '../models/search_source.dart';
import 'anilist_anime_source.dart';
import 'anilist_manga_source.dart';
import 'comicvine_source.dart';
import 'fantlab_source.dart';
import 'google_books_source.dart';
import 'hardcover_source.dart';
import 'igdb_games_source.dart';
import 'kitsu_anime_source.dart';
import 'kitsu_manga_source.dart';
import 'mangabaka_source.dart';
import 'mangadex_source.dart';
import 'openlibrary_source.dart';
import 'tmdb_anime_source.dart';
import 'tmdb_movies_source.dart';
import 'tmdb_tv_source.dart';
import 'tvmaze_tv_source.dart';
import 'vndb_source.dart';

/// All registered search sources. List order drives per-type primary /
/// fallback resolution below; register a new source next to its provider.
final List<SearchSource> searchSources = List<SearchSource>.unmodifiable(
  <SearchSource>[
    // TMDB
    TmdbMoviesSource(),
    TmdbTvSource(),
    TmdbAnimeSource(),
    // TVmaze
    TvMazeTvSource(),
    // IGDB
    IgdbGamesSource(),
    // AniList
    AniListAnimeSource(),
    AniListMangaSource(),
    // MangaBaka
    MangaBakaSource(),
    // MangaDex
    MangaDexSource(),
    // Kitsu
    KitsuAnimeSource(),
    KitsuMangaSource(),
    // VNDB
    VndbSource(),
    // Books
    OpenLibrarySource(),
    FantlabSource(),
    GoogleBooksSource(),
    HardcoverSource(),
    // Comics (a books sub-type)
    ComicVineSource(),
  ],
);

/// Falls back to the first source for an unknown ID.
SearchSource getSearchSourceById(String id) {
  return searchSources.firstWhere(
    (SearchSource s) => s.id == id,
    orElse: () => searchSources.first,
  );
}

/// Sources by [SearchSource.outputMediaType], keeping registration order, so
/// the first entry of a type is its primary source and the rest its fallbacks.
final Map<MediaType, List<SearchSource>> searchSourcesByMediaType = () {
  final Map<MediaType, List<SearchSource>> byType =
      <MediaType, List<SearchSource>>{};
  for (final SearchSource source in searchSources) {
    (byType[source.outputMediaType] ??= <SearchSource>[]).add(source);
  }
  return UnmodifiableMapView<MediaType, List<SearchSource>>(
    byType.map(
      (MediaType type, List<SearchSource> sources) =>
          MapEntry<MediaType, List<SearchSource>>(
        type,
        List<SearchSource>.unmodifiable(sources),
      ),
    ),
  );
}();

/// Media types that have at least one source, in registration order.
final List<MediaType> searchableMediaTypes =
    List<MediaType>.unmodifiable(searchSourcesByMediaType.keys);

List<SearchSource> searchSourcesFor(MediaType type) =>
    searchSourcesByMediaType[type] ?? const <SearchSource>[];

/// Primary source of [type]; null when the type has none (e.g. custom).
SearchSource? primarySearchSourceFor(MediaType? type) {
  if (type == null) return null;
  final List<SearchSource> sources = searchSourcesFor(type);
  return sources.isEmpty ? null : sources.first;
}
