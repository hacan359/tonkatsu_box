import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';

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
    super.key,
  });

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

              // Постер и основная информация
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (posterUrl != null)
                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusSm),
                      child: CachedNetworkImage(
                        imageUrl: posterUrl!,
                        width: 100,
                        height: 150,
                        fit: BoxFit.cover,
                        placeholder:
                            (BuildContext context, String url) => Container(
                          width: 100,
                          height: 150,
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
                          height: 150,
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
                        Text(
                          title,
                          style: AppTypography.h2.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.md,
                          runSpacing: AppSpacing.sm,
                          children: <Widget>[
                            if (year != null)
                              _buildChip(
                                Icons.calendar_today,
                                year.toString(),
                              ),
                            if (rating != null)
                              _buildChip(Icons.star, rating!),
                            if (extraInfo != null)
                              _buildChip(icon, extraInfo!),
                          ],
                        ),
                        if (genres != null &&
                            genres!.isNotEmpty) ...<Widget>[
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: genres!
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
        Icon(icon, size: 16, color: icon == Icons.star ? AppColors.ratingStar : AppColors.brand),
        const SizedBox(width: AppSpacing.xs),
        Text(label),
      ],
    );
  }
}
