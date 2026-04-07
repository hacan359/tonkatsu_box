// Bottom sheet с деталями манги.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/image_cache_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/manga.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/cached_image.dart';
import '../../../shared/widgets/source_badge.dart';

/// Bottom sheet с деталями манги.
class MangaDetailsSheet extends StatelessWidget {
  /// Создаёт [MangaDetailsSheet].
  const MangaDetailsSheet({
    required this.manga,
    required this.onAddToCollection,
    super.key,
  });

  /// Максимальное количество отображаемых жанров.
  static const int _maxDisplayedGenres = 8;

  /// Манга для отображения.
  final Manga manga;

  /// Callback добавления в коллекцию.
  final VoidCallback onAddToCollection;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);

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
              _buildHeader(context),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[

              if (manga.description != null) ...<Widget>[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l.searchDescription,
                  style: AppTypography.h3.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  manga.description!,
                  style: AppTypography.body,
                ),
              ],

              const SizedBox(height: AppSpacing.xl),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onAddToCollection();
                  },
                  icon: const Icon(Icons.add),
                  label: Text(l.searchAddToCollection),
                ),
              ),
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

  Widget _buildHeader(BuildContext context) {
    final Widget content = Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm,
      ),
      child: Column(
        children: <Widget>[
          Center(
            child: Container(
              width: 32, height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(80),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (manga.coverUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  child: CachedImage(
                    imageType: ImageType.mangaCover,
                    imageId: manga.id.toString(),
                    remoteUrl: manga.coverUrl!,
                    width: 100, height: 142,
                    fit: BoxFit.cover,
                    placeholder: Container(
                      width: 100, height: 142,
                      color: AppColors.surfaceLight,
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: Container(
                      width: 100, height: 142,
                      color: AppColors.surfaceLight,
                      child: const Icon(Icons.auto_stories,
                          color: AppColors.textSecondary, size: 32),
                    ),
                  ),
                ),
              if (manga.coverUrl != null)
                const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text.rich(
                      TextSpan(children: <InlineSpan>[
                        TextSpan(
                          text: manga.title,
                          style: AppTypography.h2.copyWith(
                            fontWeight: FontWeight.bold),
                        ),
                        if (manga.releaseYear != null)
                          TextSpan(
                            text: '  ${manga.releaseYear}',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textTertiary),
                          ),
                      ]),
                    ),
                    if (manga.titleEnglish != null &&
                        manga.titleEnglish != manga.title) ...<Widget>[
                      const SizedBox(height: AppSpacing.xs),
                      Text(manga.titleEnglish!,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary)),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: <Widget>[
                        SourceBadge(
                          source: DataSource.anilist,
                          onTap: manga.externalUrl != null
                              ? () => _launchUrl(manga.externalUrl!)
                              : null,
                        ),
                        if (manga.formattedRating != null) ...<Widget>[
                          const SizedBox(width: AppSpacing.sm),
                          const Icon(Icons.star, size: 14,
                              color: AppColors.ratingStar),
                          const SizedBox(width: 2),
                          Text(manga.formattedRating!,
                              style: AppTypography.bodySmall),
                        ],
                        if (manga.formatLabel != null) ...<Widget>[
                          const SizedBox(width: AppSpacing.sm),
                          Text(manga.formatLabel!,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary)),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (manga.authorsString != null)
                      _buildInfoChip(Icons.person_outline,
                          manga.authorsString!),
                    _buildInfoChip(Icons.menu_book, manga.progressString),
                    if (manga.genres != null &&
                        manga.genres!.isNotEmpty) ...<Widget>[
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: 6, runSpacing: 4,
                        children: manga.genres!
                            .take(_maxDisplayedGenres)
                            .map(_buildGenreChip)
                            .toList(),
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

    if (manga.bannerUrl == null) return content;

    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: CachedNetworkImage(
            imageUrl: manga.bannerUrl!,
            fit: BoxFit.cover,
            errorWidget:
                (BuildContext context, String url, Object error) =>
                    const SizedBox.shrink(),
          ),
        ),
        Positioned.fill(
          child: Container(color: Colors.black.withAlpha(180)),
        ),
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

  Widget _buildInfoChip(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: AppColors.brand),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
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
