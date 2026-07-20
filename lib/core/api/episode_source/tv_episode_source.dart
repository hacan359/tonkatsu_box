// Provider-agnostic source of TV show seasons and episodes.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/data_source.dart';
import '../../../shared/models/tv_episode.dart';
import '../../../shared/models/tv_season.dart';
import '../../../shared/models/tv_show.dart';
import '../tmdb_api.dart';
import 'tmdb_episode_source.dart';

/// Season/episode data source for the episode tracker and release calendar.
///
/// Implementations wrap one provider's API and return the shared
/// [TvShow]/[TvSeason]/[TvEpisode] models with [source] stamped.
abstract class TvEpisodeSource {
  /// Provider this implementation serves.
  DataSource get source;

  /// Show details — used for total season/episode counts.
  Future<TvShow?> getShow(int showId);

  /// The show's season list.
  Future<List<TvSeason>> getSeasons(int showId);

  /// Episodes of one season.
  Future<List<TvEpisode>> getSeasonEpisodes(int showId, int seasonNumber);
}

/// Resolves the [TvEpisodeSource] for an item's [DataSource]. Unknown
/// sources fall back to TMDB.
final Provider<TvEpisodeSource Function(DataSource)>
    tvEpisodeSourceResolverProvider =
    Provider<TvEpisodeSource Function(DataSource)>((Ref ref) {
  final TmdbEpisodeSource tmdb =
      TmdbEpisodeSource(ref.watch(tmdbApiProvider));
  return (DataSource source) => tmdb;
});
