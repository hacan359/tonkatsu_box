import 'package:core/models/media_type.dart';
import 'package:core/models/movie.dart';
import 'package:core/utils/cover_image_id.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_service.dart';
import '../../../core/services/image_cache_service.dart';
import '../../collections/providers/collections_provider.dart';
import '../services/search_collection_adder.dart';
import '../widgets/item_details_sheet.dart';
import 'media_action_handler.dart';

/// Handles [MediaType.movie] and [MediaType.animation]. The "already in"
/// check unions both: the same TMDB id may live under either media type.
class MovieHandler implements MediaActionHandler {
  MovieHandler({
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
    final Movie movie = item as Movie;
    final Set<int> targets = _targetCollections();
    if (targets.isNotEmpty) {
      await _addToCollections(context, targets, movie, mediaType);
      return;
    }
    showDetails(context, movie, mediaType);
  }

  @override
  Future<void> addToAnyCollection(
    BuildContext context,
    Object item,
    MediaType mediaType,
  ) async {
    final Movie movie = item as Movie;
    final Set<int?> alreadyIn = await _adder.collectedCollectionIdsAcross(
      movie.tmdbId,
      collectedMovieIdsProvider,
      collectedAnimationIdsProvider,
      source: movie.source,
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
      externalId: movie.tmdbId,
      platformId: mediaType == MediaType.animation
          ? AnimationSource.movie
          : null,
      source: movie.source,
      title: movie.title,
      upsert: () => _ref.read(movieDaoProvider).upsertMovie(movie),
      imageType: ImageType.moviePoster,
      imageId: coverImageId(
        mediaType: mediaType,
        externalId: movie.tmdbId,
        source: movie.source,
      ),
      imageUrl: movie.posterUrl,
    );
  }

  @override
  void showDetails(BuildContext context, Object item, MediaType mediaType) {
    final Movie movie = item as Movie;
    final bool isAnim = mediaType == MediaType.animation;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext _) => ItemDetailsSheet.movie(
        movie,
        isAnimation: isAnim,
        onAddToCollection: () => addToAnyCollection(context, movie, mediaType),
      ),
    );
  }

  Future<void> _addToCollections(
    BuildContext context,
    Set<int> collectionIds,
    Movie movie,
    MediaType mediaType,
  ) async {
    await _adder.addToCollections(
      context: context,
      collectionIds: collectionIds,
      mediaType: mediaType,
      externalId: movie.tmdbId,
      platformId: mediaType == MediaType.animation
          ? AnimationSource.movie
          : null,
      source: movie.source,
      title: movie.title,
      upsert: () => _ref.read(movieDaoProvider).upsertMovie(movie),
      imageType: ImageType.moviePoster,
      imageId: coverImageId(
        mediaType: mediaType,
        externalId: movie.tmdbId,
        source: movie.source,
      ),
      imageUrl: movie.posterUrl,
    );
  }
}
