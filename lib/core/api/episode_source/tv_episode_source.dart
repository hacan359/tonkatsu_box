import 'package:core/models/data_source.dart';
import 'package:core/models/tv_episode.dart';
import 'package:core/models/tv_season.dart';
import 'package:core/models/tv_show.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../kitsu_api.dart';
import '../tmdb_api.dart';
import '../tvdb_api.dart';
import '../tvmaze_api.dart';
import 'kitsu_episode_source.dart';
import 'tmdb_episode_source.dart';
import 'tvdb_episode_source.dart';
import 'tvmaze_episode_source.dart';

/// Season/episode data source for the episode tracker and release calendar.
///
/// Implementations wrap one provider's API and return the shared
/// [TvShow]/[TvSeason]/[TvEpisode] models with [source] stamped.
abstract class TvEpisodeSource {
  Future<TvShow?> getShow(int showId);

  Future<List<TvSeason>> getSeasons(int showId);

  Future<List<TvEpisode>> getSeasonEpisodes(int showId, int seasonNumber);
}

/// Resolves the [TvEpisodeSource] for an item's [DataSource]. Unknown
/// sources fall back to TMDB.
final Provider<TvEpisodeSource Function(DataSource)>
    tvEpisodeSourceResolverProvider =
    Provider<TvEpisodeSource Function(DataSource)>((Ref ref) {
  final TmdbEpisodeSource tmdb =
      TmdbEpisodeSource(ref.watch(tmdbApiProvider));
  final TvMazeEpisodeSource tvmaze =
      TvMazeEpisodeSource(ref.watch(tvMazeApiProvider));
  final KitsuEpisodeSource kitsu =
      KitsuEpisodeSource(ref.watch(kitsuApiProvider));
  final TvdbEpisodeSource tvdb = TvdbEpisodeSource(ref.watch(tvdbApiProvider));
  return (DataSource source) => switch (source) {
        DataSource.tvmaze => tvmaze,
        DataSource.kitsu => kitsu,
        DataSource.tvdb => tvdb,
        _ => tmdb,
      };
});
