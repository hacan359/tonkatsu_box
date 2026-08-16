import 'package:core/models/tv_episode.dart';
import 'package:core/models/tv_season.dart';
import 'package:core/models/tv_show.dart';

import '../tvdb_api.dart';
import 'tv_episode_source.dart';

/// [TvEpisodeSource] backed by TheTVDB. The full episode list is fetched once
/// and filtered in memory; a failed fetch is dropped so the next call retries.
class TvdbEpisodeSource implements TvEpisodeSource {
  TvdbEpisodeSource(this._api);

  final TvdbApi _api;

  int? _episodesShowId;
  Future<List<TvEpisode>>? _episodes;

  @override
  Future<TvShow?> getShow(int showId) => _api.getSeries(showId);

  @override
  Future<List<TvSeason>> getSeasons(int showId) => _api.getSeasons(showId);

  @override
  Future<List<TvEpisode>> getSeasonEpisodes(
    int showId,
    int seasonNumber,
  ) async {
    final List<TvEpisode> all = await _allEpisodes(showId);
    return all.where((TvEpisode e) => e.seasonNumber == seasonNumber).toList();
  }

  Future<List<TvEpisode>> _allEpisodes(int showId) {
    if (_episodesShowId != showId || _episodes == null) {
      _episodesShowId = showId;
      _episodes = _api.getAllEpisodes(showId).catchError((Object e) {
        if (_episodesShowId == showId) {
          _episodesShowId = null;
          _episodes = null;
        }
        throw e;
      });
    }
    return _episodes!;
  }
}
