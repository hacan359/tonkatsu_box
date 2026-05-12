import 'package:flutter/material.dart';

import '../../../core/database/database_service.dart';
import '../../../core/services/image_cache_service.dart';
import '../../../shared/models/anime.dart';
import '../../../shared/models/custom_media.dart';
import '../../../shared/models/game.dart';
import '../../../shared/models/manga.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/models/movie.dart';
import '../../../shared/models/tv_show.dart';
import '../../../shared/models/visual_novel.dart';

/// Minimal display payload for a mood-grid cell. Resolved from the global
/// `*_cache` tables, so removal of the item from any collection does not
/// affect rendering.
class MoodGridCellMedia {
  /// Creates a [MoodGridCellMedia].
  const MoodGridCellMedia({
    required this.title,
    required this.coverUrl,
    required this.imageType,
    required this.placeholderIcon,
  });

  final String? title;
  final String? coverUrl;
  final ImageType imageType;
  final IconData placeholderIcon;
}

/// Resolves a (mediaType, externalId, platformId) triple to display data.
///
/// Returns null only for unsupported / custom media missing from the
/// `custom_items` table. For other types, returns a payload — possibly with
/// `null` title/cover when the matching `*_cache` row is absent (placeholder).
Future<MoodGridCellMedia> resolveMoodGridCellMedia(
  DatabaseService db,
  MediaType mediaType,
  int externalId,
  int? platformId,
) async {
  switch (mediaType) {
    case MediaType.game:
      final Game? game = await db.getGameById(externalId);
      return MoodGridCellMedia(
        title: game?.name,
        coverUrl: game?.coverUrl,
        imageType: ImageType.gameCover,
        placeholderIcon: Icons.videogame_asset,
      );
    case MediaType.movie:
      final Movie? movie = await db.getMovieByTmdbId(externalId);
      return MoodGridCellMedia(
        title: movie?.title,
        coverUrl: movie?.posterUrl,
        imageType: ImageType.moviePoster,
        placeholderIcon: Icons.movie_outlined,
      );
    case MediaType.tvShow:
      final TvShow? tvShow = await db.getTvShowByTmdbId(externalId);
      return MoodGridCellMedia(
        title: tvShow?.title,
        coverUrl: tvShow?.posterUrl,
        imageType: ImageType.tvShowPoster,
        placeholderIcon: Icons.tv_outlined,
      );
    case MediaType.animation:
      final bool isTvBased = platformId == AnimationSource.tvShow;
      if (isTvBased) {
        final TvShow? tvShow = await db.getTvShowByTmdbId(externalId);
        return MoodGridCellMedia(
          title: tvShow?.title,
          coverUrl: tvShow?.posterUrl,
          imageType: ImageType.tvShowPoster,
          placeholderIcon: Icons.animation,
        );
      }
      final Movie? movie = await db.getMovieByTmdbId(externalId);
      return MoodGridCellMedia(
        title: movie?.title,
        coverUrl: movie?.posterUrl,
        imageType: ImageType.moviePoster,
        placeholderIcon: Icons.animation,
      );
    case MediaType.visualNovel:
      final VisualNovel? vn = await db.getVisualNovel(externalId);
      return MoodGridCellMedia(
        title: vn?.title,
        coverUrl: vn?.imageUrl,
        imageType: ImageType.vnCover,
        placeholderIcon: Icons.menu_book,
      );
    case MediaType.anime:
      final Anime? anime = await db.getAnime(externalId);
      return MoodGridCellMedia(
        title: anime?.title,
        coverUrl: anime?.coverUrl,
        imageType: ImageType.animeCover,
        placeholderIcon: Icons.play_circle_outline,
      );
    case MediaType.manga:
      final Manga? manga = await db.getManga(externalId);
      return MoodGridCellMedia(
        title: manga?.title,
        coverUrl: manga?.coverUrl,
        imageType: ImageType.mangaCover,
        placeholderIcon: Icons.auto_stories,
      );
    case MediaType.custom:
      final CustomMedia? custom = await db.customMediaDao.getById(externalId);
      return MoodGridCellMedia(
        title: custom?.title,
        coverUrl: custom?.coverUrl,
        imageType: ImageType.customCover,
        placeholderIcon: Icons.bookmark_outline,
      );
  }
}
