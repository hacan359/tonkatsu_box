import 'package:flutter/material.dart';

import '../../../core/database/database_service.dart';
import '../../../core/services/image_cache_service.dart';
import '../../../shared/models/anime.dart';
import '../../../shared/models/custom_media.dart';
import '../../../shared/models/game.dart';
import '../../../shared/models/manga.dart';
import '../../../shared/models/data_source.dart';
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
    this.year,
    this.genre,
    this.rating,
  });

  /// Empty payload — used as a stable fallback when no media reference
  /// resolves. Callers can check [title] / [coverUrl] for null.
  static const MoodGridCellMedia empty = MoodGridCellMedia(
    title: null,
    coverUrl: null,
    imageType: ImageType.gameCover,
    placeholderIcon: Icons.image_outlined,
  );

  final String? title;
  final String? coverUrl;
  final ImageType imageType;
  final IconData placeholderIcon;

  /// Release year (game / movie / show / VN / anime / manga / custom).
  final int? year;

  /// Comma-joined genre list. Empty → null.
  final String? genre;

  /// Rating normalised to a 0–10 scale with one decimal of precision.
  final double? rating;
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
  int? platformId, {
  DataSource? source,
}) async {
  switch (mediaType) {
    case MediaType.game:
      final Game? game = await db.gameDao.getGameById(externalId);
      return MoodGridCellMedia(
        title: game?.name,
        coverUrl: game?.coverUrl,
        imageType: ImageType.gameCover,
        placeholderIcon: Icons.videogame_asset,
        year: game?.releaseDate?.year,
        genre: _joinGenres(game?.genres),
        // IGDB rating is 0–100 → normalise to 0–10.
        rating: game?.rating != null ? game!.rating! / 10.0 : null,
      );
    case MediaType.movie:
      final Movie? movie = await db.movieDao.getMovieByTmdbId(externalId);
      return MoodGridCellMedia(
        title: movie?.title,
        coverUrl: movie?.posterUrl,
        imageType: ImageType.moviePoster,
        placeholderIcon: Icons.movie_outlined,
        year: movie?.releaseYear,
        genre: _joinGenres(movie?.genres),
        rating: movie?.rating,
      );
    case MediaType.tvShow:
      final TvShow? tvShow = await db.tvShowDao.getTvShowByTmdbId(externalId);
      return MoodGridCellMedia(
        title: tvShow?.title,
        coverUrl: tvShow?.posterUrl,
        imageType: ImageType.tvShowPoster,
        placeholderIcon: Icons.tv_outlined,
        year: tvShow?.firstAirYear,
        genre: _joinGenres(tvShow?.genres),
        rating: tvShow?.rating,
      );
    case MediaType.animation:
      final bool isTvBased = platformId == AnimationSource.tvShow;
      if (isTvBased) {
        final TvShow? tvShow = await db.tvShowDao.getTvShowByTmdbId(externalId);
        return MoodGridCellMedia(
          title: tvShow?.title,
          coverUrl: tvShow?.posterUrl,
          imageType: ImageType.tvShowPoster,
          placeholderIcon: Icons.animation,
          year: tvShow?.firstAirYear,
          genre: _joinGenres(tvShow?.genres),
          rating: tvShow?.rating,
        );
      }
      final Movie? movie = await db.movieDao.getMovieByTmdbId(externalId);
      return MoodGridCellMedia(
        title: movie?.title,
        coverUrl: movie?.posterUrl,
        imageType: ImageType.moviePoster,
        placeholderIcon: Icons.animation,
        year: movie?.releaseYear,
        genre: _joinGenres(movie?.genres),
        rating: movie?.rating,
      );
    case MediaType.visualNovel:
      final VisualNovel? vn = await db.visualNovelDao.getVisualNovel(externalId);
      return MoodGridCellMedia(
        title: vn?.title,
        coverUrl: vn?.imageUrl,
        imageType: ImageType.vnCover,
        placeholderIcon: Icons.menu_book,
        year: _yearFromVndbDate(vn?.released),
        genre: _joinGenres(vn?.tags),
        rating: vn?.rating,
      );
    case MediaType.anime:
      final Anime? anime = await db.animeDao.getAnime(externalId);
      return MoodGridCellMedia(
        title: anime?.title,
        coverUrl: anime?.coverUrl,
        imageType: ImageType.animeCover,
        placeholderIcon: Icons.play_circle_outline,
        year: anime?.seasonYear ?? anime?.startYear,
        genre: _joinGenres(anime?.genres),
        // AniList score is 0–100 → normalise to 0–10.
        rating:
            anime?.averageScore != null ? anime!.averageScore! / 10.0 : null,
      );
    case MediaType.manga:
      final Manga? manga = await db.mangaDao.getManga(
        externalId,
        source: source ?? DataSource.anilist,
      );
      return MoodGridCellMedia(
        title: manga?.title,
        coverUrl: manga?.coverUrl,
        imageType: ImageType.mangaCover,
        placeholderIcon: Icons.auto_stories,
        year: manga?.startYear,
        genre: _joinGenres(manga?.genres),
        rating:
            manga?.averageScore != null ? manga!.averageScore! / 10.0 : null,
      );
    case MediaType.custom:
      final CustomMedia? custom = await db.customMediaDao.getById(externalId);
      return MoodGridCellMedia(
        title: custom?.title,
        coverUrl: custom?.coverUrl,
        imageType: ImageType.customCover,
        placeholderIcon: Icons.bookmark_outline,
        year: custom?.year,
        genre: _normaliseCustomGenres(custom?.genres),
      );
  }
}

String? _joinGenres(List<String>? genres) {
  if (genres == null || genres.isEmpty) return null;
  return genres.join(', ');
}

String? _normaliseCustomGenres(String? genres) {
  if (genres == null) return null;
  final String trimmed = genres.trim();
  return trimmed.isEmpty ? null : trimmed;
}

/// VNDB releases are stored as `YYYY-MM-DD` or `YYYY-MM` or `YYYY`.
int? _yearFromVndbDate(String? raw) {
  if (raw == null || raw.length < 4) return null;
  return int.tryParse(raw.substring(0, 4));
}
