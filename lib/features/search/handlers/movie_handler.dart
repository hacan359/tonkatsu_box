import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_service.dart';
import '../../../core/services/image_cache_service.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/models/movie.dart';
import '../../collections/providers/collections_provider.dart';
import '../services/search_collection_adder.dart';
import '../widgets/item_details_sheet.dart';
import 'media_action_handler.dart';

/// Movie source handler (TMDB).
///
/// Handles both [MediaType.movie] and [MediaType.animation]
/// (with `platformId = AnimationSource.movie`). The "already in" check
/// unions movie + animation collections because the same TMDB id may
/// have been added under either media type.
class MovieHandler implements MediaActionHandler {
  const MovieHandler({
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
    final Movie movie = item as Movie;
    if (_targetCollectionId != null) {
      await _addToCollection(context, _targetCollectionId, movie, mediaType);
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
      title: movie.title,
      upsert: () => _ref.read(movieDaoProvider).upsertMovie(movie),
      imageType: ImageType.moviePoster,
      imageId: movie.tmdbId.toString(),
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

  Future<void> _addToCollection(
    BuildContext context,
    int collectionId,
    Movie movie,
    MediaType mediaType,
  ) async {
    await _adder.addToCollection(
      context: context,
      collectionId: collectionId,
      mediaType: mediaType,
      externalId: movie.tmdbId,
      platformId: mediaType == MediaType.animation
          ? AnimationSource.movie
          : null,
      title: movie.title,
      upsert: () => _ref.read(movieDaoProvider).upsertMovie(movie),
      imageType: ImageType.moviePoster,
      imageId: movie.tmdbId.toString(),
      imageUrl: movie.posterUrl,
    );
  }

}
