import '../../../shared/models/tv_episode.dart';
import '../../../shared/models/tv_season.dart';
import '../../../shared/models/tv_show.dart';
import '../tvmaze_api.dart';
import 'tv_episode_source.dart';

/// [TvEpisodeSource] backed by the TVmaze API.
///
/// TVmaze returns every episode of a show in one `/shows/{id}/episodes` call,
/// so [getSeasonEpisodes] fetches the full list once per show and filters in
/// memory — the cache warmer asks season by season, and without this each
/// season would re-download the whole list. A failed fetch is not retained so
/// the next call retries.
class TvMazeEpisodeSource implements TvEpisodeSource {
  TvMazeEpisodeSource(this._api);

  final TvMazeApi _api;

  int? _episodesShowId;
  Future<List<TvEpisode>>? _episodes;

  @override
  Future<TvShow?> getShow(int showId) => _api.getShow(showId);

  @override
  Future<List<TvSeason>> getSeasons(int showId) => _api.getSeasons(showId);

  @override
  Future<List<TvEpisode>> getSeasonEpisodes(
    int showId,
    int seasonNumber,
  ) async {
    final List<TvEpisode> all = await _allEpisodes(showId);
    return all
        .where((TvEpisode e) => e.seasonNumber == seasonNumber)
        .toList();
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
