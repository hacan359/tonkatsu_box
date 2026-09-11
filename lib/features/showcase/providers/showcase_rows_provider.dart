import 'package:core/models/anime.dart';
import 'package:core/models/calendar_entry.dart';
import 'package:core/models/collected_item_info.dart';
import 'package:core/models/collection_item.dart';
import 'package:core/models/data_source.dart';
import 'package:core/models/game.dart';
import 'package:core/models/media_type.dart';
import 'package:core/models/movie.dart';
import 'package:core/models/tv_show.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../core/api/anilist_api.dart';
import '../../../core/api/igdb_api.dart';
import '../../../core/api/listenbrainz_api.dart';
import '../../../core/api/tmdb_api.dart';
import '../../../shared/constants/platform_features.dart';
import '../../../shared/utils/provider_cache.dart';
import '../../collections/providers/collections_provider.dart';
import '../../home/providers/all_items_provider.dart';
import '../../search/providers/genre_provider.dart';
import '../../search/utils/genre_utils.dart';
import '../../settings/providers/settings_provider.dart';
import '../models/showcase_item.dart';
import '../utils/anime_season.dart';
import '../utils/tmdb_region.dart';
import 'showcase_clock_provider.dart';
import 'showcase_settings_provider.dart';

/// Feeds change by the day at most; an hour also keeps the three AniList rows
/// well under its shared 90 requests-per-minute budget.
const Duration showcaseCacheTtl = Duration(hours: 1);

/// Cards a board shows; feeds that take a size fetch [showcaseFetchLimit] so
/// hiding owned titles leaves something to show.
const int showcaseRowLimit = 20;
const int showcaseFetchLimit = 40;

final Logger _log = Logger('Showcase');

typedef ShowcaseRowProvider = AutoDisposeFutureProvider<List<ShowcaseItem>>;

Future<List<ShowcaseItem>> _seasonAnime(
  Ref ref, {
  required AnimeSeasonPoint point,
  required String status,
}) async {
  final String titleLanguage = ref.watch(
    settingsNotifierProvider
        .select((SettingsState s) => s.animeMangaTitleLanguage),
  );
  final AniListApi api = ref.watch(aniListApiProvider);
  final (List<Anime> anime, _, _) = await api.browseAnime(
    season: point.season.aniListValue,
    seasonYear: point.year,
    status: status,
    perPage: showcaseFetchLimit,
  );
  cacheFor(ref, showcaseCacheTtl);
  return anime
      .map((Anime a) => ShowcaseItem.fromAnime(a, titleLanguage))
      .toList();
}

final ShowcaseRowProvider animeThisSeasonProvider =
    FutureProvider.autoDispose<List<ShowcaseItem>>((Ref ref) {
  final DateTime now = ref.watch(showcaseClockProvider)();
  return _seasonAnime(ref, point: animeSeasonFor(now), status: 'RELEASING');
});

final ShowcaseRowProvider animeNextSeasonProvider =
    FutureProvider.autoDispose<List<ShowcaseItem>>((Ref ref) {
  final DateTime now = ref.watch(showcaseClockProvider)();
  return _seasonAnime(
    ref,
    point: nextAnimeSeason(animeSeasonFor(now)),
    status: 'NOT_YET_RELEASED',
  );
});

final ShowcaseRowProvider popularAnimeProvider =
    FutureProvider.autoDispose<List<ShowcaseItem>>((Ref ref) async {
  final String titleLanguage = ref.watch(
    settingsNotifierProvider
        .select((SettingsState s) => s.animeMangaTitleLanguage),
  );
  final AniListApi api = ref.watch(aniListApiProvider);
  final (List<Anime> anime, _, _) =
      await api.browseAnime(sort: 'TRENDING_DESC', perPage: showcaseFetchLimit);
  cacheFor(ref, showcaseCacheTtl);
  return anime
      .map((Anime a) => ShowcaseItem.fromAnime(a, titleLanguage))
      .toList();
});

/// A keyless native build has no TMDB to ask; on web the proxy holds the key.
bool _tmdbUnavailable(TmdbApi api) => !kIsWebBuild && !api.hasApiKey;

/// TMDB localizes titles and overviews, so a language switch must refetch.
void _watchTmdbLanguage(Ref ref) {
  ref.watch(
    settingsNotifierProvider.select((SettingsState s) => s.tmdbLanguage),
  );
}

typedef _MovieRelease = (Movie, String? releaseDate);

/// Release feeds carry the full date the [Movie] model reduces to a year;
/// the other feeds pass null and the card shows no date.
Future<List<ShowcaseItem>> _movieReleases(
  Ref ref,
  Future<List<_MovieRelease>> Function(TmdbApi api, String? region) fetch,
) async {
  final String language = ref.watch(
    settingsNotifierProvider.select((SettingsState s) => s.tmdbLanguage),
  );
  final TmdbApi tmdb = ref.watch(tmdbApiProvider);
  if (_tmdbUnavailable(tmdb)) return const <ShowcaseItem>[];
  final Map<String, String> genreMap =
      await ref.watch(movieGenreMapProvider.future);
  final List<_MovieRelease> releases =
      await fetch(tmdb, tmdbRegionFromLanguage(language));
  cacheFor(ref, showcaseCacheTtl);
  final List<Movie> movies = resolveMovieGenres(
    releases.map((_MovieRelease r) => r.$1).toList(),
    genreMap,
  );
  return <ShowcaseItem>[
    for (int i = 0; i < movies.length; i++)
      ShowcaseItem.fromMovie(movies[i], releaseDate: releases[i].$2),
  ];
}

/// Genre-resolved shows from [fetch], or nothing on a keyless native build.
/// Callers pin the cache themselves once their last await is done.
Future<List<TvShow>> _tmdbTvShows(
  Ref ref,
  Future<List<TvShow>> Function(TmdbApi api) fetch,
) async {
  _watchTmdbLanguage(ref);
  final TmdbApi tmdb = ref.watch(tmdbApiProvider);
  if (_tmdbUnavailable(tmdb)) return const <TvShow>[];
  final Map<String, String> genreMap =
      await ref.watch(tvGenreMapProvider.future);
  return resolveTvGenres(await fetch(tmdb), genreMap);
}

/// TMDB genres dropped from the week's episodes: news, reality, soap, talk,
/// and animation — anime already has its own AniList rows.
const List<int> _tvNoiseGenreIds = <int>[10763, 10764, 10766, 10767, 16];
const int _tvEpisodesWindowDays = 7;
const int _tvMinVoteCount = 10;

/// TMDB has no per-host pacing here; a 20-wide burst congests a phone link.
const int _tvDetailsConcurrency = 5;

/// Shows with an episode in the coming week, most popular first. The list
/// lacks the episode number, so each show costs one details call.
final ShowcaseRowProvider tvEpisodesThisWeekProvider =
    FutureProvider.autoDispose<List<ShowcaseItem>>((Ref ref) async {
  final DateTime today = ref.watch(showcaseClockProvider)();
  final TmdbApi tmdb = ref.watch(tmdbApiProvider);
  final List<TvShow> shows = await _tmdbTvShows(
    ref,
    (TmdbApi api) => api.discoverTvShows(
      airDateGte: CalendarEntry.formatDate(today),
      airDateLte: CalendarEntry.formatDate(
        today.add(const Duration(days: _tvEpisodesWindowDays)),
      ),
      withoutGenreIds: _tvNoiseGenreIds,
      voteCountGte: _tvMinVoteCount,
    ),
  );
  final List<TvShow> shown = shows.take(showcaseRowLimit).toList();
  final List<TmdbNextEpisode?> episodes = await _nextEpisodes(tmdb, shown);
  cacheFor(ref, showcaseCacheTtl);
  return <ShowcaseItem>[
    for (int i = 0; i < shown.length; i++)
      ShowcaseItem.fromTvShow(
        shown[i],
        nextAirDate: episodes[i]?.airDate,
        nextSeason: episodes[i]?.season,
        nextEpisode: episodes[i]?.episode,
      ),
  ];
});

/// One details call per show, [_tvDetailsConcurrency] at a time. A show whose
/// details fail keeps its card without an episode rather than sinking the row.
Future<List<TmdbNextEpisode?>> _nextEpisodes(
  TmdbApi tmdb,
  List<TvShow> shows,
) async {
  final List<TmdbNextEpisode?> result = <TmdbNextEpisode?>[];
  for (int i = 0; i < shows.length; i += _tvDetailsConcurrency) {
    final List<TvShow> chunk =
        shows.sublist(i, (i + _tvDetailsConcurrency).clamp(0, shows.length));
    result.addAll(await Future.wait(chunk.map((TvShow show) async {
      try {
        return await tmdb.getNextEpisodeToAir(show.tmdbId);
      } on Exception catch (e) {
        _log.warning('Next episode lookup failed for ${show.tmdbId}', e);
        return null;
      }
    })));
  }
  return result;
}

final ShowcaseRowProvider nowPlayingProvider =
    FutureProvider.autoDispose<List<ShowcaseItem>>(
  (Ref ref) => _movieReleases(
    ref,
    (TmdbApi api, String? region) =>
        api.getNowPlayingMovieReleases(region: region),
  ),
);

final ShowcaseRowProvider upcomingMoviesProvider =
    FutureProvider.autoDispose<List<ShowcaseItem>>(
  (Ref ref) => _movieReleases(
    ref,
    (TmdbApi api, String? region) =>
        api.getUpcomingMovieReleases(region: region),
  ),
);

final ShowcaseRowProvider trendingMoviesProvider =
    FutureProvider.autoDispose<List<ShowcaseItem>>(
  (Ref ref) => _movieReleases(ref, (TmdbApi api, String? _) async {
    final List<Movie> movies = await api.getTrendingMovies();
    return movies.map((Movie m) => (m, null)).toList();
  }),
);

final ShowcaseRowProvider trendingTvShowsProvider =
    FutureProvider.autoDispose<List<ShowcaseItem>>((Ref ref) async {
  final List<TvShow> shows =
      await _tmdbTvShows(ref, (TmdbApi api) => api.getTrendingTvShows());
  cacheFor(ref, showcaseCacheTtl);
  return shows.map(ShowcaseItem.fromTvShow).toList();
});

final ShowcaseRowProvider upcomingGamesProvider =
    FutureProvider.autoDispose<List<ShowcaseItem>>((Ref ref) async {
  final IgdbApi igdb = ref.watch(igdbApiProvider);
  if (!kIsWebBuild && !igdb.hasCredentials) return const <ShowcaseItem>[];
  final List<Game> games =
      await igdb.getUpcomingGames(limit: showcaseFetchLimit);
  cacheFor(ref, showcaseCacheTtl);
  return games.map(ShowcaseItem.fromGame).toList();
});

/// Most-listened first; singles and EPs are left out to keep it an album row.
final ShowcaseRowProvider freshAlbumsProvider =
    FutureProvider.autoDispose<List<ShowcaseItem>>((Ref ref) async {
  final List<FreshRelease> releases =
      await ref.watch(listenBrainzApiProvider).getFreshReleases();
  cacheFor(ref, showcaseCacheTtl);
  final List<FreshRelease> albums = releases
      .where((FreshRelease r) => r.primaryType?.toLowerCase() == 'album')
      .toList()
    ..sort((FreshRelease a, FreshRelease b) =>
        (b.listenCount ?? 0).compareTo(a.listenCount ?? 0));
  return albums
      .take(showcaseFetchLimit)
      .map((FreshRelease r) => ShowcaseItem.fromAudio(r.toAlbum()))
      .toList();
});

ShowcaseRowProvider showcaseRowProvider(ShowcaseRowId id) => switch (id) {
      ShowcaseRowId.animeThisSeason => animeThisSeasonProvider,
      ShowcaseRowId.animeNextSeason => animeNextSeasonProvider,
      ShowcaseRowId.nowPlaying => nowPlayingProvider,
      ShowcaseRowId.upcomingMovies => upcomingMoviesProvider,
      ShowcaseRowId.tvEpisodesThisWeek => tvEpisodesThisWeekProvider,
      ShowcaseRowId.upcomingGames => upcomingGamesProvider,
      ShowcaseRowId.freshAlbums => freshAlbumsProvider,
      ShowcaseRowId.trendingMovies => trendingMoviesProvider,
      ShowcaseRowId.trendingTvShows => trendingTvShowsProvider,
      ShowcaseRowId.popularAnime => popularAnimeProvider,
    };

/// Drops every row's cache so the next build refetches all of them.
void refreshShowcase(WidgetRef ref) {
  for (final ShowcaseRowId id in ShowcaseRowId.values) {
    ref.invalidate(showcaseRowProvider(id));
  }
}

/// Rows of [group] with the user's biggest library types first; ties keep the
/// declaration order. Empty types stay — the section is about finding new.
final Provider<Map<MediaType, int>> showcaseLibraryCountsProvider =
    Provider<Map<MediaType, int>>((Ref ref) {
  final List<CollectionItem> items =
      ref.watch(visibleAllItemsProvider).valueOrNull ??
          const <CollectionItem>[];
  final Map<MediaType, int> counts = <MediaType, int>{};
  for (final CollectionItem item in items) {
    counts.update(item.mediaType, (int n) => n + 1, ifAbsent: () => 1);
  }
  return counts;
});

final ProviderFamily<List<ShowcaseRowId>, ShowcaseGroup>
    showcaseRowOrderProvider =
    Provider.family<List<ShowcaseRowId>, ShowcaseGroup>(
  (Ref ref, ShowcaseGroup group) {
    final Map<MediaType, int> counts = ref.watch(showcaseLibraryCountsProvider);
    final List<ShowcaseRowId> rows = ShowcaseRowId.inGroup(group);
    rows.sort((ShowcaseRowId a, ShowcaseRowId b) {
      final int byCount =
          (counts[b.mediaType] ?? 0).compareTo(counts[a.mediaType] ?? 0);
      return byCount != 0 ? byCount : a.index.compareTo(b.index);
    });
    return rows;
  },
);

/// Ids already in a collection, keyed the way each row's source keys them.
class ShowcaseOwnedIds {
  const ShowcaseOwnedIds({
    this.tmdbMovies = const <int>{},
    this.tmdbTvShows = const <int>{},
    this.aniListAnime = const <int>{},
    this.igdbGames = const <int>{},
    this.audio = const <int>{},
  });

  final Set<int> tmdbMovies;
  final Set<int> tmdbTvShows;
  final Set<int> aniListAnime;
  final Set<int> igdbGames;
  final Set<int> audio;

  bool contains(ShowcaseItem item) => switch (item.mediaType) {
        MediaType.movie => tmdbMovies.contains(item.externalId),
        MediaType.tvShow => tmdbTvShows.contains(item.externalId),
        MediaType.anime => item.source == DataSource.anilist &&
            aniListAnime.contains(item.externalId),
        MediaType.game => igdbGames.contains(item.externalId),
        MediaType.audio => audio.contains(item.externalId),
        _ => false,
      };
}

final AutoDisposeFutureProvider<ShowcaseOwnedIds> showcaseOwnedIdsProvider =
    FutureProvider.autoDispose<ShowcaseOwnedIds>((Ref ref) async {
  final (
    Map<int, List<CollectedItemInfo>> movies,
    Map<int, List<CollectedItemInfo>> tvShows,
    Map<int, List<CollectedItemInfo>> animations,
    Map<int, List<CollectedItemInfo>> anime,
    Map<int, List<CollectedItemInfo>> games,
    Map<int, List<CollectedItemInfo>> audio,
  ) = await (
    ref.watch(collectedMovieIdsProvider.future),
    ref.watch(collectedTvShowIdsProvider.future),
    ref.watch(collectedAnimationIdsProvider.future),
    ref.watch(collectedAnimeIdsProvider.future),
    ref.watch(collectedGameIdsProvider.future),
    ref.watch(collectedAudioIdsProvider.future),
  ).wait;
  // Multi-source types reuse numeric ids, so only the row's own source counts.
  return ShowcaseOwnedIds(
    tmdbMovies: movies.idsFromSource(DataSource.tmdb),
    tmdbTvShows: <int>{
      ...tvShows.idsFromSource(DataSource.tmdb),
      ...animations.keys,
    },
    aniListAnime: anime.idsFromSource(DataSource.anilist),
    igdbGames: games.keys.toSet(),
    audio: audio.keys.toSet(),
  );
});
