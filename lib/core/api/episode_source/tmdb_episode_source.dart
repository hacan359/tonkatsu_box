// TMDB implementation of TvEpisodeSource.

import '../../../shared/models/data_source.dart';
import '../../../shared/models/tv_episode.dart';
import '../../../shared/models/tv_season.dart';
import '../../../shared/models/tv_show.dart';
import '../tmdb_api.dart';
import 'tv_episode_source.dart';

/// [TvEpisodeSource] backed by the TMDB API.
class TmdbEpisodeSource implements TvEpisodeSource {
  /// Creates a [TmdbEpisodeSource] over [api].
  const TmdbEpisodeSource(this._api);

  final TmdbApi _api;

  @override
  DataSource get source => DataSource.tmdb;

  @override
  Future<TvShow?> getShow(int showId) => _api.getTvShow(showId);

  @override
  Future<List<TvSeason>> getSeasons(int showId) => _api.getTvSeasons(showId);

  @override
  Future<List<TvEpisode>> getSeasonEpisodes(int showId, int seasonNumber) =>
      _api.getSeasonEpisodes(showId, seasonNumber);
}
