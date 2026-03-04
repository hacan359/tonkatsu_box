// Bottom sheet с деталями манги.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/models/data_source.dart';
import '../../../shared/models/manga.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';

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
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withAlpha(102),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Обложка и основная информация
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (manga.coverUrl != null)
                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusSm),
                      child: CachedNetworkImage(
                        imageUrl: manga.coverUrl!,
                        width: 100,
                        height: 142,
                        fit: BoxFit.cover,
                        placeholder:
                            (BuildContext context, String url) => Container(
                          width: 100,
                          height: 142,
                          color: AppColors.surfaceLight,
                          child: const Center(
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (BuildContext context, String url,
                                Object error) =>
                            Container(
                          width: 100,
                          height: 142,
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
                        Text(
                          manga.title,
                          style: AppTypography.h2.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (manga.titleEnglish != null &&
                            manga.titleEnglish != manga.title) ...<Widget>[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            manga.titleEnglish!,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.sm),

                        // Бейдж AniList
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: DataSource.anilist.color.withAlpha(51),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                          child: Text(
                            DataSource.anilist.label,
                            style: AppTypography.caption.copyWith(
                              color: DataSource.anilist.color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.md,
                          runSpacing: AppSpacing.sm,
                          children: <Widget>[
                            if (manga.releaseYear != null)
                              _buildChip(
                                Icons.calendar_today,
                                manga.releaseYear.toString(),
                              ),
                            if (manga.formattedRating != null)
                              _buildChip(
                                Icons.star,
                                manga.formattedRating!,
                              ),
                            if (manga.formatLabel != null)
                              _buildChip(
                                Icons.category_outlined,
                                manga.formatLabel!,
                              ),
                            if (manga.statusLabel != null)
                              _buildChip(
                                Icons.info_outline,
                                manga.statusLabel!,
                              ),
                          ],
                        ),
                        if (manga.authorsString != null) ...<Widget>[
                          const SizedBox(height: AppSpacing.sm),
                          _buildChip(
                            Icons.person_outline,
                            manga.authorsString!,
                          ),
                        ],
                        const SizedBox(height: AppSpacing.sm),
                        _buildChip(
                          Icons.menu_book,
                          manga.progressString,
                        ),
                        if (manga.genres != null &&
                            manga.genres!.isNotEmpty) ...<Widget>[
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: manga.genres!
                                .take(_maxDisplayedGenres)
                                .map((String genre) =>
                                    Chip(label: Text(genre)))
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

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
            ],
          ),
        );
      },
    );
  }

  Widget _buildChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(
          icon,
          size: 16,
          color: icon == Icons.star
              ? AppColors.ratingStar
              : AppColors.brand,
        ),
        const SizedBox(width: AppSpacing.xs),
        Flexible(child: Text(label)),
      ],
    );
  }
}
