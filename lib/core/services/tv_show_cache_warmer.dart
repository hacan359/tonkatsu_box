import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/data_source.dart';
import '../../shared/models/tv_episode.dart';
import '../../shared/models/tv_season.dart';
import '../../shared/models/tv_show.dart';
import '../api/tmdb_api.dart';
import '../database/database_service.dart';

/// Provider of [TvShowCacheWarmer].
final Provider<TvShowCacheWarmer> tvShowCacheWarmerProvider =
    Provider<TvShowCacheWarmer>((Ref ref) {
  return TvShowCacheWarmer(
    tmdb: ref.watch(tmdbApiProvider),
    db: ref.watch(databaseServiceProvider),
  );
});

/// Warms the TV cache after a show is added to a collection, so the detail
/// screen and progress badges work without another network round-trip.
///
/// List endpoints (search, recommendations) return shows without
/// season/episode totals; [warm] replaces the sparse cached row with full
/// details and caches the show's seasons and their episodes.
class TvShowCacheWarmer {
  /// Creates the warmer over the TMDB API and the local cache.
  TvShowCacheWarmer({
    required TmdbApi tmdb,
    required DatabaseService db,
  })  : _tmdb = tmdb,
        _db = db;

  final TmdbApi _tmdb;
  final DatabaseService _db;

  /// Best-effort: on network/API failure the cache is left as is and data
  /// loads on demand later.
  Future<void> warm(int tmdbId) async {
    try {
      final (TvShow, List<TvSeason>)? full =
          await _tmdb.getTvShowWithSeasons(tmdbId);
      if (full != null) {
        await _db.tvShowDao.upsertTvShow(full.$1);
      }

      List<TvSeason> seasons =
          await _db.tvShowDao.getTvSeasonsByShowId(DataSource.tmdb, tmdbId);
      if (seasons.isEmpty && full != null) {
        seasons = full.$2;
        if (seasons.isNotEmpty) {
          await _db.tvShowDao.upsertTvSeasons(seasons);
        }
      }

      for (final TvSeason season in seasons) {
        final List<TvEpisode> cached = await _db.tvShowDao
            .getEpisodesByShowAndSeason(
                DataSource.tmdb, tmdbId, season.seasonNumber);
        if (cached.isEmpty) {
          final List<TvEpisode> episodes =
              await _tmdb.getSeasonEpisodes(tmdbId, season.seasonNumber);
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
