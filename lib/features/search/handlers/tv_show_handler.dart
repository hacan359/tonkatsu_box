import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/tmdb_api.dart';
import '../../../core/database/database_service.dart';
import '../../../core/services/image_cache_service.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/models/tv_episode.dart';
import '../../../shared/models/tv_season.dart';
import '../../../shared/models/tv_show.dart';
import '../../collections/providers/collections_provider.dart';
import '../services/search_collection_adder.dart';
import '../widgets/item_details_sheet.dart';
import 'media_action_handler.dart';

/// TV show source handler (TMDB).
///
/// Handles both [MediaType.tvShow] and [MediaType.animation]
/// (with `platformId = AnimationSource.tvShow`). On successful add the
/// seasons/episodes cache is warmed so the detail screen opens without
/// a network round-trip.
class TvShowHandler implements MediaActionHandler {
  const TvShowHandler({
    required WidgetRef ref,
    required SearchCollectionAdder adder,
    required int? targetCollectionId,
  })  : _ref = ref,
        _adder = adder,
        _targetCollectionId = targetCollectionId;

  final WidgetRef _ref;
  final SearchCollectionAdder _adder;
  final int? _targetCollectionId;

  @override
  Future<void> onTap(
    BuildContext context,
    Object item,
    MediaType mediaType,
  ) async {
    final TvShow tvShow = item as TvShow;
    if (_targetCollectionId != null) {
      await _addToCollection(context, _targetCollectionId, tvShow, mediaType);
      return;
    }
    showDetails(context, tvShow, mediaType);
  }

  @override
  Future<void> addToAnyCollection(
    BuildContext context,
    Object item,
    MediaType mediaType,
  ) async {
    final TvShow tvShow = item as TvShow;
    final Set<int?> alreadyIn = await _adder.collectedCollectionIdsAcross(
      tvShow.tmdbId,
      collectedTvShowIdsProvider,
      collectedAnimationIdsProvider,
    );
    if (!context.mounted) return;

    final PickedCollection? picked = await _adder.pickCollection(
      context: context,
      alreadyIn: alreadyIn,
    );
    if (picked == null || !context.mounted) return;

    await _adder.addToCollection(
      context: context,
      collectionId: picked.id,
      collectionName: picked.name,
      mediaType: mediaType,
      externalId: tvShow.tmdbId,
      platformId: mediaType == MediaType.animation
          ? AnimationSource.tvShow
          : null,
      title: tvShow.title,
      upsert: () => _ref.read(databaseServiceProvider).upsertTvShow(tvShow),
      imageType: ImageType.tvShowPoster,
      imageId: tvShow.tmdbId.toString(),
      imageUrl: tvShow.posterUrl,
      afterAdd: () => _preloadSeasons(tvShow.tmdbId),
    );
  }

  @override
  void showDetails(BuildContext context, Object item, MediaType mediaType) {
    final TvShow tvShow = item as TvShow;
    final bool isAnim = mediaType == MediaType.animation;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext _) => ItemDetailsSheet.tvShow(
        tvShow,
        isAnimation: isAnim,
        onAddToCollection: () => addToAnyCollection(context, tvShow, mediaType),
      ),
    );
  }

  Future<void> _addToCollection(
    BuildContext context,
    int collectionId,
    TvShow tvShow,
    MediaType mediaType,
  ) async {
    await _adder.addToCollection(
      context: context,
      collectionId: collectionId,
      mediaType: mediaType,
      externalId: tvShow.tmdbId,
      platformId: mediaType == MediaType.animation
          ? AnimationSource.tvShow
          : null,
      title: tvShow.title,
      upsert: () => _ref.read(databaseServiceProvider).upsertTvShow(tvShow),
      imageType: ImageType.tvShowPoster,
      imageId: tvShow.tmdbId.toString(),
      imageUrl: tvShow.posterUrl,
      afterAdd: () => _preloadSeasons(tvShow.tmdbId),
    );
  }

  Future<void> _preloadSeasons(int tmdbId) async {
    try {
      final DatabaseService db = _ref.read(databaseServiceProvider);
      final TmdbApi tmdb = _ref.read(tmdbApiProvider);

      List<TvSeason> seasons = await db.getTvSeasonsByShowId(tmdbId);
      if (seasons.isEmpty) {
        seasons = await tmdb.getTvSeasons(tmdbId);
        if (seasons.isNotEmpty) await db.upsertTvSeasons(seasons);
      }
      for (final TvSeason season in seasons) {
        final List<TvEpisode> cached =
            await db.getEpisodesByShowAndSeason(tmdbId, season.seasonNumber);
        if (cached.isEmpty) {
          final List<TvEpisode> episodes =
              await tmdb.getSeasonEpisodes(tmdbId, season.seasonNumber);
          if (episodes.isNotEmpty) await db.upsertEpisodes(episodes);
        }
      }
    } catch (_) {
      // Network/API failure — episodes load on-demand later.
    }
  }
}
