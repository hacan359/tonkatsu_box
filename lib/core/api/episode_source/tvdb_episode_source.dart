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
  Future<TvShow?> getShow(int showId) async {
    final TvShow? show = await _api.getSeries(showId);
    if (show == null || show.totalEpisodes != null) return show;
    // TheTVDB states no episode count anywhere in the series record, and
    // without one no progress badge can render a denominator.
    final Map<int, int> counts = await _episodeCountsBySeason(showId);
    // Season 0 holds specials, which no denominator counts.
    final int total = counts.entries
        .where((MapEntry<int, int> e) => e.key > 0)
        .fold(0, (int sum, MapEntry<int, int> e) => sum + e.value);
    return total > 0 ? show.copyWith(totalEpisodes: total) : show;
  }

  @override
  Future<List<TvSeason>> getSeasons(int showId) async {
    final List<TvSeason> seasons = await _api.getSeasons(showId);
    if (seasons.every((TvSeason s) => s.episodeCount != null)) return seasons;
    final Map<int, int> counts = await _episodeCountsBySeason(showId);
    if (counts.isEmpty) return seasons;
    return <TvSeason>[
      for (final TvSeason season in seasons)
        season.episodeCount != null
            ? season
            : season.copyWith(episodeCount: counts[season.seasonNumber] ?? 0),
    ];
  }

  /// Empty when the episode list is unreachable — the tracker still works,
  /// it just cannot show how many episodes a season holds.
  Future<Map<int, int>> _episodeCountsBySeason(int showId) async {
    try {
      final Map<int, int> counts = <int, int>{};
      for (final TvEpisode episode in await _allEpisodes(showId)) {
        counts[episode.seasonNumber] =
            (counts[episode.seasonNumber] ?? 0) + 1;
      }
      return counts;
    } on Exception catch (_) {
      return const <int, int>{};
    }
  }

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
