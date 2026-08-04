import 'package:core/models/tv_episode.dart';
import 'package:core/models/tv_season.dart';
import 'package:core/models/tv_show.dart';

import '../tmdb_api.dart';
import 'tv_episode_source.dart';

/// [TvEpisodeSource] backed by the TMDB API.
class TmdbEpisodeSource implements TvEpisodeSource {
  const TmdbEpisodeSource(this._api);

  final TmdbApi _api;

  @override
  Future<TvShow?> getShow(int showId) => _api.getTvShow(showId);

  @override
  Future<List<TvSeason>> getSeasons(int showId) => _api.getTvSeasons(showId);

  @override
  Future<List<TvEpisode>> getSeasonEpisodes(int showId, int seasonNumber) =>
      _api.getSeasonEpisodes(showId, seasonNumber);
}
