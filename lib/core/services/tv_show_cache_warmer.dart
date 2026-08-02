import 'package:core/models/data_source.dart';
import 'package:core/models/tv_episode.dart';
import 'package:core/models/tv_season.dart';
import 'package:core/models/tv_show.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/episode_source/tv_episode_source.dart';
import '../database/database_service.dart';

/// Provider of [TvShowCacheWarmer].
final Provider<TvShowCacheWarmer> tvShowCacheWarmerProvider =
    Provider<TvShowCacheWarmer>((Ref ref) {
  return TvShowCacheWarmer(
    resolveSource: ref.watch(tvEpisodeSourceResolverProvider),
    db: ref.watch(databaseServiceProvider),
  );
});

/// Warms the TV cache after a show is added, replacing the sparse cached row
/// with full details, seasons and episodes from the show's own [DataSource].
class TvShowCacheWarmer {
  TvShowCacheWarmer({
    required TvEpisodeSource Function(DataSource) resolveSource,
    required DatabaseService db,
  })  : _resolveSource = resolveSource,
        _db = db;

  final TvEpisodeSource Function(DataSource) _resolveSource;
  final DatabaseService _db;

  /// Best-effort; on network/API failure the cache is left as is.
  Future<void> warm(int showId, DataSource source) async {
    try {
      final TvEpisodeSource api = _resolveSource(source);

      final TvShow? show = await api.getShow(showId);
      if (show != null) {
        await _db.tvShowDao.upsertTvShow(show);
      }

      List<TvSeason> seasons =
          await _db.tvShowDao.getTvSeasonsByShowId(source, showId);
      if (seasons.isEmpty) {
        seasons = await api.getSeasons(showId);
        if (seasons.isNotEmpty) {
          await _db.tvShowDao.upsertTvSeasons(seasons);
        }
      }

      for (final TvSeason season in seasons) {
        final List<TvEpisode> cached =
            await _db.tvShowDao.getEpisodesByShowAndSeason(
          source,
          showId,
          season.seasonNumber,
        );
        if (cached.isEmpty) {
          final List<TvEpisode> episodes =
              await api.getSeasonEpisodes(showId, season.seasonNumber);
          if (episodes.isNotEmpty) {
            await _db.tvShowDao.upsertEpisodes(episodes);
          }
        }
      }
    } on Exception catch (_) {
      // Cache stays sparse; episodes load on-demand later.
    }
  }
}
