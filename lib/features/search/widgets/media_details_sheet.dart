import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/image_cache_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/movie.dart';
import '../../../shared/models/tv_show.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/cached_image.dart';
import '../../../shared/widgets/source_badge.dart';

/// Bottom sheet с деталями фильма или сериала.
class MediaDetailsSheet extends StatelessWidget {
  /// Создаёт [MediaDetailsSheet].
  const MediaDetailsSheet({
    required this.title,
    required this.icon,
    this.onAddToCollection,
    this.overview,
    this.year,
    this.rating,
    this.genres,
    this.extraInfo,
    this.posterUrl,
    this.cacheImageType,
    this.cacheImageId,
    this.externalUrl,
    this.dataSource,
    this.backdropUrl,
    super.key,
  });

  /// Создаёт sheet для фильма.
  factory MediaDetailsSheet.movie(
    Movie movie, {
    VoidCallback? onAddToCollection,
    bool isAnimation = false,
  }) {
    return MediaDetailsSheet(
      title: movie.title,
      icon: isAnimation ? Icons.animation : Icons.movie_outlined,
      overview: movie.overview,
      year: movie.releaseYear,
      rating: movie.formattedRating,
      genres: movie.genres,
      extraInfo: movie.runtime != null ? '${movie.runtime} min' : null,
      posterUrl: movie.posterUrl,
      cacheImageType: ImageType.moviePoster,
      cacheImageId: movie.tmdbId.toString(),
      externalUrl: movie.externalUrl,
      backdropUrl: movie.backdropUrl,
      onAddToCollection: onAddToCollection,
    );
  }

  /// Создаёт sheet для сериала.
  factory MediaDetailsSheet.tvShow(
    TvShow tvShow, {
    VoidCallback? onAddToCollection,
    bool isAnimation = false,
  }) {
    return MediaDetailsSheet(
      title: tvShow.title,
      icon: isAnimation ? Icons.animation : Icons.tv_outlined,
      overview: tvShow.overview,
      year: tvShow.firstAirYear,
      rating: tvShow.formattedRating,
      genres: tvShow.genres,
      extraInfo: tvShow.status,
      posterUrl: tvShow.posterUrl,
      cacheImageType: ImageType.tvShowPoster,
      cacheImageId: tvShow.tmdbId.toString(),
      externalUrl: tvShow.externalUrl,
      backdropUrl: tvShow.backdropUrl,
      onAddToCollection: onAddToCollection,
    );
  }

  /// Название.
  final String title;

  /// Описание.
  final String? overview;

  /// Год выпуска.
  final int? year;

  /// Рейтинг (форматированный).
  final String? rating;

  /// Список жанров.
  final List<String>? genres;

  /// Иконка типа медиа.
  final IconData icon;

  /// Дополнительная информация (длительность, статус и т.д.).
  final String? extraInfo;

  /// URL постера.
  final String? posterUrl;

  /// Тип изображения для кэша.
  final ImageType? cacheImageType;

  /// ID изображения для кэша.
  final String? cacheImageId;

  /// URL внешней страницы (TMDB).
  final String? externalUrl;

  /// Источник данных (TMDB по умолчанию).
  final DataSource? dataSource;

  /// URL фонового изображения (backdrop от TMDB).
  final String? backdropUrl;

  /// Callback добавления в коллекцию (если null — кнопка не показывается).
  final VoidCallback? onAddToCollection;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (BuildContext context, ScrollController scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Header: backdrop behind poster+info block
              _buildHeader(context),

              // Rest of content (description + button)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[

              if (overview != null) ...<Widget>[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  S.of(context).searchDescription,
                  style: AppTypography.h3.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  overview!,
                  style: AppTypography.body,
                ),
              ],

              if (onAddToCollection != null) ...<Widget>[
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onAddToCollection!();
                    },
                    icon: const Icon(Icons.add),
                    label: Text(S.of(context).searchAddToCollection),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Header: backdrop (if available) behind poster + title + genres.
  Widget _buildHeader(BuildContext context) {
    final Widget content = Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm,
      ),
      child: Column(
        children: <Widget>[
          // Drag handle
          Center(
            child: Container(
              width: 32,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(80),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Poster + info row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (posterUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  child: CachedImage(
                    imageType: cacheImageType ?? ImageType.moviePoster,
                    imageId: cacheImageId ?? posterUrl!,
                    remoteUrl: posterUrl!,
                    width: 100,
                    height: 150,
                    fit: BoxFit.cover,
                    placeholder: Container(
                      width: 100, height: 150,
                      color: AppColors.surfaceLight,
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: Container(
                      width: 100, height: 150,
                      color: AppColors.surfaceLight,
                      child: Icon(icon,
                          color: AppColors.textSecondary, size: 32),
                    ),
                  ),
                ),
              if (posterUrl != null)
                const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text.rich(
                      TextSpan(children: <InlineSpan>[
                        TextSpan(
                          text: title,
                          style: AppTypography.h2.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (year != null)
                          TextSpan(
                            text: '  $year',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                      ]),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: <Widget>[
                        SourceBadge(
                          source: dataSource ?? DataSource.tmdb,
                          onTap: externalUrl != null
                              ? () => _launchUrl(externalUrl!)
                              : null,
                        ),
                        if (rating != null) ...<Widget>[
                          const SizedBox(width: AppSpacing.sm),
                          const Icon(Icons.star, size: 14,
                              color: AppColors.ratingStar),
                          const SizedBox(width: 2),
                          Text(rating!, style: AppTypography.bodySmall),
                        ],
                        if (extraInfo != null) ...<Widget>[
                          const SizedBox(width: AppSpacing.sm),
                          Icon(icon, size: 14, color: AppColors.brand),
                          const SizedBox(width: 2),
                          Text(extraInfo!, style: AppTypography.bodySmall),
                        ],
                      ],
                    ),
                    if (genres != null && genres!.isNotEmpty) ...<Widget>[
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: genres!.map(_buildGenreChip).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (backdropUrl == null) return content;

    // Backdrop behind content with dark overlay
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: CachedNetworkImage(
            imageUrl: backdropUrl!,
            fit: BoxFit.cover,
            errorWidget:
                (BuildContext context, String url, Object error) =>
                    const SizedBox.shrink(),
          ),
        ),
        // Dark overlay
        Positioned.fill(
          child: Container(color: Colors.black.withAlpha(180)),
        ),
        // Bottom gradient fade
        Positioned(
          left: 0, right: 0, bottom: 0, height: 40,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Colors.transparent,
                  Theme.of(context).scaffoldBackgroundColor,
                ],
              ),
            ),
          ),
        ),
        content,
      ],
    );
  }

  Widget _buildGenreChip(String genre) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Text(
        genre,
        style: AppTypography.caption.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
