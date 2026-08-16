import 'package:core/models/media_type.dart';
import 'package:core/models/tv_show.dart';
import 'package:core/utils/cover_image_id.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_service.dart';
import '../../../core/services/image_cache_service.dart';
import '../../../core/services/tv_show_cache_warmer.dart';
import '../../collections/providers/collections_provider.dart';
import '../services/search_collection_adder.dart';
import '../widgets/item_details_sheet.dart';
import 'media_action_handler.dart';

/// Handles [MediaType.tvShow] and [MediaType.animation]. A successful add
/// warms the seasons cache so the detail screen opens without a network trip.
class TvShowHandler implements MediaActionHandler {
  TvShowHandler({
    required WidgetRef ref,
    required SearchCollectionAdder adder,
    required Set<int> Function() targetCollections,
  })  : _ref = ref,
        _adder = adder,
        _targetCollections = targetCollections;

  final WidgetRef _ref;
  final SearchCollectionAdder _adder;
  final Set<int> Function() _targetCollections;

  @override
  Future<void> onTap(
    BuildContext context,
    Object item,
    MediaType mediaType,
  ) async {
    final TvShow tvShow = item as TvShow;
    final Set<int> targets = _targetCollections();
    if (targets.isNotEmpty) {
      await _addToCollections(context, targets, tvShow, mediaType);
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
      source: tvShow.source,
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
      source: tvShow.source,
      title: tvShow.title,
      upsert: () => _ref.read(tvShowDaoProvider).upsertTvShow(tvShow),
      imageType: ImageType.tvShowPoster,
      imageId: coverImageId(
        mediaType: mediaType,
        externalId: tvShow.tmdbId,
        source: tvShow.source,
      ),
      imageUrl: tvShow.posterUrl,
      afterAdd: () => _ref.read(tvShowCacheWarmerProvider).warm(tvShow.tmdbId, tvShow.source),
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

  Future<void> _addToCollections(
    BuildContext context,
    Set<int> collectionIds,
    TvShow tvShow,
    MediaType mediaType,
  ) async {
    await _adder.addToCollections(
      context: context,
      collectionIds: collectionIds,
      mediaType: mediaType,
      externalId: tvShow.tmdbId,
      platformId: mediaType == MediaType.animation
          ? AnimationSource.tvShow
          : null,
      source: tvShow.source,
      title: tvShow.title,
      upsert: () => _ref.read(tvShowDaoProvider).upsertTvShow(tvShow),
      imageType: ImageType.tvShowPoster,
      imageId: coverImageId(
        mediaType: mediaType,
        externalId: tvShow.tmdbId,
        source: tvShow.source,
      ),
      imageUrl: tvShow.posterUrl,
      afterAdd: () => _ref.read(tvShowCacheWarmerProvider).warm(tvShow.tmdbId, tvShow.source),
    );
  }
}
