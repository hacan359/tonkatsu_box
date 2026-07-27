import '../../../shared/models/anime.dart';
import '../../../shared/models/data_source.dart';
import '../../../shared/models/tv_episode.dart';
import '../../../shared/models/tv_season.dart';
import '../../../shared/models/tv_show.dart';
import '../kitsu_api.dart';
import 'tv_episode_source.dart';

/// [TvEpisodeSource] backed by Kitsu anime episodes.
///
/// Kitsu has no seasons endpoint and no per-season episode filter, so seasons
/// are synthesized and [getSeasonEpisodes] fetches the full list once per anime
/// and filters in memory (the shape [TvMazeEpisodeSource] already uses). Both
/// the anime record and the episode list are memoized per show id so opening a
/// card does not repeat requests; a failed fetch is dropped so the next call
/// retries.
class KitsuEpisodeSource implements TvEpisodeSource {
  KitsuEpisodeSource(this._api);

  /// Kitsu splits long-running titles into separate anime records, so a record
  /// nearly always carries a single season.
  static const int _synthesizedSeason = 1;

  final KitsuApi _api;

  int? _animeId;
  Future<Anime?>? _anime;

  int? _episodesShowId;
  Future<List<TvEpisode>>? _episodes;

  @override
  Future<TvShow?> getShow(int showId) async {
    final Anime? anime = await _animeRecord(showId);
    return anime == null ? null : _asTvShow(anime);
  }

  /// Seasons come from the episodes themselves — Kitsu has no seasons endpoint,
  /// and long-running records really do carry several seasons (Bleach: 16, with
  /// `number` counting absolutely across all of them). That costs the full
  /// episode list here, but the caller persists the result and the list is
  /// memoized, so expanding a season afterwards needs no further requests.
  ///
  /// Falls back to one synthesized season when the list is unavailable, so an
  /// API failure still renders a tracker instead of nothing.
  @override
  Future<List<TvSeason>> getSeasons(int showId) async {
    final Anime? anime = await _animeRecord(showId);

    List<TvEpisode> episodes;
    try {
      episodes = await _allEpisodes(showId);
    } on Object {
      episodes = const <TvEpisode>[];
    }

    if (episodes.isEmpty) {
      return <TvSeason>[
        _season(
          showId,
          _synthesizedSeason,
          anime?.episodes ?? await _api.getAnimeEpisodeCount(showId),
          anime,
        ),
      ];
    }

    final Map<int, int> countBySeason = <int, int>{};
    for (final TvEpisode ep in episodes) {
      countBySeason[ep.seasonNumber] = (countBySeason[ep.seasonNumber] ?? 0) + 1;
    }

    final List<int> numbers = countBySeason.keys.toList()..sort();
    return <TvSeason>[
      for (final int number in numbers)
        _season(showId, number, countBySeason[number], anime),
    ];
  }

  TvSeason _season(int showId, int number, int? episodeCount, Anime? anime) =>
      TvSeason(
        tmdbShowId: showId,
        seasonNumber: number,
        episodeCount: episodeCount,
        posterUrl: anime?.coverUrl,
        source: DataSource.kitsu,
      );

  @override
  Future<List<TvEpisode>> getSeasonEpisodes(
    int showId,
    int seasonNumber,
  ) async {
    final List<TvEpisode> all = await _allEpisodes(showId);
    final List<TvEpisode> ofSeason = all
        .where((TvEpisode e) => e.seasonNumber == seasonNumber)
        .toList();

    // Records whose episodes carry a different season number would otherwise
    // render an empty tracker, since the season list only holds the
    // synthesized one.
    if (ofSeason.isEmpty && seasonNumber == _synthesizedSeason) return all;
    return ofSeason;
  }

  Future<Anime?> _animeRecord(int showId) {
    if (_animeId != showId || _anime == null) {
      _animeId = showId;
      _anime = _api.getAnimeById(showId).catchError((Object e) {
        if (_animeId == showId) {
          _animeId = null;
          _anime = null;
        }
        throw e;
      });
    }
    return _anime!;
  }

  Future<List<TvEpisode>> _allEpisodes(int showId) {
    if (_episodesShowId != showId || _episodes == null) {
      _episodesShowId = showId;
      _episodes = _api.getAnimeEpisodes(showId).catchError((Object e) {
        if (_episodesShowId == showId) {
          _episodesShowId = null;
          _episodes = null;
        }
        throw e;
      });
    }
    return _episodes!;
  }

  TvShow _asTvShow(Anime anime) {
    return TvShow(
      tmdbId: anime.id,
      title: anime.title,
      originalTitle: anime.titleNative,
      posterUrl: anime.coverUrl,
      backdropUrl: anime.bannerUrl,
      overview: anime.description,
      genres: anime.genres,
      firstAirYear: anime.startYear,
      // Season count is unknown from the anime record alone — it only shows up
      // in the episode list, and this must not drag that in.
      totalEpisodes: anime.episodes,
      rating: anime.rating10,
      status: anime.status,
      externalUrl: anime.externalUrl,
      source: DataSource.kitsu,
    );
  }
}
